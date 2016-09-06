//
//  MSSticker-StickerKit.swift
//  StickerKit-iOS-Example-App
//
//  Copyright © 2016 StickerKit. All rights reserved.
//

import Foundation
import Messages
import ImageIO

public extension MSSticker {
    
    /**
     
     Helper method will return if a sticker has single or mutiple frames
     
     */
    
    public var canAnimate: Bool {
        guard let stickerImageSource = CGImageSourceCreateWithURL(imageFileURL as CFURL, nil) else {
            return false
        }
        
        return CGImageSourceGetCount(stickerImageSource) > 1
    }
}


