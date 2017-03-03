//
//  Transceiver.swift
//  CardsAgainst
//
//  Created by JP Simard on 11/3/14.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//  Modified by Qiulang, add startReceivingResource to help receive resource

import Foundation
import MultipeerConnectivity

enum TransceiverMode {
    case Browse, Advertise, Both
}

public class Transceiver {

    var transceiverMode = TransceiverMode.Both
    let session: Session
    let advertiser: Advertiser
    let browser: Browser

    public init(displayName: String!) {
        session = Session(displayName: displayName)
        advertiser = Advertiser(mcSession: session.mcSession)
        browser = Browser(mcSession: session.mcSession)
    }

    func startTransceiving(serviceType: String, discoveryInfo: [String: String]? = nil) {
        advertiser.startAdvertising(serviceType: serviceType, discoveryInfo: discoveryInfo)
        browser.startBrowsing(serviceType: serviceType)
        transceiverMode = .Both
    }

    func stopTransceiving() {
        advertiser.stopAdvertising()
        browser.stopBrowsing()
        session.disconnect()
    }

    func startAdvertising(serviceType: String, discoveryInfo: [String: String]? = nil) {
        advertiser.startAdvertising(serviceType: serviceType, discoveryInfo: discoveryInfo)
        transceiverMode = .Advertise
    }

    func startBrowsing(serviceType: String) {
        browser.startBrowsing(serviceType: serviceType)
        transceiverMode = .Browse
    }
}

//MARK: - SessionDelegate, re-direct to PeerKit's public blocks which users should provide

extension Transceiver: SessionDelegate {
    
    public func connecting(myPeerID: MCPeerID, toPeer peer: MCPeerID) {
        didConnecting(myPeerID: myPeerID, peer: peer)
    }

    public func connected(myPeerID: MCPeerID, toPeer peer: MCPeerID) {
        didConnect(myPeerID: myPeerID, peer: peer)
    }

    public func disconnected(myPeerID: MCPeerID, fromPeer peer: MCPeerID) {
        didDisconnect(myPeerID: myPeerID, peer: peer)
    }

    public func receivedData(_ data: Data, fromPeer peer: MCPeerID) {
        didReceiveData(data, fromPeer: peer)
    }

    public func finishReceivingResource(_ name: String,session: MCSession, fromPeer peerID: MCPeerID, localURL: URL) {
        didFinishReceivingResource(name, fromPeer: peerID, localURL: localURL)
    }
    
    public func startReceivingResource(_ name: String, session: MCSession, fromPeer peerID: MCPeerID, progress: Progress) {
        didStartReceivingResource(name, fromPeer: peerID, progress: progress)
    }
}
