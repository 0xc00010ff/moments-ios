//
//  VimeoConnector.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/13/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Alamofire

private let ACCESS_TOKEN_KEY = "Authorization"
private let ACCESS_TOKEN_VALUE_STAGING = "Bearer aa145c1d9bb318d4ef2a459c732503bc"
private let ACCESS_TOKEN_VALUE_PRODUCTION = "Bearer cbcd60a11d6c8dbad7310a4074312963"

private let HOST = "https://api.vimeo.com"

//provide this header to let Vimeo know which API version we are working with:
private let VERSION_ACCEPT_HEADER_KEY = "Accept"
private let VERSION_ACCEPT_HEADER_VALUE = "application/vnd.vimeo.*+json;version=3.2"

typealias BooleanResponseClosure = (_ success: Bool, _ error: Error?) -> Void
typealias UploadProgressClosure = (_ fractionCompleted: Double) -> Void
typealias StringCompletionHandler = (String?, Error?) -> Void
typealias UploadCompletion = (Moment?, Error?) -> Void
typealias VideoCompletion = ([Video]?, Error?) -> Void

class VimeoConnector: NSObject
{
    static var baseAPIEndpoint: String { return HOST }
    static var accessTokenKey: String { return ACCESS_TOKEN_KEY }
    static var accessTokenValue: String { return ACCESS_TOKEN_VALUE_PRODUCTION }
    static var versionAPIHeaderValue: String { return VERSION_ACCEPT_HEADER_VALUE }
    static var versionAPIHeaderKey: String { return VERSION_ACCEPT_HEADER_KEY }
    
    /**
     * Fetches all the videos from our vimeo account (me/videos), more specifically from the app community videos album.
     */
    func getCommunityMoments(completion: @escaping MomentListCompletion)
    {
        self.request(router: VideoRouter.all) { (response, error) in
            self.handleVideoResponse(withResponse: response, error: error, completion: completion)
        }
    }
    
    /**
     * Fetches next page of videos for the specifiec pagePath. This comes from Vimeo,
     * MomentList will have the next page path if there is one and this is handled w/ the video response utility method.
     */
    func getMoreVideos(forPagePath pagePath: String, completion: @escaping MomentListCompletion)
    {
        self.request(router: VideoRouter.nextPage(pagePath)) { (response, error) in
            self.handleVideoResponse(withResponse: response, error: error, completion: completion)
        }
    }
    
    // TODO: make the above function just an initial fetch call
    // Add a new function to fetch an arbitrary page expecting a video response for search and community feed paging
    
    func getCommunityMoments(forUserName name: String, completion: @escaping MomentListCompletion)
    {
        self.request(router: VideoRouter.search(name)) { (response, error) in
            self.handleVideoResponse(withResponse: response, error: error, completion: completion)
        }
    }
    
    /**
     * fetches a video from video uri, passes along name, description, and link as optionals in completion:
     */
    func getRemoteVideo(_ video: Video, completion: @escaping (Video?, Error?) -> Void)
    {
        self.request(router: VideoRouter.read(video)) { (response, error) in
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            if let result = response as? [String: Any] {
                
                let fetchedVideo = Video()
                fetchedVideo.name = result["name"] as? String
                fetchedVideo.videoDescription = result["description"] as? String
                fetchedVideo.videoLink = result["link"] as? String
                fetchedVideo.status = result["status"] as? String
                
                if let pictures = result["pictures"] as? [String: Any] {
                    fetchedVideo.thumbnailImageURL = Video.imageURL(fromPictures: pictures)
                }
                
                if let files = result["files"] as? [[String: Any]] {
                    fetchedVideo.playbackURL = self.playbackURLString(fromFiles: files)
                }

                completion(fetchedVideo, nil)
                return
            }
            
            //catch all parsing errors:
            let error = NSError(domain: "VimeoConnector.getRemoteVideo", code: 400, userInfo: [NSLocalizedDescriptionKey: "Couldn't understand HTTP response"])
            completion(nil, error)
        }
    }
    
    
    /**
     * Fetches playback urlString for specified Video, urlString passed along in the completion handler:
     * AuthToken must be for a Pro Account in order for the response to contain the correct fields...
     */
    func getPlaybackURL(forVideo video: Video, completion: @escaping StringCompletionHandler)
    {
        self.request(router: VideoRouter.read(video)) { (response, error) in
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            if let result = response as? [String: Any], let files = result["files"] as? [[String: Any]] {
                
                if let playbackURLString = self.playbackURLString(fromFiles: files) {
                    completion(playbackURLString, nil)
                    return
                }
            }
            
            //catch all parsing errors:
            let error = NSError(domain: "VimeoConnector.getVideosForCommunity:", code: 400, userInfo: [NSLocalizedDescriptionKey: "Couldn't understand HTTP response"])
            completion(nil, error)
        }
    }
    
    /**
     * Deletes a video from Vimeo, false and error if failed, true and nil if successful:
     */
    func delete(video: Video, completion: @escaping BooleanResponseClosure)
    {
        self.request(router: VideoRouter.destroy(video)) { (response, error) in
            
            guard error == nil else {
                completion(false, error)
                return
            }
            
            completion(true, nil)
            return
        }
    }
    
