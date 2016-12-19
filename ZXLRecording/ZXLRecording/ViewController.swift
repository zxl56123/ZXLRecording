//
//  ViewController.swift
//  ZXLRecording
//
//  Created by 郑晓龙 on 2016/12/19.
//  Copyright © 2016年 郑晓龙. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    var tableview:UITableView!
    var dataAr:NSArray!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.title = "列表"
        self.view.backgroundColor = UIColor.white
        
        tableview = UITableView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height-64))
        self.view.addSubview(tableview)
        self.tableview.delegate = self
        self.tableview.dataSource = self
        
        //数据源
        dataAr = ["录制音频","录制视频"]
    }

    //MARK:—tableview
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataAr.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = dataAr[indexPath.row] as! String
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableview.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0:
            self.navigationController?.pushViewController(SoundRecording(), animated: true)
        case 1:
            self.navigationController?.pushViewController(VideoRecording(), animated: true)
        default:
            break
        }
    }
    
    //MARK:-内存警告
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

