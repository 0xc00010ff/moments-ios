//
//  MyMomentsController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 3/22/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import RealmSwift
import AVKit
import AVFoundation
import PureLayout

private let COPY_TITLE_MOMENT_DETAIL = "Moment"
private let COPY_TITLE_UPLOAD_FAILED = "Oh No!"
private let COPY_MESSAGE_UPLOAD_FAILED = "Something went wrong during the upload. Please try again and make sure the app is running and connected until the upload completes."

let COPY_TITLE_NETWORK_ERROR = "Oops!"
let COPY_TITLE_NETWORK_WAITING = "Almost there!"
let COPY_MESSAGE_LIVE_MOMENT_NETWORK_ERROR = "Your Moment uploaded successfully and is being processed. Check back soon!"

private let COPY_TITLE_DELETE_UPLOADING_ALERT = "Oh No!"
private let COPY_MESSAGE_DELETE_UPLOADING_ALERT = "Sorry, but you'll need to wait until the upload is finished to modify this Moment."

private let COPY_TITLE_ALREADY_UPLOADING = "Oh No!"
private let COPY_MESSAGE_ALREADY_UPLOADING = "Sorry, but you'll need to wait until the current upload is finished before uploading another Moment."

private let KEY_CLOSED_HEADER = "didCloseShareNewMomentHeader" //Don't change

typealias NewMomentCompletion = (Moment, _ justCreated: Bool, _ shouldUpload: Bool) -> Void

class MyMomentsController: UIViewController, MITMomentCollectionViewAdapterMomentDelegate, MITHeaderViewDelegate
{
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    lazy var momentList = MomentList()
    
    private lazy var emptyStateView: MITTextActionView = {
        let view = MITTextActionView.mitEmptyStateView()
        view.actionButton.addTarget(self, action: #selector(createNewMomentAnimated), for: .touchUpInside)
        return view
    }()
    
    private lazy var newMomentHeaderView: ShareLiveMomentHeaderView = {
        let headerView = ShareLiveMomentHeaderView()
        headerView.delegate = self
        return headerView
    }()
    
    private lazy var adapter: MITMomentCollectionViewAdapter = {
        let adapter = MITMomentCollectionViewAdapter(withCollectionView: self.collectionView,
                                                     moments: self.momentList.moments,
                                                     emptyStateView: self.emptyStateView,
                                                     bannerView: nil)
        adapter.momentDelegate = self
        return adapter
    }()
    
    private enum Identifiers
    {
        static let IDENTIFIER_SEGUE_NEW_MOMENT = "NewMoment"
        static let IDENTIFIER_SEGUE_PLAYER = "myMomentsToPlayer"
    }
    
    private let vimeoConnector = VimeoConnector()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.listenForNotifications(true)
        self.setupCollectionView()
        self.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        //need this in case we rotate, switch tabs, then rotate back...
        //when we come back to this screen, the layout will be where we left it
        //even though viewWilTransition: gets called on all VCs in the tab bar controller,
        //when we come back on screen the collectinView width is no longer valid.
        self.collectionView.collectionViewLayout.invalidateLayout()
        
        //update navBar:
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedStringKey.foregroundColor: UIColor.mitText
        ]
        
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = true
            self.navigationItem.largeTitleDisplayMode = .always
            
            self.navigationController?.navigationBar.largeTitleTextAttributes = [
                NSAttributedStringKey.foregroundColor: UIColor.mitText
            ]
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        if self.collectionView != nil {
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.emptyStateView.layoutIfNeeded()
            self.collectionView.reloadEmptyDataSet()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        guard let id = segue.identifier else { return }
        
        switch id
        {
            case Identifiers.IDENTIFIER_SEGUE_NEW_MOMENT:
                if let newMomentController = segue.destination.contentViewController as? NewMomentController {
                    
                    newMomentController.completion = { moment, justCreated, shouldSubmit in
                        self.handleNewMomentCompletion(withMoment: moment, justCreated: justCreated, shouldSubmit: shouldSubmit)
                    }
                    
                    //pass along moment if we have one:
                    if let selectedMoment = sender as? Moment {
                        newMomentController.moment = selectedMoment
                        newMomentController.title = COPY_TITLE_MOMENT_DETAIL
                    }
                }
            
            case Identifiers.IDENTIFIER_SEGUE_PLAYER:
                if let playerController = segue.destination.contentViewController as? AVPlayerViewController, let videoURL = sender as? URL {
                    playerController.player = AVPlayer(url: videoURL)
                    playerController.player?.play()
                }
            
            default: break
        }
    }
    
    deinit
    {
        self.listenForNotifications(false)
    }
    
    
//MARK: Public
    
