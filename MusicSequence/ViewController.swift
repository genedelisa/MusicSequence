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

