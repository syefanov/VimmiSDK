//
//  CMDeviceMotion+Gaze.swift
//  VimmiPlayer
//
//  Created by Serhii Yefanov on 3/28/18.
//  Copyright © 2018 Serhii Yefanov. All rights reserved.
//

import Foundation
import CoreMotion
//import GLKit
import SceneKit

extension CMDeviceMotion {
    
    func vmm_gaze(atOrientation orientation: UIInterfaceOrientation) -> SCNVector4 {
        
        let attitude = self.attitude.quaternion
        let aq = GLKQuaternionMake(Float(attitude.x), Float(attitude.y), Float(attitude.z), Float(attitude.w))
        
        let final: SCNVector4
        
        switch orientation {
            
        case .landscapeRight:
            
            let cq = GLKQuaternionMakeWithAngleAndAxis(Float(Double.pi/2.0), 0, 1, 0)
            let q = GLKQuaternionMultiply(cq, aq)
            
            final = SCNVector4(x: -q.y, y: q.x, z: q.z, w: q.w)
            
        case .landscapeLeft:
            
            let cq = GLKQuaternionMakeWithAngleAndAxis(Float(-Double.pi/2.0), 0, 1, 0)
            let q = GLKQuaternionMultiply(cq, aq)
            
            final = SCNVector4(x: q.y, y: -q.x, z: q.z, w: q.w)
            
        case .portraitUpsideDown:
            
            let cq = GLKQuaternionMakeWithAngleAndAxis(Float(Double.pi/2.0), 1, 0, 0)
            let q = GLKQuaternionMultiply(cq, aq)
            
            final = SCNVector4(x: -q.x, y: -q.y, z: q.z, w: q.w)
            
        case .unknown:
            
            fallthrough
            
        case .portrait:
            
            let cq = GLKQuaternionMakeWithAngleAndAxis(Float(-Double.pi/2.0), 1, 0, 0)
            let q = GLKQuaternionMultiply(cq, aq)
            
            final = SCNVector4(x: q.x, y: q.y, z: q.z, w: q.w)
        }
        
        return final
    }
}
