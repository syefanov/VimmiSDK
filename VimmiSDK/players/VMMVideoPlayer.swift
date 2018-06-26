//
//  VMMVideoPlayer.swift
//  VimmiPlayer
//
//  Created by Serhii Yefanov on 3/12/18.
//  Copyright © 2018 Serhii Yefanov. All rights reserved.
//

import UIKit
import AVKit
import MediaPlayer
import GoogleCast

fileprivate let assetKeys = ["playable", "hasProtectedContent", "duration"]
fileprivate let kPlayer_playbackLikelyToKeepUp = "currentItem.playbackLikelyToKeepUp"
fileprivate let kPlayer_rate = "rate"
fileprivate let kView_bounds = "bounds"
fileprivate let kPlayer_status = "status"

private var playbackLikelyToKeepUpContext = 0
private var rateContext = 0
private var statusContext = 0

public class VMMVideoPlayer: VMMCorePlayer {
    // MARK: - Properties
    // MARK: Public
    
    private var _currentAsset : VMMPlayerItemAsset? //backing var
    override public var currentAsset: VMMAsset? {
        get { return self._currentAsset }
        set {
            if newValue is VMMPlayerItemAsset {
                self._currentAsset = newValue as? VMMPlayerItemAsset
                
                if let audioTrack = self._currentAsset?.preferredAudioTrack {
                    var criteria: AVPlayerMediaSelectionCriteria
                    if let possibleTags = audioTrack.possibleLanguageTags {
                        criteria = AVPlayerMediaSelectionCriteria(preferredLanguages: possibleTags, preferredMediaCharacteristics: nil)
                    }
                    else {
                        criteria = AVPlayerMediaSelectionCriteria(preferredLanguages: [audioTrack.languageTag], preferredMediaCharacteristics: nil)
                    }
                    
                    self.player.setMediaSelectionCriteria(criteria, forMediaCharacteristic: .audible)
                }
                
                if self._currentAsset?.isLoaded == false {
                    self.currentLoadingAsset = newValue as? VMMPlayerItemAsset
                    self.currentLoadingAsset?.prepareForPlay(completion: { [weak self] (_asset, error) in
                        if error != nil {
                            self?.playerDidFailLoadingAsset(_asset, error: error!)
                        }
                        else {
                            if let loadedAsset = _asset as? VMMPlayerItemAsset {
                                self?.player.replaceCurrentItem(with: self?._currentAsset?.playerItem)
                                self?._currentAsset?.isLoaded = true;
                                self?.currentLoadingAsset = nil
                                self?.setPlayerPlaybackTime(timeInSeconds: loadedAsset.currentPlaybackTime) {}
                                self?.playerDidLoadAsset(loadedAsset)
                            }
                        }
                    })
                }
                else {
                    self.player.replaceCurrentItem(with: self._currentAsset?.playerItem)
                    self.setPlayerPlaybackTime(timeInSeconds: self._currentAsset!.currentPlaybackTime) {}
                    self.playerDidLoadAsset(self.currentAsset!)
                }
            }
            else {
                self.playerDidFailLoadingAsset(newValue, error: VMMPlayerError.WrongAsset)
            }
        }
    }
    
    override public var isPlaying : Bool {
        return self.player.rate > 0
    }
    
    private var _volume: Float = 1.0
    override public var volume: Float {
        get {
            return _volume
        }
        set {
            if newValue > 1.0{
                _volume = 1.0
            }
            else if newValue < 0.0 {
                _volume = 0.0
            }
            else {
                _volume = newValue
            }
            
            self.player.volume = _volume
        }
    }
    
    // MARK: Private
    
    internal var currentLoadingAsset : VMMPlayerItemAsset?
    
    private var imagePlayerOverlay : VMMPlayerOverlayView?
    
    internal var timeObserver: Any!
    internal var player: AVPlayer!

    fileprivate var _allowAirPlay : Bool = true
    private var externalWindow : UIWindow?
    private var _backingView : UIView? = nil
    
    @objc public override init() {
        super.init()
        
        self.setupPlayer()
        VMMGlobalVideoHandler.registerPlayer(self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(screenDidConnect(notification:)), name: .UIScreenDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screenDidDisconnect(notification:)), name: .UIScreenDidDisconnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onActiveRouteChanged(notification:)), name: NSNotification.Name.MPVolumeViewWirelessRouteActiveDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerFinishedPlaying(notification:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .MPVolumeViewWirelessRouteActiveDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .AVAudioSessionRouteChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        self.removePlayerView()
        self.player.removeObserver(self, forKeyPath: kPlayer_rate, context: &rateContext)
        self.player.removeObserver(self, forKeyPath: kPlayer_playbackLikelyToKeepUp, context: &playbackLikelyToKeepUpContext)
        self.player.removeObserver(self, forKeyPath: kPlayer_status, context: &statusContext)
        self.removeTimeObserver()
    }
    
