/*****************************************************************************
 * PlaybackViewController.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit
import MediaPlayer
import AVFoundation

class PlaybackViewController: UIViewController {
    var mediaURL = "https://grins.upc.edu/en/shared/videos/demo.webm/@@download/file/demo.webm"
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var movieView: UIView!
    @IBOutlet weak var timeView: UIView!
    @IBOutlet weak var controlPanel: UIView!
    @IBOutlet weak var toolbar: UINavigationBar!
    @IBOutlet weak var btnPlayPause: UIButton!
    @IBOutlet weak var positionSlider: UISlider!
    @IBOutlet weak var volumeView: MPVolumeView!
    @IBOutlet weak var timeDisplay: UIButton!
    @IBOutlet weak var toolbarItem: UINavigationItem!
    @IBOutlet weak var btnVolume: UIButton!
    
    var mediaPlayer = VLCMediaPlayer()
    var idleTimer = Timer()
    var setPosition: Bool!
    var displayRemainingTime: Bool = true
    var volumeOn: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    func setupUI() {
        var frame = toolbar.frame
        frame.size.height += 20
        toolbar.frame = frame
        toolbarItem.title = URL(string: mediaURL)?.lastPathComponent
        
        timeDisplay.setTitle("", for: .normal)
        
        do {
            try AVAudioSession.sharedInstance().setActive(true, options: AVAudioSession.SetActiveOptions.init())
        } catch {
            print("AVAudioSession set active failed: \(error)")
        }
        
//        var volumeSlider = UISlider()
//        for view in volumeView.subviews {
//            let description = view.self.description
//            if description.contains("MPVolumeSlider") {
//                volumeSlider = (view as? UISlider)!
//                break
//            }
//        }
//        volumeSlider.addTarget(self, action: #selector(volumeSliderAction), for: .valueChanged)
        
        movieView.isUserInteractionEnabled = true
        let tapOnVideoRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleControlsVisible))
        tapOnVideoRecognizer.delegate = self
        movieView.addGestureRecognizer(tapOnVideoRecognizer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setupMediaPLayer()
    }
    
    func setupMediaPLayer() {
        mediaPlayer.delegate = self
        mediaPlayer.drawable = movieView
        mediaPlayer.media = VLCMedia(url: URL(string: mediaURL)!)
        mediaPlayer.addObserver(self, forKeyPath: "time", options: [], context: nil)
        mediaPlayer.addObserver(self, forKeyPath: "remainingTime", options: [], context: nil)
        mediaPlayer.play()
        
        if controlPanel.isHidden {
            toggleControlsVisible()
        }
        resetIdleTimer()
    }
    
    @IBAction func btnBacktapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func playAndPause(_ sender: Any) {
        if mediaPlayer.remainingTime == VLCTime(int: 1) {
            setupMediaPLayer()
        }
        if mediaPlayer.isPlaying {
            mediaPlayer.pause()
            btnPlayPause.setImage(UIImage(named: "play"), for: .normal)
        } else {
            mediaPlayer.play()
            btnPlayPause.setImage(UIImage(named: "pause"), for: .normal)
            DispatchQueue.main.asyncAfter(deadline: .now()+2) {
                let controlsHidden = true
                self.controlPanel.isHidden = controlsHidden
                self.toolbar.isHidden = controlsHidden
                UIApplication.shared.isStatusBarHidden = controlsHidden
            }
        }
    }
    
    @IBAction func positionSliderDrag(_ sender: Any) {
        resetIdleTimer()
    }
    
    @IBAction func positionSliderAction(_ sender: Any) {
        perform(#selector(setPositionForReal), with: nil, afterDelay: 0.3)
        setPosition = false
    }
    
    @IBAction func toggleTimeDisplay() {
        resetIdleTimer()
        displayRemainingTime = !displayRemainingTime
    }
    
    @IBAction func volumeButtonTapped(_ sender: Any) {
        if mediaPlayer.remainingTime != VLCTime(int: 1) {
            if volumeOn {
                btnVolume.setImage(UIImage(named: "volumeOff"), for: .normal)
                mediaPlayer.audio.isMuted = true
            } else {
                btnVolume.setImage(UIImage(named: "volumeOn"), for: .normal)
                mediaPlayer.audio.isMuted = false
            }
            volumeOn = !volumeOn
        }
    }
}

extension PlaybackViewController: VLCMediaPlayerDelegate {
    
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        if mediaPlayer.state == .stopped {
            self.dismiss(animated: true, completion: nil)
        } else if mediaPlayer.state == .playing {
            activityIndicator.isHidden = true
        }
    }
}

extension PlaybackViewController: UIGestureRecognizerDelegate {
    func positionSliderAction(slider: UISlider) {
        resetIdleTimer()
        perform(#selector(setPositionForReal), with: nil, afterDelay: 0.3)
        setPosition = false
    }
    
    func resetIdleTimer() {
        if !idleTimer.isValid {
            idleTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(idleTimerExceeded), userInfo: nil, repeats: false)
        } else {
            if abs(Float(idleTimer.fireDate.timeIntervalSinceNow)) < 5.0 {
                idleTimer.fireDate = Date(timeIntervalSinceNow: 5.0)
            }
        }
    }
    
    @objc func idleTimerExceeded() {
        idleTimer.invalidate()
        if !self.controlPanel.isHidden {
             toggleControlsVisible()
        }
    }
    
    @objc func toggleControlsVisible() {
        if mediaPlayer.isPlaying {
            btnPlayPause.setImage(UIImage(named: "pause"), for: .normal)
        } else {
            btnPlayPause.setImage(UIImage(named: "play"), for: .normal)
        }
        
        let controlsHidden = !self.controlPanel.isHidden
        self.controlPanel.isHidden = controlsHidden
        self.toolbar.isHidden = controlsHidden
        UIApplication.shared.isStatusBarHidden = controlsHidden
        DispatchQueue.main.asyncAfter(deadline: .now()+2) {
            if self.mediaPlayer.isPlaying {
                let controlsHidden = true
                self.controlPanel.isHidden = controlsHidden
                self.toolbar.isHidden = controlsHidden
                UIApplication.shared.isStatusBarHidden = controlsHidden
            }
        }
    }
    
    @objc func setPositionForReal() {
        if !setPosition {
            mediaPlayer.position = positionSlider.value
            setPosition = true
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        positionSlider.value = mediaPlayer.position
        
        var title: String!
        if !displayRemainingTime {
            title = mediaPlayer.remainingTime.stringValue
        } else {
            title = mediaPlayer.time.stringValue
        }
        timeDisplay.setTitle(title, for: .normal)
    }
    
    @objc func volumeSliderAction() {
        resetIdleTimer()
    }
}
