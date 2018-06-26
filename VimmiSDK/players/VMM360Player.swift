//
//  VMM360Player.swift
//  VimmiPlayer
//
//  Created by Serhii Yefanov on 3/26/18.
//  Copyright © 2018 Serhii Yefanov. All rights reserved.
//

import UIKit
import AVKit
import SpriteKit
import SceneKit
import CoreMotion

fileprivate let assetKeys = ["playable", "duration"]
fileprivate let kPlayer_playbackLikelyToKeepUp = "currentItem.playbackLikelyToKeepUp"
fileprivate let kPlayer_rate = "rate"
fileprivate let kView_bounds = "bounds"

private var playbackLikelyToKeepUpContext = 0
private var rateContext = 0
private var boundsContext = 0


@objc public enum VMM360PlayerRotationMode : Int, Error {
    case manualRotation
    case cameraRotation
}

@objc public class VMM360Player: VMMVideoPlayer {
    // MARK: - Properties
    // MARK: Public
    
    private var _rotationMode : VMM360PlayerRotationMode = .manualRotation
    @objc public var rotationMode : VMM360PlayerRotationMode {
        get { return self._rotationMode }
        set { self._rotationMode = newValue; self.updateRotationMode() }
    }
    
    // MARK: Private
    
    private var additionalGestureViews : [UIView: UIPanGestureRecognizer] = [UIView: UIPanGestureRecognizer]()
    private var cameraNode : SCNNode!
    private var motionManager : CMMotionManager!
    private var sceneView : SCNView!
    private var panGesture : UIPanGestureRecognizer!
    private var lastWidthRatio : CGFloat = 0.0
    private var lastHeightRatio : CGFloat = 0.0
    private var cameraEnabled : Bool = false
    
    deinit {
        self.removePlayerView()
        self.player.removeObserver(self, forKeyPath: kPlayer_rate, context: &rateContext)
        self.player.removeObserver(self, forKeyPath: kPlayer_playbackLikelyToKeepUp, context: &playbackLikelyToKeepUpContext)
        self.removeTimeObserver()
        self.additionalGestureViews.forEach { (view, recognizer) in
            view.removeGestureRecognizer(recognizer)
        }
        self.additionalGestureViews.removeAll()
    }
    
    // MARK: - Public Methods
    
    override public func updateWithPlayerView(_ container: UIView) {
        self.removePlayerView()
        
        self.playerView = playerView
        self.playerView!.addObserver(self, forKeyPath: kView_bounds, options: .new, context: &boundsContext)
        
        self.sceneView = SCNView(frame: self.playerView!.bounds)
        self.sceneView.isUserInteractionEnabled = true
        
        let videoScene = self.createVideoScene()
        videoScene.backgroundColor = .black
        let sphereNode = self.createSphereNode(material: videoScene)
        self.configureScene(node: sphereNode)
        self.updateRotationMode()
        self.playerView?.addSubview(self.sceneView)
        self.sceneView.play(nil)
    }
    
    override public func stopPlaying() {
        super.stopPlaying()
        self.sceneView.pause(nil)
    }
    
    @objc public func addPanRecognizer(to view: UIView) {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(panGesture(sender:)))
        recognizer.isEnabled = self._rotationMode == .manualRotation
        view.addGestureRecognizer(recognizer)
        
