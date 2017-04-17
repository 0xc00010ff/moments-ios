//
//  MITVideoCollectionViewAdapter.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/14/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

/**
 * Manages UICollectionViews throughout the app that display VideoCells...
 * The collectionViews are still responsible for loading and refreshing their content (VideoList),
 * but this class manages displaying the [Video].
 */
class MITVideoCollectionViewAdapter: NSObject, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    private struct Identifiers
    {
        static let IDENTIFIER_REUSE_VIDEO_CELL = "videoCell"
        static let IDENTIFIER_REUSE_CONTAINER_CELL = "containerCell"
    }
    
    var collectionView: UICollectionView!
    
    var videos = [Video]() {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    //if we have accessoryView, we will need an array of videos and accessoryViews:
    var videosAndAccessoryViews: [Any]?
    
    var emptyStateView = UIView()
    
    //optional top view that will be contained in a cell in section 0 at the top:
    //good for announcements, ads etc.
    //if it becomes necessary we could allow for an array of these views...
    var bannerView: UIView?
    
    //optional view that will be displayed in a vanilla cell every nth cell (index represents n)
    //good for ads...
    struct AccessoryView {
        var view: UIView
        var frequency: Int = 9
    }
    
    var accessoryView: AccessoryView?
    
    init(withCollectionView collectionView: UICollectionView, videos: [Video], emptyStateView: UIView, bannerView: UIView?, accessoryView: AccessoryView?)
    {
        super.init()
        
        self.collectionView = collectionView
        self.videos = videos
        self.emptyStateView = emptyStateView
        self.bannerView = bannerView
        self.accessoryView = accessoryView
        
        if self.bannerView != nil || self.accessoryView != nil {
            self.collectionView.register(ContainerCell.self, forCellWithReuseIdentifier: Identifiers.IDENTIFIER_REUSE_CONTAINER_CELL)
        }
        
        if self.accessoryView != nil {
            self.configureAccessoryView()
        }
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(UINib(nibName: String(describing: VideoCell.self), bundle: nil), forCellWithReuseIdentifier: Identifiers.IDENTIFIER_REUSE_VIDEO_CELL)
        
        self.collectionView.emptyDataSetDelegate = self
        self.collectionView.emptyDataSetSource = self
    }
    
    //MARK: CollectionView
    
    func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        switch section {
            
        case 0:
            
            let itemCount = self.bannerView != nil ? 1 : 0
            return itemCount
        
        case 1:
            
            if let data = self.videosAndAccessoryViews {
                return data.count
            }
            
            return self.videos.count
        
        default:
            
            assert(false, "unknown section in collectionView!")
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        switch indexPath.section {
        
        case 0:
            
            if let bannerView = self.bannerView,
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.IDENTIFIER_REUSE_CONTAINER_CELL, for: indexPath) as? ContainerCell {
                cell.containedView = bannerView
                return cell
            }
            
            assert(false, "dequeued cell was of an unknown type!")
            return ContainerCell()
        
        case 1:
            
            //check if we have videos and accessoryViews, then return the appropriate cell:
            if let data = self.videosAndAccessoryViews {
                
                if let video = data[indexPath.item] as? Video {
                    
                    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.IDENTIFIER_REUSE_VIDEO_CELL, for: indexPath) as? VideoCell {
                        cell.video = video
                        return cell
                    }
                    
                    assert(false, "dequeued cell was of an unknown type!")
                    return UICollectionViewCell()
                }
                else if let accessoryView = data[indexPath.item] as? AccessoryView {
                    
                    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.IDENTIFIER_REUSE_CONTAINER_CELL, for: indexPath) as? ContainerCell {
                        cell.containedView = accessoryView.view
                        print(cell.containedView)
                        return cell
                    }
                    
                    assert(false, "dequeued cell was of an unknown type!")
                    return UICollectionViewCell()
                }
                
            }
            
            //otherwise return a video cell:
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.IDENTIFIER_REUSE_VIDEO_CELL, for: indexPath) as? VideoCell {
                cell.video = self.videos[indexPath.item]
                return cell
            }
            
            assert(false, "dequeued cell was of an unknown type!")
            return UICollectionViewCell()
        
        default:
            
            assert(false, "unknown section in collectionView!")
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {        
        switch indexPath.section {
        
        case 0:
            
            if let viewToDisplay = self.bannerView {
                let size = ContainerCell.sizeForCell(withWidth: collectionView.bounds.width, containedView: viewToDisplay)
                return size
            }
            return .zero
        
        case 1:
            
            if let data = self.videosAndAccessoryViews {
                
                if let video = data[indexPath.row] as? Video {
                    return VideoCell.sizeForVideo(video, width: collectionView.bounds.width)
                }
                else if let accessoryView = data[indexPath.row] as? AccessoryView {
                    return ContainerCell.sizeForCell(withWidth: collectionView.bounds.width, containedView: accessoryView.view)
                }
            }
            
            let video = self.videos[indexPath.item]
            return VideoCell.sizeForVideo(video, width: collectionView.bounds.width)
        
        default:
            
            assert(false, "unknown section in collectionView!")
            return .zero
        }
    }
    
    //MARK: DZNEmptyDataSet
    
    func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView!
    {
        return self.emptyStateView
    }
    
    //MARK: Utilities:
    
    private func configureAccessoryView()
    {
        self.videosAndAccessoryViews = self.videos
        
        if let data = self.videosAndAccessoryViews, let accessoryView = self.accessoryView {
            for index in 0..<data.count {
                if (index % accessoryView.frequency == (accessoryView.frequency - 1)) {
                    self.videosAndAccessoryViews?.insert(accessoryView, at: index + 1)
                }
            }
        }
    }
}

