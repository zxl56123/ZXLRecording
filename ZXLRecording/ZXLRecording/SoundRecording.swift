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
class SoundRecording: UIViewController,AVAudioRecorderDelegate,AVAudioPlayerDelegate,UITableViewDelegate,UITableViewDataSource{
    
    let SCREENWITH = UIScreen.main.bounds.size.width
    let SCREENHEIGHT = UIScreen.main.bounds.size.height
    
    //audioRecorder和audioPlayer，一个用于录音，一个用于播放
    var audioRecorder:AVAudioRecorder!
    var audioPlayer:AVAudioPlayer!
    
    var recordBtn : UIButton!
    var finishBtn : UIButton!
    var switchBtn : UIButton!
    var playBtn : UIButton!
    var statueLab : UILabel!
    var tableview : UITableView!
    
    //获取音频会话单例
    let audioSession = AVAudioSession.sharedInstance()
    var isAllowed:Bool = false
    var isFinishRecord:Bool = false
    
    let btnWith = CGFloat(60)
    let btnSpace = CGFloat(40)
    
    //定义音频的编码参数 - 实例化一个音频录制者AVAudioRecorder，指定录音保存的路径并且设置录音相关属性，注意因为录音机必须知道录音文件的格式、采样率、通道数、每个采样点的位数等信息，但是也并不是所有的信息都必须设置，通常只需要几个常用设置。AVAudioRecorder为我们提供了settings属性字典用于设置相关信息。关于录音设置详见帮助文档中的 AV Foundation Audio Settings Constants。
    let recordSettings = [
        AVSampleRateKey : NSNumber(value: Float(44100.0)),//声音采样率
        AVFormatIDKey   : NSNumber(value: Int32(kAudioFormatMPEG4AAC)),//编码格式
        AVNumberOfChannelsKey : NSNumber(value: 1),//采集音轨
        AVEncoderAudioQualityKey : NSNumber(value: Int32(AVAudioQuality.max.rawValue))]//音频质量
    
    //MARK:- viewDidLoad
    override func viewDidLoad() {
        
        self.title = "录制音频"
        self.view.backgroundColor = UIColor.white
        
        //首先要判断是否允许访问麦克风&初始化
        self.recordPermissionAndInit()
        
        //初始化显示状态lab
        self.initStatueLab()
 
        //初始化录音按钮、暂停按钮、播放按钮
        self.initRecordBtn()

        //初始化切换按钮 麦克风/扬声器
        self.initSwitchBtn()
        
        //初始化tableview
        self.initTableView()
    }
    
