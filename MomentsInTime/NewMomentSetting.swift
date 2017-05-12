//
//  NewMomentSetting.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/18/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation

let COPY_SELECT_INTERVIEW_SUBJECT = "Select a special person to interview"
let COPY_CREATE_TOPIC = "Select a topic"
let COPY_CREATE_VIDEO = "Start filming or upload a video"
let COPY_CREATE_NOTE = "Add a new note"

let COPY_LINK_START_FILMING = "Start filming"
let COPY_LINK_UPLOAD_VIDEO = "upload a video"

enum NewMomentSetting: Int
{
    case interviewing = 0
    case topic = 1
    case video = 2
    case notes = 3
    
    static var titles: [String] {
        return ["Interviewing", "Topic", "Video", "Notes"]
    }
    
    static var defaultNotes: [Note] {
        
        let notes = [
            Note(withText: "This is where we can show question prompts, like the ones everyone will see by default"),
            Note(withText: "We will also allow users to create and edit their own notes in case they want to go freeform"),
            Note(withText: "This is a note about an interesting question that someone might want to ask when they are interviewing someone. There will be stock notes and user-created notes."),
            Note(withText: "Another note, possibly user-created with some ideas for an interview. I am going to make this a long note because, hey, I can do whatever I want. I am the user and I am in control. I want to make sure that a longer note will still look right in this app too!")
        ]
        
        return notes
    }
    
    var text: String {
        switch self {
        case .interviewing: return COPY_SELECT_INTERVIEW_SUBJECT
        case .topic: return COPY_CREATE_TOPIC
        case .video: return COPY_CREATE_VIDEO
        case .notes: return COPY_CREATE_NOTE
        }
    }
    
    var activeLinks: [String] {
        switch self {
        case .interviewing: return [COPY_SELECT_INTERVIEW_SUBJECT]
        case .topic: return [COPY_CREATE_TOPIC]
        case .video: return [COPY_LINK_START_FILMING, COPY_LINK_UPLOAD_VIDEO]
        case .notes: return [COPY_CREATE_NOTE]
        }
    }
}
