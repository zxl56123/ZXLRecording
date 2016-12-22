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
    var dataAr : [String]!
    
    var manager: AFHTTPSessionManager! //上传
    
    //获取音频会话单例
    let audioSession = AVAudioSession.sharedInstance()
    var isAllowed:Bool = false
    var isFinishRecord:Bool = false
    var savePathStr : String!
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
        
         dataAr = Array<String>()
        
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
        
        //遍历目录，获取录音文件
        let fileManager = FileManager()
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as NSURL
        let docStr : String = documentDirectory.path!
        savePathStr = docStr
        
        self.getFilelist(type: "m4a", path: self.savePathStr)
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
                //切换为听筒
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
        
        //1、文件目录是否存，不存在就创建目录
        let fileManager = FileManager()
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as NSURL
        //I figured this one out. createDirectoryAtPath() is unable to process a path with the "file://" prefix. To get a path without the prefix you must use path() or relativePath().
        //使用path获取路径
        //如果使用absoluteString 获取路径会包含"file://"前缀,如果用这个带file://前缀目录就会是错的！！不能获取目录中的内容
        //let docStr : String = documentDirectory.absoluteString! //不用用于获取路径
        let docStr : String = documentDirectory.path!
        
        savePathStr = docStr
       
//        if !fileManager.fileExists(atPath: savePathStr) {
//            do {
//                try fileManager.createDirectory(at: NSURL.fileURL(withPath: savePathStr), withIntermediateDirectories: true, attributes: nil)
//            } catch let error as NSError {
//                print(error)
//            }
//        }
        
        //2、用时间目录命名录音文件
        //定义并构建一个url来保存音频，音频文件名为ddMMyyyyHHmmss.caf，根据时间来设置存储文件名
        let currentDateTime = NSDate()
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:YY:SS"
        //以下2种格式都可以
        //let recordingName = formatter.stringFromDate(currentDateTime)+".caf"
        let recordingName = formatter.string(from: currentDateTime as Date)+".m4a"
        let soundURL = documentDirectory.appendingPathComponent(recordingName)
        
        
        return soundURL as NSURL?
    }
    
    func getFilelist(type:String, path:String) -> Void {
        let fileManager = FileManager()
        var tmpList:[String]?
        do {
            //1.先删除
            dataAr.removeAll()
            
            try tmpList = fileManager.contentsOfDirectory(atPath: path)
            //var filename:String?
            for filename in tmpList! {
                
                print(filename)
                //2.重新赋值 insert到第一个，append追加
                dataAr?.insert(filename, at: 0)
            }
            
            //刷新tableview
            tableview.reloadData()
            
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
        
        if !isFinishRecord {
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
                    
                    //是否正在录音，如果没有，开始录音
                    if !audioRecorder.isRecording {
                        do {
                            try audioSession.setActive(true)
                            audioRecorder.record()
                        }catch let error as NSError{
                            print(error)
                        }
                    }
                    
                } catch let error as NSError{
                    print(error)
                }
            }
        }
    }
    
    //停止录音
    func stopRecord(sender: AnyObject) {
        statueLab.text = "录音完成"
        isFinishRecord = true
        
        //遍历目录，获取录音文件
        self.getFilelist(type: "m4a", path: self.savePathStr)
        
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

                    statueLab.text = "播放中..."
                }
            } catch let error as NSError{
                print(error)
            }
        }
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
                /*
                self.statueLab.text = "录音完成"
                
                let alert = UIAlertController(title: "录音",
                                              message: "录音完成",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK!", style: .default, handler: {action in
                    print("OK was tapped")
                    
                }))
                self.present(alert, animated:true, completion:nil)
                */
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
        if dataAr != nil {
            return dataAr.count
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        cell.textLabel?.text = dataAr[indexPath.row]
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableview.deselectRow(at: indexPath, animated: true)
        
        let urlStr = savePathStr + "/" + dataAr[indexPath.row]
        print(urlStr)

        if audioRecorder != nil {
            //是否正在录音
            if (!audioRecorder.isRecording){
                do {
                    //创建音频播放器AVAudioPlayer，用于在录音完成之后播放录音
                    let url:NSURL? = NSURL.fileURL(withPath: urlStr) as NSURL?
                    if let url = url{
                        try audioPlayer = AVAudioPlayer(contentsOf: url as URL)
                        audioPlayer.delegate = self
                        audioPlayer.play()
                        
                        statueLab.text = "播放中..."
                    }
                } catch let error as NSError{
                    print(error)
                }
            }
        }else{
            //直接播放
            do {
                //创建音频播放器AVAudioPlayer，用于在录音完成之后播放录音
                let url:NSURL? = NSURL.fileURL(withPath: urlStr) as NSURL?
                if let url = url{
                    try audioPlayer = AVAudioPlayer(contentsOf: url as URL)
                    audioPlayer.delegate = self
                    audioPlayer.play()
                    
                    statueLab.text = "播放中..."
                }
            } catch let error as NSError{
                print(error)
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let upload = UITableViewRowAction(style: .normal, title: "上传") {
            action, index in
            let urlStr = self.savePathStr + "/" + self.dataAr[indexPath.row]
            print("上传 \(urlStr)")
            
            self.uploadData(path: urlStr, filename: self.dataAr[indexPath.row])
        }
        upload.backgroundColor = UIColor.green
        return [upload]
    }
    
    
    func uploadData(path:String, filename:String) -> Void {
        
        let baseURL = URL(string:
            "http://172.31.60.54:8989/yxb/public/uploadImg_v1_3_3")
        // 创建AFHTTPSessionManager实例
        manager = AFHTTPSessionManager(baseURL:baseURL)
        // 为服务端的HTML响应设置解析器
        manager.responseSerializer = AFHTTPResponseSerializer()
        
        let parameters: NSDictionary = ["enterpriseId": "43",
                                        "inteVersion": "1.0.1",
                                        "module": "annc"
                                        ]
        let url:NSURL? = NSURL.fileURL(withPath: path) as NSURL?

        // 使用AFHTTPSessionManager发送POST请求
        manager.post("", parameters:parameters,
                     // 使用代码块来封装要上传的文件数据
        
            constructingBodyWith:{formData in
                //获取音频文件
                //let soundData = UIImageJPEGRepresentation(image, 1)
                // 将照片数据添加到上传请求中
                let soundData = try! Data(contentsOf: URL(fileURLWithPath: path))

                formData.appendPart(withFileData: soundData, name:filename,
                                    fileName:filename,
                                    // 指定上传文件的MIME类型
                    mimeType:"application/octet-stream") //"audio/mp3"
                
//                let url:NSURL? = NSURL.fileURL(withPath: path) as NSURL?
//
//        
//                do {
//                    try formData.appendPart(withFileURL: url as! URL, name: filename, fileName: filename, mimeType: "audio/mp3")
//                }catch let error as NSError {
//                    print(error)
//                }

        },
            progress:nil,
            // 获取服务器响应成功时激发的代码块
            success:{task, responseObject in
                // 当使用HTTP响应解析器时，服务器响应数据被封装在NSData中
                // 此处将NSData转换成NSString，并使用UIAlertController显示上传结果
                let msg = NSString(data:responseObject as! Data,encoding: String.Encoding.utf8.rawValue)
                let alert = UIAlertController(title:"上传结果",
                                              message:msg! as String, preferredStyle:.alert)
                alert.addAction(UIAlertAction(title:"确定",
                                              style:.cancel, handler:{action in
                                                self.dismiss(animated: true, completion:nil)
                }))
                self.present(alert, animated:true, completion:nil)
        },
            // 获取服务器响应失败时激发的代码块
            failure:{task, error in
                print("获取服务器响应出错！\(error)")
        })
        
    }
    
}


//FIXME:暂时用不到
extension ViewController:AVAudioRecorderDelegate{
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag{
            if #available(iOS 8.0, *) {
//                let alert = UIAlertController(title: "Recorder",
//                                              message: "Finished Recording",
//                                              preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "OK!", style: .default, handler: {action in
//                    print("OK was tapped")
//                }))
//                self.present(alert, animated:true, completion:nil)
            } else {
                 //Fallback on earlier versions
            }
        }
    }
}

    extension ViewController:AVAudioPlayerDelegate{
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag{ print("播放完成!") }
    }
}
