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
    var minuteDataSource: [KLineMinuteModel] = []
    lazy var providerView: StockProviderView = {
        let view = StockProviderView.init(CGRect.init(x: 0, y: 0, width: 375, height: 230), false, 0.5, [StockKDJComponent.init(CGRect.init(x: 0, y: 0, width: 375, height: 90) , ["k", "d", "j"]), StockVolComponent.init(CGRect.init(x: 0, y: 0, width: 375, height: 90)), StockMacdComponent.init(CGRect.init(x: 0, y: 0, width: 375, height: 90) , ["MACD", "DEA", "DIF"])])
        view.frame = CGRect(x: 0, y: 100, width: self.view.frame.width, height: 500)
        view.dataSource = self
        return view
    }()
    var willRenderData: [KLineModel] = []
    
    fileprivate var type: StcokLineType = .kline
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(providerView)
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
                let model = KLineModel.init(time: time, openingPrice: openPrice, closingPrice: closePrice, highestPrice: maxPrice, lowestPrice: minPrice, volume: dealNum, quoteChange: exchangeRate, riseAndFall: exchangeRate, indexDict: [:], indexColor: [:])
                dataSource.append(model)
            }
            self.caculateKDJIndicator()
            self.caculateMACD()
            self.loadMinuteData()
            self.providerView.reloadData()
        }catch(let err) {
            print(err)
        }
    }
    
    
    
    fileprivate func loadMinuteData() {
        let path = Bundle.main.path(forResource: "minute.json", ofType: nil) ?? ""
        guard let nsData = NSData.init(contentsOfFile: path) else { return }
        let jsonData = Data.init(referencing: nsData)
        do {
            guard let dict = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String:Any] else { return }
            guard let arrs = dict["data"] as? [[Any]] else { return }
            arrs.forEach { arr in
                let time = TimeInterval((arr[0] as? Double ?? 0))
                let price = CGFloat((arr[1] as? Double ?? 0))
                let volume = CGFloat((arr[2] as? Double ?? 0))
                let model = KLineMinuteModel.init(time: time, minutePrice: price, volume: volume, openPrice: 82.1)
                minuteDataSource.append(model)
            }
        }catch(let err) {
            print(err)
        }
    }
    
    
    /*KDJ(9,3.3),下面以该参数为例说明计算方法。
     9，3，3代表指标分析周期为9天，K值D值为3天
     RSV(9)=（今日收盘价－9日内最低价）÷（9日内最高价－9日内最低价）×100
     K(3日)=（当日RSV值+2*前一日K值）÷3
     D(3日)=（当日K值+2*前一日D值）÷3
     J=3K－2D
     */
    fileprivate func caculateKDJIndicator() {
        var lastK: CGFloat = 50
        var lastD: CGFloat = 50
        for (index, item) in self.dataSource.enumerated() {
            var min: CGFloat = 0
            var max: CGFloat = 0
            if index <= 8 {
                min = Array(self.dataSource[0..<index + 1]).map{ $0.lowestPrice }.min() ?? 0
                max = Array(self.dataSource[0..<index + 1]).map{ $0.highestPrice }.max() ?? 0
            } else {
                min = Array(self.dataSource[index-8..<index + 1]).map{ $0.lowestPrice }.min() ?? 0
                max = Array(self.dataSource[index-8..<index + 1]).map{ $0.highestPrice }.max() ?? 0
            }
            let rsv9 = (item.closingPrice - min) / (max - min) * 100
            let k = (rsv9 + 2 * lastK) / 3
            let d = (k + 2 * lastD) / 3
            lastK = k.roundTo(places: 2)
            lastD = d.roundTo(places: 2)
            let j = (3 * lastK - 2 * lastD).roundTo(places: 2)
            self.dataSource[index].indexDict["k"] = lastK
            self.dataSource[index].indexDict["d"] = lastD
            self.dataSource[index].indexDict["j"] = j
            self.dataSource[index].indexColor["k"] = UIColor.init(red: 190 / 255.0, green: 120 / 255.0, blue: 46 / 255.0, alpha: 1)
            self.dataSource[index].indexColor["d"] = UIColor.init(red: 47 / 255.0, green: 165 / 255.0, blue: 206 / 255.0, alpha: 1)
            self.dataSource[index].indexColor["j"] = UIColor.init(red: 208 / 255.0, green: 126 / 255.0, blue: 187 / 255.0, alpha: 1)
        }
    }
    
    fileprivate func caculateMACD() {
        var lastEMA12: CGFloat = 0
        var lastEMA26: CGFloat = 0
        var lastDEA: CGFloat = 0
        for (index, item) in self.dataSource.enumerated() {
            let ema12 = lastEMA12 * 11 / 13 + item.closingPrice * 2 / 13
            let ema26 = lastEMA26 * 25 / 27 + item.closingPrice * 2 / 27
            let dif = ema12 - ema26
            let dea = lastDEA * 8 / 10 + dif * 2 / 10
            let macd = (dif - dea) * 2
            self.dataSource[index].indexDict["DEA"]  = dea.roundTo(places: 2)
            self.dataSource[index].indexDict["MACD"] = macd.roundTo(places: 2)
            self.dataSource[index].indexDict["DIF"] = dif.roundTo(places: 2)
            lastDEA = dea
            lastEMA12 = ema12
            lastEMA26 = ema26
        }
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if self.type == .kline {
            self.type = .minute
        } else {
            self.type = .kline
        }
        
        self.providerView.reloadData()
    }

}

extension ViewController: StockProviderViewDataSource {
    func providerDataType(_ view: StockProviderView) -> StcokLineType {
        return type
    }
    func loadMinuteData(_ view: StockProviderView) -> [KLineMinuteModel] {
        return minuteDataSource
    }
    func willShowCandles(_ view: StockProviderView, _ begin: Int, _ end: Int) -> [BaseKLineModel] {
        return Array(self.dataSource[begin...end])
    }
    func numberOfCandles(_ view: StockProviderView) -> Int {
        return self.dataSource.count
    }
}
