//
//  StockLineView.swift
//  Kline_Example
//
//  Created by yaxun on 2019/1/14.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class StockLineView: UIView {
    /// 时间分割线
    fileprivate var _timeVerticalLine: CAShapeLayer? = nil
    /// 时间分割文字
    fileprivate var _timeTextLayers: [CATextLayer] = []
    /// 内边距 (需要去适配屏幕大小)
    var contentInset: UIEdgeInsets = UIEdgeInsets.init(top: 30, left: 10, bottom: 10, right: 10)
    /// 绘制视图
    fileprivate lazy var drawBoardView: UIView = {  return UIView.init() }()
    /// 绘制区域的宽度
    var drawboardWidth: CGFloat {
        get {
            return self.drawBoardView.bounds.width
        }
    }
        
    fileprivate lazy var contentView: UIView = {
        let contentView = UIView.init(frame: .zero)
        contentView.layer.masksToBounds = true
        return contentView
    }()
    /// 标记的文字layer
    fileprivate var markStrings: [CATextLayer] = []
    /// 在长按手势中用来计算y轴值
    fileprivate var averageY: CGFloat = 0

    /// 颜色 字体之类的配置信息
    fileprivate let _config: KLineConfig
    fileprivate let _isHorizon: Bool
    
    init(_ config: KLineConfig, _ isHorizon: Bool) {
        self._config = config
        self._isHorizon = isHorizon
        super.init(frame: .zero)
        self.backgroundColor = self._config.bgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if contentView.superview != nil { return }
        if self.constraints.count > 0 && self.frame.width == 0 || self.frame.height == 0 {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        setupUI()
    }

    fileprivate func setupUI() {
        contentView.frame = CGRect.init(x: self.contentInset.left, y: self.contentInset.top, width: self.bounds.width - self.contentInset.left - self.contentInset.right, height: self.bounds.height - self.contentInset.top - self.contentInset.bottom)
        addSubview(contentView)
        let borderPath = UIBezierPath.drawRect(nil, contentView.bounds)
        let borderLayer = CAShapeLayer.drawLayer(contentView.bounds, borderPath, _config.seperatorColor, false, 0.5)
        self.contentView.layer.addSublayer(borderLayer)
        let seperatorNum = _isHorizon ? _config.horizonSeperatorNum : _config.verticalSeperatorNum
        let paddingTop = (contentView.bounds.height - _config.tagFontSize) / CGFloat(seperatorNum)
        var startY = _config.tagFontSize
        var points: [(CGPoint, CGPoint)] = []
        markStrings.append(CATextLayer.initWithFrame(CGRect.init(x: 0, y: startY - _config.tagFontSize, width: 40, height: _config.tagFontSize) , _config.tagFontSize, self._config.tagFontColor))
        for _ in 0..<seperatorNum {
            let startP = CGPoint.init(x: 0, y: startY)
            let endP = CGPoint.init(x: contentView.frame.width, y: startY)
            points.append((startP, endP))
            startY += paddingTop
            markStrings.append(CATextLayer.initWithFrame(CGRect.init(x: 0, y: startY - _config.tagFontSize, width: 40, height: _config.tagFontSize) , _config.tagFontSize, self._config.tagFontColor))
        }
        let linePath = UIBezierPath.drawLines(points)
        let lineLayer = CAShapeLayer.drawLayer(contentView.bounds, linePath, _config.seperatorColor, false, 1)
        self.contentView.layer.addSublayer(lineLayer)
        drawBoardView.frame = contentView.bounds
        contentView.addSubview(drawBoardView)
        markStrings.forEach { textLayer in
            self.contentView.layer.addSublayer(textLayer)
        }
    }
    
}


extension StockLineView: StockComponentDelegate {
    
    func transform(_ tx: CGFloat) {
        self.drawBoardView.transform = CGAffineTransform.init(translationX: tx, y: 0)
    }
    
