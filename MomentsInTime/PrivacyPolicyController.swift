//
//  PrivacyPolicyController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 12/13/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

class PrivacyPolicyController: WebViewController
{    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        if let privacyPolicyFileURL = MITDocuments.privacyPolicy.localURL {
            self.loadLocalURL(url: privacyPolicyFileURL)
        }
    }
}



