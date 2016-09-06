//
//  SKImageManager.swift
//  StickerKit
//
//  Copyright © 2016 StickerKit. All rights reserved.
//

import Foundation
import Messages

/**
 SKImageManager helps you download stickers from StickerKit's API
 
 It has 3 Key Parts:
 
 Part 1 - Specify your project ID
 
  Use setup(project:, appGroup:) to specify your project ID and instantiate the singleton as needed. After that, use SKImageManager.sharedInstance. Without an app group identifier specified, the image manager caches images previously downloaded to the Caches directory, with app groups it caches images to the App Group Shared Container with the identifier you pass in.
 
 Part 2 - get JSON back from StickerKit's API.
 
 - func stickers(completion:(stickers:[Sticker]). This method will get sticker details for all the Stickers for your active project. A Sticker object contains a url for the sticker image data to be downloaded at.

 - func stickerGroups(completion:(stickerGroups:[StickerGroup]) An alternative to the above method, this method will get stickers and they will be grouped as you have specified on StickerKit's Website. A StickerGroup object has a name and an array of stickers.
 
 Part 3 - download or use cached sticker image data for a specific Sticker.
 
 - func convert(sticker:Sticker, completion:(sticker:MSSticker?). This is perfect is you are bulding a sticker app and want back MSSticker objects. This method will download the sticker image data and then cache them for subsequent use.
 
 - func imageData(sticker: Sticker , completion:(local: URL?) Use this alternative if you are building a sticker app but would rather work with sticker image data yourself. This method will download the sticker image data and then cache them for subsequent use.
 
    You can find more sample code and projects for StickerKit at https://github.com/StickerKit
 */

open class SKImageManager {
    
    fileprivate static var _sharedInstance: SKImageManager?
    
    internal static var user:SKUser?
    
    // MARK: - Public setup methods
    
    open static var sharedInstance: SKImageManager {
        guard let si = _sharedInstance else {
            fatalError("Make sure to call setup before accessing the SKImageManager singleton")
        }
        
        return si
    }
    
    open static func setup(_ project: String, appGroup: String? = nil, trackUserAnalytics:Bool = true) {

//        guard _sharedInstance == nil else {
//            fatalError("Do not setup your SKImageManager more than once per run.")
//        }
        
        if let appGroup = appGroup {
            _sharedInstance = SKImageManager(project: project, appGroup: appGroup)
        } else {
            _sharedInstance = SKImageManager(project: project)
        }
        
        if trackUserAnalytics{
            user = getSKUser(projectID: project)
            SKEvent.track(event: .openedApp)
        }
    }
    
    // MARK: - Properties
    
    let projectID: String
    
    fileprivate let fileManager = FileManager.default
    fileprivate let cacheDirectory: URL
    fileprivate let stickersDirectoryName = "stickers"
    fileprivate let jsonFileName = "APIData.json"
    
    fileprivate let diskQueue = DispatchQueue(label: "com.StickerKit.diskQueue")
    
    fileprivate var stickersDirectory: URL {
        return cacheDirectory.appendingPathComponent(self.stickersDirectoryName)
    }
    
    fileprivate var metadataFileURL: URL {
        return cacheDirectory.appendingPathComponent(jsonFileName)
    }
    
    // MARK: - init
    