    /**
     * Upon successful upload, the new video will be populated with its new Vimeo URI and will be passed along in the completion handler:
     */
    func create(moment: Moment, uploadProgress: UploadProgressClosure?, completion: @escaping UploadCompletion)
    {
        self.checkForPendingUploads { alreadyUploading in
            
            guard alreadyUploading == false else {
                print("already uploading")
                let error = NSError(domain: "VimeoConnector.create", code: 400, userInfo: [NSLocalizedDescriptionKey: "Already uploading another video"])
                completion(nil, error)
                return
            }
            
            self.request(router: VideoRouter.create) { (response, error) in
                
                guard error == nil else {
                    completion(nil, error)
                    return
                }
                
                if let result = response as? [String: Any],
                    let ticketID = result["ticket_id"] as? String,
                    let uploadLink = result["upload_link_secure"] as? String,
                    let completeURI = result["complete_uri"] as? String {
                    
                    //pass along the complete URI to the sessionManager that will handle this request:
                    BackgroundUploadCompleteSessionManager.shared.completeURI = completeURI
                    
                    //now that we have generated an upload ticket, we can stream an upload to Vimeo with a PUT request to uploadLink:
                    BackgroundUploadSessionManager.shared.upload(moment: moment,
                                                                 router: UploadRouter.create(ticketID: ticketID, uploadLink: uploadLink),
                                                                 uploadCompletion: completion)
                    return
                }
                
                //catch any errors:
                let error = NSError(domain: "VimeoConnector.create:", code: 400, userInfo: [NSLocalizedDescriptionKey: "Couldn't understand HTTP response"])
                completion(nil, error)
            }
        }
    }
    
    //true if there is an active upload already:
    func checkForPendingUploads(completion: @escaping (Bool) -> Void)
    {
        //if moment is not nil and also not live then we are uploading:
        if let moment = BackgroundUploadSessionManager.shared.moment, moment.momentStatus != .live {
            completion(true)
            return
        }
        
        if let moment = BackgroundUploadCompleteSessionManager.shared.moment, moment.momentStatus != .live {
            completion(true)
            return
        }
        
        if let moment = BackgroundUploadVideoMetadataSessionManager.shared.moment, moment.momentStatus != .live {
            completion(true)
            return
        }
        
        //nil out any that didn't already get niled out:
        BackgroundUploadSessionManager.shared.moment = nil
        BackgroundUploadCompleteSessionManager.shared.moment = nil
        BackgroundUploadVideoMetadataSessionManager.shared.moment = nil
        
        completion(false)
    }
    
    // MARK: Utilities
    
    /**
     * handles result of self.request for list of videos (communty fetch and search fetch):
     */
    private func handleVideoResponse(withResponse response: Any?, error: Error?, completion: @escaping MomentListCompletion)
    {
        guard error == nil else {
            completion(nil, error)
            return
        }
        
        if let result = response as? [String: Any],
            let paging = result["paging"] as? [String: Any],
            let data = result["data"] as? [[String: Any]] {
            
            let moments = self.moments(fromData: data)
            let nextPagePath = self.nextPagePath(fromPaging: paging)
            
            if moments.count == 0 {
                print("No videos made it through - something probably went wrong.")
            }
            
            let momentList = MomentList(moments: moments, nextPagePath: nextPagePath)
            
            completion(momentList, nil)
            return
        }
        
        //catch all parsing errors:
        let error = NSError(domain: "VimeoConnector.getMomentsForCommunity:", code: 400, userInfo: [NSLocalizedDescriptionKey: "Couldn't understand HTTP response"])
        completion(nil, error)
    }
    
    /**
     * request utitily function for requests with JSON responses:
     */
    private func request(router: URLRequestConvertible, completion: @escaping (Any?, Error?) -> Void)
    {
        let request = Alamofire.request(router)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                
                //print rate limiting info:
                if let httpResponse = response.response,
                    let limitPerHour = httpResponse.allHeaderFields["X-RateLimit-Limit"] as? String {
                    print("\nrate limit per 15 min: \(limitPerHour)")
                }
                
                switch response.result {
                case .success(let value):
                    print(response.result)
                    completion(value, nil)
                    
                case .failure(let error):
                    print(error)
                    completion(nil, error)
                }
        }
        
        print(request)
    }
}

/**
 * Extension for Parsing:
 */
extension VimeoConnector
{
    fileprivate func moments(fromData data: [[String: Any]]) -> [Moment]
    {
        var moments = [Moment]()
        
        for videoObject in data {
            if let video = Video.from(parameters: videoObject) {
                let newMoment = Moment()
                newMoment.video = video
                moments.append(newMoment)
            }
        }
        
        return moments
    }
    
    fileprivate func nextPagePath(fromPaging paging: [String: Any]) -> String?
    {
        if let nextPage = paging["next"] as? String {
            return nextPage
        }
        
        return nil
    }
    
    fileprivate func playbackURLString(fromFiles files: [[String: Any]]) -> String?
    {
        var maxHeight = 0
        var urlString: String? = nil
        
        //loop through each Video file and select the highest quality one based on height:
        for file in files {
            
            if let videoHeight = file["height"] as? Int {
                
                if videoHeight > maxHeight {
                    maxHeight = videoHeight
                    urlString = file["link_secure"] as? String
                }
            }
        }
        
        return urlString
    }
}

