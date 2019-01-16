//
//  StockBaseLineView.swift
//  Kline_Example
//
//  Created by yaxun on 2019/1/16.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class StockBaseLineView: UIView {
    /// 时间分割线
    var _timeVerticalLine: CAShapeLayer? = nil
    /// 时间分割文字
    var _timeTextLayers: [CATextLayer] = []
    /// 内边距 (需要去适配屏幕大小)
    var contentInset: UIEdgeInsets = UIEdgeInsets.init(top: 30, left: 10, bottom: 10, right: 10)
    /// 绘制视图
    lazy var drawBoardView: UIView = {  return UIView.init() }()
    /// 绘制区域的宽度
    var drawboardWidth: CGFloat { get { return self.drawBoardView.bounds.width } }
    /// 内容区
    lazy var contentView: UIView = {
        let contentView = UIView.init(frame: .zero)
        contentView.layer.masksToBounds = true
        return contentView
    }()
    /// 标记的文字layer
    var markStrings: [CATextLayer] = []
    /// 颜色 字体之类的配置信息
    let _config: KLineConfig
    /// 是否垂直
    let _isHorizon: Bool
    /// 分时图时间段
    let times: [String] = ["10:00", "10:30", "11:00", "11:30", "13:30", "14:00", "14:30"]
    /// 分时图右边的坐标系
    var rateLayers: [CATextLayer] = []
    /// 标记线
    var markLines: [CAShapeLayer] = []
    /// 最大的边界x值
    var maxBorderX: CGFloat = 0
    
    /// 分时图的宽度
    var candleW: CGFloat { get { return self.drawBoardView.bounds.width / 360 } }
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
    
    func setupUI() {
        contentView.frame = CGRect.init(x: self.contentInset.left, y: self.contentInset.top, width: self.bounds.width - self.contentInset.left - self.contentInset.right, height: self.bounds.height - self.contentInset.top - self.contentInset.bottom)
        addSubview(contentView)
        let borderPath = UIBezierPath.drawRect(nil, contentView.bounds)
        let borderLayer = CAShapeLayer.drawLayer(contentView.bounds, borderPath, _config.seperatorColor, false, 1)
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
    
    /// 移动画板
    func transform(_ tx: CGFloat) { self.drawBoardView.transform = CGAffineTransform.init(translationX: tx, y: 0) }

    /// 分时图需要添加的 一些f线
    fileprivate func setMinuteUI() {
        /* 分时图相关的 */
        let stepWidth = self.drawBoardView.bounds.width / CGFloat(times.count + 1)
        var points: [(CGPoint, CGPoint)] = []
        for i in 0..<times.count {
            let x = CGFloat(i + 1) * stepWidth
            points.append((CGPoint.init(x: x, y: 0), CGPoint.init(x: x, y: self.contentView.bounds.height)))
            if self._timeTextLayers.count == times.count { continue }
            let text = CATextLayer.initWithFrame(CGRect.init(x: x + self.contentView.frame.minX, y: self.contentView.frame.maxY + 1, width: 100, height: self._config.tagFontSize) , self._config.tagFontSize, self._config.tagFontColor, times[i])
            self.layer.addSublayer(text)
            self._timeTextLayers.append(text)
        }
        
        if _timeVerticalLine == nil {
            let timePath = UIBezierPath.drawLines(points, nil)
            _timeVerticalLine = CAShapeLayer.drawLayer(self.drawBoardView.frame, timePath, self._config.seperatorColor, false, 1)
            self.contentView.layer.insertSublayer(_timeVerticalLine!, at: 0)
        }

        /// 增加右侧的坐标轴
        if self.rateLayers.count == 0 {
            self.markStrings.forEach { text in
                let rateLayer = CATextLayer.initWithFrame(CGRect.init(x: self.contentView.bounds.width - 40, y: text.frame.minY, width: 40, height: self._config.tagFontSize) , self._config.tagFontSize, self._config.tagFontColor)
                rateLayer.alignmentMode = "right"
                self.rateLayers.append(rateLayer)
                self.contentView.layer.addSublayer(rateLayer)
            }
        }
    }
    
    fileprivate func clearDrawBoardContext() {
        self.drawBoardView.layer.sublayers?.forEach{ $0.removeFromSuperlayer() }
        _timeVerticalLine?.removeFromSuperlayer()
        _timeVerticalLine = nil
        _timeTextLayers.forEach{ $0.removeFromSuperlayer() }
        _timeTextLayers.removeAll()
        self.rateLayers.forEach{ $0.removeFromSuperlayer() }
        self.rateLayers.removeAll()
        self.markLines.forEach{$0.removeFromSuperlayer()}
        self.markLines.removeAll()
    }

    /// 当y值在这里的时候 对应的价格是多少
    func valueOfY(_ y: CGFloat) -> CGFloat? {
        
    }
}

