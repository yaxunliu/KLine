//
//  StockKDJComponent.swift
//  Kline_Example
//
//  Created by yaxun on 2019/1/15.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class StockKDJComponent: StockComponent {
    
    fileprivate let max: CGFloat = 140
    fileprivate let min: CGFloat = -20
    
    fileprivate var kdjDescLayers: [CATextLayer] = []
    
    override func setupUI() {
        super.setupUI()
        updateMarks()
        setKDJLayers()
    }
    

    override func reloadData(_ nums: Int, _ candleWidth: CGFloat, _ datas: [BaseKLineModel], _ isMin: Bool, _ scale: CGFloat) {
        self.drawBoardView.layer.sublayers?.forEach{ $0.removeFromSuperlayer() }
        // 1.取出所有的指标线数据
        var lines: [String: [CGFloat]] = [:]
        indexNames.forEach { str in
            let values = datas.map{ $0.indexDict[str] ?? 0 }
            lines[str] = values
        }
        
        // 2.更新最后一条数据的值
        guard let lastModel = datas.last else { return }
        self.updateValue(lastModel)
        
        // 3.绘制折线
        self.drawLine(lines, candleWidth)
        
        // 4.绘制竖线
        var preTime = (datas.first?.time ?? 0) / 1000
        var seperatorsPoints: [(CGPoint, CGPoint)] = []
        datas.enumerated().forEach { index, model in
            /// 1.计算时间
            let currentTime = model.time / 1000
            let isSmmeYear = Date.isSameYear(preTime, currentTime)
            let isSameMonth = Date.isSameMonth(preTime, currentTime)
            let midX = (CGFloat(index) + 0.5) * candleWidth
            if !isSmmeYear || !isSameMonth {
                let orgP = CGPoint.init(x: midX, y: 0)
                let endP = CGPoint.init(x: midX, y: self.drawBoardView.bounds.height)
                seperatorsPoints.append((orgP, endP))
            }
            preTime = model.time / 1000
        }
        let verticalLinePath = UIBezierPath.drawLines(seperatorsPoints)
        let verticalLineLayer = CAShapeLayer.drawLayer(self.drawBoardView.bounds, verticalLinePath, KLineConfig.shareConfig.seperatorColor, false, 1, KLineConfig.shareConfig.seperatorColor)
        self.drawBoardView.layer.insertSublayer(verticalLineLayer, at: 0)
    }
    
    fileprivate func updateMarks() {
        let average = self.drawBoardView.bounds.height / (max - min)
        let values: [CGFloat] = [80, 50, 20]
        var points: [(CGPoint, CGPoint)] = []
        zip(values, markString).forEach { (value, layer) in
            let y = (max - value) * average + self.drawBoardView.frame.minY
            let begin = CGPoint.init(x: self.drawBoardView.frame.minX, y: y)
            let end = CGPoint.init(x: self.drawBoardView.frame.maxX, y: y)
            points.append((begin, end))
            layer.frame = CGRect.init(x: 0, y: y - layer.bounds.height, width: layer.bounds.width, height: layer.bounds.height)
            layer.string = String.init(format: "%d", Int(value))
        }
        let path = UIBezierPath.drawLines(points, nil)
        let layer = CAShapeLayer.drawLayer(self.contentView.bounds, path, KLineConfig.shareConfig.tagFontColor, false, 1, .clear, true)
        self.contentView.layer.insertSublayer(layer, at: 0)
    }
    
    override func touchLocationY(_ p: CGPoint) -> CGFloat? {
        let y = p.y - self.frame.minY
        if y <= self.drawBoardView.frame.maxY {
            let average = (max - min) / self.drawBoardView.bounds.height
            let value = (self.drawBoardView.frame.maxY - y) * average + min
            return value
        }
        return nil
    }
    
}

extension StockKDJComponent {

    fileprivate func drawLine(_ lines: [String: [CGFloat]], _ candleWidth: CGFloat) {
        // 3.计算出平均值
        let average = self.drawBoardView.bounds.height / (max - min)
        lines.forEach { line in
            var path: UIBezierPath? = nil
            line.value.enumerated().forEach({ (arg) in
                let (index, value) = arg
                path = self.drawLine(path, index, candleWidth, value, average, max)
            })
            let subLayer = CAShapeLayer.drawLayer(self.drawBoardView.bounds, path!, lineColor(line.key), true, 1)
            self.drawBoardView.layer.addSublayer(subLayer)
        }
    }
    
    
    fileprivate func lineColor(_ name: String) -> UIColor {
        var lineColors: [String : UIColor] = [
            "k": UIColor.init(red: 190 / 255.0, green: 120 / 255.0, blue: 46 / 255.0, alpha: 1),
            "d": UIColor.init(red: 47 / 255.0, green: 165 / 255.0, blue: 206 / 255.0, alpha: 1),
            "j": UIColor.init(red: 208 / 255.0, green: 126 / 255.0, blue: 187 / 255.0, alpha: 1),
            ]
        return lineColors[name] ?? .red
    }
    
    fileprivate func drawLine(_ path: UIBezierPath?, _ index: Int, _ width: CGFloat, _ value: CGFloat, _ average: CGFloat, _ max: CGFloat) -> UIBezierPath {
        let bPath = path ?? UIBezierPath.init()
        let y = (max - value) * average
        let x = (CGFloat(index) + 0.5) * width
        let p = CGPoint.init(x: x, y: y)
        if index == 0 {
            bPath.move(to: p)
        } else {
            bPath.addLine(to: p)
        }
        return bPath
    }
    
    fileprivate func setKDJLayers() {
        var x = self.drawBoardView.frame.minX + 5
        let y = self.drawBoardView.frame.minY / 2 - KLineConfig.shareConfig.tagFontSize * 0.5
        let h = KLineConfig.shareConfig.tagFontSize
        let tagLayer = CATextLayer.initWithFrame(CGRect.init(x: x, y: y, width: 50, height: h) , KLineConfig.shareConfig.tagFontSize, .white, "KDJ(9,3,3)")
        self.contentView.layer.addSublayer(tagLayer)
        x += 44
        let w: CGFloat = 44
        let kLayer = CATextLayer.initWithFrame(CGRect.init(x: x, y: y, width: w, height: h) , KLineConfig.shareConfig.tagFontSize, self.lineColor("k"), "K:89.123")
        self.contentView.layer.addSublayer(kLayer)
        x += w
        let dLayer = CATextLayer.initWithFrame(CGRect.init(x: x, y: y, width: w, height: h) , KLineConfig.shareConfig.tagFontSize, self.lineColor("d"), "D:89.123")
        self.contentView.layer.addSublayer(dLayer)
        x += w
        let jLayer = CATextLayer.initWithFrame(CGRect.init(x: x, y: y, width: w, height: h) , KLineConfig.shareConfig.tagFontSize, self.lineColor("j"), "J:89.123")
        self.contentView.layer.addSublayer(jLayer)
        self.kdjDescLayers.append(contentsOf: [kLayer, dLayer, jLayer])
    }
    
    fileprivate func updateValue(_ m: BaseKLineModel) {
        let k = String.init(format: "K: %.03f", m.indexDict["k"] ?? 0)
        let d = String.init(format: "D: %.03f", m.indexDict["d"] ?? 0)
        let j = String.init(format: "J: %.03f", m.indexDict["j"] ?? 0)
        let kdj = [k, d, j]
        zip(kdj, self.kdjDescLayers).forEach { (str, layer) in
            layer.string = str
        }
    }
    
    
}
