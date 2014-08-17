//
//  TrackTableViewController.swift
//  MusicSequence
//
//  Created by Gene De Lisa on 8/16/14.
//  Copyright (c) 2014 Gene De Lisa. All rights reserved.
//

import UIKit
import AudioToolbox

class TrackTableViewController: UITableViewController {
    
    var frobs:MIDIFrobs = MIDIFrobs()
    //    var musicSequence:MusicSequence!
    var tracks: [[MIDINoteMessage]] = []
    var events: [[Any]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        //musicSequence = frobs.loadMIDIFile("ntbldmtn", ext: "mid")
        
        
        println("loading tracks")
        var ntracks = frobs.getNumberOfTracks()
        println("n tracks \(ntracks)")
        for var i = 0; i < ntracks; i++ {
            println("getting note messages for track \(i)")
            tracks.append(frobs.getMIDINoteMessages(i))
            events.append(frobs.getEvents(i))
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        //        return frobs.getNumberOfTracks(self.musicSequence)
        println("returning \(tracks.count) sections")
        return tracks.count
    }
    
    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        
        //        var mess = frobs.getMIDINoteMessages(section)
        var track = tracks[section]
        println("returning \(track.count) rows")
        return track.count
    }
    
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("MIDICell", forIndexPath: indexPath) as UITableViewCell
        
        var te = events[indexPath.section][indexPath.row] as TimedMIDIEvent
        var event = te.event
        var t = String(format: "%@%0.2f", "t: ", te.eventTimeStamp)
        
        if event is MIDINoteMessage {
            var note = event as MIDINoteMessage
            var n = String(format: "%@%X", "p: ", note.note)
            var d = String(format: "%@%0.2f", "d: ", note.duration)
            var v = String(format: "%@%X", "v: ", note.velocity)
            var c = String(format: "%@%X", "c: ", note.channel)
            cell.textLabel.text = "\(t) Note \(n) \(d) \(v) \(c)"
        }
        
        if event is MIDIMetaEvent {
            var meta = event as MIDIMetaEvent

            cell.textLabel.text = "\(t) meta event \(meta.metaEventType) \(meta.data)"
        }
        
        if event is ExtendedNoteOnEvent {
            var e = event as ExtendedNoteOnEvent

            cell.textLabel.text = "\(t) extended noteon \(e.duration)"
        }
        
        if event is ExtendedTempoEvent {
            var e = event as ExtendedTempoEvent

            cell.textLabel.text = "\(t) ext tempo \(e.bpm)"
        }
        
        if event is MusicEventUserData {
            var e = event as MusicEventUserData

            cell.textLabel.text = "\(t) user event \(e.length)"
        }
        
        if event is MIDIChannelMessage {
            var e = event as MIDIChannelMessage

            var status = String(format: "%@%X", "status: ", e.status)
            var d1 = String(format: "%@%X", "d1: ", e.data1)
            var d2 = String(format: "%@%X", "d2: ", e.data2)

            cell.textLabel.text = "\(t) chmess \(status) \(d1) \(d2)"
        }
        if event is MIDIRawData {
            var e = event as MIDIRawData
            
            cell.textLabel.text = "\(t) SysEx \(e.length)"
        }
        
        if event is ParameterEvent {
            var e = event as ParameterEvent
            
            cell.textLabel.text = "\(t) au parameter \(e.parameterID)"
        }
        
        return cell
    }
    
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView!, canEditRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
    // Return NO if you do not want the specified item to be editable.
    return true
    }
    */
    
    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!) {
    if editingStyle == .Delete {
    // Delete the row from the data source
    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    } else if editingStyle == .Insert {
    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
    }
    */
    
    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView!, moveRowAtIndexPath fromIndexPath: NSIndexPath!, toIndexPath: NSIndexPath!) {
    
    }
    */
    
    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView!, canMoveRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
    // Return NO if you do not want the item to be re-orderable.
    return true
    }
    */
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    }
    */
    
}