// MARK: 计算k线相关的内容
extension StockBaseLineView {
    
    /// 刷新k线数据
    func reloadData(_ nums: Int, _ candleWidth: CGFloat, _ models: [BaseKLineModel], _ isMin: Bool, _ scale: CGFloat) {
        /// 1.移除之前绘制的
        self.clearDrawBoardContext()
        self.maxBorderX = (CGFloat(models.count) - 0.5) * candleWidth
        
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
        /// 8.绘制文字
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

// MARK: 分时图相关
extension StockBaseLineView {
    /// 刷新分时数据
    func reloadMinute(_ openPrice: CGFloat, _ models: [KLineMinuteModel]) {
        /// 0.clear
        self.clearDrawBoardContext()
        self.setMinuteUI()
        self.maxBorderX = (CGFloat(models.count) - 0.5) * self.candleW

        /// 1.计算出最低价和最高价
        var min = models.map{ $0.minutePrice }.min() ?? 0
        var max = models.map{ $0.minutePrice }.max() ?? 0
        let minus = (max - min) * 0.1
        max += minus
        min -= minus
        
        /// 2.计算出文字的
        let averagePrice = (max - min) / CGFloat(self.markStrings.count)
        var currentPrice = max
        zip(self.markStrings, self.rateLayers).forEach { (str, rate) in
            str.string = String.init(format: "%.2f", currentPrice)
            let fontColor = currentPrice > openPrice ? self._config.upColor.cgColor : self._config.downColor.cgColor
            str.foregroundColor = fontColor
            rate.foregroundColor = fontColor
            rate.string = String.init(format: "%.2f%%", (currentPrice - openPrice) / openPrice)
            currentPrice -= averagePrice
        }
        let averageH = self.drawBoardView.bounds.height / (max - min)
        
        /// 3.开始绘制折线图
        var points: [CGPoint] = []
        models.enumerated().forEach { (index, model) in
            let x = (CGFloat(index) + 0.5) * candleW
            let y = (max - model.minutePrice) * averageH
            let p = CGPoint.init(x: x, y: y)
            points.append(p)
        }
        
        let linePath = UIBezierPath.drawLinePath(nil, points)
        let lineLayer = CAShapeLayer.drawLayer(self.drawBoardView.bounds, linePath, self._config.lineColor, false, 1)
        self.drawBoardView.layer.addSublayer(lineLayer)
        points.insert(CGPoint.init(x: 0, y: self.drawBoardView.bounds.height) , at: 0)
        points.append(CGPoint.init(x: (CGFloat(models.count - 1) + 0.5) * candleW, y: self.drawBoardView.bounds.height))
        let bgPath = UIBezierPath.drawLinePath(nil, points)
        bgPath.close()
        let bgLayer = CAShapeLayer.drawLayer(self.drawBoardView.bounds, bgPath, UIColor.clear, true, 1, self._config.minuteBgColor, false)
        self.drawBoardView.layer.addSublayer(bgLayer)
        
        /// 4.绘制开盘价的成本线
        let y = (max - openPrice) * averageH
        let openLinePath = UIBezierPath.drawLinePath(nil, [CGPoint.init(x: 0, y: y), CGPoint.init(x: self.drawBoardView.bounds.width, y: y)])
        let openLayer = CAShapeLayer.drawLayer(self.drawBoardView.frame, openLinePath, self._config.tagFontColor, false, 1, .clear, true)
        self.contentView.layer.addSublayer(openLayer)
        markLines.append(openLayer)
        
        /// 5.绘制最后一根线的价格
        let lastY = (max - (models.last?.minutePrice ?? 0)) * averageH
        let lastLinePath = UIBezierPath.drawLinePath(nil, [CGPoint.init(x: 0, y: lastY), CGPoint.init(x: self.drawBoardView.bounds.width, y: lastY)])
        let lastLayer = CAShapeLayer.drawLayer(self.drawBoardView.frame, lastLinePath, self._config.markLineColor, false, 1, .clear, true)
        self.contentView.layer.addSublayer(lastLayer)
        
        markLines.append(lastLayer)
        
    }
}
