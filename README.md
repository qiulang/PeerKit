# PeerKit

## An open-source Swift framework for building event-driven, zero-config Multipeer Connectivity apps

##Qiulang's modification:
1. Maintain a MCSessionState in Session, only stopAdvertising when connected. Because <1> when you accept invitation there is no guarantee you will be connected. In fact I find it is quite often Session goes from .connecting to .notConnected without .connected. <2> When 2 peers first connected then disconnected they can't reconnect again because they have called stopAdvertising.
2. Re-implement sendResourceAtURL, add startReceivingResource, ResourceProgressBlock because it is my main use case, e.g. sending picture from UIImagePickerController
3. Remove SessionDelegate from Session, access Transceiver directly. I don't think many people will implement SessionDelegate, after all we provide public block in PeerKit and I assume most PeerKit's users will use those blocks instead of implementing SessionDelegate.

## Usage

```swift
//Qiulang, my use case will focuse on sending image from
//UIImagePickerController, the original implementation 
//failed to do it right. It focused more on sending message.

----- original sample -----
// Automatically detect and attach to other peers with this service type
PeerKit.transceive("com-jpsim-myApp")

enum Event: String {
    case StartGame, EndGame
}

// Send a StartGame event with attached data to all peers
PeerKit.sendEvent(Event.StartGame.rawValue, object: ["myInfo": "hello!"])
```

See the [CardsAgainst](https://github.com/jpsim/CardsAgainst) app for example usage. Specifically the [ConnectionManager](https://github.com/jpsim/CardsAgainst/blob/master/CardsAgainst/Controllers/ConnectionManager.swift) class.

## License

This project is under the MIT license.
