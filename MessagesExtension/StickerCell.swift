//
//  StickerCell.swift
//  StickerKit-iMessage-Example-App
//
//  Created by Admin on 2016-09-06.
//  Copyright © 2016 StickerKit. All rights reserved.
//

import UIKit
import Messages
import StickerKit

class StickerCell: UICollectionViewCell {
    
    @IBOutlet weak var stickerView: SKStickerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var sticker: Sticker? {
        didSet{
            
            if let sticker = sticker {
                
                activityIndicator.startAnimating()
                stickerView.SKSticker = sticker
                
                SKImageManager.sharedInstance.convert(sticker) { msSticker in
                    
                    self.activityIndicator.stopAnimating()
                    
                    if let msSticker = msSticker {
                        self.stickerView.sticker = msSticker
                        self.stickerView.startAnimating()
                    }
                }
                
            }
        }
    }
}
