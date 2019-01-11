//
//  ViewController.swift
//  Kline
//
//  Created by liuyaxun on 07/19/2018.
//  Copyright (c) 2018 liuyaxun. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var dataSource: [KLineModel] = []
    let kView = KLineView.init(KLineConfig.shareConfig, false, 1)
    let indexView = IndexLineView.init(IndexLineConfig.init())
    override func viewDidLoad() {
        super.viewDidLoad()
        kView.frame = CGRect(x: 0, y: 100, width: self.view.frame.width, height: 230)
        kView.dataSource = self
        view.addSubview(kView)
        
        
        indexView.frame = CGRect.init(x: 0, y: 340, width: self.view.frame.width, height: 90)
        view.addSubview(indexView)

        
        requestData()
    }
    
    
    fileprivate func requestData() {
        let path = Bundle.main.path(forResource: "line.json", ofType: nil) ?? ""
        guard let nsData = NSData.init(contentsOfFile: path) else { return }
        let jsonData = Data.init(referencing: nsData)
        do {
            guard let dict = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String:Any] else { return }
            guard let arrs = dict["data"] as? [[Any]] else { return }
            
            arrs.forEach { arr in
                let time = arr.first as? Double ?? 0
                let openPrice = CGFloat((arr[1] as? NSString ?? "0").floatValue)
                let maxPrice = CGFloat((arr[2] as? NSString ?? "0").doubleValue)
                let minPrice = CGFloat((arr[3] as? NSString ?? "0").doubleValue)
                let closePrice = CGFloat((arr[4] as? NSString ?? "0").doubleValue)
                let dealNum =  CGFloat((arr[5] as? NSString ?? "0").doubleValue)
                let exchangeRate = CGFloat((arr[6] as? NSString ?? "0").doubleValue)
                let model = KLineModel.init(time: time, openingPrice: openPrice, closingPrice: closePrice, highestPrice: maxPrice, lowestPrice: minPrice, volume: dealNum, quoteChange: exchangeRate, riseAndFall: exchangeRate)
                dataSource.append(model)
            }
            kView.reloadData()
        }catch(let err) {
            print(err)
        }
    }

}

extension ViewController: KLineDataSource {
    
    func numberOfCandles(_ view: KLineView) -> Int {
        return dataSource.count
    }
    
    func willShowCandles(_ view: KLineView, _ begin: Int, _ end: Int) -> [BaseKLineModel] {
        return Array(dataSource[begin..<end+1])
    }
    
    func startRenderIndex(_ view: KLineView) -> Int {
        return dataSource.count - 1 - 17
    }
    
    func currentCandlesType(_ view: KLineView) -> KlineAdjustType {
        return KlineAdjustType.unadjust
    }
    
}

