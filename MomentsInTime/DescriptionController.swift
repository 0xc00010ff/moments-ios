//
//  DescriptionController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/26/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

private let COPY_TEXT_PLACEHOLDER_TITLE_FIELD = "Enter title"
private let COPY_TEXT_PLACEHOLDER_DESCRIPTION_FIELD = "Enter description"

enum DescriptionSection: Int
{
    case title = 0
    case description = 1
    
    static var titles: [String] {
        return ["Title", "Description"]
    }
    
    var placeholderText: String {
        switch self {
        case .title: return COPY_TEXT_PLACEHOLDER_TITLE_FIELD
        case .description: return COPY_TEXT_PLACEHOLDER_DESCRIPTION_FIELD
        }
    }
}

class DescriptionController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    @IBOutlet weak var saveButton: BouncingButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    
    private enum Identifiers
    {
        static let IDENTIFIER_CELL_TEXT_FIELD = "textFieldCell"
        static let IDENTIFIER_CELL_TEXT_VIEW = "textViewCell"
        static let IDENTIFIER_VIEW_SECTION_HEADER = "sectionHeaderView"
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.saveButton.isEnabled = false
        self.setupTableView()
    }
    
    //MARK: Actions
    
    @IBAction func handleSave(_ sender: BouncingButton)
    {
        print("save Title and Description")
    }
    
    @IBAction func handleCancel(_ sender: BouncingButton)
    {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    //MARK: TableView
    
    private func setupTableView()
    {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.contentInset.top = 12
        
        //setup sectionHeaderViews:
        self.tableView.register(UINib(nibName: String(describing: MITSectionHeaderView.self), bundle: nil), forHeaderFooterViewReuseIdentifier: Identifiers.IDENTIFIER_VIEW_SECTION_HEADER)
        self.tableView.estimatedSectionHeaderHeight = 64
        self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        self.tableView.sectionFooterHeight = 16
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return DescriptionSection.titles.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        if let sectionHeaderView = tableView.dequeueReusableHeaderFooterView(withIdentifier: Identifiers.IDENTIFIER_VIEW_SECTION_HEADER) as? MITSectionHeaderView {
            sectionHeaderView.title = DescriptionSection.titles[section]
            return sectionHeaderView
        }
        
        assert(false, "Unknown SectionHeaderView dequeued")
        return MITSectionHeaderView()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        return UITableViewCell()
    }
}
