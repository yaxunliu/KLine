//
//  StockMacdComponent.swift
//  Kline_Example
//
//  Created by yaxun on 2019/1/15.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

/*
 * DIF
 * DEA
 * MACD
 */
import UIKit

class StockMacdComponent: StockComponent {
    
    override func setupUI() {
        super.setupUI()
        setupMacdLayers()
    }

    fileprivate var macdLayers: [CATextLayer] = []
    
    
    override func reloadData(_ nums: Int, _ candleWidth: CGFloat, _ datas: [BaseKLineModel], _ isMin: Bool, _ scale: CGFloat) {
        /// 0.移除之前绘制的
        self.drawBoardView.layer.sublayers?.forEach{ $0.removeFromSuperlayer() }
        
        /// 1.拿到最小值和最大值
        let minCollec: [CGFloat] = [datas.map{ $0.indexDict["DIF"] ?? 0 }.min() ?? 0, datas.map{ $0.indexDict["DEA"] ?? 0 }.min() ?? 0, datas.map{ $0.indexDict["MACD"] ?? 0 }.min() ?? 0]
        let maxCollec: [CGFloat] = [datas.map{ $0.indexDict["DIF"] ?? 0 }.max() ?? 0, datas.map{ $0.indexDict["DEA"] ?? 0 }.max() ?? 0, datas.map{ $0.indexDict["MACD"] ?? 0 }.max() ?? 0]
        var min = minCollec.min() ?? 0
        var max = maxCollec.max() ?? 0
        let padding = (max - min) * 0.1
        var textValues: [CGFloat] = []
        if abs(Int32(min * 1000)) > abs(Int32(max * 1000)) { // 以最小值为标准
            if abs(Int32(min * 1000)) - abs(Int32(max * 1000)) > abs(Int32(min * 500)) { // 大于一半 底部占据大多数
                max += padding
                min -= padding
                textValues.append(0)
                textValues.append(min / 2)
                textValues.append(min)
            } else {
                min -= padding
                max = -min
                textValues.append(max)
                textValues.append(0)
                textValues.append(min)
            }
        } else { // 以最大值为标准
            if abs(Int32(max * 1000)) - abs(Int32(min * 1000)) > abs(Int32(max * 500)) { // 大于一半 顶部部占据大多数
                max += padding
                min -= padding
                textValues.append(max)
                textValues.append(max / 2)
                textValues.append(0)
                
            } else {
                max += padding
                min = -max
                textValues.append(max)
                textValues.append(0)
                textValues.append(min)
            }
        }
        
        
        let average = self.drawBoardView.bounds.height / (max - min)

        /// 3.更新提示文字的frame
        updateMarks(max, min, textValues, average)
        
        /// 4.开始绘制Macd
        drawMacdLine(datas.map{ $0.indexDict["MACD"] ?? 0 }, candleWidth, average, max)
        
        /// 5.开始绘制折线
        drawLines(datas.map{ $0.indexDict["DEA"] ?? 0 }, candleWidth, max, average, lineColor("DEA"))
        drawLines(datas.map{ $0.indexDict["DIF"] ?? 0 }, candleWidth, max, average, lineColor("DIF"))
        
        /// 6.刷新描述文字
        guard let last = datas.last else { return }
        updateValue(last)
    }
    
    fileprivate func updateMarks(_ max: CGFloat, _ min: CGFloat, _ values: [CGFloat], _ average: CGFloat) {
        zip(values, self.markString).forEach { (value, layer) in
            layer.string = String.init(format: "%.02f", value)
            let y = (max - value) * average + self.drawBoardView.frame.minY
            layer.frame = CGRect.init(x: self.drawBoardView.frame.minX, y: y, width: layer.bounds.width, height: layer.bounds.height)
        }
    }
    
