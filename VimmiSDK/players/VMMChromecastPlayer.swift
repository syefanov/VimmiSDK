
//
//  VMMChromecastPlayer.swift
//  VimmiPlayer
//
//  Created by Serhii Yefanov on 4/13/18.
//  Copyright © 2018 Serhii Yefanov. All rights reserved.
//

import UIKit
import GoogleCast

@objc public class VMMChromecastPlayer: VMMCorePlayer {
    
    private var externalPlayerOverlay : VMMPlayerOverlayView?
    
    private var _currentAsset : VMMVideoAsset? //backing var
    override public var currentAsset: VMMAsset? {
        get { return self._currentAsset }
        set {
            if newValue is VMMVideoAsset {
                self._currentAsset = newValue as? VMMVideoAsset
            }
        }
    }
    
    private var playerTimer : Timer?
    private var timerRunning : Bool = false
    private var seekRequest : GCKRequest?
    
    @objc public override init() {
        super.init()
        
        VMMGlobalVideoHandler.shared.currentChromecastPlayer = self
    }
    
    // MARK: - Private methods
    
    fileprivate func runTimer() {
        self.stopTimer()
        
        playerTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(firePlayerTimer), userInfo: nil, repeats: true)
        self.timerRunning = true
    }
    
    fileprivate func stopTimer() {
        if self.playerTimer != nil {
            self.playerTimer?.invalidate()
            self.playerTimer = nil
            self.timerRunning = false
        }
    }
    
    @objc private func firePlayerTimer() {
        if let time = GCKCastContext.sharedInstance().sessionManager.currentSession?.remoteMediaClient?.approximateStreamPosition() {
            VMMGlobalVideoHandler.shared.currentChromecastPlayer?.currentAsset?.currentPlaybackTime = time
            self.playerTimeObserverFired(time: time)
        }
    }
    
    // MARK: - Public methods
    
    override public var isPlaying: Bool {
        if let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession {
            guard let state = session.remoteMediaClient?.mediaStatus?.playerState else { return false }
            return state == .playing
        }
        
        return false
    }
    
    @objc public func playAsset(_ asset: VMMVideoAsset) {
        self.currentAsset = asset
        if let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession {
            let metadata = GCKMediaMetadata(metadataType: .movie)
            if let title = self.currentAsset?.title {
                metadata.setString(title, forKey: kGCKMetadataKeyTitle)
            }
            if let imageLink = self.currentAsset?.imagePosterLink {
                metadata.addImage(GCKImage(url: URL(string: imageLink)!, width: 0, height: 0))
            }
            
            let mediaInfo = GCKMediaInformation(contentID: asset.assetUrl.absoluteString,
                                                streamType: .buffered,
                                                contentType: "video/mp4",
                                                metadata: metadata,
                                                streamDuration: 0.0,
                                                mediaTracks: nil,
                                                textTrackStyle: nil,
                                                customData: nil)
            
            let loadingOptions = GCKMediaLoadOptions()
            loadingOptions.playPosition = asset.currentPlaybackTime
            loadingOptions.autoplay = true
            
            if let client = session.remoteMediaClient {
                let request = client.loadMedia(mediaInfo, with: loadingOptions)
                request.delegate = self
            }
        }
    }
    
    override public func updateWithPlayerView(_ playerView: UIView) {
        self.playerView = playerView as? VMMPlayerView
        self.externalPlayerOverlay = VMMPlayerOverlayView(frame: playerView.bounds)
        
        self.externalPlayerOverlay!.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.externalPlayerOverlay!.backgroundColor = .clear
        
        let name = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.device.friendlyName
        
        if let image = self.currentAsset?.imageBackdrop {
            self.externalPlayerOverlay?.overlayImage.image = image
        }
        else if let imageLink = self.currentAsset?.imageBackdropLink,
            let imageUrl = URL(string: imageLink) {
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: imageUrl)
                DispatchQueue.main.async {
                    self.externalPlayerOverlay?.overlayImage.image = UIImage(data: data!)
                }
            }
        }
        self.externalPlayerOverlay?.labelText.text = "Currently playing on \(name ?? "Chromecast")"
        
        playerView.addSubview(self.externalPlayerOverlay!)
    }
    
    @objc public override func detachPlayerView() -> UIView? {
        self.externalPlayerOverlay?.removeFromSuperview()
        
        return self.playerView
    }
    
    override public func play() {
        if let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession {
            session.remoteMediaClient?.play()
        }
    }
    
    override public func pause() {
        if let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession {
            session.remoteMediaClient?.pause()
        }
    }
    
    override public func setPlayerPlaybackTime(timeInSeconds time: Double, completion: (() -> Void)?) {
        if let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession {
            let seekOptions = GCKMediaSeekOptions()
            seekOptions.interval = time
            self.seekRequest = session.remoteMediaClient?.seek(with: seekOptions)
        }
    }
    
    override public func moveForward(onSeconds seconds: Double) {
        if let currentTime = GCKCastContext.sharedInstance().sessionManager.currentSession?.remoteMediaClient?.approximateStreamPosition() {
            var time = currentTime + seconds
            if let duration = currentAsset?.assetDuration,
                time > duration {
                time = duration
            }
            self.setPlayerPlaybackTime(timeInSeconds: time, completion:nil)
        }
    }
    
    override public func moveBackward(onSeconds seconds: Double) {
        if let currentTime = GCKCastContext.sharedInstance().sessionManager.currentSession?.remoteMediaClient?.approximateStreamPosition() {
            var time = currentTime - seconds
            if time < 0 {
                time = 0
            }
            self.setPlayerPlaybackTime(timeInSeconds: time, completion:nil)
        }
    }
    
    override public func stopPlaying() {
        if let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession {
            session.remoteMediaClient?.stop()
        }
    }
}

extension VMMChromecastPlayer: GCKRemoteMediaClientListener {
    public func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        if let state = mediaStatus?.playerState {
            if state == .idle {
                if mediaStatus?.idleReason == GCKMediaPlayerIdleReason.error {
                    self.playerDidFailLoadingAsset(self.currentAsset, error: VMMPlayerError.ChromecastLoadingError)
                }
                else if mediaStatus?.idleReason == GCKMediaPlayerIdleReason.finished {
                    self.playerDidFinishPlaying()
                }
            }
            
        }
        if let state = mediaStatus?.playerState {
            if state == .playing {
                if timerRunning == false {
                    self.runTimer()
                    self.playerDidStartPlaying()
                }
            }
            else {
                self.stopTimer()
                self.playerDidPause()
            }
        }
    }
}

extension VMMChromecastPlayer: GCKRequestDelegate {
    public func requestDidComplete(_ request: GCKRequest) {
        if request.requestID == self.seekRequest?.requestID,
            let time = GCKCastContext.sharedInstance().sessionManager.currentSession?.remoteMediaClient?.approximateStreamPosition() {
            self.playerDidChangePlaybackTime(time: time)
        }
    }
    
    public func request(_ request: GCKRequest, didFailWithError error: GCKError) {
        //print("error" + error.localizedDescription)
    }
    
    public func request(_ request: GCKRequest, didAbortWith abortReason: GCKRequestAbortReason) {
        //print("abort" + "\(abortReason.rawValue)")
    }
}
