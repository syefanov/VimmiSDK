//
//  Double+TimeRepresentation.swift
//  VimmiPlayer
//
//  Created by Serhii Yefanov on 3/7/18.
//  Copyright © 2018 Serhii Yefanov. All rights reserved.
//

import Foundation

public extension Double {
    //Time string from seconds
    func vmm_timeString() -> String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = (Int(self) % 3600) % 60
        
        var hoursStr = ""
        if hours > 0 {
            hoursStr = hours < 10 ? "0\(hours):" : "\(hours):"
        }
        let minutesStr = minutes < 10 ? "0\(minutes)" : "\(minutes)"
        let secondsStr = seconds < 10 ? "0\(seconds)" : "\(seconds)"
        
        return hoursStr + minutesStr + ":" + secondsStr
    }
}
