//
//  VimmiSDKSettings.swift
//  VimmiSDK
//
//  Created by Serhii Yefanov on 6/12/18.
//  Copyright © 2018 Serhii Yefanov. All rights reserved.
//

import Foundation

public class VimmiSDKSettings {
    
    internal var serverAddress: String?
    internal var sessionID: String?
    internal var userName: String?
    
    private init() {
    }
    
    static internal let shared: VimmiSDKSettings = VimmiSDKSettings()
    
    public static func setup(serverAddress: String, sessionId: String, userName: String) {
        VimmiSDKSettings.shared.serverAddress = serverAddress
        VimmiSDKSettings.shared.sessionID = sessionId
        VimmiSDKSettings.shared.userName = userName
    }
    
    public static func setSessionId(_ sId: String) {
        VimmiSDKSettings.shared.sessionID = sId
    }
    
    public static func setUserName(_ name: String) {
        VimmiSDKSettings.shared.userName = name
    }
}