    // MARK: - Observers
    
    @objc private func screenDidConnect(notification: Notification) {
        if let screen = notification.object as? UIScreen {
            self.setPlayerOverlayHidden(false)
            self.externalWindow = UIWindow(frame: screen.bounds)
            self.externalWindow?.screen = screen
            
            let view = UIView(frame: self.externalWindow!.bounds)
            view.backgroundColor = .darkGray
            self.externalWindow?.addSubview(view)
            self.externalWindow?.isHidden = false
            self._backingView = self.playerView
            self.updateWithPlayerView(view)
        }
    }
    
    @objc private func screenDidDisconnect(notification: Notification) {
        self.externalWindow = nil
        self.setPlayerOverlayHidden(true)
        if let view = self._backingView {
            self.updateWithPlayerView(view)
        }
    }
    
    
    @objc private func onActiveRouteChanged(notification: Notification) {
        if let volumeView = self.volumeView {
            self.setPlayerOverlayHidden(!volumeView.isWirelessRouteActive)
        }
    }
    
    @objc private func playerFinishedPlaying(notification: Notification) {
        self.playerDidFinishPlaying()
    }
    
    override public func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if context == &playbackLikelyToKeepUpContext {
            if let buffering = self.player.currentItem?.isPlaybackLikelyToKeepUp,
                buffering == true {
                self.playerDidFinishBuffering()
            } else if self.player.currentItem != nil {
                self.playerDidStartBuffering()
            }
        }
        else if context == &rateContext {
            if self.player.rate == 0.0 {
                self.playerDidPause()
            }
            else {
                self.playerDidStartPlaying()
            }
        }
        else if keyPath == kPlayer_status {
            let status: AVPlayerStatus = self.player.status
            switch status {
            case .unknown, .failed:
                if let asset = self.currentAsset {
                    self.playerFailedPlayingAsset(asset, error: self.player.error)
                }
            default:
                break
            }
        }
    }
    
    // MARK: - Public Methods
    
    @objc override public func updateWithPlayerView(_ container: UIView) {
        self.removePlayerView()
        
        self.playerView = VMMPlayerView(frame: container.bounds)
        self.playerView?.clipsToBounds = true
        self.playerView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.playerView?.delegate = self
        container.addSubview(self.playerView!)
        self.playerView?.playerLayer = AVPlayerLayer(player: self.player)
        self.playerView?.playerLayer.videoGravity = .resizeAspect
        self.playerView?.playerLayer.frame = self.playerView!.bounds
        self.playerView!.layer.addSublayer(self.playerView!.playerLayer)
        
        self.setupPlayerOverlayView()
    }
    
    public func setPlayerOverlayHidden(_ hidden: Bool) {
        if hidden {
            self.imagePlayerOverlay?.isHidden = true
        }
        else {
            self.imagePlayerOverlay?.isHidden = false
            if self.currentAsset?.imageBackdrop != nil {
                self.imagePlayerOverlay?.overlayImage.image = self.currentAsset?.imageBackdrop
            }
            else if let link = self.currentAsset?.imageBackdropLink {
                if let imageUrl = URL(string: link) {
                    DispatchQueue.global().async {
                        let data = try? Data(contentsOf: imageUrl)
                        DispatchQueue.main.async { [data] in
                            let image = UIImage(data: data!)
                            self.currentAsset?.imageBackdrop = image
                            self.imagePlayerOverlay?.overlayImage.image = image
                        }
                    }
                }
                self.imagePlayerOverlay?.labelText.text = "Currently playing on \(self.airPlayDeviceName())"
            }
        }
    }
    
    public func setPlayerOverlayHidden(hidden: Bool, link: String?) {
        if hidden {
            self.imagePlayerOverlay?.isHidden = true
        }
        else {
            self.imagePlayerOverlay?.isHidden = false
            if let link = link {
                if let imageUrl = URL(string: link) {
                    DispatchQueue.global().async {
                        let data = try? Data(contentsOf: imageUrl)
                        DispatchQueue.main.async { [data] in
                            let image = UIImage(data: data!)
                            self.currentAsset?.imageBackdrop = image
                            self.imagePlayerOverlay?.overlayImage.image = image
                        }
                    }
                }
            }
        }
    }
    
    @objc public override func detachPlayerView() -> UIView? {
        return self.playerView
    }
        
    override public func play() {
        super.play()
        self.player.play()
        if self.currentAsset == nil {
            self.pause()
        }
        else if isPlaying {
            self.addTimeObserver()
        }
    }
    
    override public func pause() {
        self.player.pause()
    }
    
    override public func stopPlaying() {
        super.stopPlaying()
        self.player.currentItem?.cancelPendingSeeks()
        self.player.pause()
        
        self.removeTimeObserver()
    }
    
    @objc public override func currentAspectRatio() -> AVLayerVideoGravity? {
        return self.playerView?.playerLayer.videoGravity
    }
    
    @objc public override func setAspectRatio(_ aspectRatio: AVLayerVideoGravity) {
        self.playerView?.playerLayer.videoGravity = aspectRatio
    }
    
    @objc public override func moveForward(onSeconds seconds: Double) {
        var time = self.player.currentTime().seconds + seconds
        if let duration = self.player.currentItem?.duration.seconds,
            time > duration {
            time = duration
        }
        self.setPlayerPlaybackTime(timeInSeconds: time, completion:nil)
    }
    
    @objc public override func moveBackward(onSeconds seconds: Double) {
        var time = self.player.currentTime().seconds - seconds
        if time < 0 {
            time = 0
        }
        self.setPlayerPlaybackTime(timeInSeconds: time, completion:nil)
    }
    
    override public func setPlayerPlaybackTime(timeInSeconds time: Double, completion: (()->Void)?) {
        let completionBlock : () -> Void = { [weak self, time] in
            if completion != nil {
                completion!()
            }
            self?.addTimeObserver()
            self?.playerDidChangePlaybackTime(time: time)
        }
        
        self.removeTimeObserver()
        let cmTime = CMTime(seconds: time, preferredTimescale: self.player.currentTime().timescale)
        self.player.seek(to: cmTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero) { (completed) in
            completionBlock()
            super.setPlayerPlaybackTime(timeInSeconds: time, completion: completion)
        }
    }
    
    @objc override public func detachAsset() {
        super.detachAsset()
        self.setPlayerPlaybackTime(timeInSeconds: 0.0, completion:nil)
        self.stopPlaying()
        self.currentAsset = nil
        self.player.replaceCurrentItem(with: nil)
    }
    
    // MARK: - Private methods
    
    // MARK: UI
    
    private func setupPlayerOverlayView() {
        if self.imagePlayerOverlay != nil {
            self.imagePlayerOverlay?.removeFromSuperview()
            self.imagePlayerOverlay = nil
        }
        if let view = self.playerView {
            if self.imagePlayerOverlay == nil {
                self.imagePlayerOverlay = VMMPlayerOverlayView(frame: CGRect.zero)
                self.imagePlayerOverlay?.backgroundColor = .clear
                self.imagePlayerOverlay?.isHidden = true
                view.addSubview(self.imagePlayerOverlay!)
            }
            
            self.imagePlayerOverlay?.frame = view.bounds
        }
    }
    
    private func removePlayerView() {
        if self.playerView != nil {
            self.playerView?.playerLayer.removeFromSuperlayer()
            self.playerView = nil
        }
    }
    
    // MARK: Logic
    private func setupPlayer() {
        
        self.player = AVPlayer()
        self.player.allowsExternalPlayback = true
        self.player.addObserver(self,
                                forKeyPath: kPlayer_playbackLikelyToKeepUp,
                                options: .new,
                                context: &playbackLikelyToKeepUpContext)
        self.player.addObserver(self,
                                forKeyPath: kPlayer_rate,
                                options: .new,
                                context: &rateContext)
        self.player.addObserver(self,
                                forKeyPath: kPlayer_status,
                                options: .new,
                                context: &statusContext)
        
        self.addTimeObserver()
    }
    
    internal func addTimeObserver() {
        let interval = CMTime(seconds: 1.0,
                              preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        self.removeTimeObserver()
        timeObserver = self.player.addPeriodicTimeObserver(forInterval: interval,
                                                           queue: DispatchQueue.main) { [weak self] (time) in
                                                            self?.currentAsset?.currentPlaybackTime = time.seconds
                                                            self?.playerTimeObserverFired(time: time.seconds)
        }
    }
    
    private func airPlayDeviceName() -> String {
        var name = ""
        
        for outputPort in AVAudioSession.sharedInstance().currentRoute.outputs {
            if outputPort.portType == AVAudioSessionPortAirPlay ||
                outputPort.portType == AVAudioSessionPortHDMI {
                name = outputPort.portName
            }
        }
        
        return name
    }
    
    internal func removeTimeObserver() {
        if ((timeObserver) != nil) {
            self.player.removeTimeObserver(timeObserver)
            timeObserver = nil
        }
    }
}

extension VMMVideoPlayer: VMMPlayerViewDelegate {
    func didLayoutSubviews() {
        if let frame = self.playerView?.bounds {
            self.imagePlayerOverlay?.frame = frame
        }
    }
}

extension VMMVideoPlayer : VMMPlayerExternal {
    
    var allowAirPlay: Bool {
        get {
            return self._allowAirPlay
        }
        set {
            self._allowAirPlay = newValue
        }
    }
}
