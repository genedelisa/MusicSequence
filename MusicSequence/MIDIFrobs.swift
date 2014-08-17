//
//  MIDIFrobs.swift
//  MusicSequence
//
//  Created by Gene De Lisa on 8/16/14.
//  Copyright (c) 2014 Gene De Lisa. All rights reserved.
//

import Foundation

import AudioToolbox
//import AVFoundation

/**
Loads a standard MIDIfile into a MusicSequence and displays the events to stdout.
*/
class MIDIFrobs {
    
    var musicPlayer:MusicPlayer
    var currentMusicSequence:MusicSequence
    
    init() {
        musicPlayer = nil
        var status = OSStatus(noErr)
        status = NewMusicPlayer(&musicPlayer)
        if !(status == OSStatus(noErr)) {
            println("bad status \(status)")
        }
        
        currentMusicSequence = nil
        currentMusicSequence = loadMIDIFile("ntbldmtn", ext: "mid")
        println("init finished")
    }
    
    func loadMIDIFile(filename:CFString, ext:CFString) -> MusicSequence {
        
        let midiFileURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), filename, ext, nil)
        
        var musicSequence:MusicSequence = nil
        var status = NewMusicSequence(&musicSequence)
        if !(status == OSStatus(noErr)) {
            println("\(__LINE__) bad status \(status)")
            println("creating sequence")
            return nil
        }
        
        var flags:MusicSequenceLoadFlags = MusicSequenceLoadFlags(kMusicSequenceLoadSMF_ChannelsToTracks)
        var typeid = MusicSequenceFileTypeID(kMusicSequenceFile_MIDIType)
        status = MusicSequenceFileLoad(musicSequence,
            midiFileURL,
            typeid,
            flags)
        if !(status == OSStatus(noErr)) {
            println("\(__LINE__) bad status \(status)")
            println("loading file")
            return nil
        }
        
        // if you set up an AUGraph. Otherwise it will be played with a sine wave.
        //        status = MusicSequenceSetAUGraph(musicSequence, self.processingGraph)
        
        currentMusicSequence = musicSequence
        
        // debugging using C(ore) A(udio) show.
        CAShow(UnsafeMutablePointer<MusicSequence>(musicSequence))
        return musicSequence
    }
    
    func getNumberOfTracks(musicSequence:MusicSequence) -> Int {
        var trackCount:UInt32 = 0
        var status = MusicSequenceGetTrackCount(musicSequence, &trackCount)
        if !(status == OSStatus(noErr)) {
            println("bad status \(status)")
            println("getting track count")
        }
        return Int(trackCount)
    }
    
    func getNumberOfTracks() -> Int {
        return getNumberOfTracks(currentMusicSequence)
    }
    
    
    func getTrackN(musicSequence:MusicSequence, n:UInt32) -> MusicTrack {
        var track:MusicTrack = nil
        var status = MusicSequenceGetIndTrack(musicSequence, n, &track)
        if !(status == OSStatus(noErr)) {
            println("bad status \(status)")
        }
        return track
    }
    
    func getTrackN(n:Int) -> MusicTrack {
        var track:MusicTrack = nil
        var status = MusicSequenceGetIndTrack(currentMusicSequence, UInt32(n), &track)
        if !(status == OSStatus(noErr)) {
            println("bad status \(status)")
        }
        return track
    }
    
    //MARK: playback
    func setupPlayer() {
        var musicSequence:MusicSequence = loadMIDIFile("ntbldmtn", ext: "mid")
        setPlayerSequence(musicSequence)
    }
    
    
    func setPlayerSequence(musicSequence:MusicSequence)  {
        var status = OSStatus(noErr)
        status = MusicPlayerSetSequence(musicPlayer, musicSequence)
        if status != OSStatus(noErr) {
            println("bad status \(status)")
        }
        status = MusicPlayerPreroll(musicPlayer)
        if status != OSStatus(noErr) {
            println("bad status \(status)")
        }
    }
    
    func togglePlaying()  {
        var status = OSStatus(noErr)
        
        var playing:Boolean = 0
        status = MusicPlayerIsPlaying(musicPlayer, &playing)
        if playing == 0 {
            MusicPlayerStart(musicPlayer)
            if !(status == OSStatus(noErr)) {
                println("bad status \(status)")
            }
        } else {
            stopPlaying()
        }
    }
    
    func stopPlaying() {
        var status = OSStatus(noErr)
        
        MusicPlayerStop(musicPlayer)
        if !(status == OSStatus(noErr)) {
            println("bad status \(status)")
        }
    }
    
    //MARK: display
    
    func display(musicSequence:MusicSequence)  {
        var status = OSStatus(noErr)
        
        var trackCount:UInt32 = 0
        status = MusicSequenceGetTrackCount(musicSequence, &trackCount)
        if !(status == OSStatus(noErr)) {
            println("bad status \(status)")
            println("in display: getting track count")
        }
        println("There are \(trackCount) tracks")
        
        var track:MusicTrack = nil
        for var i:UInt32 = 0; i < trackCount; i++ {
            status = MusicSequenceGetIndTrack(musicSequence, i, &track)
            if !(status == OSStatus(noErr)) {
                println("bad status \(status)")
            }
            println("\n\nTrack \(i)")
            
            // getting track properties is ugly
            
            var trackLength:MusicTimeStamp = -1
            var prop:UInt32 = UInt32(kSequenceTrackProperty_TrackLength)
            // the size is filled in by the function
            var size:UInt32 = 0
            status = MusicTrackGetProperty(track, prop, &trackLength, &size)
            if !(status == OSStatus(noErr)) {
                println("bad status \(status)")
            }
            println("track length \(trackLength)")
            
            var loopInfo:MusicTrackLoopInfo = MusicTrackLoopInfo(loopDuration: 0,numberOfLoops: 0)
            prop = UInt32(kSequenceTrackProperty_LoopInfo)
            status = MusicTrackGetProperty(track, prop, &loopInfo, &size)
            if !(status == OSStatus(noErr)) {
                println("bad status \(status)")
            }
            println("loop info \(loopInfo.loopDuration)")
            
            iterate(track)
        }
    }
    
    
    func display()  {
        var musicSequence:MusicSequence = loadMIDIFile("ntbldmtn", ext: "mid")
        display(musicSequence)
    }
    
    func getNumberOfEvents(track:MusicTrack) -> Int {
        var	iterator:MusicEventIterator = nil
        var status = OSStatus(noErr)
        var numberOfEvents = 0
        status = NewMusicEventIterator(track, &iterator)
        if !(status == OSStatus(noErr)) {
            println("bad status \(status)")
        }
        var hasCurrentEvent:Boolean = 0
        status = MusicEventIteratorHasCurrentEvent(iterator, &hasCurrentEvent)
        if !(status == OSStatus(noErr)) {
            println("bad status \(status)")
        }
        var eventType:MusicEventType = 0
        var eventTimeStamp:MusicTimeStamp = -1
        var eventData: UnsafePointer<()> = nil
        var eventDataSize:UInt32 = 0
        
        while (hasCurrentEvent != 0) {
            status = MusicEventIteratorGetEventInfo(iterator, &eventTimeStamp, &eventType, &eventData, &eventDataSize)
            if !(status == OSStatus(noErr)) {
                println("bad status \(status)")
            }
            numberOfEvents++
        }
        return numberOfEvents
    }
    
    func getMIDINoteMessages(trackN:Int) -> [MIDINoteMessage] {
        var track = self.getTrackN(trackN)
        return getMIDINoteMessages(track)
        
    }
    
    
    func getMIDINoteMessages(track:MusicTrack) -> [MIDINoteMessage] {
        var	iterator:MusicEventIterator = nil
        var status = OSStatus(noErr)
        var numberOfEvents = 0
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
        var results:[MIDINoteMessage] = []
        while (hasCurrentEvent != 0) {
            status = MusicEventIteratorGetEventInfo(iterator, &eventTimeStamp, &eventType, &eventData, &eventDataSize)
            if status != OSStatus(noErr) {
                println("bad status \(status)")
            }
            if Int(eventType) == kMusicEventType_MIDINoteMessage {
                let data = UnsafePointer<MIDINoteMessage>(eventData)
                let note = data.memory
                results.append(note)
            }
            numberOfEvents++
            status = MusicEventIteratorHasNextEvent(iterator, &hasCurrentEvent)
            if status != OSStatus(noErr) {
                println("bad status \(status)")
            }
            status = MusicEventIteratorNextEvent(iterator)
            if status != OSStatus(noErr) {
                println("bad status \(status)")
            }
        }
        return results
    }
    
    func getEvents(trackN:Int) -> [Any] {
        var track = self.getTrackN(trackN)
        return getEvents(track)
        
    }
    func getEvents(track:MusicTrack) -> [Any] {
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
        var results:[Any] = []
        while (hasCurrentEvent != 0) {
            status = MusicEventIteratorGetEventInfo(iterator, &eventTimeStamp, &eventType, &eventData, &eventDataSize)
            if !(status == OSStatus(noErr)) {
                println("bad status \(status)")
            }
            
            //TODO: save the timestamps
            
            switch Int(eventType) {
            case kMusicEventType_MIDINoteMessage:
                let data = UnsafePointer<MIDINoteMessage>(eventData)
                let note = data.memory
                results.append(note)
                break
                
            case kMusicEventType_ExtendedNote:
                let data = UnsafePointer<ExtendedNoteOnEvent>(eventData)
                let event = data.memory
                results.append(event)
                break
                
            case kMusicEventType_ExtendedTempo:
                let data = UnsafePointer<ExtendedTempoEvent>(eventData)
                let event = data.memory
                results.append(event)
                break
                
            case kMusicEventType_User:
                let data = UnsafePointer<MusicEventUserData>(eventData)
                let event = data.memory
                results.append(event)
                break
                
            case kMusicEventType_Meta:
                let data = UnsafePointer<MIDIMetaEvent>(eventData)
                let event = data.memory
                results.append(event)
                break
                
            case kMusicEventType_MIDIChannelMessage :
                let data = UnsafePointer<MIDIChannelMessage>(eventData)
                let cm = data.memory
                results.append(cm)
                break
                
            case kMusicEventType_MIDIRawData :
                let data = UnsafePointer<MIDIRawData>(eventData)
                let raw = data.memory
                results.append(raw)
                break
                
            case kMusicEventType_Parameter :
                let data = UnsafePointer<ParameterEvent>(eventData)
                let param = data.memory
                results.append(param)
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
            }            }
        return results
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
    
}
