//
//  ViewController.swift
//  AudioQueueRecorder
//
//  Created by Kaoru Tachibana on 2020/05/03.
//  Copyright © 2020 Toyship.org. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var audioRecorder: AudioQueueRecorder?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        audioRecorder = AudioQueueRecorder()
        audioRecorder?.prepare()
        audioRecorder?.prepareQueue()
        audioRecorder?.setupBuffer()
    }

    @IBAction func stopAudio(_ sender: Any) {
        
        audioRecorder?.stopRecord()

    }
    
    @IBAction func startAudio(_ sender: Any) {
        
        audioRecorder?.startRecord()

    }

}

