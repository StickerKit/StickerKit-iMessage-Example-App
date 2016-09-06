#
# validate using `pod lib lint StickerKit.podspec'

Pod::Spec.new do |s|
  s.name             = 'StickerKit'
  s.version          = '1.0.0'
  s.summary          = 'StickerKit - Power up your sticker app!'

  s.description      = <<-DESC

StickerKit is an online service for building powerful sticker apps. The iOS SDK provides tools for quickly deploying a sticker app with dynamically loaded and locally cached stickers!
DESC

  s.homepage         = 'https://github.com/StickerKit/StickerKit-iOS-SDK'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'StickerKit' => 'info@stickerkit.io' }
  s.source           = { :git => 'https://github.com/StickerKit/StickerKit-iOS-SDK.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.source_files = 'StickerKit/Classes/**/*'
  s.frameworks = 'Messages', 'ImageIO', 'Foundation'
end
