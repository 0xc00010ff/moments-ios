//
//  Moment.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/30/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation
import RealmSwift

class Moment: Object
{
    dynamic var momentID = UUID().uuidString
    dynamic var subject: Subject?
    dynamic var video: Video?
    dynamic var createdAt = Date()
    dynamic var existsInRealm = false
    let notes = List<Note>()
    
    var isValid: Bool {
        return false
    }
    
    override static func primaryKey() -> String?
    {
        return "momentID"
    }
    
    
    override static func ignoredProperties() -> [String]
    {
        return ["exists"]
    }
    
    func create()
    {
        // add a new thing to realm
        if !self.existsInRealm
        {
            //add moment to realm:
            if let realm = try? Realm() {
                
                try? realm.write {
                    realm.add(self)
                }
            }
            
            self.existsInRealm = true
        }
    }
}

extension Moment
{
    //modify objects and perform any UI updates in handler:
    class func writeToRealm(withHandler handler: () -> Void)
    {
        if let realm = try? Realm() {
            realm.beginWrite()
            handler()
            try? realm.commitWrite()
        }
    }
}