    fileprivate init(project: String) {
        guard let smp = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            fatalError("couldn't obtain caches directory, exiting")
        }
        projectID = project
        cacheDirectory = smp
        createStickersFolder()
    }
    
    fileprivate init(project: String, appGroup:String) {
        guard let smp = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("app group not found, make sure you've got the right identifier")
        }
        
        projectID = project
        
        cacheDirectory = smp
    
        createStickersFolder()
    }
    
    fileprivate static func getSKUser(projectID: String) -> SKUser {
        
        let userDefaults = UserDefaults.standard
        guard let userUUID = userDefaults.string(forKey: SKUser.PropertyKey.SKUserUserDefaultsKey) else {
            
            let user = SKUser(projectID: projectID)
            userDefaults.set(user.UUID, forKey: SKUser.PropertyKey.SKUserUserDefaultsKey)
            userDefaults.synchronize()
            return user
        }
        
        return SKUser(UUID: userUUID, projectID: projectID)
        
    }
    
    // MARK: - Public interface:
    
    /**
     
     This method will get sticker details for all the stickers in your specified project. It will always go check StickerKit's server to see if there are any new or updated stickers that you have added on StickerKit's website, download it, and cache it for next time. If there have been no updates to your project, it will return the cached version of sticker details.
     
     Writing and reading to file is done on a background queue but the completion block is returned on the main thread for ease of use.
     
     If you care about having your stickers in groups see the alternative method -stickerGroups(completion:)
     
     - parameter completion: Returns an array of Sticker Objects. Each Sticker object contains an id, description (String) and the url at which the sticker can be downloaded at.
     
     */
    open func stickers(_ completion:@escaping ([Sticker]) -> ()) {
        self.stickerGroups {
            groups in
            let stickers = groups.flatMap({ $0.stickers })
            completion(stickers)
        }
    }
    
    /**
     
     This method will get stickers and which group each sticker is in. It will always go check StickerKit's server to see if there are any new or updated stickers, download it, and cache it for next time. If there have been no updates to your project, it will return the cached version of StickerGroup details.
     
     Writing and reading to file is done on a background queue but the completion block is returned on the main thread for ease of use.
     
     If you just care about having an array of stickers (not stored into groups) see the alternative method -stickers(completion:)
     
     - parameter completion: Returns an array of StickerGroup Objects. Each StickerGroup object contains a groupName, and an array of Sticker objects.
     
     */
    fileprivate func stickerGroups(_ completion:@escaping ([StickerGroup]) -> ()) {
        
        let endpoint = "https://app.stickerkit.io/api/v1/project/\(self.projectID)"
        
        guard let endpointUrl = URL(string: endpoint) else {
            fatalError("couldn't create endpoint url, bad project id?")
        }
        
        let task = URLSession.shared.dataTask(with: endpointUrl) { (jsonData, response, error) in
            
            self.diskQueue.async {
                do {
                    
                    guard let jsonData = jsonData, let JSON = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:AnyObject] else {
                        
                        // Load for cache if possible
                        guard self.hasLocalMetadata else {
                            DispatchQueue.main.async {
                                completion([StickerGroup]())
                            }
                            return
                        }
                        
                        let stickerGroups = try self.cachedStickerGroups()
                        
                        DispatchQueue.main.async {
                            completion(stickerGroups)
                        }
                        
                        return
                    }
                    
                    guard self.hasLocalMetadata else {
                        // JSON doesn't exist on disk
                        
                        let stickerGroups = StickerGroup.loadGroups(JSON)
                        
                        DispatchQueue.main.async {
                            completion(stickerGroups)
                        }
                        
                        try self.write(jsonData)
                        
                        return
                    }
                    
                    guard try self.localMetadataOlder(than: JSON) else {
                        // JSON on Disk is as recent as downloaded JSON
                        
                        let stickerGroups = try self.cachedStickerGroups()
                        
                        DispatchQueue.main.async {
                            completion(stickerGroups)
                        }
                        
                        return
                    }
                    
                    // json on disk is out of date!
                    
                    let stickerGroups = StickerGroup.loadGroups(JSON)
                    let newStickers = stickerGroups.flatMap { $0.stickers }
                    
                    let localStickers = try self.cachedStickers()
                    
                    //Return stickers
                    DispatchQueue.main.async {
                        completion(stickerGroups)
                    }
                    
                    // Remove Cached stickers that are now longer required
                    let newStickerSet = Set(newStickers)
                    let oldStickersSet = Set(localStickers).subtracting(newStickerSet)
                    
                    for oldSticker in oldStickersSet {
                        try self.decache(oldSticker)
                    }
                    
                    // Update local JSON to newly downloaded JSON
                    try self.write(jsonData)
                    return
                    
                } catch {
                    print("Could not load JSON from StickerKit. Error - \(error)")
                    
                    // On File Wiriting Thread before moving to main thread
                    DispatchQueue.main.async {
                        completion([StickerGroup]())
                    }
                }
            }
        }
        
        task.resume()
    }
    
    /**
     
     This method will get image data for the specified Sticker Object. It will always go check locally to see if there is a cached version of your sticker, if not it will download it from StickerKit's server.
     
     Writing and reading to file is done on a background queue but the completion block is returned on the main thread for ease of use.
     
     - parameter sticker: Pass in your unique sticker
     
     - parameter completion: Returns the local URL to where the sticker image data has been downloaded.
     
     */
    
    open func imageData(_ sticker: Sticker , completion:@escaping (URL?) -> ()) {
        diskQueue.async {
            if let stickerURL = self.localDataURL(sticker){
                DispatchQueue.main.async {
                    completion(stickerURL)
                }
            } else { //download + save Sticker to disk + return image
                self.downloadToCache(sticker) {
                    stickerFile in
                    DispatchQueue.main.async {
                        completion(stickerFile)
                    }
                }
            }
        }
    }
    
    /**
     
     This method will get get image data for the specified Sticker Object and return it as a MSSticker object. It will always go check locally to see if there is a cached version of your sticker, if not it will download it from StickerKit's server.
     
     Writing and reading to file is done on a background queue but the completion block is returned on the main thread for ease of use.
     
     - parameter sticker: Pass in your unique sticker
     
     - parameter completion: Returns a MSSticker initalized with your sticker image data
     
     */
    
    open func convert(_ sticker:Sticker, completion:@escaping (MSSticker?) -> ()) {
        
        imageData(sticker) { (localURL) in
            
            guard let localURL = localURL else {
                completion(nil)
                return
            }
            
            do {
                let sticker = try MSSticker(contentsOfFileURL: localURL, localizedDescription: sticker.descriptionEn ?? "")
                completion(sticker)
            } catch {
                print("Could not convert Sticker object to MSSticker object - Error \(error)")
                completion(nil)
            }
            
        }
    }
    
    fileprivate func createStickersFolder() {
        
        diskQueue.async {
            
            let stickerPathURL = self.stickersDirectory
            
            if !self.fileManager.fileExists(atPath: stickerPathURL.path){
                do {
                    try self.fileManager.createDirectory(at: stickerPathURL, withIntermediateDirectories: false, attributes: nil)
                } catch {
                    print("Error could not load Documents directory with error \(error)")
                }
            }
        }
    
    }
    
    fileprivate var hasLocalMetadata: Bool {
        return fileManager.fileExists(atPath: metadataFileURL.path)
    }
    
    fileprivate func loadMetadata(fromFile url:URL) throws -> [String:AnyObject]? {
        let jsonData = try Data(contentsOf: url)
        let jsonUnfromatted = try JSONSerialization.jsonObject(with: jsonData, options: [])
        if let JSON = jsonUnfromatted as? [String:AnyObject]{
            return JSON
        }
        return nil
    }
    
    fileprivate func localMetadataOlder(than JSON:[String:AnyObject]) throws -> Bool {
        
        let df = DateFormatter()
        df.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZ"

        guard let remoteDateString = JSON[StickerGroup.PropertyKey.updatedAt] as? String,
            let remoteDate = df.date(from: remoteDateString)
            else {
            return false
        }
        
        guard let localMetadata = try loadMetadata(fromFile: metadataFileURL),
            let localDateString = localMetadata[StickerGroup.PropertyKey.updatedAt] as? String,
            let localDate = df.date(from: localDateString) else {
            return true
        }
        
        return remoteDate > localDate
    }
    
    fileprivate func cachedStickers() throws -> [Sticker] {
        return try cachedStickerGroups().flatMap({ $0.stickers })
    }
    
    fileprivate func cachedStickerGroups() throws -> [StickerGroup] {
        if let localJSON = try loadMetadata(fromFile: metadataFileURL){
            return StickerGroup.loadGroups(localJSON)
        }
        return [StickerGroup]()
    }
    
    // MARK: - Sticker Cache

    fileprivate func localDataURL(_ sticker:Sticker) -> URL? {
        
        let stickerFileURL = stickersDirectory.appendingPathComponent(sticker.cacheFilename)
        
        if fileManager.fileExists(atPath: stickerFileURL.path) {
            return stickerFileURL
        }
        
        return nil
    }
    
    fileprivate func downloadToCache(_ sticker:Sticker, completion:@escaping (URL?) -> (Void)) {
        
        URLSession.shared.downloadTask(with: sticker.url, completionHandler: {
            url, response, error in
            
            self.diskQueue.async {
                
                guard let localTempURL = url else {
                    completion(nil)
                    return
                }
                
                do {
                    let data = try Data(contentsOf: localTempURL)
                    
                    let stickerFile = self.stickersDirectory.appendingPathComponent(sticker.cacheFilename)
                    
                    try data.write(to: stickerFile)
                    
                    completion(stickerFile)
                    
                } catch {
                    print("Error - cannot access data at URL or write sticker to disk w/ \(error)")
                    completion(nil)
                    
                }
            }
            
        }).resume()
        
    }
    
    fileprivate func decache(_ sticker:Sticker) throws {
        let stickerPathURL = self.stickersDirectory
        let thisStickerPathURL = stickerPathURL.appendingPathComponent(sticker.cacheFilename)
        if fileManager.fileExists(atPath: thisStickerPathURL.path){
            try fileManager.removeItem(at: thisStickerPathURL)
        }
    }
    
    // MARK: - Metadata persistance
    
    fileprivate func write(_ metadataJson: Data) throws {
        try metadataJson.write(to: metadataFileURL)
    }

    
}

