# Change Log
##Qiulang's modification:
1. Maintain a MCSessionState in Session, only stopAdvertising when connected. Because <1> when you accept invitation there is no guarantee you will be connected. In fact I find it is quite often Session goes from .connecting to .notConnected without .connected. <2> When 2 peers first connected then disconnected they can't reconnect again because they have called stopAdvertising.
2. Re-implement sendResourceAtURL, add startReceivingResource, ResourceProgressBlock because it is my main use case, e.g. sending picture from UIImagePickerController
3. Remove SessionDelegate from Session, access Transceiver directly. I don't think many people will implement SessionDelegate, after all we provide public block in PeerKit and I assume most PeerKit's users will use those blocks instead of implementing SessionDelegate.

### Provide example to show how to send images from UIImagePickerController

