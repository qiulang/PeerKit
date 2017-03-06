//
//  PeerKit.swift
//  CardsAgainst
//
//  Created by JP Simard on 11/5/14.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//  Modified by Qiulang to add support for sending/receiving image from UIImagePickerController

import Foundation
import MultipeerConnectivity

// MARK: Type Aliases

public typealias PeerBlock = ((_ myPeerID: MCPeerID, _ peerID: MCPeerID) -> Void)
public typealias EventBlock = ((_ peerID: MCPeerID, _ event: String, _ object: AnyObject?) -> Void)
public typealias ObjectBlock = ((_ peerID: MCPeerID, _ object: AnyObject?) -> Void)
public typealias ResourceBlock = (( _ resourceName: String, _ peer: MCPeerID, _ localURL: URL) -> Void)
public typealias ResourceProgressBlock = ((_ resourceName: String, _ peer: MCPeerID, _ progress:Progress) -> Void)

// MARK: Event Blocks, users of PeerKit should provide event handler they are interested
// It is easier than implementing SessionDelegate

public var onConnecting: PeerBlock?
public var onConnect: PeerBlock?
public var onDisconnect: PeerBlock?
public var onEvent: EventBlock?
public var onEventObject: ObjectBlock?
public var onFinishReceivingResource: ResourceBlock?
public var onReceivingResource:ResourceProgressBlock?
public var eventBlocks = [String: ObjectBlock]()

// MARK: PeerKit Globals

#if os(iOS)
import UIKit
public let myName = UIDevice.current.name
#else
public let myName = Host.current().localizedName ?? ""
#endif

public var transceiver = Transceiver(displayName: myName)
public var session: MCSession?
let format = DateFormatter()

// MARK: Event Handling, re-directed from SessionDelegate

func didConnecting(myPeerID: MCPeerID, peer: MCPeerID) {
    if let onConnecting = onConnecting {
        DispatchQueue.main.async {
            onConnecting(myPeerID, peer)
        }
    }
}

func didConnect(myPeerID: MCPeerID, peer: MCPeerID) {
    if session == nil {
        session = transceiver.session.mcSession
    }
    if let onConnect = onConnect {
        DispatchQueue.main.async {
            onConnect(myPeerID, peer)
        }
    }
}

func didDisconnect(myPeerID: MCPeerID, peer: MCPeerID) {
    if let onDisconnect = onDisconnect {
        DispatchQueue.main.async {
            onDisconnect(myPeerID, peer)
        }
    }
}

func didReceiveData(_ data: Data, fromPeer peer: MCPeerID) {
    if let dict = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: AnyObject],
        let event = dict["event"] as? String,
        let object = dict["object"] {
            DispatchQueue.main.async {
                if let onEvent = onEvent {
                    onEvent(peer, event, object)
                }
                if let eventBlock = eventBlocks[event] {
                    eventBlock(peer, object)
                }
            }
    }
}

func didStartReceivingResource(_ name: String, fromPeer peerID: MCPeerID, progress: Progress) {
    guard let onReceivingResource =  onReceivingResource else {
        return;
    }
    DispatchQueue.main.async {
        onReceivingResource(name, peerID, progress)
    }
}

func didFinishReceivingResource(_ name: String, fromPeer peerID: MCPeerID, localURL: URL) {
    guard let onFinishReceivingResource = onFinishReceivingResource else {
        return;
    }
    DispatchQueue.main.async {
        onFinishReceivingResource(name, peerID, localURL)
    }
}

// MARK: Advertise/Browse

public func transceive(serviceType: String, discoveryInfo: [String: String]? = nil) {
    transceiver.startTransceiving(serviceType: serviceType, discoveryInfo: discoveryInfo)
}

public func advertise(serviceType: String, discoveryInfo: [String: String]? = nil) {
    transceiver.startAdvertising(serviceType: serviceType, discoveryInfo: discoveryInfo)
}

public func browse(serviceType: String) {
    transceiver.startBrowsing(serviceType: serviceType)
}

public func stopTransceiving() {
    transceiver.stopTransceiving()
    session = nil
}

// MARK: Send message/resource

public func sendEvent(_ event: String, object: AnyObject? = nil, toPeers peers: [MCPeerID]? = session?.connectedPeers) {
    guard let peers = peers, !peers.isEmpty else {
        return
    }

    var rootObject: [String: AnyObject] = ["event": event as AnyObject]

    if let object: AnyObject = object {
        rootObject["object"] = object
    }

    let data = NSKeyedArchiver.archivedData(withRootObject: rootObject)

    do {
        try session?.send(data, toPeers: peers, with: .reliable)
    } catch _ {
    }
}

public func sendResourceAtURL(_ resourceURL: URL,
                              resourceName: String,
                              peers: [MCPeerID]? = session?.connectedPeers,
                   info: [String : Any]?,
                completionHandler: ((Error?) -> Void)? = nil) -> [Progress?]?  {
    guard let session = session else {
        return nil
    }
    guard let _ = peers?.first else {
        return nil
    }
    if resourceURL.isFileURL {
        return peers!.map { peerID in
            return session.sendResource(at: resourceURL, withName: resourceName, toPeer: peerID, withCompletionHandler: completionHandler)
        }
    }
    guard resourceURL.scheme?.hasPrefix("assets-library") == true,
          let image = info?[UIImagePickerControllerOriginalImage] as? UIImage else {
            return nil;
    }
    format.timeStyle = .medium
    let documentDirectory = NSTemporaryDirectory() + "sentPic-" + format.string(from: Date.init()) + ".jpg"
    let photoURL          = URL(fileURLWithPath: documentDirectory)
    let data              = UIImageJPEGRepresentation(image, 1.0)
    guard (try? data?.write(to: photoURL, options: Data.WritingOptions.atomic)) != nil  else {
        return nil
    }
    return peers!.map { peerID in
        return session.sendResource(at: photoURL, withName: resourceName, toPeer: peerID, withCompletionHandler: completionHandler)
    }
}
