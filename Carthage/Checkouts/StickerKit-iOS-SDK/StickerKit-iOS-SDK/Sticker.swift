//
//  Sticker.swift
//  StickerKit
//
//  Copyright © 2016 StickerKit. All rights reserved.
//

import Foundation

open class Sticker: Hashable {
    
    open let id: String
    open let url: URL
    open let sortOrder: Int
    open let descriptionEn: String?
    
    open var hashValue: Int {
        return id.hashValue
    }
    
    fileprivate struct PropertyKey {
        static let id = "id"
        static let url = "url"
        static let sortOrder = "sortOrder"
        static let descriptionEn = "description_en"
    }
    
    public init(id: String, url: URL, sortOrder: Int, descriptionEn: String?) {
        self.id = id
        self.url = url
        self.sortOrder = sortOrder
        self.descriptionEn = descriptionEn
    }
    
    public convenience init?(dictionary: [String:AnyObject]){
        guard let id = dictionary[PropertyKey.id] as? String,
        let URLString = dictionary[PropertyKey.url] as? String,
        let url = URL(string:URLString),
        let orderNumber = dictionary[PropertyKey.sortOrder] as? Int else {
            
            //Could not parse JSON
            return nil
        
        }
        
        let descriptionEn = dictionary[PropertyKey.descriptionEn] as? String
        
        self.init(id: id, url:url, sortOrder: orderNumber, descriptionEn: descriptionEn)
    }
    
    var cacheFilename: String {
        
        guard let indexofQ = self.url.absoluteString.range(of: "?", options: .backwards)?.lowerBound else {
            return String(id)
        }
        
        let substring2 = self.url.absoluteString.substring(to: indexofQ)
        
        guard let indexofDot = substring2.range(of: ".", options: .backwards)?.lowerBound else {
            return String(id)
        }
        
        let fileType = substring2.substring(from: indexofDot)
        return String(id) + fileType
    }

    //Equatable Protocol
    public static func ==(lhs:Sticker, rhs:Sticker) -> Bool {
        return lhs.id == rhs.id
    }
}


internal extension Sticker {
    internal static func loadStickers(_ JSON:[String:AnyObject]) -> [Sticker] {
        
        guard let groupDicts = JSON["groups"] as? [[String:AnyObject]] else {
            return []
        }
        
        let groups = groupDicts.flatMap {
            StickerGroup.loadGroups($0)
        }

        return groups.flatMap {
            $0.stickers
        }
    }
}
