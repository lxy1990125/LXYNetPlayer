//
//  LXYNetPlayerSwift.swift
//  LXYNetPlayer
//
//  Created by 李 欣耘 on 16/4/15.
//  Copyright © 2016年 lixinyun. All rights reserved.

//  git remote add origin https://github.com/lxy1990125/LXYNetPlayer.git


import UIKit
import AVFoundation
import MediaPlayer

let InterruptPlayNotification = "InterruptPlayNotification"

//MARK: delegate function----------------------------------------

protocol LXYNetPlayerDelegate: NSObjectProtocol{
    func playDone()
    func playStart(item: PlayItem)
    func playFail()
    func bufferLoading()
    func loadEnd()
    func playChange(item: PlayItem)// want play again
}

//MARK: player
class LXYNetPlayerSwift: NSObject {
    private var avPlayer : AVPlayer?
    private var isStop : Bool?
    private var isPause : Bool?
    private var taskId : NSString?
    private var todayHeadIsPlay : Bool?
    private var totalPlayIndex : Int?//count of play

    var currIndex : Int?//now isplaying number
    var allStop : Bool?

    var delegate: LXYNetPlayerDelegate?
    var avCurrPlayerItem : AVPlayerItem?
    var playMenu : NSMutableArray?
    var currenItem : PlayItem?
    var oldTaskID : Int?
    var isnull : Bool?//
    var headItem : PlayItem!
    
//MARK: public function----------------------------------------
    
    class func shareInstance() ->LXYNetPlayerSwift! {
        struct Private {
            static var avAudioclass : LXYNetPlayerSwift!
        }
        if  Private.avAudioclass == nil {
            let session : AVAudioSession? = AVAudioSession.sharedInstance()
            try! session!.setActive(true)
            try! session!.setCategory(AVAudioSessionCategoryPlayback)
            Private.avAudioclass = LXYNetPlayerSwift()
        }
        
        return Private.avAudioclass
    }
    
//MARK: play with list from frist one ---
    
    func playWith(paths: NSArray?, taskid: NSString?) {

        allStop = false
        oldTaskID = 0
        
        
        if paths != nil && paths!.count > 0 {
            isStop = false
            taskId = taskid
            
            let InterruptNotification = NSNotification.init(name: InterruptPlayNotification, object: taskId)
            NSNotificationCenter.defaultCenter().postNotification(InterruptNotification)
            currIndex = 0
            totalPlayIndex = paths!.count
            
            playMenu = NSMutableArray.init(array: paths!)
            
            
            todayHeadIsPlay = true
                
            currIndex = 0
            totalPlayIndex = paths!.count
            self.NetURLPlay((playMenu?.objectAtIndex(currIndex!))! as? PlayItem)
            
            
            
        }else {
            currIndex = 0
            totalPlayIndex = 1
        }
    }
    
//MARK: play with list from you choose one ---
    
    func playWithArrayAndCurrent(paths: NSArray?, taskid: NSString?, current: Int){
        
        let InterruptNotification = NSNotification.init(name: InterruptPlayNotification, object: taskId)
        NSNotificationCenter.defaultCenter().postNotification(InterruptNotification)
        oldTaskID = 0
        isStop = false
        taskId = taskid
        totalPlayIndex = paths!.count
        playMenu = NSMutableArray.init(array: paths!)
        currIndex = current
        allStop = false
        self.NetURLPlay((playMenu?.objectAtIndex(currIndex!))! as? PlayItem)
    }
    
//MARK: play again when the current is playing -------
    
    func playAgain(){
        let InterruptNotification = NSNotification.init(name: InterruptPlayNotification, object: taskId)
        NSNotificationCenter.defaultCenter().postNotification(InterruptNotification)
        allStop = false
        self.NetURLPlay((playMenu?.objectAtIndex(currIndex!))! as? PlayItem)
    }

//MARK: stop -------
    
