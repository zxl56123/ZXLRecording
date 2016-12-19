//
//  SoundRecording.swift
//  ZXLRecording
//
//  Created by 郑晓龙 on 2016/12/19.
//  Copyright © 2016年 郑晓龙. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

/// 音频录制
class SoundRecording: UIViewController,AVAudioRecorderDelegate,AVAudioPlayerDelegate{
    
    let SCREENWITH = UIScreen.main.bounds.size.width
    let SCREENHEIGHT = UIScreen.main.bounds.size.height
    
    //audioRecorder和audioPlayer，一个用于录音，一个用于播放
    var audioRecorder:AVAudioRecorder!
    var audioPlayer:AVAudioPlayer!
    
    var recordBtn : UIButton!
    var finishBtn : UIButton!
    var playBtn : UIButton!
    
    //获取音频会话单例
    let audioSession = AVAudioSession.sharedInstance()
    var isAllowed:Bool = false
    
    
    //定义音频的编码参数
    let recordSettings = [
        AVSampleRateKey : NSNumber(value: Float(44100.0)),//声音采样率
        AVFormatIDKey   : NSNumber(value: Int32(kAudioFormatMPEG4AAC)),//编码格式
        AVNumberOfChannelsKey : NSNumber(value: 1),//采集音轨
        AVEncoderAudioQualityKey : NSNumber(value: Int32(AVAudioQuality.medium.rawValue))]//音频质量
    
    //MARK:- viewDidLoad
    override func viewDidLoad() {
        
        self.title = "录制音频"
        self.view.backgroundColor = UIColor.white
        
        //首先要判断是否允许访问麦克风
        audioSession.requestRecordPermission { (allowed) in
            if !allowed{
                let alertView = UIAlertView(title: "无法访问您的麦克风" , message: "请到设置 -> 隐私 -> 麦克风 ，打开访问权限", delegate: nil, cancelButtonTitle: "取消", otherButtonTitles: "好的")
                alertView.show()
                self.isAllowed = false
            }else{
                self.isAllowed = true
            }
        }
        
        if self.isAllowed{
            do {
                try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
                //初始化实例
                try audioRecorder = AVAudioRecorder(url: self.directoryURL()! as URL,
                                                    settings: recordSettings)
                //try audioRecorder = AVAudioRecorder(URL: self.directoryURL()! as URL,settings: "SoundRecording")
                audioRecorder.delegate = self
                //准备录音
                audioRecorder.prepareToRecord()
            } catch let error as NSError{
                print(error)
            }
        }
        
        //录音按钮
        recordBtn = UIButton(frame: CGRect(x: 0,y: SCREENHEIGHT - 64 - 100,width: SCREENWITH,height: 40))
        recordBtn.setTitle("开始录音", for:.normal)
        recordBtn.setTitle("暂停录音", for: .selected)
        recordBtn.titleLabel?.textAlignment = .center
        recordBtn.setTitleColor(UIColor.black, for: .normal)
        recordBtn.setTitleColor(UIColor.red, for: .selected)
        recordBtn.addTarget(self, action:#selector(startRecord(sender:)), for:.touchUpInside)
        self.view.addSubview(recordBtn)
        
        finishBtn = UIButton(frame: CGRect(x: 0,y:recordBtn.frame.maxY + 10,width: SCREENWITH,height: 40))
        finishBtn.setTitle("完成", for:.normal)
        finishBtn.titleLabel?.textAlignment = .center
        finishBtn.setTitleColor(UIColor.black, for: .normal)
        finishBtn.setTitleColor(UIColor.red, for: .selected)
        finishBtn.addTarget(self, action:#selector(stopRecord(sender:)), for:.touchUpInside)
        self.view.addSubview(finishBtn)
        
        
        playBtn = UIButton(frame: CGRect(x: 0,y:finishBtn.frame.maxY + 10,width: SCREENWITH,height: 40))
        playBtn.setTitle("播放", for:.normal)
        playBtn.titleLabel?.textAlignment = .center
        playBtn.setTitleColor(UIColor.black, for: .normal)
        playBtn.setTitleColor(UIColor.red, for: .selected)
        playBtn.addTarget(self, action:#selector(startPlaying(sender:)), for:.touchUpInside)
        self.view.addSubview(playBtn)

    }
    
    func tapbtn() -> Void {
        print("tap")
    }
    
    func directoryURL() -> NSURL? {
        //定义并构建一个url来保存音频，音频文件名为ddMMyyyyHHmmss.caf，根据时间来设置存储文件名
        let currentDateTime = NSDate()
        let formatter = DateFormatter()
        formatter.dateFormat = "ddMMyyyyHHmmss"
        //以下2种格式都可以
        //let recordingName = formatter.stringFromDate(currentDateTime)+".caf"
        let recordingName = formatter.string(from: currentDateTime as Date)+".m4a"
        
        let fileManager = FileManager()
        
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as NSURL
        let soundURL = documentDirectory.appendingPathComponent(recordingName)
        
        print(soundURL)
        
        return soundURL as NSURL?
    }
    
    
    //开始录音
    func startRecord(sender: AnyObject) {
        
        //如果正在播放，先停止播放
        if let audioPlayer = audioPlayer, audioPlayer.isPlaying {
            audioPlayer.stop()
        }
        //是否正在录音，如果没有，开始录音
        if !audioRecorder.isRecording {
            do {
                try audioSession.setActive(true)
                audioRecorder.record()
            }catch let error as NSError{
                print(error)
            }
        }
    }
    
    //停止录音
    func stopRecord(sender: AnyObject) {
        if audioRecorder.isRecording{
            audioRecorder.stop()
            do {
                try audioSession.setActive(false)
            } catch let error as NSError{
                print(error)
            }
        }
    }
    
    //开始播放
    func startPlaying(sender: AnyObject) {
        if (!audioRecorder.isRecording){
            do {
                //创建音频播放器AVAudioPlayer，用于在录音完成之后播放录音
                let url:NSURL? = audioRecorder.url as NSURL?
                if let url = url{
                    try audioPlayer = AVAudioPlayer(contentsOf: url as URL)
                    audioPlayer.delegate = self
                    audioPlayer.play()
                }
            } catch let error as NSError{
                print(error)
            }
        }
    }
    
    //暂停播放
    func pausePlaying(sender: AnyObject) {
        if let audioPlayer = audioPlayer, audioPlayer.isPlaying{
            if (!audioRecorder.isRecording){
                audioPlayer.pause()
            }
        }
    }
    
    //暂停录制
    func pauseRecoder(sender: AnyObject) {
        if audioRecorder.isRecording{
            audioRecorder.pause()
        }
    }
    
    //恢复录制，恢复录音只需要再次调用record，AVAudioSession会帮助你记录上次录音位置并追加录音
    func resumeRecoder(sender: AnyObject) {
        if (!audioRecorder.isRecording){
            self.startRecord(sender: sender)
        }
    }
    
}

extension ViewController:AVAudioRecorderDelegate{
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag{
            if #available(iOS 8.0, *) {
                let alert = UIAlertController(title: "Recorder",
                                              message: "Finished Recording",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK!", style: .default, handler: {action in
                    print("OK was tapped")
                }))
                self.present(alert, animated:true, completion:nil)
            } else {
                // Fallback on earlier versions
            }
        }
    }
}

    extension ViewController:AVAudioPlayerDelegate{
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag{ print("播放完成!") }
    }
}
