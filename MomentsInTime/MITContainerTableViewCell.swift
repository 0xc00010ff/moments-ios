//
//  MITContainerTableViewCell.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/28/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import PureLayout

class MITContainerTableViewCell: ContainerTableViewCell
{
    @objc dynamic var upperSeparatorColor: UIColor? {
        get {
            return self.upperSeparatorView.backgroundColor
        }
        set {
            self.upperSeparatorView.backgroundColor = newValue
        }
    }
    
    @objc dynamic var lowerSeparatorColor: UIColor? {
        get {
            return self.lowerSeparatorView.backgroundColor
        }
        set {
            self.lowerSeparatorView.backgroundColor = newValue
        }
    }
    
    private lazy var upperSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var lowerSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    private func setup()
    {
        self.backgroundColor = .white
        self.addSubview(self.upperSeparatorView)
        self.addSubview(self.lowerSeparatorView)
        
        let separatorSize = 1.0 / UIScreen.main.scale
        
        self.upperSeparatorView.autoPinEdge(toSuperviewEdge: .leading)
        self.upperSeparatorView.autoPinEdge(toSuperviewEdge: .trailing)
        self.upperSeparatorView.autoPinEdge(toSuperviewEdge: .top)
        self.upperSeparatorView.autoSetDimension(.height, toSize: separatorSize)
        
        self.lowerSeparatorView.autoPinEdge(toSuperviewEdge: .leading)
        self.lowerSeparatorView.autoPinEdge(toSuperviewEdge: .trailing)
        self.lowerSeparatorView.autoPinEdge(toSuperviewEdge: .bottom)
        self.lowerSeparatorView.autoSetDimension(.height, toSize: separatorSize)
    }
}