    func stop(){
        
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nil
        currIndex = 0
        isStop = true
        allStop = true
        avPlayer?.pause()
        if ((delegate?.respondsToSelector(Selector("playDone"))) != nil) {
            delegate?.playDone()
        }
        delegate = nil
    }

//MARK: pause -------
    
    func pause(){
        if avPlayer != nil && isStop == false {
            if avPlayer?.rate > 0.0 {
                avPlayer?.pause()
                isPause = true
            }else {
                avPlayer?.play()
                isPause = false
            }
        }
    }

//MARK: next -------

    func nextPlay() {

        allStop = false

        currIndex = currIndex! + 1
        if currIndex! < totalPlayIndex! {

            self.NetURLPlay((playMenu?.objectAtIndex(currIndex!))! as? PlayItem)

        }else {
            self.stop()
        }
    }

//MARK: prev -------
    func prevPlay() {
        
        
        allStop = false
        currIndex = currIndex! - 1
        
        if currIndex < 0 {
            self.stop()
        }else {
            
            if ((playMenu?.objectAtIndex(currIndex!))! as? PlayItem)?.path == "" {//pre is null
                self.prevPlay()
                return
            }
            

            self.NetURLPlay((playMenu?.objectAtIndex(currIndex!))! as? PlayItem)
            
        }
    }
    
//MARK: singal Player ---
    func play(item: PlayItem?,taskid: NSString?){
        
        allStop = false
        
        if item != nil {
            currenItem = item
            currIndex = 0
            totalPlayIndex = 1
            taskId = taskid
            isStop = false
            let InterruptNotification = NSNotification.init(name: InterruptPlayNotification, object: taskId)
            NSNotificationCenter.defaultCenter().postNotification(InterruptNotification)
            self.NetURLPlay(currenItem!)
        }
        
    }

//MARK: seek -----
    func setPlaySeek(sliderValue: Float) {
        if avPlayer != nil && avPlayer?.rate > 0 {
            if Double(sliderValue) < self.duration() {
                avPlayer?.pause()
                avPlayer?.seekToTime(CMTimeMakeWithSeconds(self.duration() * Double(sliderValue), Int32(NSEC_PER_SEC)))
                self.playAction()
            }
        }
        if isPause == true {
            avPlayer?.seekToTime(CMTimeMakeWithSeconds(self.duration() * Double(sliderValue), Int32(NSEC_PER_SEC)))
            self.playAction()
            if todayHeadIsPlay == false {
                self.delegate?.playStart(headItem)
            }else {
                self.delegate?.playStart(((self.playMenu?.objectAtIndex(self.currIndex!))! as? PlayItem)!)
            }
        }
    }
    
    func progress() -> Double {
        if avPlayer != nil {
            return Double(CMTimeGetSeconds((avPlayer?.currentTime())!))
        }else {
            return 0
        }
    }
    
    func duration() -> Double {
        let playerItem : AVPlayerItem = (avPlayer?.currentItem)!
        if playerItem.status.rawValue ==  AVPlayerStatus.ReadyToPlay.rawValue {
            return CMTimeGetSeconds(playerItem.duration)
        }
        return 0.0
    }
    
    
//MARK: private function----------------------------------------
    
