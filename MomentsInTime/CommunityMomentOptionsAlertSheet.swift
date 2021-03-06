//
//  CommunityMomentOptionsAlertSheet.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/13/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import MessageUI

private let TITLE_MORE_VIDEOS = "{name}'s videos"
private let TITLE_SHARE_ACTION = "Share"
private let TITLE_REPORT_ACTION = "Contact a moderator"
private let TITLE_CANCEL = "Cancel"
let EMAIL_FEEDBACK = "momentsintimeproj@gmail.com"
private let EMAIL_FEEDBACK_SUBJECT = "Reporting a video"
private let EMAIL_FEEDBACK_BODY = "I am reporting this video {url} ({title}) because "

protocol CommunityOptionsDelegate : class
{
    func communityOptionsSelectedMoreUserVideos(name: String)
}

class CommunityMomentOptionsAlertSheet: NSObject, MFMailComposeViewControllerDelegate
{
    var moment: Moment?
    var allowsSharing = false
    var allowsRelatedVideos = true
    weak var delegate: CommunityOptionsDelegate? // really most of the handling should be done by the dele' and the moment stay out of here
    
    private let assistant = Assistant()
    
    func showFrom(viewController: UIViewController, sender: UIView, forMoment moment: Moment, completion: AlertCompletion? = nil)
    {
        self.moment = moment
        
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.popoverPresentationController?.sourceView = sender
        controller.popoverPresentationController?.sourceRect = sender.bounds
        controller.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        
        // feature flag for sharing from alert sheet:
        if self.allowsSharing {
            let shareAction = UIAlertAction(title: TITLE_SHARE_ACTION, style: .default) { _ in
                self.handleShare(withViewController: viewController, sender: sender)
            }
            controller.addAction(shareAction)
        }
        
        // option for "more by this user":
        if let inferredName = self.moment?.video?.titleInferredName(), self.allowsRelatedVideos
        {
            let moreVideosOption = TITLE_MORE_VIDEOS.replacingOccurrences(of: "{name}", with: inferredName)
            
            let moreUserVideos = UIAlertAction(title: moreVideosOption, style: .default) { _ in
                self.handleMoreUserVideos(name: inferredName)
            }
            controller.addAction(moreUserVideos)
        }
        
        // moderation action:
        let reportAction = UIAlertAction(title: TITLE_REPORT_ACTION, style: .destructive) { _ in
            self.handleReport(withViewController: viewController, sender: sender, forMoment: moment)
        }
        controller.addAction(reportAction)
        
        // cancel:
        let cancelAction = UIAlertAction(title: TITLE_CANCEL, style: .cancel, handler: nil)
        controller.addAction(cancelAction)
        
        viewController.present(controller, animated: true, completion: nil)
    }
    
    private func handleShare(withViewController presenter: UIViewController, sender: UIView)
    {
        guard let momentToShare = self.moment else { return }
        
        let shareSheet = ShareAlertSheet()
        shareSheet.showFrom(viewController: presenter, sender: sender, moment: momentToShare)
    }
    
    private func handleReport(withViewController presenter: UIViewController, sender: UIView, forMoment moment: Moment)
    {
        let videoLink = moment.video?.videoLink ?? ""
        let videoTitle = moment.video?.name ?? ""
        
        let emailBody = EMAIL_FEEDBACK_BODY
                        .replacingOccurrences(of: "{title}", with: videoTitle)
                        .replacingOccurrences(of: "{url}", with: videoLink)
        
        self.assistant.handleEmail(toRecipients: [EMAIL_FEEDBACK], subject: EMAIL_FEEDBACK_SUBJECT, message: emailBody, presenter: presenter)
    }
    
    private func handleMoreUserVideos(name inferredName: String)
    {
        self.delegate?.communityOptionsSelectedMoreUserVideos(name: inferredName)
    }
}
