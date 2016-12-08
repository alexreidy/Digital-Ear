//
//  SoundViewController.swift
//  Digital Ear
//
//  Created by Alex Reidy on 3/22/15.
//  Copyright (c) 2015 Alex Reidy. All rights reserved.
//

import Foundation
import AVFoundation
import StoreKit
import UIKit

class SoundViewController: UIViewController, AVAudioRecorderDelegate, UITableViewDataSource, SKProductsRequestDelegate, SKPaymentTransactionObserver {
//    @available(iOS 3.0, *)
    

    
    @IBOutlet weak var titleTextField: UITextField!

    @IBOutlet weak var recordingsTableView: UITableView!
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    var fileName = ""
    var timeRecordingStarted: Double = 0
    
    let productIDs: Set<NSObject> = ["unlimited_sounds_1" as NSObject]
    var unlimitedSoundsProduct: SKProduct?
    
    @IBOutlet weak var flashSwitch: UISwitch!
    @IBAction func flashToggled(_ sender: AnyObject) {
        if sender is UISwitch {
            let s = sender as! UISwitch
            sound.flashWhenRecognized = s.isOn
        }
    }
    @IBOutlet weak var vibrateSwitch: UISwitch!
    @IBAction func vibrateToggled(_ sender: AnyObject) {
        if sender is UISwitch {
            let s = sender as! UISwitch
            sound.vibrateWhenRecognized = s.isOn
        }
    }
    
