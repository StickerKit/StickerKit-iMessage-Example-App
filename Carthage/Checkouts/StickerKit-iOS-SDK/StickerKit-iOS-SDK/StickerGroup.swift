//
//  Group.swift
//  StickerKit-iOS-Example-App
//
//  Copyright © 2016 StickerKit. All rights reserved.
//

import Foundation

open class StickerGroup {
    
    open let groupName: String
    open let stickers: [Sticker]
    
    internal struct PropertyKey {
        static let groupName = "groupName"
        static let stickers = "stickers"
        static let updatedAt = "updatedAt"
    }
    
    public init(groupName: String, stickers: [Sticker]) {
        self.groupName = groupName
        self.stickers = stickers
    }
    
    public convenience init?(dictionary: [String:AnyObject]){
        guard let groupName = dictionary[PropertyKey.groupName] as? String,
            let stickersArray = dictionary[PropertyKey.stickers] as? [[String:AnyObject]] else {
                
                //Could not parse JSON
                return nil
                
        }
        
        let stickers = stickersArray.flatMap { Sticker(dictionary: $0) }
        
        self.init(groupName:groupName, stickers:stickers)
    }
    
}

internal extension StickerGroup {
    internal static func loadGroups(_ JSON: [String:AnyObject]) -> [StickerGroup] {
        
        guard let groupDicts = JSON["groups"] as? [[String:AnyObject]] else {
            return []
        }
        
        return groupDicts.flatMap { StickerGroup(dictionary: $0) }
    }

}
