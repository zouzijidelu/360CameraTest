//
//  VRAudioPlayer.swift
//  VRCapture_iOS
//
//  Created by wzb on 2023/5/19.
//

import UIKit
import AVFoundation

class VRAudioPlayer {

    var audioPlayer: AVAudioPlayer!
    
    func playAudio(imageName: String) {
        guard let audioFilePath = Bundle.main.path(forResource: imageName, ofType: "mp3") else {return}
        let session = AVAudioSession()
        do{
            try session.setCategory(AVAudioSession.Category.playback, options: [])
            try session.setActive(true)
        } catch {
    
        }
        let audioFileUrl = URL(fileURLWithPath: audioFilePath)
        DispatchQueue.global().async {
            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: audioFileUrl)
                self.audioPlayer.volume = 1.0
                self.audioPlayer.play()
            }
            catch {
                print("Player not available")
            }
        }
    }
}
