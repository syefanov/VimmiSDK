//
//  VMMPlayerView.swift
//  VimmiSDK
//
//  Created by Serhii Yefanov on 6/12/18.
//  Copyright © 2018 Serhii Yefanov. All rights reserved.
//

import Foundation
import AVKit

protocol VMMPlayerViewDelegate: class {
    func didLayoutSubviews()
}

@objc public class VMMPlayerView: UIView {
    
    var playerLayer: AVPlayerLayer!
    
    weak var delegate: VMMPlayerViewDelegate?
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        if playerLayer != nil,
            playerLayer.bounds != bounds {
            if playerLayer.superlayer == layer {
                playerLayer.frame = bounds
            }
            if let animationPosition = layer.animation(forKey: "position") {
                playerLayer.add(animationPosition, forKey: "position")
            }
        }
        self.delegate?.didLayoutSubviews()
    }
}
