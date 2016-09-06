//
//  SKUser.swift
//  StickerKit-iMessage-Example-App
//
//  Copyright © 2016 StickerKit. All rights reserved.
//

import UIKit

open class SKUser {
    
    open let UUID: String
    open let projectID: String
    open let countryCode: String
    open let deviceType: String
    
    internal struct PropertyKey {
        static let UUID = "UUID"
        static let projectID = "projectID"
        static let countryCode = "countryCode"
        static let deviceType = "deviceType"
        static let SKUserUserDefaultsKey = "SKUserKey"
    }
    
    public init (UUID:String, projectID:String) {
        self.UUID = UUID
        self.projectID = projectID
        self.countryCode = NSLocale.current.regionCode ?? ""
        self.deviceType = UIDevice.current.deviceType
    }
    
    convenience init(projectID:String) {
        let UUID = NSUUID().uuidString
        self.init(UUID: UUID, projectID: projectID)
    }
    
}

public extension UIDevice {
    
    var deviceType: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machine = systemInfo.machine
        let mirror = Mirror(reflecting: machine)
        var identifier = ""
        
        for child in mirror.children {
            if let value = child.value as? Int8 , value != 0 {
                identifier.append(String(UnicodeScalar(UInt8(value))))
            }
        }
        
        return parseDeviceType(identifier)
    }
    
}

func parseDeviceType(_ identifier: String) -> String {
    
    if identifier == "i386" || identifier == "x86_64" {
        return "Simulator"
    }
    
    switch identifier {
    case "iPhone1,1": return "iPhone 2G"
    case "iPhone1,2": return "iPhone 3G"
    case "iPhone2,1": return "iPhone 3GS"
    case "iPhone3,1", "iPhone3,2", "iPhone3,3": return "iPhone 4"
    case "iPhone4,1": return "iPhone 4S"
    case "iPhone5,1", "iPhone5,2": return "iPhone 5"
    case "iPhone5,3", "iPhone5,4": return "iPhone 5C"
    case "iPhone6,1", "iPhone6,2": return "iPhone 5S"
    case "iPhone7,1": return "iPhone 6 Plus"
    case "iPhone7,2": return "iPhone 6"
    case "iPhone8,2": return "iPhone 6S Plus"
    case "iPhone8,1": return "iPhone 6S"
    case "iPhone8,4": return "iPhone SE"
        
    case "iPod1,1": return "iPodTouch 1G"
    case "iPod2,1": return "iPodTouch 2G"
    case "iPod3,1": return "iPodTouch 3G"
    case "iPod4,1": return "iPodTouch 4G"
    case "iPod5,1": return "iPodTouch 5G"
        
    case "iPad1,1", "iPad1,2": return "iPad"
    case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4": return "iPad 2"
    case "iPad2,5", "iPad2,6", "iPad2,7": return "iPad Mini"
    case "iPad3,1", "iPad3,2", "iPad3,3": return "iPad 3"
    case "iPad3,4", "iPad3,5", "iPad3,6": return "iPad 4"
    case "iPad4,1", "iPad4,2", "iPad4,3": return "iPad Air"
    case "iPad4,4", "iPad4,5", "iPad4,6": return "iPad Mini Retina"
    case "iPad4,7", "iPad4,8": return "iPad Mini 3"
    case "iPad5,3", "iPad5,4": return "iPad Air 2"
    case "iPad6,3", "iPad6,4", "iPad6,7", "iPad6,8": return "iPad Pro"
        
    default: return identifier
    }
}