    fileprivate func drawMacdLine(_ values: [CGFloat], _ candleW: CGFloat, _ average: CGFloat, _ max: CGFloat) {
        var upPath: UIBezierPath? = nil
        var downPath: UIBezierPath? = nil
        let beginY = (max) * average
        var upPoints: [(CGPoint, CGPoint)] = []
        var downPoints: [(CGPoint, CGPoint)] = []
        values.enumerated().forEach { index, value in
            let isUp = value > 0
            let beginX = (CGFloat(index) + 0.5) * candleW
            let endY = (max - value) * average
            let beginP = CGPoint.init(x: beginX, y: beginY)
            let endP = CGPoint.init(x: beginX, y: endY)
            if isUp {
                upPoints.append((beginP, endP))
            } else {
                downPoints.append((beginP, endP))
            }
        }
        upPath = UIBezierPath.drawLines(upPoints)
        downPath = UIBezierPath.drawLines(downPoints)
        if upPath != nil {
            let layer = CAShapeLayer.drawLayer(self.drawBoardView.bounds, upPath!, KLineConfig.shareConfig.upColor, false, 1)
            self.drawBoardView.layer.addSublayer(layer)
        }
        if downPath != nil {
            let layer = CAShapeLayer.drawLayer(self.drawBoardView.bounds, downPath!, KLineConfig.shareConfig.downColor, false, 1)
            self.drawBoardView.layer.addSublayer(layer)
        }

    }
    
    fileprivate func drawLines(_ values: [CGFloat], _ candleW: CGFloat, _ max: CGFloat, _ average: CGFloat, _ color: UIColor) {
        let path = UIBezierPath.init()
        values.enumerated().forEach { index, value in
            let x = (CGFloat(index) + 0.5) * candleW
            let y = (max - value) * average
            let p = CGPoint.init(x: x, y: y)
            if index == 0 {
                path.move(to: p)
            } else {
                path.addLine(to: p)
            }
        }
        let layer = CAShapeLayer.drawLayer(self.drawBoardView.bounds, path, color, false, 1)
        self.drawBoardView.layer.addSublayer(layer)
    }
    
    
    fileprivate func lineColor(_ name: String) -> UIColor {
        var lineColors: [String : UIColor] = [
            "DEA": UIColor.init(red: 190 / 255.0, green: 120 / 255.0, blue: 46 / 255.0, alpha: 1),
            "DIF": UIColor.init(red: 47 / 255.0, green: 165 / 255.0, blue: 206 / 255.0, alpha: 1),
            "MACD": UIColor.init(red: 208 / 255.0, green: 126 / 255.0, blue: 187 / 255.0, alpha: 1)]
        
        return lineColors[name] ?? .red
    }
    
    fileprivate func updateValue(_ m: BaseKLineModel) {
        let k = String.init(format: "DIF: %.03f", m.indexDict["DIF"] ?? 0)
        let d = String.init(format: "DEA: %.03f", m.indexDict["DEA"] ?? 0)
        let j = String.init(format: "MACD: %.03f", m.indexDict["MACD"] ?? 0)
        let kdj = [k, d, j]
        zip(kdj, self.macdLayers).forEach { (str, layer) in
            layer.string = str
        }
    }
    
    
    fileprivate func setupMacdLayers() {
        var x = self.drawBoardView.frame.minX + 5
        let y = self.drawBoardView.frame.minY / 2 - KLineConfig.shareConfig.tagFontSize * 0.5
        let h = KLineConfig.shareConfig.tagFontSize
        let tagLayer = CATextLayer.initWithFrame(CGRect.init(x: x, y: y, width: 80, height: h) , KLineConfig.shareConfig.tagFontSize, .white, "MACD(12,26,9)")
        self.contentView.layer.addSublayer(tagLayer)
        x += 80
        let w: CGFloat = 44
        let kLayer = CATextLayer.initWithFrame(CGRect.init(x: x, y: y, width: w, height: h) , KLineConfig.shareConfig.tagFontSize, self.lineColor("DIF"), "DIF: 0.00")
        self.contentView.layer.addSublayer(kLayer)
        x += w
        let dLayer = CATextLayer.initWithFrame(CGRect.init(x: x, y: y, width: w, height: h) , KLineConfig.shareConfig.tagFontSize, self.lineColor("DEA"), "DEA: 0.00")
        self.contentView.layer.addSublayer(dLayer)
        x += w
        let jLayer = CATextLayer.initWithFrame(CGRect.init(x: x, y: y, width: w, height: h) , KLineConfig.shareConfig.tagFontSize, self.lineColor("MACD"), "MACD: 0.00")
        self.contentView.layer.addSublayer(jLayer)
        self.macdLayers.append(contentsOf: [kLayer, dLayer, jLayer])
    }
    
}
