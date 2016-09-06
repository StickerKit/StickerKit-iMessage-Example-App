//
//  SKEvent.swift
//  StickerKit-iMessage-Example-App
//
//  Copyright © 2016 StickerKit. All rights reserved.
//

import Foundation

open class SKEvent {
    
    public enum SKEventType : String {
        case openedApp = "Opened App"
        case sentSticker = "Sent Sticker"
    }
    
    internal struct PropertyKey {
        static let type = "type"
        static let stickerID = "stickerID"
    }
    
    open static func track(event:SKEventType, sticker:Sticker? = nil){
        
        guard let user = SKImageManager.user else {
            // Don't track event
            return
        }
        
        guard let request = createUserEventData(user: user, eventType: event, sticker: sticker) else {
            print("Could not save event. Are you using a proper projectID?")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request)

        task.resume()
        
    }
    
    private static func createUserEventData(user:SKUser, eventType:SKEventType, sticker:Sticker?) -> URLRequest? {
        
        let endpoint = "https://app.stickerkit.io/userEvent/v1/\(user.projectID)"
        
        guard let endpointUrl = URL(string: endpoint) else {
            return nil
        }
        
        var json = [String:Any]()
        
        json[SKUser.PropertyKey.UUID] = user.UUID
        json[SKUser.PropertyKey.projectID] = user.projectID
        json[SKUser.PropertyKey.countryCode] = user.countryCode
        json[SKUser.PropertyKey.deviceType] = user.deviceType
        json[SKEvent.PropertyKey.type] = eventType.rawValue
        json[SKEvent.PropertyKey.stickerID] = sticker?.id ?? ""
        
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            
            var request = URLRequest(url: endpointUrl)
            request.httpMethod = "POST"
            request.httpBody = data
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")

            return request
            
        }catch{
            return nil
        }
    }
    
}
