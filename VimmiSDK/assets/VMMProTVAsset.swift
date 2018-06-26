//
//  VMMProTVAsset.swift
//  VimmiSDK
//
//  Created by Serhii Yefanov on 6/7/18.
//  Copyright © 2018 Serhii Yefanov. All rights reserved.
//

import Foundation
import AVKit

let k_media = "media"
let k_link = "link"
let k_poster = "poster"
let k_thumbnail = "thumbnail"
let k_head = "head"
let k_manifest_url = "manifest_url"

fileprivate let assetKeys = ["playable", "hasProtectedContent", "duration"]

class VMMProTVAsset : NSObject, VMMPlayerItemAsset {
    
    public var assetDuration: Double
    public var isLoaded: Bool
    public var currentPlaybackTime: Double
    public var title: String
    public var imagePoster: UIImage?
    public var imagePosterLink: String?
    public var imageBackdrop: UIImage?
    public var imageBackdropLink: String?
    public var sourcesCount: Int
    public var availableAudioTracks: [VMMAssetAudioTrack]?
    public var preferredAudioTrack: VMMAssetAudioTrack?
    public var availableSubtitles: [VMMAssetSubtitles]?
    
    public var mediaId: String?
    
    var streamLoaded : Bool = false
    
    var mediaLink: String?
    var asset : AVURLAsset?
    var playerItem: AVPlayerItem?
    
    var urlLoadingCounter = 0
    
    public init(mediaId: String) {
        self.assetDuration = 0.0
        self.isLoaded = false
        self.currentPlaybackTime = 0.0
        self.imagePoster = nil
        self.imageBackdrop = nil
        self.sourcesCount = 0
        self.title = ""
        self.mediaId = mediaId
    }
    
    func prepareForPlay(autoPlay: Bool, completion: @escaping (VMMAsset?, Error?) -> Void) {
        self.loadMediaDataWithCompletion { [weak self, completion] _dataDictionary, _error in
            if _error != nil {
                completion(nil, _error)
            }
            else if let dataDictionary = _dataDictionary {
                self?.parseMediaDataDictionary(dataDictionary)
                if autoPlay {
                    self?.loadVideoStream(completion: completion)
                }
                else {
                    completion(self, nil)
                }
            }
        }
    }
    
    func prepareForPlay(completion: @escaping (VMMAsset?, Error?) -> Void) {
        self.prepareForPlay(autoPlay: false, completion: completion)
    }
    
    func loadVideoStream(completion: @escaping (VMMAsset?, Error?) -> Void) {
        if self.mediaLink != nil {
            self.getVideoUrl(completion: { [weak self] _videoUrlString, _error  in
                if let videoUrlString = _videoUrlString {
                    guard let videoUrl = URL(string: videoUrlString)
                        else { completion(self, VMMPlayerError.AssetLoadingFailed); return }
                    self?.isLoaded = true
                    self?.streamLoaded = true
                    self?.asset = AVURLAsset(url: videoUrl)
                    self?.asset?.loadValuesAsynchronously(forKeys: assetKeys, completionHandler: { [weak self] in
                        DispatchQueue.main.async {
                            guard let asset = self?.asset else { completion(self, VMMPlayerError.AssetLoadingFailed); return }
                            self?.assetDuration = asset.duration.seconds
                            self?.playerItem = AVPlayerItem(asset: asset)
                            
                            completion(self, nil)
                        }
                    })
                }
                else {
                    completion(nil, _error)
                }
            })
        }
        else {
            completion(nil, VMMPlayerError.MediaLinkEmpty)
        }
    }
    
    func stopLoadingAsset() {
        self.asset?.cancelLoading()
    }
    
    func loadMediaDataWithCompletion(completion: @escaping ([String: Any]?, Error?) -> Void) {
        guard let server = VimmiSDKSettings.shared.serverAddress,
            let SID = VimmiSDKSettings.shared.sessionID
            else {
                completion(nil, VMMPlayerError.WrongSDKSettings)
                return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let mId = self.mediaId {
                let requestUrlString = "\(server)" + "/play/" + "\(mId)/"
                
                let config = URLSessionConfiguration.default
                config.httpShouldUsePipelining = false
                config.urlCache = nil
                config.httpShouldSetCookies = false
                
                let defaultSession = URLSession(configuration: config)
                var dataTask: URLSessionDataTask?
                
                if let url = URL(string: requestUrlString) {
                    var urlRequest = URLRequest(url: url)
                    urlRequest.addValue(SID, forHTTPHeaderField: "sid")
                    
                    dataTask = defaultSession.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
                        defer { dataTask?.cancel() }
                        DispatchQueue.main.async {
                            if let _error = error {
                                completion(nil, _error)
                            }
                            else if let _data = data {
                                do {
                                    let json = try JSONSerialization.jsonObject(with: _data, options: .allowFragments)
                                    if json is [String: Any] {
                                        completion((json as! [String: Any]), nil)
                                    }
                                }
                                catch let parsingError{
                                    print(parsingError.localizedDescription)
                                }
                            }
                        }
                    })
                    
                    dataTask?.resume()
                }
            }
        }
    }
    
    func getVideoUrl(completion: @escaping (String?, Error?) -> Void) {
        var deadlineTime = DispatchTime.now()// + .seconds(2)
        if urlLoadingCounter == 0 { deadlineTime = deadlineTime + .seconds(2) }
        
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: deadlineTime, execute: { [weak self] in
            if let mediaLink = self?.mediaLink {
                let defaultSession = URLSession(configuration: .default)
                
                var dataTask: URLSessionDataTask?
                
                if let url = URL(string: mediaLink) {
                    self?.urlLoadingCounter += 1
                    dataTask = defaultSession.dataTask(with: url, completionHandler: { (data, response, error) in
                        if let _data = data {
                            defer { dataTask?.cancel() }
                            DispatchQueue.main.async {
                                do {
                                    let json = try JSONSerialization.jsonObject(with: _data, options: .allowFragments) as? [String: Any]
                                    if let videoUrl = json?[k_manifest_url] as? String {
                                        completion(videoUrl, nil)
                                    }
                                    else {
                                        if let counter = self?.urlLoadingCounter,
                                            counter < 5 {
                                            self?.getVideoUrl(completion: completion)
                                        }
                                        else {
                                            completion(nil, VMMPlayerError.MissingVideoURL)
                                        }
                                    }
                                }
                                catch let parsingError{
                                    print(parsingError.localizedDescription)
                                    completion(nil, VMMPlayerError.MissingVideoURL)
                                }
                            }
                        }
                    })
                    
                    dataTask?.resume()
                }
            }
        })
    }
    
    func parseMediaDataDictionary(_ dict: [String: Any]) {
        if let mediaArray = dict[k_media] as? [[String: Any]],
            !mediaArray.isEmpty {
            let mediaDict = mediaArray.first!
            if let link = mediaDict[k_link] as? String,
                link.count > 0 {
                self.mediaLink = link
            }
        }
        if let headDict = dict[k_head] as? [String: Any] {
            self.imageBackdropLink = (headDict[k_thumbnail] as? String)?.replacingOccurrences(of: "http:", with: "https:")
            self.imagePosterLink = headDict[k_poster] as? String
        }
    }
    
    public func selectAudioTrack(_ track: VMMAssetAudioTrack) {
    }
    
    public func selectSubtitles(_ track: VMMAssetSubtitles?) {
    }
}
