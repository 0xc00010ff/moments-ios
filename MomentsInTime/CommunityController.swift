//
//  CommunityController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 3/22/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import PureLayout
import AVKit
import AVFoundation

private let FREQUENCY_ACCESSORY_VIEW = 2
private let IDENTIFIER_SEGUE_PLAYER = "communityToPlayer"

class CommunityController: UIViewController, MITVideoCollectionViewAdapterDelegate, MITVideoCollectionViewAdapterPlayerDelegate, MITVideoCollectionViewAdapterInfiniteScrollDelegate
{
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    lazy var videoList = VideoList()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()
    
    private var emptyStateView: MITTextActionView = {
        let view = MITTextActionView()
        view.title = "Where are all the moments?"
        view.message = "Even if you're not ready to film, you can create the plans for an interview now."
        view.actionButton.setTitle("Let's make a moment", for: .normal)
        view.actionButton.addTarget(self, action: #selector(handleNewMoment), for: .touchUpInside)
        return view
    }()
    
    private lazy var adapter: MITVideoCollectionViewAdapter = {
        let adapter = MITVideoCollectionViewAdapter(withCollectionView: self.collectionView,
                                                   videos: self.videoList.videos,
                                                   emptyStateView: self.emptyStateView,
                                                   bannerView: nil)
        adapter.allowsEmptyStateScrolling = true
        adapter.accessoryViewdelegate = self
        adapter.playerDelegate = self
        adapter.infiniteScrollDelegate = self
        adapter.allowsInfiniteScrolling = true
        return adapter
    }()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.spinner.startAnimating()
        self.setupCollectionView()
        self.fetchCommunityVideos()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        //need this in case we rotate, switch tabs, then rotate back...
        //when we come back to this screen, the layout will be where we left it
        //even though viewWilTransition: gets called on all VCs in the tab bar controller,
        //when we come back on screen the collectinView width is no longer valid.
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        if self.collectionView != nil {
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    //for IDENTIFIER_SEGUE_PLAYER, sender will be the videoURL to pass to AVPlayer:
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == IDENTIFIER_SEGUE_PLAYER && sender is URL {
            
            if let playerController = segue.destination.contentViewController as? AVPlayerViewController, let videoURL = sender as? URL {
                playerController.player = AVPlayer(url: videoURL)
                playerController.player?.play()
            }
        }
    }
    
    //MARK: Actions
    
    @objc private func handleNewMoment()
    {
        print("handle new moment")
    }
    
    @objc private func handleAskToInterview()
    {
        print("handle Ask To Interview")
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
        self.collectionView?.addSubview(self.refreshControl)
    }
    
    //MARK: MITVideoCollectionViewAdapterDelegate
    
    func accessoryViewFrequency(forAdaptor adapter: MITVideoCollectionViewAdapter) -> Int
    {
        return 7
    }
    
    func accessoryView(for adapter: MITVideoCollectionViewAdapter) -> UIView
    {
        let textActionView = MITTextActionView()
        textActionView.title = "Make a Moment"
        textActionView.message = "Who do you know that has a story to tell?"
        textActionView.actionButton.setTitle("Ask To Interview", for: .normal)
        textActionView.actionButton.addTarget(self, action: #selector(handleAskToInterview), for: .touchUpInside)
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(textActionView)
        textActionView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 30, left: 0, bottom: 30, right: 0))
        
        return containerView
    }
    
    //MARK: MITVideoCollectionViewAdapterPlayerDelegate
    
    func adapter(adapter: MITVideoCollectionViewAdapter, handlePlayForVideo video: Video)
    {
        video.fetchPlaybackURL { (urlString, error) in
            
            guard error == nil else {
                return
            }
            
            if let videoURLString = urlString, let videoURL = URL(string: videoURLString) {
                self.performSegue(withIdentifier: IDENTIFIER_SEGUE_PLAYER, sender: videoURL)
            }
        }
    }
    
    //MARK: MITVideoCollectionViewAdapterInfiniteScrollDelegate
    
    func fetchNewVideos(for adapter: MITVideoCollectionViewAdapter, completion: @escaping () -> Void)
    {
        self.videoList.fetchNextCommunityVideos { (_, videos, error) in
            
            if let error = error {
                print(error)
            }
            
            if let newVideos = videos {
                self.adapter.videos += newVideos
            }
            
            self.adapter.allowsInfiniteScrolling = self.videoList.hasNextPage
            completion()
        }
    }
    
    // MARK: Refresh
    
    @objc private func refresh()
    {
        self.fetchCommunityVideos()
    }
    
    private func fetchCommunityVideos()
    {
        self.videoList.fetchCommunityVideos { list, error in
            
            self.refreshControl.endRefreshing()
            
            if let error = error {
                print(error)
            }
            
            self.spinner.stopAnimating()
            self.adapter.videos = self.videoList.videos
            self.adapter.allowsInfiniteScrolling = true
        }
    }
}
