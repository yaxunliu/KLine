//
//  ViewController.swift
//  Kline
//
//  Created by liuyaxun on 07/19/2018.
//  Copyright (c) 2018 liuyaxun. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var kView = KlineView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        kView.frame = CGRect(x: 0, y: 100, width: self.view.frame.width, height: 400)
        view.addSubview(kView)
        
        guard let url = Bundle.main.url(forResource: "minute.json", withExtension: nil) else { return }
        do {
            let data = try Data.init(contentsOf: url)
            guard let minuteDict = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableLeaves) as? Dictionary<String, Any> else { return }
            let arr = minuteDict["data"]
            let array = arr as! Array<Array<Any>>
            let results = array.map { (arrs) -> KlineTimeModel in
                return KlineTimeModel(time: arrs[0] as! CLongLong, minutePrice: arrs[1] as! Double, dealNum: arrs[2] as! Double)
            }
            kView.timeModels = results
        } catch let error {
            print("error", error)
        }

    }

}

