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
    
    @IBOutlet weak var titleTextField: UITextField!

    @IBOutlet weak var recordingsTableView: UITableView!
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    var fileName = ""
    var timeRecordingStarted: Double = 0
    
    let productIDs: Set<NSObject> = ["unlimited_sounds_1"]
    var unlimitedSoundsProduct: SKProduct?
    
    @IBOutlet weak var flashSwitch: UISwitch!
    @IBAction func flashToggled(sender: AnyObject) {
        if sender is UISwitch {
            let s = sender as! UISwitch
            sound.flashWhenRecognized = s.on
        }
    }
    @IBOutlet weak var vibrateSwitch: UISwitch!
    @IBAction func vibrateToggled(sender: AnyObject) {
        if sender is UISwitch {
            let s = sender as! UISwitch
            sound.vibrateWhenRecognized = s.on
        }
    }
    
    func purchaseUnlimitedSounds(action: UIAlertAction!) {
        if SKPaymentQueue.canMakePayments() {
            if let product = unlimitedSoundsProduct {
                SKPaymentQueue.defaultQueue().addPayment(SKPayment(product: product))
            }
        } else {
            println("Can't make payments")
            let alert = UIAlertController(title: nil,
                message: "Unable to make payments",
                preferredStyle: UIAlertControllerStyle.Alert)
            let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default,
                handler: nil)
            alert.addAction(okAction)
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func setUI(#enabled: Bool) {
        recordButton.enabled = enabled
        titleTextField.enabled = enabled
    }
    
    override func viewDidLoad() {
        recordingsTableView.dataSource = self
        recordingsTableView.autoresizesSubviews = true
        titleTextField.text = sound.name
        
        if sound.name != "" {
            flashSwitch.on = sound.flashWhenRecognized
            vibrateSwitch.on = sound.vibrateWhenRecognized
        }
        
        if sound.name == "" && !canAddSound() {
            setUI(enabled: false)
            SKPaymentQueue.defaultQueue().addTransactionObserver(self)
            var productsRequest = SKProductsRequest(productIdentifiers: productIDs)
            productsRequest.delegate = self
            productsRequest.start()
        }
    }
    
    func restorePurchases(action: UIAlertAction!) {
        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
    }

    func showPopupForIAP() {
        if unlimitedSoundsProduct == nil { return }
        let price: String = unlimitedSoundsProduct!.localizedPrice()
        let alert = UIAlertController(title: nil,
            message: "With the Unlimited Sounds upgrade (\(price)), you can create any number of distinct sounds in order to be notified whenever one is recognized. Please only make this purchase after ensuring that Digital Ear works well in your environment by testing with the free sound slot. Thanks for your business!",
            preferredStyle: UIAlertControllerStyle.Alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        let restoreAction = UIAlertAction(title: "I already own this", style: UIAlertActionStyle.Default, handler: restorePurchases)
        let purchaseAction = UIAlertAction(title: "Purchase", style: UIAlertActionStyle.Default,
            handler: purchaseUnlimitedSounds)
        alert.addAction(cancelAction)
        alert.addAction(purchaseAction)
        alert.addAction(restoreAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }

    func deleteRecording(action: UIAlertAction!) -> Void {
        sound.deleteRecordingWithFileName(fileName)
        waveformViewCache.removeValueForKey(fileName)
        recordingsTableView.reloadData()
    }
    
    func deleteRecButtonTapped(sender: AnyObject) {
        fileName = String(sender.tag)
        let alert = UIAlertController(title: nil,
            message: "Are you sure you want to delete this recording?",
            preferredStyle: UIAlertControllerStyle.Alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Yes, delete", style: UIAlertActionStyle.Default,
            handler: deleteRecording)
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sound.recordings.count
    }
    
    var waveformViewCache: [String : WaveformView] = Dictionary()
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Value2, reuseIdentifier: nil)
        let fileName = sound.recordings[indexPath.row].valueForKey("fileName") as? String
        if fileName == nil {
            return cell
        }
        
        let deleteButton = UIButton()
        deleteButton.setTitle("delete", forState: UIControlState.Normal)
        deleteButton.titleLabel?.font = UIFont(name: "Avenir Next", size: 11)
        deleteButton.addTarget(self, action: Selector("deleteRecButtonTapped:"),
            forControlEvents: UIControlEvents.TouchUpInside)
        deleteButton.frame = CGRectMake(recordingsTableView.frame.width - 46, 5, 50, cell.frame.height - 10)
        deleteButton.backgroundColor = UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0)
        deleteButton.setTitleColor(UIColor(red: 48.0/255.0, green: 48.0/255.0, blue: 48.0/255.0, alpha: 1.0),
            forState: UIControlState.Normal)
        cell.contentView.addSubview(deleteButton)
        
        var view: WaveformView? = nil
        let index = waveformViewCache.indexForKey(fileName!)
        if index == nil {
            let waveformViewRect = CGRectMake(5, 5, deleteButton.frame.minX, cell.frame.height - 10)
            view = WaveformView(frame: waveformViewRect, samples:
                extractSamplesFromWAV(DOCUMENT_DIR+fileName!+".wav"))
            waveformViewCache[fileName!] = view
        } else {
            view = waveformViewCache[index!].1
        }
        cell.contentView.addSubview(view!)
        
        if let fn = fileName {
            deleteButton.tag = fn.toInt()!
        }
        
        return cell
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator
        coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        waveformViewCache = Dictionary()
        recordingsTableView.reloadData()
    }
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!, successfully flag: Bool) {
        sound.addRecordingWithFileName(fileName)
        sound.save()
        recordingsTableView.reloadData()
        recordButton.setTitle("Record an instance of this sound",
            forState: UIControlState.Normal)
        titleTextField.enabled = true
        backButton.enabled = true
    }
    
    func changeSoundNameTo(newSoundName: String) {
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
    
    @IBAction func onRecordButtonTapped(sender: AnyObject) {
        changeSoundNameTo(titleTextField.text)
        if sound.name == "" {
            let alert = UIAlertController(title: nil,
                message: "Sound name required",
                preferredStyle: UIAlertControllerStyle.Alert)
            let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default,
                handler: nil)
            alert.addAction(okAction)
            presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        if recording() && timestampDouble() - timeRecordingStarted >= 0.4 {
            stopRecordingAudio()
        } else if !recording() {
            titleTextField.enabled = false
            backButton.enabled = false
            fileName = String(now())
            timeRecordingStarted = timestampDouble()
            startRecordingAudio(toPath: DOCUMENT_DIR + "\(fileName).wav", delegate: self, seconds: 4)
            recordButton.setTitle("Stop recording", forState: UIControlState.Normal)
        }
    }
    
    @IBAction func doneEditing(sender: AnyObject) {
        changeSoundNameTo(titleTextField.text)
    }
    
    func productsRequest(request: SKProductsRequest!, didReceiveResponse response: SKProductsResponse!) {
        let products: [SKProduct] = response.products as! [SKProduct]
        if products.count > 0 {
            if let product = products.first {
                println(product.localizedTitle)
                if product.productIdentifier == productIDs.first {
                    unlimitedSoundsProduct = product
                    showPopupForIAP()
                }
            }
        }
    }
    
    func unlockFeatures() {
        NSUserDefaults().setBool(true, forKey: "unlimited")
        setUI(enabled: true)
    }
    
    func paymentQueue(queue: SKPaymentQueue!, updatedTransactions transactions: [AnyObject]!) {
        for transaction in transactions as! [SKPaymentTransaction] {
            switch transaction.transactionState {
            case SKPaymentTransactionState.Purchased:
                println("Purchased")
                unlockFeatures()
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                break
            case SKPaymentTransactionState.Restored:
                println("Restored")
                unlockFeatures()
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                break
            case SKPaymentTransactionState.Purchasing:
                println("Purchasing...")
                break
            case SKPaymentTransactionState.Failed:
                println("Failed to purchase")
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                break
            default:
                println(transaction.transactionState)
            }
            
        }
    }
    
    func featuresUnlocked() -> Bool {
        return titleTextField.enabled && recordButton.enabled
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue!) {
        if featuresUnlocked() { return } // => successfully restored
        func backToPopup(action: UIAlertAction!) {
            showPopupForIAP()
        }
        let alert = UIAlertController(title: nil,
            message: "It looks like you have not yet purchased Unlimited Sounds",
            preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default,
            handler: backToPopup)
        alert.addAction(okAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    deinit {
        SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
    }
    
}