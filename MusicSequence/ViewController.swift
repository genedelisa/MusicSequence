//
//  ViewController.swift
//  MusicSequence
//
//  Created by Gene De Lisa on 8/16/14.
//  Copyright (c) 2014 Gene De Lisa. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var frobs:MIDIFrobs!
    var sampler:MIDISampler!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  frobs = MIDIFrobs()
        // frobs.setupPlayer()
        // frobs.display()
        sampler = MIDISampler()
        
        var sequence = MIDISequence()
        var beat:Float = 1.0
        var scale = [60, 62, 64, 65, 67, 69, 71, 72]
        for note in scale {
            sequence.addNoteToTrack(0, beat: beat++, channel: 0, note: note, velocity: 64, releaseVelocity: 0, duration: 1.0)
        }
        
        
        sequence.display()
        sequence.play()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func playMIDIFile(sender: AnyObject) {
        //        sampler.playMIDIFile()
        // frobs.togglePlaying()
    }
    
}

