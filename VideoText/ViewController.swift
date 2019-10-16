//
//  ViewController.swift
//  VideoText
//
//  Created by MacMaster on 7/11/19.
//  Copyright © 2019 MacMaster. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        guard let url1 = Bundle.main.url(forResource: "movie1", withExtension: "mov") else {
            print("Impossible to find the video.")
            return
        }
        
        let textlayer = CATextLayer()
        textlayer.string = "Test"
        textlayer.backgroundColor = UIColor.blue.cgColor
        textlayer.foregroundColor = UIColor.cyan.cgColor
        textlayer.frame = CGRect(x: 0, y: 0, width: 150, height: 50)
        
        mergeVideoWithOverlay(videoUrl: url1, overlayText: textlayer, completion: {(session) -> Void in
            
        })
    }


    func mergeVideoWithOverlay (videoUrl: URL, overlayText: CATextLayer,
                                completion: @escaping (AVAssetExportSession) -> Void) -> AVAssetExportSession {
        
        // Create main composition & its tracks
        let mainComposition = AVMutableComposition()
        let compositionVideoTrack = mainComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))
        let compositionAudioTrack = mainComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))
        
        // Get source video & audio tracks
        let videoAsset = AVAsset(url: videoUrl)
        let sourceVideoTrack = videoAsset.tracks(withMediaType: AVMediaType.video).first!
        let sourceAudioTrack = videoAsset.tracks(withMediaType: AVMediaType.audio).first!
        
        // Add source tracks to composition
        do {
            try compositionVideoTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: videoAsset.duration), of: sourceVideoTrack, at: CMTime.zero)
            try compositionAudioTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: videoAsset.duration), of: sourceAudioTrack, at: CMTime.zero)
        } catch {
            print("Error with insertTimeRange while exporting video: \(error)")
        }
        
        // Create video composition
        let videoComposition = AVMutableVideoComposition(propertiesOf: sourceVideoTrack.asset!)
        print("Video composition duration: \(CMTimeGetSeconds(mainComposition.duration))")
        
        // -- Set parent layer & set size equal to device bounds
        let parentLayer = CALayer()
        //parentLayer.frame = CGRect(x: 0, y: 0, width: self.videoPreview.bounds.width, height: self.videoPreview.bounds.height)
        parentLayer.frame = CGRect(x: 0, y: 0, width: sourceVideoTrack.naturalSize.width, height: sourceVideoTrack.naturalSize.height)
        parentLayer.contentsGravity = CALayerContentsGravity.resizeAspectFill
        
        // -- Create video layer
        let videoLayer = CALayer()
        videoLayer.frame = parentLayer.frame
        videoLayer.contentsGravity = CALayerContentsGravity.resizeAspectFill
        
        // -- Add sublayers to parent layer
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(overlayText)
        
        // -- Set animation tool
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        videoComposition.renderSize = sourceVideoTrack.naturalSize
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: mainComposition.duration)
        let videotrack = mainComposition.tracks(withMediaType: AVMediaType.video)[0] as! AVAssetTrack
        let layerinstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videotrack)
        instruction.layerInstructions = [layerinstruction]
        videoComposition.instructions = [instruction]
        
        let fileManager = FileManager.default
        var destinationFilePath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        destinationFilePath!.appendPathComponent("text-1-overlay.mp4")
        
        // Create exporter
        let exporter = AVAssetExportSession(asset: mainComposition, presetName: AVAssetExportPresetHighestQuality)!
        exporter.outputURL = destinationFilePath
        exporter.outputFileType = AVFileType.mp4
        exporter.videoComposition = videoComposition
        exporter.shouldOptimizeForNetworkUse = true
        exporter.exportAsynchronously {
            let status = exporter.status
            let message = exporter.error
            
            self.openPreviewScreen(destinationFilePath!)
        }
        
        return exporter
    }
    
    func openPreviewScreen(_ videoURL:URL) -> Void {
        DispatchQueue.main.async {
            
            let player = AVPlayer(url: videoURL)
            let playerController = AVPlayerViewController()
            playerController.player = player
            
            self.present(playerController, animated: true, completion: {
                player.play()
            })
        }
    }
}

