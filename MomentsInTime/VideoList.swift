//
//  VideoList.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 3/31/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation

typealias VideoListCompletion = (VideoList?, Error?) -> Void
typealias VideoListNewVideosCompletion = (VideoList?, [Video]?, Error?) -> Void

class VideoList: NSObject
{
    lazy var videos = [Video]()
    
    var hasNextPage: Bool {
        return self.nextPagePath != nil
    }
    
    private static let firstPagePath: String = "/me/videos"
    private(set) var nextPagePath: String?
    
    init(videos: [Video], nextPagePath: String?)
    {
        super.init()
        self.videos = videos
        self.nextPagePath = nextPagePath
    }
    
    override init()
    {
        super.init()
    }
    
    func fetchCommunityVideos(completion: VideoListCompletion?)
    {
        VimeoConnector().getCommunityVideos(forPagePath: VideoList.firstPagePath) { (videoList, error) in
            
            guard error == nil else {
                completion?(nil, error)
                return
            }
            
            if let fetchedVideoList = videoList {
                
                DispatchQueue.main.async {
                    self.videos = fetchedVideoList.videos
                    self.nextPagePath = fetchedVideoList.nextPagePath
                    completion?(self, nil)
                }
            }
        }
    }
    
    func fetchNextCommunityVideos(completion: VideoListNewVideosCompletion?)
    {
        guard let nextPage = self.nextPagePath else { return }
        
        VimeoConnector().getCommunityVideos(forPagePath: nextPage) { (videoList, error) in
            
            guard error == nil else {
                completion?(nil, nil, error)
                return
            }
            
            if let fetchedVideoList = videoList {
                
                DispatchQueue.main.async {
                    self.videos += fetchedVideoList.videos
                    self.nextPagePath = fetchedVideoList.nextPagePath
                    completion?(self, fetchedVideoList.videos, nil)
                }
            }
        }
    }
}