    //MARK:-判断是否允许访问麦克风
    func recordPermissionAndInit() -> Void {
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
                //AVAudioSessionCategoryPlayback 、AVAudioSessionCategoryPlayAndRecord
                try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord) //默认使用扬声器
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
    }
    
    //MARK:-初始化状态栏lab
    func initStatueLab() -> Void {
        statueLab = UILabel(frame: CGRect(x: 20, y: 64 + 20, width: SCREENWITH, height: 40))
        statueLab.text = "等待中..."
        statueLab.font = UIFont.systemFont(ofSize: 15)
        self.view.addSubview(statueLab)
    }
    
    //MARK:-初始化暂停按钮、播放按钮
    func initRecordBtn() -> Void {
        
        let imageV = UIImageView(frame: CGRect(x: (SCREENWITH-64)/2, y: statueLab.frame.maxY + 8, width: 64, height: 64))
        imageV.image = UIImage(named: "micImage")
        self.view.addSubview(imageV)
        
        playBtn = UIButton(frame: CGRect(x: (SCREENWITH-40)/2,y:imageV.frame.maxY + 8,width: btnWith,height: 40))
        playBtn.setTitle("播放", for:.normal)
        playBtn.titleLabel?.textAlignment = .center
        playBtn.setTitleColor(UIColor.black, for: .normal)
        playBtn.setTitleColor(UIColor.red, for: .selected)
        playBtn.layer.borderWidth = 0.5
        playBtn.layer.cornerRadius = 4.0
        playBtn.addTarget(self, action:#selector(startPlaying(sender:)), for:.touchUpInside)
        self.view.addSubview(playBtn)
        
        //录音按钮
        recordBtn = UIButton(frame: CGRect(x: playBtn.frame.minX - btnSpace - btnWith,y: playBtn.frame.minY,width: btnWith,height: 40))
        recordBtn.setTitle("开始", for:.normal)
        recordBtn.setTitle("暂停", for: .selected)
        recordBtn.titleLabel?.textAlignment = .center
        recordBtn.setTitleColor(UIColor.black, for: .normal)
        recordBtn.setTitleColor(UIColor.red, for: .selected)
        recordBtn.layer.borderWidth = 0.5
        recordBtn.layer.cornerRadius = 4.0
        recordBtn.addTarget(self, action:#selector(startRecord(sender:)), for:.touchUpInside)
        self.view.addSubview(recordBtn)
        
        finishBtn = UIButton(frame: CGRect(x: playBtn.frame.maxX + btnSpace,y:playBtn.frame.minY,width: btnWith,height: 40))
        finishBtn.setTitle("完成", for:.normal)
        finishBtn.titleLabel?.textAlignment = .center
        finishBtn.setTitleColor(UIColor.black, for: .normal)
        finishBtn.setTitleColor(UIColor.red, for: .selected)
        finishBtn.layer.borderWidth = 0.5
        finishBtn.layer.cornerRadius = 4.0
        finishBtn.addTarget(self, action:#selector(stopRecord(sender:)), for:.touchUpInside)
        self.view.addSubview(finishBtn)
    }
    
    //MARK:-初始化切换按钮 麦克风/扬声器
    func initSwitchBtn() ->  Void{
        switchBtn = UIButton(frame: CGRect(x: SCREENWITH - 40, y: 64 + 20, width: 40, height: 40))
        switchBtn.setImage(UIImage(named:"speaker"), for: .normal)
        switchBtn.setImage(UIImage(named:"mic"), for: .selected)
        
        switchBtn.addTarget(self, action: #selector(tapSwitchBtn(sender:)), for: .touchUpInside)
        self.view.addSubview(switchBtn)
    }
    
    func initTableView() -> Void {
        tableview = UITableView(frame: CGRect(x: 0, y: playBtn.frame.maxY + 8, width: SCREENWITH, height: SCREENHEIGHT - playBtn.frame.maxY - 8))
        tableview.delegate = self
        tableview.dataSource = self
        self.view.addSubview(tableview)
        
    }
    
    func tapSwitchBtn(sender:UIButton) -> Void {
        sender.isSelected = !sender.isSelected
        
        do {
            if sender.isSelected { //选中
                //切换为扬声器
                try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            }else{ //未选中
                //切换为听筒📞
                try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            }
        } catch let error as NSError {
            print(error)
        }
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
        
        print(soundURL?.absoluteString)
        return soundURL as NSURL?
    }
    
    func getFilelist(type:String, path:String) -> Void {
        let fileManager = FileManager()
        var tmpList:[String]?
        do {
            try tmpList = fileManager.contentsOfDirectory(atPath: path)
            var filename:String!
            for  filename in tmpList! {
    
                print(filename)
                
            }
        } catch let error as NSError {
            print(error)
        }
        

    }
    
    
    //开始录音
    func startRecord(sender: AnyObject) {

        statueLab.text = "录音中..."
        //如果正在播放，先停止播放
        if let audioPlayer = audioPlayer, audioPlayer.isPlaying {
            audioPlayer.stop()
        }
        
        if isFinishRecord {
            if self.isAllowed{
                do {
                    //AVAudioSessionCategoryPlayback 、AVAudioSessionCategoryPlayAndRecord
                    try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord) //默认使用扬声器
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
        statueLab.text = "录音完成"
        isFinishRecord = true
        
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
        statueLab.text = "播放中..."
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
        
        //获取录音文件列表
        let fileManager = FileManager()
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as NSURL
        let urlStr : String = documentDirectory.absoluteString!
        self.getFilelist(type: ".m4a", path: urlStr)

    }
    
    //暂停播放
    func pausePlaying(sender: AnyObject) {
        statueLab.text = "暂停播放"
        if let audioPlayer = audioPlayer, audioPlayer.isPlaying{
            if (!audioRecorder.isRecording){
                audioPlayer.pause()
            }
        }
    }
    
    //暂停录制
    func pauseRecoder(sender: AnyObject) {
        statueLab.text = "暂停录音"
        if audioRecorder.isRecording{
            audioRecorder.pause()
        }
    }
    
    //恢复录制，恢复录音只需要再次调用record，AVAudioSession会帮助你记录上次录音位置并追加录音
    func resumeRecoder(sender: AnyObject) {
        statueLab.text = "开始录音..."
        if (!audioRecorder.isRecording){
            self.startRecord(sender: sender)
        }
    }
    
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag{
            if #available(iOS 8.0, *) {
                let alert = UIAlertController(title: "录音",
                                              message: "录音完成",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK!", style: .default, handler: {action in
                    print("OK was tapped")
                    self.statueLab.text = "录音完成"
                }))
                self.present(alert, animated:true, completion:nil)
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag{
            print("播放完成!")
            statueLab.text = "播放完成"
        }
    }
    
    //MARK:-uitableview
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableview.deselectRow(at: indexPath, animated: true)
    
        NSLog("%ld", indexPath.row)
    
    }
}


//FIXME:暂时用不到
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