    private func pauseChange(item: PlayItem?) {
        delegate?.playChange(item!)
    }
    
    
    private func NetURLPlay(item: PlayItem?){//网络播放 或者本地也可 //netPlayer
        
        
        if item != nil {
            let asset : AVURLAsset?
            
            if item?.path == "" {
                isPause = false
                self.nextPlay()
                return
            }
                
            if item!.path?.lowercaseString.hasPrefix("http://") == true {
                asset = AVURLAsset.init(URL: (NSURL.init(string: (item!.path as! String)))!, options:nil)
            }else {
                asset = AVURLAsset.init(URL: (NSURL.init(fileURLWithPath: (item!.path as! String))), options: nil)
            }

            isPause = true
            if asset != nil {
                isPause = false
                
                if avCurrPlayerItem != nil {
                    NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: avCurrPlayerItem)
                    avCurrPlayerItem?.removeObserver(self, forKeyPath: "status", context: nil)
                    avCurrPlayerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges", context: nil)
                }
                
                avCurrPlayerItem = AVPlayerItem.init(asset: asset!)
                avCurrPlayerItem!.addObserver(self, forKeyPath: "status", options: .New, context: nil)
                avCurrPlayerItem!.addObserver(self, forKeyPath: "loadedTimeRanges", options: .New, context:nil)
                
                
                NSNotificationCenter.defaultCenter().addObserver(self, selector: (#selector(LXYNetPlayerSwift.audioPlayDidEnd(_:))), name: AVPlayerItemDidPlayToEndTimeNotification, object: avCurrPlayerItem)
                
                NSNotificationCenter.defaultCenter().addObserver(self, selector: (#selector(LXYNetPlayerSwift.audioPlayDidEnd(_:))), name: AVPlayerItemFailedToPlayToEndTimeNotification, object: avCurrPlayerItem)
                
                if avPlayer == nil {
                    avPlayer = AVPlayer.init(playerItem: avCurrPlayerItem!)
                    avPlayer?.allowsExternalPlayback = true
                }
                
                if avPlayer?.currentItem != avCurrPlayerItem! {
                    avPlayer?.replaceCurrentItemWithPlayerItem(avCurrPlayerItem)
                }
                
                
            }
            
        }else {
            if currIndex < totalPlayIndex {
                self.nextPlay()
                return
            }
            if (delegate?.respondsToSelector(Selector("playFail"))) != nil {
                delegate?.playFail()
            }
        }
        
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        let playerItem : AVPlayerItem = (object as! AVPlayerItem)
        if keyPath == "status" {
            let status = (change?[NSKeyValueChangeNewKey] as! NSNumber).integerValue as AVPlayerStatus.RawValue
            if status == AVPlayerStatus.ReadyToPlay.rawValue {
                
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.playAction()
                    if self.todayHeadIsPlay == false {
                        self.delegate?.playStart(self.headItem)
                        self.todayHeadIsPlay = true
                    }else {
                        self.delegate?.playStart(((self.playMenu?.objectAtIndex(self.currIndex!))! as? PlayItem)!)
                    }
                })
                
            }else if playerItem.status.rawValue == AVPlayerStatus.Unknown.rawValue {
                playerItem.cancelPendingSeeks()
                playerItem.asset.cancelLoading()
                avPlayer?.replaceCurrentItemWithPlayerItem(avCurrPlayerItem)//去掉这个
                avPlayer = nil//置为nil
                if currIndex < totalPlayIndex!  {
                    self.playAgain()
                    currIndex = currIndex! + 1
                }else {
                    if (delegate?.respondsToSelector(Selector("playFail"))) != nil {
                        delegate?.playFail()
                    }
                }
            }else if playerItem.status.rawValue == AVPlayerStatus.Failed.rawValue {
                playerItem.cancelPendingSeeks()
                playerItem.asset.cancelLoading()
                avPlayer?.replaceCurrentItemWithPlayerItem(avCurrPlayerItem)
                avPlayer = nil
               
                if currIndex < totalPlayIndex {
                    self.playAgain()
                    currIndex = currIndex! + 1
                }else {
                    if (delegate?.respondsToSelector(Selector("playFail"))) != nil {
                        delegate?.playFail()
                    }
                }
            }
        }else if keyPath == "loadedTimeRanges" {
            let bufferTime : Float = self.availableDuration
            let currentTime : CMTime = playerItem.currentTime()
            
            let currenDuration : CGFloat = CGFloat(Int64(currentTime.value)/Int64(currentTime.timescale))
            
            if bufferTime - Float(currenDuration) > 5 {
                if isStop == false && isPause == false {
                    avPlayer?.play()
                }
                if (delegate?.respondsToSelector(Selector("loadEnd"))) != nil {
                    delegate?.loadEnd()
                }
            }else {
                if (delegate?.respondsToSelector(Selector("bufferLoading"))) != nil {
                    delegate?.bufferLoading()
                }
            }
        }else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
        
    }
    
    private var availableDuration : Float {//总长度
        let loadedTimeRange : NSArray = (avPlayer?.currentItem?.loadedTimeRanges)!
        if loadedTimeRange.count > 0 {
            let timeRange : CMTimeRange =  loadedTimeRange.objectAtIndex(0).CMTimeRangeValue
            let startSeconds : Float = Float(CMTimeGetSeconds(timeRange.start))
            let durationSeconds : Float = Float(CMTimeGetSeconds(timeRange.duration))
            return (startSeconds + durationSeconds);
        }else {
            return 0.0
        }
    }
    
    internal func audioPlayDidEnd(notification: NSNotification) {//这首歌播完了
        self.nextPlay()
    }
    
    private func setVolume(volume: Float) {//音量
        
        let audioInputParams : AVMutableAudioMixInputParameters = AVMutableAudioMixInputParameters.init()
        audioInputParams.setVolume(volume, atTime: kCMTimeZero)
        audioInputParams.trackID = 1
        let allAudioParams : NSArray = [audioInputParams]
        let audioMix : AVMutableAudioMix = AVMutableAudioMix.init()
        audioMix.inputParameters = allAudioParams as! [AVAudioMixInputParameters]
        avCurrPlayerItem?.audioMix = audioMix
        
        avPlayer?.volume = volume
    }
    
    private var getVolum : Double {
        if avPlayer != nil {
            return Double((avPlayer?.volume)!)
        }else {
            return 0.0
        }
    }
    
    private func playAction() {//to play event
        if allStop == true {
            
        }else {
            
            
            var newTaskID : UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.init()
            newTaskID = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler(nil)
            if newTaskID != UIBackgroundTaskInvalid && oldTaskID != UIBackgroundTaskInvalid {
                UIApplication.sharedApplication().endBackgroundTask(oldTaskID!)
            }
            oldTaskID = newTaskID
            
            if todayHeadIsPlay == false {
                self.configPlayingInfo(headItem)
            }else {
                self.configPlayingInfo(playMenu!.objectAtIndex(currIndex!) as! PlayItem)
            }
            
            
            let session : AVAudioSession? = AVAudioSession.sharedInstance()
            try! session!.setActive(true)
            try! session!.setCategory(AVAudioSessionCategoryPlayback)
            avPlayer?.play()
            
            
            
            
        }
        
    }
    
//MARK: 封面,名字 作者等等-------
    
    private func configPlayingInfo(item : PlayItem) {
        
        
        if (NSClassFromString("MPNowPlayingInfoCenter") != nil) {
            
            let blbumart : MPMediaItemArtwork = MPMediaItemArtwork.init(image: UIImage.init(named: "cover")!)
            
            
            let audioInfo: [String: AnyObject]? = [
                MPMediaItemPropertyTitle: "11",
                MPMediaItemPropertyArtist: item.name!,
                MPMediaItemPropertyArtwork: blbumart,
                MPMediaItemPropertyPlaybackDuration: self.duration(),
                MPMediaItemPropertyAlbumTrackNumber: self.progress(),
                MPMediaItemPropertyAlbumTrackCount: self.progress(),
                MPMediaItemPropertyDiscCount: self.progress(),
                MPMediaItemPropertyDiscNumber: self.progress()
            ]
            
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = audioInfo
        }
        
    }
    


}

//MARK: PlayerItem now I gave your some basic, other design by yourself ----------------

class PlayItem: NSObject {
    var path : NSString? //playPath
    var name : NSString?
    var subject : NSString?
    var imageUrl : NSString?
    var square_icon : NSString?
    var playText : NSString?

}