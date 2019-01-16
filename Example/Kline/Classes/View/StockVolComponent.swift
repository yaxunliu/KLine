//
//  StockVolComponent.swift
//  Kline_Example
//
//  Created by yaxun on 2019/1/15.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class StockVolComponent: StockComponent {
    
    init(_ bounds: CGRect) {
        super.init(bounds, [])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupUI() {
        super.setupUI()
        
        // 加三条横线
        let averageH = self.drawBoardView.bounds.height / 3.5
        var y = averageH * 0.5
        var points: [(CGPoint, CGPoint)] = []
        self.markString.enumerated().forEach { (index, layer) in
            let begin = CGPoint.init(x: self.drawBoardView.frame.minX, y: self.drawBoardView.frame.minY + y)
            let end = CGPoint.init(x: self.drawBoardView.frame.maxX, y: self.drawBoardView.frame.minY + y)
            points.append((begin, end))
            layer.frame = CGRect.init(x: layer.frame.minX, y: y - layer.bounds.height + self.drawBoardView.frame.minY, width: layer.bounds.width, height: layer.bounds.height)
            y += averageH
        }
        let path = UIBezierPath.drawLines(points, nil)
        self.contentView.layer.insertSublayer(CAShapeLayer.drawLayer(self.contentView.bounds, path, KLineConfig.shareConfig.seperatorColor, false, 1), at: 0)
        /// 加一个单位提示文字
        self.contentView.layer.insertSublayer(CATextLayer.initWithFrame(CGRect.init(x: self.drawBoardView.frame.minX, y: self.drawBoardView.frame.maxY - KLineConfig.shareConfig.tagFontSize, width: 100, height: KLineConfig.shareConfig.tagFontSize) , KLineConfig.shareConfig.tagFontSize, KLineConfig.shareConfig.tagFontColor, "万股"), at: 0)
        
        
        /// 加一个title 文字
        let titleLayer = CATextLayer.initWithFrame(CGRect.init(x: self.drawBoardView.frame.minX + 5, y: (self.drawBoardView.frame.minY - KLineConfig.shareConfig.tagFontSize) / 2, width: 100, height: KLineConfig.shareConfig.tagFontSize) , KLineConfig.shareConfig.tagFontSize, KLineConfig.shareConfig.tagFontColor, "VOL")
        self.contentView.layer.insertSublayer(titleLayer, at: 0)
        
    }
    
    override func reloadData(_ nums: Int, _ candleWidth: CGFloat, _ datas: [BaseKLineModel], _ isMin: Bool, _ scale: CGFloat) {
        self.drawBoardView.layer.sublayers?.forEach{ $0.removeFromSuperlayer() }
        
        /// 最高交易量
        let maxVolume = (datas.map{ $0.volume }.max() ?? 0) / 10000 * 1.1
        var upPath: UIBezierPath? = nil
        var downPath: UIBezierPath? = nil
        
        let average = self.drawBoardView.bounds.height / maxVolume
        var w = candleWidth - scale * 2 - 2
        if w < 1 {
            w = 1
        }
        
        /// 更新文字内容
        self.updateMarks(maxVolume)
        
        /// 绘制柱状图
        datas.enumerated().forEach { (index, model) in
            let isUp = model.closingPrice > model.openingPrice
            let x = CGFloat(index) * candleWidth + scale
            let y = (maxVolume - model.volume / 10000) * average
            let h = self.drawBoardView.bounds.height - y
            if isUp {
                upPath = UIBezierPath.drawRect(upPath, CGRect.init(x: x, y: y, width: w, height: h) )
            } else {
                downPath = UIBezierPath.drawRect(downPath, CGRect.init(x: x, y: y, width: w, height: h) )
            }
        }
        
        if upPath != nil {
            let upLayer = CAShapeLayer.drawLayer(self.drawBoardView.bounds, upPath!, KLineConfig.shareConfig.upColor, false, 1, KLineConfig.shareConfig.upColor, false)
            self.drawBoardView.layer.addSublayer(upLayer)
        }
        if downPath != nil {
            let downLayer = CAShapeLayer.drawLayer(self.drawBoardView.bounds, downPath!, KLineConfig.shareConfig.downColor, false, 1, KLineConfig.shareConfig.downColor, false)
            self.drawBoardView.layer.addSublayer(downLayer)
        }
    }
    
}

extension StockVolComponent {
    fileprivate func updateMarks(_ maxVolume: CGFloat) {
        let average = Int(maxVolume / 3.5)
        let texts = [String.init(format: "%d", average * 3),
                     String.init(format: "%d", average * 2),
                     String.init(format: "%d", average)]
        zip(texts, self.markString).forEach { (str, layer) in
            layer.string = str
        }
    }
}
