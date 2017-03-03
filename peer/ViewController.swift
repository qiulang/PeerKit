//
//  ViewController.swift
//  peer
//
//  Created by qiulang on 23/02/2017.
//  Copyright © 2017 qiulang. All rights reserved.
//

import UIKit
import PeerKit
import MultipeerConnectivity
import SwiftyBeaver
import MobileCoreServices

class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {

    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    
    let imagePicker = UIImagePickerController()
    let log = SwiftyBeaver.self
    let console = ConsoleDestination()  // log to Xcode Console
    let cloud = SBPlatformDestination(appID: "dGP88v", appSecret: "XHmd1bylvxhhin0nehtloobr4cg3cSaZ", encryptionKey: "jBnpkgmuXB4adoV1m8ccmmwpvtxwakz2")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        log.addDestination(console)
        log.addDestination(cloud)
        //console.format = "$Dyyyy-MM-dd HH:mm:ss.SSS$d $T $L: $M"
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
        imagePicker.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        PeerKit.onConnect = { (_ myPeerID: MCPeerID, _ peerID: MCPeerID) -> Void in
            self.nameLabel.text = peerID.displayName
            self.sendButton.isEnabled = true
            //print("\(PeerKit.session?.connectedPeers)")
            self.log.debug("\(PeerKit.session?.connectedPeers)")
        }
        PeerKit.onDisconnect = { (_ myPeerID: MCPeerID, _ peerID: MCPeerID) -> Void in
            if PeerKit.session?.connectedPeers.count == 0 {
                self.sendButton.isEnabled = false
                self.nameLabel.text = "Waiting"
            } else {
                let tmp = PeerKit.session?.connectedPeers[0]
                self.nameLabel.text = tmp?.displayName
            }
            self.log.debug("\(PeerKit.session?.connectedPeers)")
        }
        PeerKit.onFinishReceivingResource = { ( _ resourceName: String, _ peer: MCPeerID, _ localURL: URL) -> Void in
            print(resourceName)
            //try {
            try!   self.imageView.image = UIImage(data: Data(contentsOf: localURL))
            DispatchQueue.main.asyncAfter(deadline: .now()+1 , execute: {
                self.progressView.isHidden = true
            })
            //}
        }
        PeerKit.onReceivingResource = { (_ resourceName: String, _ peer: MCPeerID, _ progress:Progress) -> Void in
            self.progressView.isHidden = false
            self.progressView.progress = 0
            progress.addObserver(self, forKeyPath: "completedUnitCount", options: .new, context: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func chooseImage(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }
//MARK: - UIImagePickerControllerDelegate
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        defer {
            dismiss(animated: true, completion:nil)
        }
        
        func send(_ url:URL) {
            //let sendto:MCPeerID = PeerKit.session!.connectedPeers.first!
            let progresses = PeerKit.sendResourceAtURL(url, withName: "send", info:info, completionHandler:{
                error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    print("Succeed")
                }
                DispatchQueue.main.asyncAfter(deadline: .now()+1 , execute: {
                    self.progressView.isHidden = true
                })
            })
            if let progress = progresses?.first ?? nil {
                progress.addObserver(self, forKeyPath: "completedUnitCount", options: .new, context: nil)
                progressView.isHidden = false
                progressView.progress = 0
            }
        }
        
        let type = info[UIImagePickerControllerMediaType] as! String
        if type == kUTTypeMovie as String {
            let url = info[UIImagePickerControllerMediaURL] as! URL
            if url.isFileURL {
                send(url)
            }
            return
        }
        if type == kUTTypeImage as String {
            guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
                return
            }
            imageView.image = image;
            let imageUrl = info[UIImagePickerControllerReferenceURL] as! URL
            send(imageUrl)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "completedUnitCount" {
            let progress = object as! Progress
            DispatchQueue.main.async {
                self.progressView.progress = Float(progress.fractionCompleted)
            }
        }
    }
}