    /// to be used when called from outside (highlights the plus button before pushing)
    @objc func createNewMomentAnimated()
    {
        let pulsar = Pulsar()
        
        // show a pulsar over the add button
        if let addButton = self.navigationItem.rightBarButtonItem?.customView
        {
            pulsar.showAlertFrom(addButton.superview!, centeredOn: addButton, manualOffset: UIEdgeInsetsMake(0, 5, 0, 0))
        }
        
        wait(seconds: 0.67) {
            // stop pulsing if its there
            pulsar.stop()
            // just call into our private moment creation logic
            self.handleNewMoment()
        }
    }
    
//MARK: Actions
    
    @objc private func handleNewMoment()
    {
        self.performSegue(withIdentifier: Identifiers.IDENTIFIER_SEGUE_NEW_MOMENT, sender: nil)
    }
    
    @IBAction func handleCreateMoment(_ sender: BouncingButton)
    {
        self.performSegue(withIdentifier: Identifiers.IDENTIFIER_SEGUE_NEW_MOMENT, sender: nil)
        
        //for debugging (delete all the moments then tap create button and make sure realm is empty):
        if let realm = try? Realm() {
            if realm.isEmpty {
                print("\nrealm is empty")
            }
            else {
                print("\nrealm is NOT empty")
            }
        }
    }
    
    //MARK: ShareLiveMomentHeaderViewDelegate
    
    func handleClose(forHeaderView headerView: MITHeaderView)
    {
        self.closeBannerView()
    }
    
    func handleAction(forHeaderView headerView: MITHeaderView, sender: UIButton)
    {
        if let momentToShare = self.momentList.getLocalMoments().first {
            let shareSheet = ShareAlertSheet()
            shareSheet.showFrom(viewController: self, sender: sender, moment: momentToShare)
        }
    }
    
    //MARK: MITMomentCollectionViewAdapterMomentDelegate
    
    func adapter(adapter: MITMomentCollectionViewAdapter, handleShareForMoment moment: Moment, sender: UIButton)
    {
        let shareSheet = ShareAlertSheet()
        shareSheet.showFrom(viewController: self, sender: sender, moment: moment)
    }
    
    func adapter(adapter: MITMomentCollectionViewAdapter, handlePlayForMoment moment: Moment, sender: UIButton)
    {
        guard let video = moment.video else { return }
        
        if moment.momentStatus == .live {
            video.fetchPlaybackURL { (urlString, error) in
                
                guard error == nil else {
                    if video.uri != nil {
                        
                        //inform user that their video uploaded successfully (.live and uri != nil) but is still processing
                        UIAlertController.explain(withPresenter: self, title: COPY_TITLE_NETWORK_WAITING, message: COPY_MESSAGE_LIVE_MOMENT_NETWORK_ERROR)
                    }
                    return
                }
                
                if let videoURLString = urlString, let videoURL = URL(string: videoURLString) {
                    self.performSegue(withIdentifier: Identifiers.IDENTIFIER_SEGUE_PLAYER, sender: videoURL)
                    return
                }
            }
            return
        }
        
        //for local videos:
        if video.localURL != nil {
            if let localVideoURL = video.localPlaybackURL {
                self.performSegue(withIdentifier: Identifiers.IDENTIFIER_SEGUE_PLAYER, sender: localVideoURL)
            }
        }
    }
    
    func adapter(adapter: MITMomentCollectionViewAdapter, handleOptionsForMoment moment: Moment, sender: UIButton)
    {
        UIAlertController.showDeleteSheet(withPresenter: self, sender: sender, title: nil, itemToDeleteTitle: "Moment") { action in
            DispatchQueue.main.async {
                self.handleDelete(forMoment: moment)
            }
        }
    }
    
    func didSelectMoment(_ moment: Moment)
    {
        self.performSegue(withIdentifier: Identifiers.IDENTIFIER_SEGUE_NEW_MOMENT, sender: moment)
    }
    
    //MARK: CollectionView
    
    private func setupCollectionView()
    {
        if let flowLayout = self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.scrollDirection = .vertical
            flowLayout.minimumLineSpacing = 0
            flowLayout.sectionInset = .zero
        }
        
