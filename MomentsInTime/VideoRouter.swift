//
//  VideoRouter.swift
//  VideoWonderland
//
//  Created by Andrew Ferrarone on 3/23/17.
//  Copyright © 2017 Andrew Ferrarone. All rights reserved.
//

import Alamofire

private let FILTER_VIDEOS_VALUE = "uri,name,description,link,pictures.sizes,status"
private let FILTER_FEED_VALUE = "clip.uri,clip.name,clip.description,clip.link,clip.created_time,clip.pictures.sizes,clip.user.name,clip.user.pictures.sizes,clip.status"

protocol VideoRouterCompliant
{
    static func from(parameters: [String: Any]) -> Video?
    func videoParameters() -> [String: Any]
}

enum VideoRouter: URLRequestConvertible
{
    case all
    case create
    case update(Video)
    case destroy(Video)
    
    var method: Alamofire.HTTPMethod {
        switch self {
        case .all: return .get
        case .create: return .post
        case .update: return .patch
        case .destroy: return .delete
        }
    }
    
    var path: String {
        switch self {
        case .all: return "/me/feed"
        case .create: return "/me/videos"
        case .update(let video): return video.uri
        case .destroy: return ""
        }
    }
    
    
// MARK: URLRequestConvertible
    
    func asURLRequest() throws -> URLRequest
    {
        let url = try VimeoConnector.baseAPIEndpoint.asURL()
        
        var urlRequest = URLRequest(url: url.appendingPathComponent(self.path))
        urlRequest.httpMethod = self.method.rawValue
        
        //api version header and auth token header:
        urlRequest.setValue(VimeoConnector.versionAPIHeaderValue, forHTTPHeaderField: VimeoConnector.versionAPIHeaderKey)
        urlRequest.setValue(VimeoConnector.accessTokenValue, forHTTPHeaderField: VimeoConnector.accessTokenKey)
        
        //add any necessary params:
        switch self {
        case .all:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: ["fields": FILTER_FEED_VALUE])
            
        case .create:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: ["type": "streaming"])
            
        case .update(let video):
            urlRequest = try URLEncoding.default.encode(urlRequest, with: video.videoParameters())
            
        default:
            break
        }
        
        return urlRequest
    }
}