    func reloadData(_ nums: Int, _ candleWidth: CGFloat, _ models: [BaseKLineModel], _ isMin: Bool, _ scale: CGFloat) {
        /// 1.移除之前绘制的
        self.drawBoardView.layer.sublayers?.forEach{ $0.removeFromSuperlayer() }
        _timeVerticalLine?.removeFromSuperlayer()
        _timeTextLayers.forEach{ $0.removeFromSuperlayer() }
        
        /// 2.计算最大值和最小值
        var highestPrice = models.map{ $0.highestPrice }.max() ?? 0
        var lowestPrice = models.map{ $0.lowestPrice }.min() ?? 0
        let minus = (highestPrice - lowestPrice) * 0.1
        lowestPrice -= minus
        highestPrice += minus
        
        /// 3.根据最大值计算出标记文字
        let averagePrice = (highestPrice - lowestPrice) / CGFloat(self.markStrings.count)
        var currentPrice = highestPrice
        self.markStrings.forEach { layer in
            layer.string = String.init(format: "%.2f", currentPrice)
            currentPrice -= averagePrice
        }
        
        /// 4.开始绘制k线
        let offsetY = self._config.tagFontSize
        let averageHeight = (self.contentView.bounds.height - offsetY) / (highestPrice - lowestPrice)
//        self.maxmumPrice = offsetY * (highestPrice - lowestPrice) / (self.contentView.bounds.height - offsetY)  + highestPrice
        self.averageY = (highestPrice - lowestPrice) / (self.contentView.bounds.height - offsetY)
        var upPath: UIBezierPath? = nil
        var downPath: UIBezierPath? = nil
        var linePath: UIBezierPath? = nil
        
        // 5.分割线的起点 终点
        var seperatorsPoints: [(CGPoint, CGPoint)] = []
        var timeStrs: [String] = []
        var preTime = (models.first?.time ?? 0) / 1000
        let isLine = isMin
        for (index, model) in models.enumerated() {
            /// 1.计算时间
            let currentTime = model.time / 1000
            let isSmmeYear = Date.isSameYear(preTime, currentTime)
            let isSameMonth = Date.isSameMonth(preTime, currentTime)
            let midX = (CGFloat(index) + 0.5) * candleWidth
            if !isSmmeYear || !isSameMonth {
                let touple = Date.transformStr(currentTime)
                let str = !isSmmeYear || timeStrs.count == 0 ? String.init(format: "%02d/%02d", touple.0, touple.1) : String.init(format: "%02d", touple.1)
                timeStrs.append(str)
                let orgP = CGPoint.init(x: midX, y: 0)
                let endP = CGPoint.init(x: midX, y: self.contentView.bounds.height)
                seperatorsPoints.append((orgP, endP))
            }
            preTime = model.time / 1000
            /// 2.绘制k线或者折线
            if isLine { // 绘制折现
                linePath = self.caculateCandleRect(scale, candleWidth, model, linePath, index, offsetY, averageHeight, highestPrice, false, isLine)
                continue
            }
            let isUp = model.closingPrice - model.openingPrice > 0
            if isUp {
                upPath = self.caculateCandleRect(scale, candleWidth, model, upPath, index, offsetY, averageHeight, highestPrice, isUp, isLine)
            } else {
                downPath = self.caculateCandleRect(scale, candleWidth, model, downPath, index, offsetY, averageHeight, highestPrice, isUp, isLine)
            }
        }
        /// 6.开始渲染k线
        if upPath != nil {
            let upLayer = CAShapeLayer.drawLayer(self.drawBoardView.bounds, upPath!, self._config.upColor, true, 1)
            self.drawBoardView.layer.addSublayer(upLayer)
        }
        if downPath != nil {
            let downLayer = CAShapeLayer.drawLayer(self.drawBoardView.bounds, downPath!, self._config.downColor, false, 1, self._config.downColor)
            self.drawBoardView.layer.addSublayer(downLayer)
        }
        if linePath != nil {
            let lineLayer = CAShapeLayer.drawLayer(self.drawBoardView.bounds, linePath!, self._config.lineColor, true, 1)
            self.drawBoardView.layer.addSublayer(lineLayer)
        }
        /// 7.绘制竖线分割线
        let verticalLinePath = UIBezierPath.drawLines(seperatorsPoints)
        let verticalLineLayer = CAShapeLayer.drawLayer(self.contentView.bounds, verticalLinePath, self._config.seperatorColor, false, 1, self._config.seperatorColor)
        _timeVerticalLine = verticalLineLayer
        self.contentView.layer.insertSublayer(verticalLineLayer, at: 0)
        /// 8    .绘制文字
        timeStrs.enumerated().forEach { (index, str) in
            let x = seperatorsPoints[index].1.x
            let y = self.contentView.frame.maxY
            let h = self._config.tagFontSize
            let frame = CGRect.init(x: x, y: y, width: 100.0, height: h)
            let textLayer = CATextLayer.initWithFrame(frame, h, self._config.tagFontColor)
            textLayer.string = timeStrs[index]
            _timeTextLayers.append(textLayer)
            self.layer.addSublayer(textLayer)
        }

        
    }
    
    func longPress(_ p: CGPoint) -> CGFloat {
        return 1
    }
    
}


extension StockLineView {
    /// 计算蜡烛图的k线位置
    fileprivate func caculateCandleRect(_ scale: CGFloat, _ candleWidth: CGFloat, _ model: BaseKLineModel, _ path: UIBezierPath?, _ index: Int, _ offsetY: CGFloat, _ averageHeight: CGFloat, _ highestPrice: CGFloat, _ isUp: Bool, _ isLine: Bool)
        -> UIBezierPath {
            let highestY = (highestPrice - model.highestPrice) * averageHeight + offsetY
            /// 1.先判断是不是折线图
            if isLine {
                let midX = (CGFloat(index) + 0.5) * candleWidth
                let p = CGPoint.init(x: midX, y: highestY)
                let bPath = path ?? UIBezierPath.init()
                if index == 0 {
                    bPath.move(to: p)
                } else {
                    bPath.addLine(to: p)
                }
                return bPath
            }
            let lowestY = (highestPrice - model.lowestPrice) * averageHeight + offsetY
            var w = candleWidth - scale * 2 - 2
            /// 2.判断是否是最小
            if w < 1 {
                w = 1
                let midX = (CGFloat(index) + 0.5) * candleWidth
                return UIBezierPath.drawLines([(CGPoint.init(x: midX, y: highestY), CGPoint.init(x: midX, y: lowestY))], path)
            }
            let openY = (highestPrice - model.openingPrice) * averageHeight + offsetY
            let closeY = (highestPrice - model.closingPrice) * averageHeight + offsetY
            let y = isUp ? closeY : openY
            let x = CGFloat(index) * candleWidth + scale
            
            let h = isUp ?  openY - closeY : closeY - openY
            let candleRect = CGRect.init(x: x, y: y, width: w, height: h)
            if isUp {
                return UIBezierPath.drawCandle(path, candleRect, highestY, lowestY)
            }
            return UIBezierPath.drawCandle(path, candleRect, highestY, lowestY)
    }
}
