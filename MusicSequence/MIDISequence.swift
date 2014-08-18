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
            println("bad status \(status) getting track count")
            println("getting track count")
        }
        return Int(trackCount)
    }
    
    func getTrack(trackIndex:Int) -> MusicTrack {
        var track:MusicTrack = nil
        var status = MusicSequenceGetIndTrack(musicSequence, UInt32(trackIndex), &track)
        if status != OSStatus(noErr) {
            println("bad status \(status) getting track")
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
        }
        
        var hasCurrentEvent:Boolean = 0
        status = MusicEventIteratorHasCurrentEvent(iterator, &hasCurrentEvent)
        if status != OSStatus(noErr) {
            println("bad status \(status) checking current event")
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
                println("something or other \(eventType)")
            }
            
            status = MusicEventIteratorHasNextEvent(iterator, &hasCurrentEvent)
            if status != OSStatus(noErr) {
                println("bad status \(status) checking for next event")
            }
            status = MusicEventIteratorNextEvent(iterator)
            if status != OSStatus(noErr) {
                println("bad status \(status) going to next event")
            }
        }
        return results
    }
    
    func addNoteToTrack(trackIndex:Int, beat:Float, channel:Int, note:Int, velocity:Int, releaseVelocity:Int, duration:Float) {
        var track = getTrack(trackIndex)
        addNoteToTrack(trackIndex, beat: beat, channel: channel, note: note, velocity: velocity, releaseVelocity: releaseVelocity, duration: duration)
    }
    
    func addNoteToTrack(track:MusicTrack, beat:Float, channel:Int, note:Int, velocity:Int, releaseVelocity:Int, duration:Float) {
        
        var mess = MIDINoteMessage(channel: UInt8(channel), note: UInt8(note), velocity: UInt8(velocity), releaseVelocity: UInt8(releaseVelocity), duration: Float32(duration))
        
        var status = OSStatus(noErr)
        status = MusicTrackNewMIDINoteEvent(track, MusicTimeStamp(beat), &mess)
        if status != OSStatus(noErr) {
            println("bad status \(status) creating note event")
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
        }
    }
    
   

    
}