    func purchaseUnlimitedSounds(_ action: UIAlertAction!) {
        if SKPaymentQueue.canMakePayments() {
            if let product = unlimitedSoundsProduct {
                SKPaymentQueue.default().add(SKPayment(product: product))
            }
        } else {
            print("Can't make payments")
            let alert = UIAlertController(title: nil,
                message: "Unable to make payments",
                preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default,
                handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        }
    }
    
    func setUI(enabled: Bool) {
        recordButton.isEnabled = enabled
        titleTextField.isEnabled = enabled
    }
    
    override func viewDidLoad() {
        recordingsTableView.dataSource = self
        recordingsTableView.autoresizesSubviews = true
        titleTextField.text = sound.name
        
        if sound.name != "" {
            flashSwitch.isOn = sound.flashWhenRecognized
            vibrateSwitch.isOn = sound.vibrateWhenRecognized
        }
        
        if sound.name == "" && !canAddSound() {
            setUI(enabled: false)
            SKPaymentQueue.default().add(self)
            var productsRequest = SKProductsRequest(productIdentifiers: productIDs as! Set<String>)
            productsRequest.delegate = self
            productsRequest.start()
        }
    }
    
    func restorePurchases(_ action: UIAlertAction!) {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    func showPopupForIAP() {
        if unlimitedSoundsProduct == nil { return }
        let price: String = unlimitedSoundsProduct!.localizedPrice()
        let alert = UIAlertController(title: nil,
            message: "With the Unlimited Sounds upgrade (\(price)), you can create any number of distinct sounds in order to be notified whenever one is recognized. Please only make this purchase after ensuring that Digital Ear works well in your environment by testing with the free sound slot. Thanks for your business!",
            preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        let restoreAction = UIAlertAction(title: "I already own this", style: UIAlertActionStyle.default, handler: restorePurchases)
        let purchaseAction = UIAlertAction(title: "Purchase", style: UIAlertActionStyle.default,
            handler: purchaseUnlimitedSounds)
        alert.addAction(cancelAction)
        alert.addAction(purchaseAction)
        alert.addAction(restoreAction)
        
        present(alert, animated: true, completion: nil)
    }

    func deleteRecording(_ action: UIAlertAction!) -> Void {
        sound.deleteRecordingWithFileName(fileName)
        waveformViewCache.removeValue(forKey: fileName)
        recordingsTableView.reloadData()
        if sound.recordings.count == 0 {
            // To remove associated settings
            sound.delete()
        }
    }
    
    func deleteRecButtonTapped(_ sender: AnyObject) {
        fileName = String(sender.tag)
        let alert = UIAlertController(title: nil,
            message: "Are you sure you want to delete this recording?",
            preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Yes, delete", style: UIAlertActionStyle.default,
            handler: deleteRecording)
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        present(alert, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sound.recordings.count
    }
    
    var waveformViewCache: [String : WaveformView] = Dictionary()
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.value2, reuseIdentifier: nil)
        let fileName = sound.recordings[indexPath.row].value(forKey: "fileName") as? String
        if fileName == nil {
            return cell
        }
        
        let deleteButton = UIButton()
        deleteButton.setTitle("delete", for: UIControlState())
        deleteButton.titleLabel?.font = UIFont(name: "Avenir Next", size: 11)
        deleteButton.addTarget(self, action: #selector(SoundViewController.deleteRecButtonTapped(_:)),
            for: UIControlEvents.touchUpInside)
        deleteButton.frame = CGRect(x: recordingsTableView.frame.width - 46, y: 5, width: 50, height: cell.frame.height - 10)
        deleteButton.backgroundColor = UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0)
        deleteButton.setTitleColor(UIColor(red: 48.0/255.0, green: 48.0/255.0, blue: 48.0/255.0, alpha: 1.0),
            for: UIControlState())
        cell.contentView.addSubview(deleteButton)
        
        var view: WaveformView? = nil
        let index = waveformViewCache.index(forKey: fileName!)
        if index == nil {
            let waveformViewRect = CGRect(x: 5, y: 5, width: deleteButton.frame.minX, height: cell.frame.height - 10)
            view = WaveformView(frame: waveformViewRect, samples:
                extractSamplesFromWAV(DOCUMENT_DIR+fileName!+".wav"))
            waveformViewCache[fileName!] = view
        } else {
            view = waveformViewCache[index!].1
        }
        cell.contentView.addSubview(view!)
        
        if let fn = fileName {
            deleteButton.tag = Int(fn)!
        }
        
        return cell
    }
    
    override func viewWillTransition(to size: CGSize, with
        coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        waveformViewCache = Dictionary()
        recordingsTableView.reloadData()
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder!, successfully flag: Bool) {
        sound.addRecordingWithFileName(fileName)
        sound.save()
        recordingsTableView.reloadData()
        recordButton.setTitle("Record an instance of this sound",
            for: UIControlState())
        titleTextField.isEnabled = true
        backButton.isEnabled = true
    }
    
    func changeSoundNameTo(_ newSoundName: String) {
        titleTextField.resignFirstResponder()
        if newSoundName == "" {
            titleTextField.text = sound.name
        } else if newSoundName != sound.name {
            sound.name = newSoundName
            // Reload in case sounds were merged
            sound = Sound(name: sound.name)
            recordingsTableView.reloadData()
        }
    }
    
    @IBAction func onRecordButtonTapped(_ sender: AnyObject) {
        changeSoundNameTo(titleTextField.text!)
        if sound.name == "" {
            let alert = UIAlertController(title: nil,
                message: "Sound name required",
                preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default,
                handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
            return
        }
        
        if recording() && timestampDouble() - timeRecordingStarted >= 0.4 {
            stopRecordingAudio()
        } else if !recording() {
            titleTextField.isEnabled = false
            backButton.isEnabled = false
            fileName = String(now())
            timeRecordingStarted = timestampDouble()
            startRecordingAudio(toPath: DOCUMENT_DIR + "\(fileName).wav", delegate: self, seconds: 4)
            recordButton.setTitle("Stop recording", for: UIControlState())
        }
    }
    
    @IBAction func doneEditing(_ sender: AnyObject) {
        changeSoundNameTo(titleTextField.text!)
    }
    
    func productsRequest(_ request: SKProductsRequest!, didReceive response: SKProductsResponse!) {
        let products: [SKProduct] = response.products 
        if products.count > 0 {
            if let product = products.first {
                print(product.localizedTitle)
                if let productID = productIDs.first as? String {
                    if product.productIdentifier == productID {
                        unlimitedSoundsProduct = product
                        showPopupForIAP()
                    }
                }
            }
        }
    }
    
    func unlockFeatures() {
        UserDefaults().set(true, forKey: "unlimited")
        setUI(enabled: true)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case SKPaymentTransactionState.purchased:
                print("Purchased")
                unlockFeatures()
                SKPaymentQueue.default().finishTransaction(transaction)
                break
            case SKPaymentTransactionState.restored:
                print("Restored")
                unlockFeatures()
                SKPaymentQueue.default().finishTransaction(transaction)
                break
            case SKPaymentTransactionState.purchasing:
                print("Purchasing...")
                break
            case SKPaymentTransactionState.failed:
                print("Failed to purchase")
                SKPaymentQueue.default().finishTransaction(transaction)
                break
            default:
                print(transaction.transactionState)
            }
            
        }
    }
    
    func featuresUnlocked() -> Bool {
        return titleTextField.isEnabled && recordButton.isEnabled
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue!) {
        if featuresUnlocked() { return } // => successfully restored
        func backToPopup(_ action: UIAlertAction!) {
            showPopupForIAP()
        }
        let alert = UIAlertController(title: nil,
            message: "It looks like you have not yet purchased Unlimited Sounds",
            preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default,
            handler: backToPopup)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    deinit {
        // To prevent leaving defaultQueue with a dangling reference:
        SKPaymentQueue.default().remove(self)
    }
    
}