        self.additionalGestureViews[view] = recognizer
    }
    
    @objc public func removePanRecognizer(from view: UIView) {
        if let recognizer = self.additionalGestureViews[view] {
            view.removeGestureRecognizer(recognizer)
            self.additionalGestureViews.removeValue(forKey: view)
        }
    }
    
    // MARK: - Private methods
    
    // MARK: UI
    
    private func removePlayerView() {
        if self.playerView != nil {
            self.playerView!.removeObserver(self, forKeyPath: kView_bounds, context: &boundsContext)
            self.motionManager.stopDeviceMotionUpdates()
            self.sceneView.removeFromSuperview()
            self.playerView = nil
        }
    }
    
    private func createVideoScene() -> SKScene {
        let videoNode = SKVideoNode(avPlayer: self.player)
        let size = CGSize(width: 1024.0, height: 512.0)
        let spriteScene = SKScene(size: size)
        
        videoNode.size = size
        videoNode.position = CGPoint(x: size.width/2, y: size.height/2)
        spriteScene.addChild(videoNode)
        
        return spriteScene
    }
    
    private func createSphereNode(material: AnyObject) -> SCNNode {
        let sphere = SCNSphere(radius: 20.0)
        sphere.firstMaterial?.isDoubleSided = true
        sphere.firstMaterial?.diffuse.contents = material
        
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3Make(0.0, 0.0, 0.0)
        
        var transform = SCNMatrix4MakeRotation(Float.pi, 0.0, 0.0, 1.0)
        transform = SCNMatrix4Translate(transform, 1.0, 1.0, 0.0)
        
        sphereNode.geometry?.firstMaterial?.diffuse.contentsTransform = transform
        
        return sphereNode
    }
    
    private func configureScene(node: SCNNode) {
        let scene = SCNScene()
        
        self.sceneView.scene = scene
        
        self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGesture(sender:)))
        self.panGesture.isEnabled = false
        self.sceneView.addGestureRecognizer(self.panGesture)
        
        self.cameraNode = SCNNode()
        self.cameraNode.camera = SCNCamera()
        
        self.cameraNode.position = SCNVector3Make(0.0, 0.0, 0.0)
        
        scene.rootNode.addChildNode(node)
        scene.rootNode.addChildNode(self.cameraNode)
    }
    
    // MARK: Logic
    
    private func setupPlayer() {
        
        self.player = AVPlayer()
        
        self.player.addObserver(self,
                                forKeyPath: kPlayer_playbackLikelyToKeepUp,
                                options: .new,
                                context: &playbackLikelyToKeepUpContext)
        self.player.addObserver(self,
                                forKeyPath: kPlayer_rate,
                                options: .new,
                                context: &rateContext)
        
        self.addTimeObserver()
    }
    
    @objc private func panGesture(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: sender.view)
        
        guard let senderView = sender.view else { return }
        let widthRatio = translation.x / senderView.frame.size.width + self.lastWidthRatio
        let heightRatio = translation.y / senderView.frame.size.height + self.lastHeightRatio
        
        var vector = SCNVector3Zero
        
        vector.y = Float(CGFloat.pi * widthRatio)
        vector.x = Float(CGFloat.pi * heightRatio)
        vector.z = self.cameraNode.eulerAngles.z
        
        self.cameraNode.eulerAngles = vector
        
        if sender.state == .ended {
            self.lastWidthRatio = widthRatio
            self.lastHeightRatio = heightRatio
        }
    }
    
    private func startCameraTracking() {
        self.motionManager = CMMotionManager()
        self.motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;
        
        self.motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { [weak self] (motion, error) in
            if motion != nil {
                self?.cameraNode.orientation = motion!.vmm_gaze(atOrientation: UIApplication.shared.statusBarOrientation)
            }
        }
    }
    
    private func stopCameraTracking() {
        if self.motionManager != nil {
            self.motionManager.stopDeviceMotionUpdates()
            self.motionManager = nil
        }
    }
    
    private func updateRotationMode() {
        self.lastWidthRatio = 0.0
        self.lastHeightRatio = 0.0
        
        SCNTransaction.begin()
        self.cameraNode.eulerAngles = SCNVector3Zero
        SCNTransaction.commit()
        
        if self.rotationMode == .manualRotation {
            self.stopCameraTracking()
            self.panGesture.isEnabled = true
            self.additionalGestureViews.forEach({ (_, recognizer) in
                recognizer.isEnabled = true
            })
        }
        else {
            self.panGesture.isEnabled = false
            self.additionalGestureViews.forEach({ (_, recognizer) in
                recognizer.isEnabled = false
            })
            self.startCameraTracking()
        }
    }
}
