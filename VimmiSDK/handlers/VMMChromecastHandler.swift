//
//  VMMChromecastHandler.swift
//  VimmiPlayer
//
//  Created by Serhii Yefanov on 4/13/18.
//  Copyright © 2018 Serhii Yefanov. All rights reserved.
//

import GoogleCast

fileprivate let kReceiverAppID = "EC33F028"
fileprivate let kDebugLoggingEnabled = true

protocol VMMChromecastHandlerDelegate: class {
    func sessionDidStart(session: GCKSession)
    func sessionDidEnd(session: GCKSession, withError error:Error?)
    func mediaLoadingFailed(error: Error)
}

@objc public class VMMChromecastHandler: NSObject {

    @objc public static let shared = VMMChromecastHandler()
    private override init() {
        super.init()
        
        if !GCKCastContext.isSharedInstanceInitialized() {
            let gcOptions = GCKCastOptions(discoveryCriteria: GCKDiscoveryCriteria(applicationID: kReceiverAppID))
            GCKCastContext.setSharedInstanceWith(gcOptions)
            GCKLogger.sharedInstance().delegate = self
            
            GCKCastContext.sharedInstance().useDefaultExpandedMediaControls = true
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(showExpandedController),
                                                   name: .gckExpandedMediaControlsTriggered,
                                                   object: nil)
            
            
        }
        
        if (self.gcMiniController == nil) {
            self.gcMiniController = GCKCastContext.sharedInstance().createMiniMediaControlsViewController()
            self.gcMiniController.delegate = self
            self.gcMiniController.view.isHidden = !self.gcMiniController.active
        }
        
        GCKCastContext.sharedInstance().sessionManager.add(self)
    }
    
    weak var delegate: VMMChromecastHandlerDelegate?
    
    fileprivate var gcMiniController : GCKUIMiniMediaControlsViewController!
    
    // MARK: - Public methods
    
    @objc public func miniControllerView(frame: CGRect) -> UIView {
        let view = self.gcMiniController.view!
        view.frame = frame
        
        return view
    }
    
    @objc public func castBarButton() -> UIBarButtonItem {
        let castButton = GCKUICastButton(frame: CGRect(x: 0.0, y: 0.0, width: 24.0, height: 24.0))
        castButton.tintColor = .black
        
        return UIBarButtonItem(customView: castButton)
    }
    
    @objc public func castButton(size: CGSize) -> GCKUICastButton {
        let castButton = GCKUICastButton(frame: CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
        castButton.tintColor = .black
        
        return castButton
    }
    
    //MARK: - Private methods
    
    @objc private func showExpandedController() {
        GCKCastContext.sharedInstance().presentDefaultExpandedMediaControls()
    }
}

// MARK: -
// MARK: - Extensions

extension VMMChromecastHandler: GCKSessionManagerListener {
    
    public func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKCastSession) {
        self.delegate?.sessionDidStart(session: session)
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, willResumeSession session: GCKSession) {
        self.delegate?.sessionDidStart(session: session)
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, willEnd session: GCKSession) {
        if let currentPosition = session.remoteMediaClient?.approximateStreamPosition() {
            VMMGlobalVideoHandler.shared.currentChromecastPlayer?.currentAsset?.currentPlaybackTime = currentPosition
        }
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        self.delegate?.sessionDidEnd(session: session, withError: error)
    }
}

extension VMMChromecastHandler: GCKUIMiniMediaControlsViewControllerDelegate {
    public func miniMediaControlsViewController(_ miniMediaControlsViewController: GCKUIMiniMediaControlsViewController, shouldAppear: Bool) {
            self.gcMiniController.view.isHidden = !shouldAppear
    }
}

extension VMMChromecastHandler: GCKLoggerDelegate {
    public func logMessage(_ message: String, at level: GCKLoggerLevel, fromFunction function: String, location: String) {
        if kDebugLoggingEnabled {
            //print("\(function) --- \(message)")
        }
    }
}