        self.collectionView.contentInset.top = 12
    }
    
    //MARK: Utilities
    
    private func handleDelete(forMoment moment: Moment)
    {
        //no deleting while a moment is uploading... strange and unwanted things will ensue:
        guard moment.momentStatus != .uploading else {
            UIAlertController.explain(withPresenter: self, title: COPY_TITLE_DELETE_UPLOADING_ALERT, message: COPY_MESSAGE_DELETE_UPLOADING_ALERT)
            return
        }
        
        //check if this is the top moment and if there is also a header view:
        if moment == self.momentList.getLocalMoments().first {
            
            //remove header view (nothing happens if there isn't one)
            self.closeBannerView()
        }
        
        self.adapter.removeMoment(moment, completion: nil)
        moment.delete()
    }
    
    private func closeBannerView()
    {
        self.adapter.closeBannerView()
        UserDefaults.standard.set(true, forKey: KEY_CLOSED_HEADER)
    }
    
    private func handleNewMomentCompletion(withMoment moment: Moment, justCreated: Bool, shouldSubmit: Bool)
    {
        Moment.writeToRealm {
            moment.video?.name = moment.canonicalTitle
        }
        
        if justCreated {
            self.adapter.insertNewMoment(moment)
        }
        
        if shouldSubmit {
            self.handleSubmit(forMoment: moment) {
                self.adapter.refreshMoment(moment)
            }
        }
        else {
            self.adapter.refreshMoment(moment)
        }
    }
    
    private func handleSubmit(forMoment moment: Moment, completion: @escaping () -> Void)
    {
        self.vimeoConnector.checkForPendingUploads { alreadyUploading in
            DispatchQueue.main.async {
                
                guard !alreadyUploading else {
                    UIAlertController.explain(withPresenter: self, title: COPY_TITLE_ALREADY_UPLOADING, message: COPY_MESSAGE_ALREADY_UPLOADING)
                    return
                }
                
                moment.upload { (_, error) in
                    
                    if error != nil {
                        
                        //inform the user that the upload failed,
                        //the moment's status is already set to .uploadFailed:
                        UIAlertController.explain(withPresenter: self, title: COPY_TITLE_UPLOAD_FAILED, message: COPY_MESSAGE_UPLOAD_FAILED)
                    }
                    
                    self.adapter.refreshMoment(moment)
                }
                
                completion()
            }
        }
    }
    
    @objc private func refresh()
    {
        self.adapter.moments = self.momentList.getLocalMoments()
        self.adapter.refreshData(shouldReload: true)
        
        //verification temporary?
        self.verifyMoments {
            print("verification complete")
        }
    }
    
    private func verifyMoments(completion: (() -> Void)?)
    {
        self.vimeoConnector.checkForPendingUploads { uploadIsInProgress in
            
            print("upload is in progress: \(uploadIsInProgress)")
            
            for moment in self.momentList.moments {
                
                guard !moment.isInvalidated else { continue }
                
                switch moment.momentStatus {
                    
                case .uploading:
                    if moment.video?.uri != nil {
                        print("video has uri, changing status from uploading to live")
                        moment.handleSuccessUpload()
                        self.verifyMetadata(forMoment: moment)
                    }
                    else if uploadIsInProgress == false {
                        print("moment is uploading but no upload is going on so changing status to uploadFailed: \(moment)")
                        moment.handleFailedUpload()
                    }
                    
                case .live:
                    self.verifyMetadata(forMoment: moment)
                    
                default:
                    if moment.video?.uri != nil {
                        print("video has uri, changing status from uploadFailed to live")
                        moment.handleSuccessUpload()
                        self.verifyMetadata(forMoment: moment)
                    }
                    print("status was new or local or uploadFailed")
                }
                
                self.adapter.refreshMoment(moment)
            }
            
            //completion after inspecting all the moments:
            completion?()
        }
    }
    
    //make sure local video is in sync with remote one and that it is in the right album:
    private func verifyMetadata(forMoment moment: Moment)
    {
        guard let video = moment.video,
            video.uri != nil,
            !video.liveVerified,
            !moment.isInvalidated else {
            if let video = moment.video, video.liveVerified { print("\nvideo has already been verified") }
            return
        }
        
        self.vimeoConnector.getRemoteVideo(video) { (fetchedVideo, error) in
            
            if let newVideo = fetchedVideo, !moment.isInvalidated {
                
                //add link, playbackURI, and thumbnailImageURL:
                Moment.writeToRealm {
                    moment.video?.videoLink = newVideo.videoLink
                    moment.video?.playbackURL = newVideo.playbackURL
                    moment.video?.thumbnailImageURL = newVideo.thumbnailImageURL
                }
                
                //if we got a playback url, remove the local video:
                self.removeVideo(forMoment: moment)
                
                //check for metadata and add if necessary:
                self.checkMetadata(forVideo: newVideo, moment: moment)
                
                //make sure video was added to the uploaded album on vimeo and update live verified:
                self.verifyVideoAlbum(forMoment: moment)
                
                //if we got a thumbnailImage url, swap the local photos:
                //do this last before updating liveVerified, b/c thumbnailImageURL is not a realm property
                //so we have no way of checking if we swapped out for the right image so check it last
                //and only if we successfully swapped photos will we check/ update live verified...
                if let thumbnailURL = newVideo.thumbnailImageURL {
                    self.replaceImage(forMoment: moment, withImageURL: thumbnailURL)
                }
                
                self.adapter.refreshMoment(moment)
            }
        }
    }
    
    private func removeVideo(forMoment moment: Moment)
    {
        guard !moment.isInvalidated else { return }
        
        if moment.video?.playbackURL != nil, let relativeLocalURL = moment.video?.localURL {
            
            print("\nwe have a playback url, so removing local video from disk")
            
            Assistant.removeVideoFromDisk(atRelativeURLString: relativeLocalURL) { success in
                if success {
                    Moment.writeToRealm {
                        moment.video?.localURL = nil
                    }
                }
            }
        }
    }
    
    private func checkMetadata(forVideo newVideo: Video, moment: Moment)
    {
        guard !moment.isInvalidated else { return }
        
        if newVideo.name == nil
            || newVideo.name == "Untitled"
            || newVideo.name == "untitled"
            || newVideo.videoDescription == nil {
            
            print("\nadding metadata in verify moments")
            
            BackgroundUploadVideoMetadataSessionManager.shared.sendMetadata(moment: moment) { (moment, error) in
                DispatchQueue.main.async {
                    
                    guard error == nil, moment != nil, !moment!.isInvalidated else {
                        print(error ?? "")
                        Moment.writeToRealm {
                            moment?.video?.liveVerified = false
                        }
                        return
                    }
                }
            }
        }
    }
    
    private func verifyVideoAlbum(forMoment moment: Moment)
    {
        guard let video = moment.video, !moment.isInvalidated else { return }
        
        if !video.addedToUploadAlbum {
            
            print("adding video to album since it wasn't already done")
            
            BackgroundUploadAlbumSessionManager.shared.addToUploadAlbum(moment: moment) {
                guard !moment.isInvalidated else { return }
                self.updateLiveVerifiedStatus(forMoment: moment)
            }
        }
    }
    
    private func replaceImage(forMoment moment: Moment, withImageURL imageURLString: String)
    {
        if let imageURL = URL(string: imageURLString) {
            DispatchQueue.global(qos: .userInitiated).async {
                
                if let imageData = try? Data(contentsOf: imageURL), let image = UIImage(data: imageData) {
                    
                    //make sure moment has not been deleted before updating:
                    guard !moment.isInvalidated else {
                        print("moment does not exist so do not try to replace image")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        Moment.writeToRealm {
                            print("\nreplacing thumbnail image")
                            let relativePath = Assistant.persistImage(image, compressionQuality: 0.5, atRelativeURLString: moment.video?.localThumbnailImageURL)
                            moment.video?.localThumbnailImageURL = relativePath
                            moment.video?.localThumbnailImage = image
                            self.adapter.refreshMoment(moment)
                        }
                        self.updateLiveVerifiedStatus(forMoment: moment)
                    }
                }
            }
        }
    }
    
    private func updateLiveVerifiedStatus(forMoment moment: Moment?)
    {
        guard moment != nil, !moment!.isInvalidated else { return }
        
        guard let video = moment?.video else {
            Moment.writeToRealm {
                moment?.video?.liveVerified = false
            }
            return
        }
        
        Moment.writeToRealm {
            moment?.video?.liveVerified = (video.playbackURL != nil
                && video.name != nil
                && video.name != "Untitled"
                && video.name != "untitled"
                && video.videoDescription != nil
                && video.addedToUploadAlbum == true)
        }
        
        if let status = moment?.video?.liveVerified, status == true {
            print("\nVideo is now live verified!!")
        }
    }
    
    @objc private func handleVideoUploaded(notification: Notification)
    {
        if let moment = notification.object as? Moment {
            self.adapter.refreshMoment(moment)
            
            wait(seconds: 2, then: { 
                self.adapter.insertBanner(withView: self.newMomentHeaderView)
                UserDefaults.standard.set(false, forKey: KEY_CLOSED_HEADER)
            })
        }
    }
    
    private func listenForNotifications(_ shouldListen: Bool)
    {
        if shouldListen {
            NotificationCenter.default.addObserver(self, selector: #selector(handleVideoUploaded(notification:)), name: Notification.Name(rawValue: NOTIFICATION_VIDEO_UPLOADED), object: nil)
        } else {
            NotificationCenter.default.removeObserver(self)
        }
    }
}

