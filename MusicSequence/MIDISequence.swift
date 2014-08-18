//
//  MIDISequence.swift
//  MusicSequence
//
//  Created by Gene De Lisa on 8/17/14.
//  Copyright (c) 2014 Gene De Lisa. All rights reserved.
//

import Foundation
import AudioToolbox

/**
Trying to ease the pain of uaing Core Audio.

*/

class MIDISequence : NSObject {
    
    var musicSequence:MusicSequence
    
    override init() {
        musicSequence = nil
        var status = NewMusicSequence(&musicSequence)
        if status != OSStatus(noErr) {
            println("\(__LINE__) bad status \(status) creating sequence")
        }
        
        var track:MusicTrack = nil
        status = MusicSequenceNewTrack(musicSequence, &track)
        if status != OSStatus(noErr) {
            println("\(__LINE__) bad status \(status) creating track")
        }
        
        super.init()
    }
    
    func loadMIDIFile(filename:String, ext:String) -> MusicSequence {
        let fn:CFString = filename as NSString
        let ex:CFString = ext as NSString
        let midiFileURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), fn, ex, nil)
        var flags:MusicSequenceLoadFlags = MusicSequenceLoadFlags(kMusicSequenceLoadSMF_ChannelsToTracks)
        var typeid = MusicSequenceFileTypeID(kMusicSequenceFile_MIDIType)
        var status = MusicSequenceFileLoad(musicSequence,
            midiFileURL,
            typeid,
            flags)
        if status != OSStatus(noErr) {
            println("\(__LINE__) bad status \(status) loading file")
            displayStatus(status)
            return nil
        }
        
        // if you set up an AUGraph. Otherwise it will be played with a sine wave.
        //        status = MusicSequenceSetAUGraph(musicSequence, self.processingGraph)
        
        // debugging using C(ore) A(udio) show.
        CAShow(UnsafeMutablePointer<MusicSequence>(musicSequence))
        return musicSequence
    }
    
    func getNumberOfTracks() -> Int {
        var trackCount:UInt32 = 0
        var status = MusicSequenceGetTrackCount(musicSequence, &trackCount)
        if status != OSStatus(noErr) {
            displayStatus(status)
            println("getting track count")
        }
        return Int(trackCount)
    }
    
    func getTrack(trackIndex:Int) -> MusicTrack {
        var track:MusicTrack = nil
        var status = MusicSequenceGetIndTrack(musicSequence, UInt32(trackIndex), &track)
        if status != OSStatus(noErr) {
            println("bad status \(status) getting track")
            displayStatus(status)
        }
        return track
    }
    
    func getTrackEvents(trackIndex:Int) -> [TimedMIDIEvent] {
        var track = self.getTrack(trackIndex)
        return getTrackEvents(track)
        
    }
    
    func getTrackEvents(track:MusicTrack) -> [TimedMIDIEvent] {
        var	iterator:MusicEventIterator = nil
        var status = OSStatus(noErr)
        status = NewMusicEventIterator(track, &iterator)
        if status != OSStatus(noErr) {
            println("bad status \(status) creating iterator")
            displayStatus(status)
        }
        
        var hasCurrentEvent:Boolean = 0
        status = MusicEventIteratorHasCurrentEvent(iterator, &hasCurrentEvent)
        if status != OSStatus(noErr) {
            println("bad status \(status) checking current event")
            displayStatus(status)
        }
        
        var eventType:MusicEventType = 0
        var eventTimeStamp:MusicTimeStamp = -1
        var eventData: UnsafePointer<()> = nil
        var eventDataSize:UInt32 = 0
        var results:[TimedMIDIEvent] = []
        while (hasCurrentEvent != 0) {
            status = MusicEventIteratorGetEventInfo(iterator, &eventTimeStamp, &eventType, &eventData, &eventDataSize)
            if !(status == OSStatus(noErr)) {
                println("bad status \(status) getting event info")
            }
            
            switch Int(eventType) {
            case kMusicEventType_MIDINoteMessage:
                let data = UnsafePointer<MIDINoteMessage>(eventData)
                let note = data.memory
                
                var te = TimedMIDIEvent(eventType: eventType, eventTimeStamp: eventTimeStamp, event: note)
                results.append(te)
                
                break
                
            case kMusicEventType_ExtendedNote:
                let data = UnsafePointer<ExtendedNoteOnEvent>(eventData)
                let event = data.memory
                var te = TimedMIDIEvent(eventType: eventType, eventTimeStamp: eventTimeStamp, event: event)
                results.append(te)
                break
                
            case kMusicEventType_ExtendedTempo:
                let data = UnsafePointer<ExtendedTempoEvent>(eventData)
                let event = data.memory
                var te = TimedMIDIEvent(eventType: eventType, eventTimeStamp: eventTimeStamp, event: event)
                results.append(te)
                break
                
            case kMusicEventType_User:
                let data = UnsafePointer<MusicEventUserData>(eventData)
                let event = data.memory
                var te = TimedMIDIEvent(eventType: eventType, eventTimeStamp: eventTimeStamp, event: event)
                results.append(te)
                break
                
            case kMusicEventType_Meta:
                let data = UnsafePointer<MIDIMetaEvent>(eventData)
                let event = data.memory
                var te = TimedMIDIEvent(eventType: eventType, eventTimeStamp: eventTimeStamp, event: event)
                results.append(te)
                break
                
            case kMusicEventType_MIDIChannelMessage :
                let data = UnsafePointer<MIDIChannelMessage>(eventData)
                let cm = data.memory
                var te = TimedMIDIEvent(eventType: eventType, eventTimeStamp: eventTimeStamp, event: cm)
                results.append(te)
                break
                
            case kMusicEventType_MIDIRawData :
                let data = UnsafePointer<MIDIRawData>(eventData)
                let raw = data.memory
                var te = TimedMIDIEvent(eventType: eventType, eventTimeStamp: eventTimeStamp, event: raw)
                results.append(te)
                break
                
            case kMusicEventType_Parameter :
                let data = UnsafePointer<ParameterEvent>(eventData)
                let param = data.memory
                var te = TimedMIDIEvent(eventType: eventType, eventTimeStamp: eventTimeStamp, event: param)
                results.append(te)
                break
                
            default:
                println("Something or other \(eventType)")
            }
            
            status = MusicEventIteratorHasNextEvent(iterator, &hasCurrentEvent)
            if status != OSStatus(noErr) {
                println("bad status \(status) checking for next event")
                displayStatus(status)
            }
            status = MusicEventIteratorNextEvent(iterator)
            if status != OSStatus(noErr) {
                println("bad status \(status) going to next event")
                displayStatus(status)
            }
        }
        return results
    }
    
    func addNoteToTrack(trackIndex:Int, beat:Float, channel:Int, note:Int, velocity:Int, releaseVelocity:Int, duration:Float) {
        var track = getTrack(trackIndex)
        addNoteToTrack(track, beat: beat, channel: channel, note: note, velocity: velocity, releaseVelocity: releaseVelocity, duration: duration)
    }
    
    func addNoteToTrack(track:MusicTrack, beat:Float, channel:Int, note:Int, velocity:Int, releaseVelocity:Int, duration:Float) {
        
        var mess = MIDINoteMessage(channel: UInt8(channel), note: UInt8(note), velocity: UInt8(velocity), releaseVelocity: UInt8(releaseVelocity), duration: Float32(duration))
        
        var status = OSStatus(noErr)
        status = MusicTrackNewMIDINoteEvent(track, MusicTimeStamp(beat), &mess)
        if status != OSStatus(noErr) {
            println("bad status \(status) creating note event")
            displayStatus(status)
        }
        
    }
    
    func addChannelMessageToTrack(trackIndex:Int, beat:Float, channel:Int, status:Int, data1:Int, data2:Int, reserved:Int) {
        var track = getTrack(trackIndex)
        addChannelMessageToTrack(track, beat: beat, channel: channel, status: status, data1: data1, data2: data2, reserved: reserved)
    }
    
    func addChannelMessageToTrack(track:MusicTrack, beat:Float, channel:Int, status:Int, data1:Int, data2:Int, reserved:Int) {
        var mess = MIDIChannelMessage(status: UInt8(status), data1: UInt8(data1), data2: UInt8(data2), reserved: UInt8(reserved))
        var status = OSStatus(noErr)
        status = MusicTrackNewMIDIChannelEvent(track, MusicTimeStamp(beat), &mess)
        if status != OSStatus(noErr) {
            println("bad status \(status) creating channel event")
            displayStatus(status)
        }
    }
    
    func display()  {
        var status = OSStatus(noErr)
        
        var trackCount:UInt32 = 0
        status = MusicSequenceGetTrackCount(self.musicSequence, &trackCount)
        
        if status != OSStatus(noErr) {
            displayStatus(status)
            
            println("in display: getting track count")
        }
        println("There are \(trackCount) tracks")
        
        var track:MusicTrack = nil
        for var i:UInt32 = 0; i < trackCount; i++ {
            status = MusicSequenceGetIndTrack(self.musicSequence, i, &track)
            
            if status != OSStatus(noErr) {
                displayStatus(status)
                
            }
            println("\n\nTrack \(i)")
            
            // getting track properties is ugly
            
            var trackLength:MusicTimeStamp = -1
            var prop:UInt32 = UInt32(kSequenceTrackProperty_TrackLength)
            // the size is filled in by the function
            var size:UInt32 = 0
            status = MusicTrackGetProperty(track, prop, &trackLength, &size)
            if status != OSStatus(noErr) {
                println("bad status \(status)")
            }
            println("track length \(trackLength)")
            
            var loopInfo:MusicTrackLoopInfo = MusicTrackLoopInfo(loopDuration: 0,numberOfLoops: 0)
            prop = UInt32(kSequenceTrackProperty_LoopInfo)
            status = MusicTrackGetProperty(track, prop, &loopInfo, &size)
            if status != OSStatus(noErr) {
                println("bad status \(status)")
            }
            println("loop info \(loopInfo.loopDuration)")
            
            iterate(track)
        }
        
        CAShow(UnsafeMutablePointer<MusicSequence>(musicSequence))

    }
    /**
    Itereates over a MusicTrack and prints the MIDI events it contains.
    
    :param: track:MusicTrack the track to iterate
    */
    func iterate(track:MusicTrack) {
        var	iterator:MusicEventIterator = nil
        var status = OSStatus(noErr)
        status = NewMusicEventIterator(track, &iterator)
        if status != OSStatus(noErr) {
            println("bad status \(status)")
        }
        
        var hasCurrentEvent:Boolean = 0
        status = MusicEventIteratorHasCurrentEvent(iterator, &hasCurrentEvent)
        if status != OSStatus(noErr) {
            println("bad status \(status)")
        }
        
        var eventType:MusicEventType = 0
        var eventTimeStamp:MusicTimeStamp = -1
        var eventData: UnsafePointer<()> = nil
        var eventDataSize:UInt32 = 0
        
        while (hasCurrentEvent != 0) {
            status = MusicEventIteratorGetEventInfo(iterator, &eventTimeStamp, &eventType, &eventData, &eventDataSize)
            if status != OSStatus(noErr) {
                println("bad status \(status)")
            }
            
            switch Int(eventType) {
            case kMusicEventType_MIDINoteMessage:
                let data = UnsafePointer<MIDINoteMessage>(eventData)
                let note = data.memory
                println("Note message \(note.note), vel \(note.velocity) dur \(note.duration) at time \(eventTimeStamp)")
                break
                
            case kMusicEventType_ExtendedNote:
                let data = UnsafePointer<ExtendedNoteOnEvent>(eventData)
                let event = data.memory
                println("ext note message")
                break
                
            case kMusicEventType_ExtendedTempo:
                let data = UnsafePointer<ExtendedTempoEvent>(eventData)
                let event = data.memory
                println("ext tempo message")
                NSLog("ExtendedTempoEvent, bpm %f", event.bpm)
                
                break
                
            case kMusicEventType_User:
                let data = UnsafePointer<MusicEventUserData>(eventData)
                let event = data.memory
                println("user message")
                break
                
            case kMusicEventType_Meta:
                let data = UnsafePointer<MIDIMetaEvent>(eventData)
                let event = data.memory
                println("meta message \(event.metaEventType)")
                break
                
            case kMusicEventType_MIDIChannelMessage :
                let data = UnsafePointer<MIDIChannelMessage>(eventData)
                let cm = data.memory
                NSLog("channel event status %X", cm.status)
                NSLog("channel event d1 %X", cm.data1)
                NSLog("channel event d2 %X", cm.data2)
                if (cm.status == (0xC0 & 0xF0)) {
                    println("preset is \(cm.data1)")
                }
                break
                
            case kMusicEventType_MIDIRawData :
                let data = UnsafePointer<MIDIRawData>(eventData)
                let raw = data.memory
                NSLog("MIDIRawData i.e. SysEx, length %lu", raw.length)
                break
                
            case kMusicEventType_Parameter :
                let data = UnsafePointer<ParameterEvent>(eventData)
                let param = data.memory
                NSLog("ParameterEvent, parameterid %lu", param.parameterID)
                break
                
            default:
                println("something or other \(eventType)")
            }
            
            status = MusicEventIteratorHasNextEvent(iterator, &hasCurrentEvent)
            if status != OSStatus(noErr) {
                println("bad status \(status)")
            }
            
            status = MusicEventIteratorNextEvent(iterator)
            if status != OSStatus(noErr) {
                println("bad status \(status)")
            }
        }
    }
    
    /**
    Just for testing. Uses a sine wave.
    */
    func play() {
        var status = OSStatus(noErr)
        
        var musicPlayer:MusicPlayer = nil
        status = NewMusicPlayer(&musicPlayer)
        if status != OSStatus(noErr) {
            println("bad status \(status) creating player")
            displayStatus(status)
            return
        }
        
        status = MusicPlayerSetSequence(musicPlayer, self.musicSequence)
        if status != OSStatus(noErr) {
            displayStatus(status)
            println("setting sequence")
            return
        }
        
        status = MusicPlayerPreroll(musicPlayer)
        if status != OSStatus(noErr) {
            displayStatus(status)
            return
        }
        
        status = MusicPlayerStart(musicPlayer)
        if status != OSStatus(noErr) {
            displayStatus(status)
            return
        }
    }
    
    
    func displayStatus(status:OSStatus) {
        println("Bad status: \(status)")
        var nserror = NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        println("\(nserror.localizedDescription)")
        
        switch status {
            // ugly
        case OSStatus(kAudioToolboxErr_InvalidSequenceType):
            println("Invalid sequence type")
            
        case OSStatus(kAudioToolboxErr_TrackIndexError):
            println("Track index error")
            
        case OSStatus(kAudioToolboxErr_TrackNotFound):
            println("Track not found")
            
        case OSStatus(kAudioToolboxErr_EndOfTrack):
            println("End of track")
            
        case OSStatus(kAudioToolboxErr_StartOfTrack):
            println("start of track")
            
        case OSStatus(kAudioToolboxErr_IllegalTrackDestination):
            println("Illegal destination")
            
        case OSStatus(kAudioToolboxErr_NoSequence):
            println("No Sequence")
            
        case OSStatus(kAudioToolboxErr_InvalidEventType):
            println("Invalid Event Type")
            
        case OSStatus(kAudioToolboxErr_InvalidPlayerState):
            println("Invalid Player State")
            
        case OSStatus(kAudioToolboxErr_CannotDoInCurrentContext):
            println("Cannot do in current context")
            
        default:
            println("Something or other went wrong")
        }
    }
    
    
}