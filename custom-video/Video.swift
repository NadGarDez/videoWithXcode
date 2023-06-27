//
//  Video.swift
//  custom-video
//
//  Created by Nad on 21/6/23.
//

import Foundation
import UIKit
import AVKit

class Video : UIView, AVPictureInPictureControllerDelegate {
    
    var videoPlayer = AVPlayer()
    var playerLayer:AVPlayerLayer?
    var videoUrl: String?
    var item:AVPlayerItem?
    private var statusContext = UnsafeMutableRawPointer(bitPattern: 0)
    var timer:Timer?
    
    var pipController: AVPictureInPictureController!
    var pipPossibleObservation: NSKeyValueObservation?
    var loadIndicator: UIActivityIndicatorView!
    // buttons
    
    var pictureInPictureButton:UIButton?
    var progressBar:UIProgressView?
    var stopPlayButton:UIButton?

    // pip image
    
    let active = AVPictureInPictureController.pictureInPictureButtonStopImage.withTintColor(UIColor.white)
    let unactive = AVPictureInPictureController.pictureInPictureButtonStopImage.withTintColor(UIColor.white)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
        // setup AVPlayer
        videoUrl = "https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4"
        item = AVPlayerItem(url:URL(string: videoUrl!)!)
        videoPlayer.replaceCurrentItem(with: item)
        
        playerLayer = AVPlayerLayer(player: videoPlayer)
        playerLayer?.frame = self.bounds
       // playerLayer?.player!.addObserver(self, forKeyPath: "status", options: [.new, .old], context: nil)
        self.layer.addSublayer(playerLayer!)
        
        // picture in picture button
        pictureInPictureButton = UIButton()//UIButton(frame: CGRect(x: self.bounds.width-40, y:self.bounds.height - 30 , width: 40, height: 40))
        pictureInPictureButton!.translatesAutoresizingMaskIntoConstraints = false
        pictureInPictureButton?.setImage(active, for: .normal)
        pictureInPictureButton?.setImage(unactive, for: .selected)
        pictureInPictureButton?.addTarget(self, action: #selector(setPictureInPicture), for: .touchUpInside)
        self.setupPictureInPicture()
        self.addSubview(pictureInPictureButton!)
        NSLayoutConstraint.activate([
            pictureInPictureButton!.rightAnchor.constraint(equalTo: rightAnchor, constant: -10),
            pictureInPictureButton!.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
        ])

        
        // progress bar
        
        progressBar = UIProgressView(frame: CGRect(x: bounds.width*0.15, y: bounds.height-30, width: self.bounds.width - (bounds.width*0.3), height:20))
        progressBar!.layer.backgroundColor = UIColor.black.cgColor
        progressBar?.progress = 0.0
        progressBar?.layer.opacity = 0.7
        self.addSubview(progressBar!)

        
        // progressBar?.addTarget(self, action: #selector(seek), for: .valueChanged)
        
        
        //play stop button
        
        stopPlayButton = UIButton(type: .custom)
        stopPlayButton!.setImage(UIImage(systemName: "stop"), for: .normal)
        stopPlayButton!.translatesAutoresizingMaskIntoConstraints = false
        stopPlayButton?.isHidden = true
        addSubview(stopPlayButton!)
        
        stopPlayButton?.addTarget(self, action: #selector(stopStart), for: .touchUpInside)

        NSLayoutConstraint.activate([
            stopPlayButton!.leftAnchor.constraint(equalTo: leftAnchor, constant: 10),
            stopPlayButton!.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
        ])
        
        videoPlayer.addObserver(self, forKeyPath: "timeControlStatus", options: .new, context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.videoDidFinish), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: videoPlayer.currentItem)
        
        // load indicator
        loadIndicator = UIActivityIndicatorView(style: .medium)
        loadIndicator.color = .blue
        loadIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(loadIndicator)
        NSLayoutConstraint.activate([
            loadIndicator!.leftAnchor.constraint(equalTo: leftAnchor, constant: 10),
            loadIndicator!.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
        ])
    
        loadIndicator.startAnimating()
    }
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func play(){
        videoPlayer.play()
    }
    
    
    @IBAction func setPictureInPicture(_ sender: UIButton) {
        if pipController.isPictureInPictureActive {
            pipController.stopPictureInPicture()
        } else {
            pipController.startPictureInPicture()
            self.isHidden = true
        }
    }



    func setupPictureInPicture() {
       
        if AVPictureInPictureController.isPictureInPictureSupported() {
           
            pipController = AVPictureInPictureController(playerLayer: playerLayer!)
            pipController.delegate = self


            pipPossibleObservation = pipController.observe(\AVPictureInPictureController.isPictureInPicturePossible,
options: [.initial, .new]) { [weak self] _, change in
                
                self?.pictureInPictureButton?.isEnabled = change.newValue ?? false
            }
        } else {
           
            pictureInPictureButton?.isHidden = true
        }
    }
    
    @objc private func seek(sender: UISlider){
        let durationInMilliseconds = Float(getMillisecondsFromCMTime((videoPlayer.currentItem?.duration)!))
        let timeToSeekInMilliseconds = (sender.value * durationInMilliseconds)
        videoPlayer.seek(to: getCMTimeFromMilliseconds(Int(timeToSeekInMilliseconds)))
    }
    
    func updateProgressBar(){
        
        if loadIndicator.isAnimating == true {
            loadIndicator.stopAnimating()
        }
        
        if stopPlayButton?.isHidden == true {
            stopPlayButton?.isHidden = false
        }
       
        guard let player = playerLayer?.player else { return }
        if player.rate == 1 && player.currentItem?.duration != nil {
            let currentTime = getMillisecondsFromCMTime(player.currentTime())
            let duration = getMillisecondsFromCMTime(player.currentItem!.duration)
            if duration != 0 {
                let percent = (currentTime * 100) / duration
                progressBar!.progress = Float(percent)/100
            }
            
        }
    }
    
    @objc func videoDidFinish(){
        self.progressBar?.progress = 1
    }
    
    
    
    @objc func stopStart(){
        if videoPlayer.rate == 1 {
            videoPlayer.pause()
            stopPlayButton?.setImage(UIImage(systemName: "play"), for: .normal)
        }
        else {
            videoPlayer.play()
            stopPlayButton?.setImage(UIImage(systemName: "stop"), for: .normal)
        }
    }
    
    func getMillisecondsFromCMTime(_ cmTime: CMTime) -> Int {
        let seconds = CMTimeGetSeconds(cmTime)
        if !seconds.isNaN {
            let milliseconds = Int(seconds * 1000)
            return milliseconds
        } else {
            return 0
        }
    }
    
    func getCMTimeFromMilliseconds(_ milliseconds: Int, timescale: Int32 = 1000) -> CMTime {
        let seconds = Double(milliseconds / 1000)
        let cmTime = CMTime(seconds: seconds, preferredTimescale: timescale)
        return cmTime
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "timeControlStatus" {
            let timeStatus  = AVPlayer.TimeControlStatus(rawValue: change![.newKey] as! Int)!
            switch timeStatus {
                case .paused:
                    self.updateProgressBar()
                    self.stopLoop()
                case .waitingToPlayAtSpecifiedRate:break
                case .playing:
                    self.updateProgressBar()
                    self.startLoop()
                   
                @unknown default: break
            }
        }
        
    }
    
    private func startLoop(){
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            self.updateProgressBar()
        }
    }
    
    private func stopLoop(){
        timer?.invalidate()
    }
    
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        self.isHidden = false
    }
    
}
