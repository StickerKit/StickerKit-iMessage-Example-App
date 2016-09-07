<p align="center">
  <img src ="https://app.stickerkit.io/images/StickerKit-Logo-Text.png" />
</p>


## Running iMessage Example App

After uploading stickers to stickerkit.io, All you need to do to get your stickers inside this Example App is change one line of code.

Inside of MessagesViewController.swift

We have to change this line:

```
SKImageManager.setup(“57cca495ac62ce0f00b23496”)
```

to

```
SKImageManager.setup(“YOUR_PROJECT_ID”)
```

where “YOUR__PROJECT_-ID” should be replaced with the project ID from your dashboard.

If you would like more instructions, please see [this guide.](https://medium.com/@dmathewwws/using-stickerkit-to-build-an-imessage-sticker-app-28d301ee745d#.6vdnqrioi)


## Author

Cory Alder & Daniel Mathews, StickerKit

## License

StickerKit is available under the MIT license. See the LICENSE file for more info.