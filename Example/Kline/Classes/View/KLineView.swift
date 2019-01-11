//
//  KLineView.swift
//  Kline_Example
//
//  Created by yaxun on 2018/7/19.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit

class KLineView: UIView {
    /// 内边距 (需要去适配屏幕大小)
    var contentInset: UIEdgeInsets = UIEdgeInsets.init(top: 30, left: 10, bottom: 10, right: 10)
    /// 数据源代理
    var dataSource: KLineDataSource?
    /// 时间传递代理
    var delegate: KLineDelegate?
    /// 当前展示的蜡烛图开始索引(只读属)
    private(set) var candleIndex: Int = 0
    
    
    /// 最外层的视图
    fileprivate lazy var contentView: UIView = {
        let contentView = UIView.init(frame: .zero)
        return contentView
    }()
    /// 滚动的视图
    fileprivate lazy var contentScroll: UIScrollView = {
        let scroll = UIScrollView.init()
        scroll.delegate = self
        return scroll
    }()
    /// 绘制视图
    fileprivate lazy var drawBoardView: UIView = {
        let view = UIView.init()
        return view
    }()
    /// 标记的文字layer
    fileprivate var markStrings: [CATextLayer] = []
    /// 颜色 字体之类的配置信息
    fileprivate let _config: KLineConfig
    /// 是否为横屏状态
    fileprivate let _isHorizon: Bool
    /// 当前蜡烛图的总数
    fileprivate var _candlesCount: Int = 0
    /// 当前屏幕的scale (根据scale来计算出当前一屏幕的宽度能绘制多少的蜡烛图)
    fileprivate var _scale: CGFloat = 0.5
    /// 当前k线最大的绘制开始下标
    fileprivate var _maxDrawIndex: Int = 0
    /// 时间分割线
    fileprivate var _timeVerticalLine: CAShapeLayer? = nil
    /// 时间分割文字
    fileprivate var _timeTextLayers: [CATextLayer] = []
    /// 开始缩放时的中心index
    fileprivate var _beganScaleCenterIndex: Int = 0
    /// 最小缩放比
    fileprivate let _minScale: CGFloat = 0.4
    /// 最大缩放比
    fileprivate let _maxScale: CGFloat = 1
    /// 记录上一次缩放的比例
    fileprivate var preScale: CGFloat = 1
    /// 当前坐标系Y轴最大值
    fileprivate var maxmumPrice: CGFloat = 0
    /// y轴平均价格
    fileprivate var averageY: CGFloat = 0
    // MARK: 计算属性
    /// 蜡烛图的宽度 (动态变化, 会随着手势变化而变化)
    fileprivate var candleWidth: CGFloat {
        get {
            return self.contentView.bounds.width / CGFloat(self._candlesOfScreen)
        }
    }
    /// 当前屏幕绘制的蜡烛数量 (动态变化 随着缩放值变化而变化)
    fileprivate var _candlesOfScreen: Int {
        get {
            return self.candlesOfScale(self._scale)
        }
    }
    
    // MARK: 初始化
    init(_ config: KLineConfig, _ isHorizon: Bool, _ scale: CGFloat) {
        _config = config
        _isHorizon = isHorizon
        _scale = scale
        super.init(frame: .zero)
        self.backgroundColor = _config.bgColor
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("error initinal")
    }
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if contentView.superview != nil { return }
        if self.constraints.count > 0 && self.frame.width == 0 || self.frame.height == 0 {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        setupUI()
        observerGesture()
    }
}

// MARK: 外界调用的方法
extension KLineView {
    /// 刷新数据
    public func reloadData() {
        /// 1.计算scroll的ContentSize
        guard let num = dataSource?.numberOfCandles(self) else { return }
        guard let startIndex = dataSource?.startRenderIndex(self) else { return }
        if startIndex > num - 1 { return }
        self._candlesCount = num
        var width = CGFloat(num) * self.candleWidth + self._config.klinePaddingRight
        if width <= self.contentScroll.bounds.width {
            width = self.contentScroll.bounds.width + 0.5
            self._maxDrawIndex = 0
        } else {
            let index = Int((width - self.contentScroll.bounds.width - self._config.klinePaddingRight) / self.candleWidth)
            self._maxDrawIndex = index
        }
        self.contentScroll.contentSize = CGSize.init(width: width, height: self.contentScroll.bounds.height)
        /// 2.开始绘制当前屏幕的k线图
        var endIndex = startIndex + _candlesOfScreen - 1
        if endIndex >= num {
            endIndex = num - 1
        }
        /// 3.绘制
        self.willDrawCandles(startIndex, endIndex)
    }
}

// MARK: 核心绘制方法
extension KLineView {
    
    /// 核心绘制k线的方法
    ///
    /// - Parameters:
    ///   - begin: 数据开始的位置
    ///   - end: 数据结束的位置
    fileprivate func willDrawCandles(_ begin: Int, _ end: Int) {
        /// 0.移除之前绘制的
        self.drawBoardView.layer.sublayers?.forEach{ $0.removeFromSuperlayer() }
        _timeVerticalLine?.removeFromSuperlayer()
        _timeTextLayers.forEach{ $0.removeFromSuperlayer() }
        /// 1.取出数据模型
        guard let models = dataSource?.willShowCandles(self, begin, end) else { return }
        self.candleIndex = begin
        /// 2.计算出m最大值
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
        self.maxmumPrice = offsetY * (highestPrice - lowestPrice) / (self.contentView.bounds.height - offsetY)  + highestPrice
        self.averageY = (highestPrice - lowestPrice) / (self.contentView.bounds.height - offsetY)
        var upPath: UIBezierPath? = nil
        var downPath: UIBezierPath? = nil
        var linePath: UIBezierPath? = nil
        // 分割线的起点 终点
        var seperatorsPoints: [(CGPoint, CGPoint)] = []
        var timeStrs: [String] = []
        var preTime = (models.first?.time ?? 0) / 1000
        let isLine = self._scale == self._minScale
        for (index, model) in models.enumerated() {
            /// 1.计算时间
            let currentTime = model.time / 1000
            let isSmmeYear = Date.isSameYear(preTime, currentTime)
            let isSameMonth = Date.isSameMonth(preTime, currentTime)
            let midX = (CGFloat(index) + 0.5) * self.candleWidth
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
                linePath = self.caculateCandleRect(model, linePath, index, offsetY, averageHeight, highestPrice, false, isLine)
                continue
            }
            let isUp = model.closingPrice - model.openingPrice > 0
            if isUp {
                upPath = self.caculateCandleRect(model, upPath, index, offsetY, averageHeight, highestPrice, isUp, isLine)
            } else {
                downPath = self.caculateCandleRect(model, downPath, index, offsetY, averageHeight, highestPrice, isUp, isLine)
            }
        }
        /// 5.开始渲染k线
        if upPath != nil {
            let upLayer = CAShapeLayer.drawLayer(self.drawBoardView.bounds, upPath!, self._config.upColor, .clear, true, 1)
            self.drawBoardView.layer.addSublayer(upLayer)
        }
        if downPath != nil {
            let downLayer = CAShapeLayer.drawLayer(self.drawBoardView.bounds, downPath!, self._config.downColor, self._config.downColor, false, 1)
            self.drawBoardView.layer.addSublayer(downLayer)
        }
        if linePath != nil {
            let lineLayer = CAShapeLayer.drawLayer(self.drawBoardView.bounds, linePath!, self._config.lineColor, .clear, true, 1)
            self.drawBoardView.layer.addSublayer(lineLayer)
        }
        /// 6.绘制竖线分割线
        let verticalLinePath = UIBezierPath.drawLines(seperatorsPoints)
        let verticalLineLayer = CAShapeLayer.drawLayer(self.contentView.bounds, verticalLinePath, self._config.seperatorColor, self._config.seperatorColor, false, 1)
        _timeVerticalLine = verticalLineLayer
        self.contentView.layer.insertSublayer(verticalLineLayer, at: 0)
        /// 7.绘制文字
        timeStrs.enumerated().forEach { (index, str) in
            let x = seperatorsPoints[index].1.x
            let y = seperatorsPoints[index].1.y
            let h = self._config.tagFontSize
            let frame = CGRect.init(x: x, y: y, width: 100.0, height: h)
            let textLayer = CATextLayer.initWithFrame(frame, h, self._config.tagFontColor)
            textLayer.string = timeStrs[index]
            _timeTextLayers.append(textLayer)
            self.contentView.layer.addSublayer(textLayer)
        }
    }
    
    /// 计算蜡烛图的k线位置
    fileprivate func caculateCandleRect(_ model: BaseKLineModel, _ path: UIBezierPath?, _ index: Int, _ offsetY: CGFloat, _ averageHeight: CGFloat, _ highestPrice: CGFloat, _ isUp: Bool, _ isLine: Bool)
        -> UIBezierPath {
            let highestY = (highestPrice - model.highestPrice) * averageHeight + offsetY

            /// 1.先判断是不是折线图
            if isLine {
                let midX = (CGFloat(index) + 0.5) * self.candleWidth
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
            var w = self.candleWidth - self._scale * 2 - 2
            /// 2.判断是否是最小
            if w < 1 {
                w = 1
                let midX = (CGFloat(index) + 0.5) * self.candleWidth
                return UIBezierPath.drawLines([(CGPoint.init(x: midX, y: highestY), CGPoint.init(x: midX, y: lowestY))], path)
            }
            let openY = (highestPrice - model.openingPrice) * averageHeight + offsetY
            let closeY = (highestPrice - model.closingPrice) * averageHeight + offsetY
            let y = isUp ? closeY : openY
            let x = CGFloat(index) * self.candleWidth + self._scale

            let h = isUp ?  openY - closeY : closeY - openY
            let candleRect = CGRect.init(x: x, y: y, width: w, height: h)
            if isUp {
                return UIBezierPath.drawCandle(path, candleRect, highestY, lowestY)
            }
            return UIBezierPath.drawCandle(path, candleRect, highestY, lowestY)
    }

    
    fileprivate func beganDrawiCandles() {
        
    }
    
}

// MARK: 滚动代理 UIScrollViewDelegate
extension KLineView: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetx = scrollView.contentOffset.x
        if offsetx < 0 { // 往右边偏移
            self.drawBoardView.transform = CGAffineTransform.init(translationX: -offsetx, y: 0)
            if self.candleIndex == 0 { return }
            var end: Int = self._candlesOfScreen - 1
            if end >= self._candlesCount {
                end = self._candlesCount - 1
            }
            self.willDrawCandles(0, end)
            
        } else if offsetx + scrollView.bounds.width > scrollView.contentSize.width { // 往左边偏移
            self.drawBoardView.transform = CGAffineTransform.init(translationX: -(offsetx + scrollView.bounds.width - scrollView.contentSize.width), y: 0)
            if self.candleIndex == self._maxDrawIndex { return }
            self.willDrawCandles(self._maxDrawIndex, self._candlesCount - 1)
        } else {
            let beginIndex = Int((scrollView.contentOffset.x / self.candleWidth).rounded())
            if beginIndex == self.candleIndex || beginIndex > self._maxDrawIndex { return }
            var endIndex = beginIndex + self._candlesOfScreen
            endIndex = endIndex >= self._candlesCount ? self._candlesCount - 1 : endIndex
            self.willDrawCandles(beginIndex, endIndex)
        }
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x < 0 || scrollView.contentOffset.x + scrollView.bounds.width > scrollView.contentSize.width { return }
        scrollView.setContentOffset(CGPoint.init(x: CGFloat(self.candleIndex) * candleWidth, y: 0), animated: false)
    }
    
}


// MARK: 计算需要用到的函数
extension KLineView {
    /// 计算当前屏幕能绘制多少蜡烛图
    fileprivate func candlesOfScale(_ scale: CGFloat) -> Int {
        if _isHorizon {
            return Int(-25 * scale + 105)
        } 
        return Int(-266 * scale + 286)
    }
    
    /// y轴对应的价格
    fileprivate func priceOf(_ y: CGFloat) -> CGFloat? {
        if y < 0 || y > self.contentView.bounds.height { return nil }
        return self.maxmumPrice - self.averageY * y
    }
    
}

// MARK: 手势监听
extension KLineView {
    
    /// 长按手势监听
    @objc fileprivate func longtap(_ event: UILongPressGestureRecognizer) {
        let p = event.location(in: self.drawBoardView)
        var index = Int(p.x / self.candleWidth)
        if index < 0 {
            index = self.candleIndex
        } else if index > self._candlesOfScreen - 1 {
            index = self._candlesOfScreen - 1 + self.candleIndex
        } else {
            index += self.candleIndex
        }
        if index > self._candlesCount - 1 {
            index = self._candlesCount - 1
        }
        delegate?.longPress(self, index, p, priceOf(p.y), event.state == .began, event.state == .ended)
    }
    
    /// 手势缩放
    @objc func scaleScroll(_ event: UIPinchGestureRecognizer) {
        let p = event.location(in: self.drawBoardView)
        // 1.限制缩放的范围在 (0.5 和 3) 之间
        self._scale += (event.scale - self.preScale > 0 ? 0.004 : -0.004)
        if self._scale < self._minScale {
            self._scale = self._minScale
            return
        } else if self._scale >= self._maxScale {
            self._scale = self._maxScale
            return
        }
        self.preScale = event.scale
        switch event.state {
        case .began:
            /// 2.计算出将要缩放的点
            _beganScaleCenterIndex = self.candleIndex + Int(p.x / self.candleWidth)
            break
        case .changed:
            /// 3.计算出缩放的开始位置和结束位置
            self.reloadScale(self._scale, p)
            break
        case .ended:
            self.preScale = 1
            break
        default:
            break
        }
    }
    
    /// 刷新手势缩放
    fileprivate func reloadScale(_ targetScale: CGFloat, _ position: CGPoint) {
        /// 计算出要绘制的蜡烛图
        var began = _beganScaleCenterIndex - self._candlesOfScreen / 2
        if began < 0 {
            began = 0
        }
        var end = self._candlesOfScreen + began - 1
        if end > self._candlesCount - 1 {
            end = self._candlesCount - 1
        }
        var width = self.candleWidth * CGFloat(self._candlesCount) + self._config.klinePaddingRight
        if width <= self.contentScroll.bounds.width {
            width = self.contentScroll.bounds.width + 0.5
        }
        self.contentScroll.contentSize = CGSize.init(width: width, height: self.contentScroll.bounds.height)
        self.contentScroll.setContentOffset(CGPoint.init(x: CGFloat(began) * self.candleWidth, y: 0), animated: false)
        self.willDrawCandles(began, end)
    }
    
}



// MARK: k线图的UI初始化
extension KLineView {
    
    /// 初始化UI
    fileprivate func setupUI() {
        contentView.frame = CGRect.init(x: self.contentInset.left, y: self.contentInset.top, width: self.bounds.width - self.contentInset.left - self.contentInset.right, height: self.bounds.height - self.contentInset.top - self.contentInset.bottom)
        addSubview(contentView)
        let borderPath = UIBezierPath.drawRect(nil, contentView.bounds)
        let borderLayer = CAShapeLayer.drawLayer(contentView.bounds, borderPath, _config.seperatorColor, .clear, false, 0.5)
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
        let lineLayer = CAShapeLayer.drawLayer(contentView.bounds, linePath, _config.seperatorColor, .clear, false, 1)
        self.contentView.layer.addSublayer(lineLayer)
        drawBoardView.frame = contentView.bounds
        contentScroll.frame = contentView.bounds
        contentView.addSubview(drawBoardView)
        contentView.addSubview(contentScroll)
        markStrings.forEach { textLayer in
            self.contentView.layer.addSublayer(textLayer)
        }
    }
    
    /// 手势进行监听
    fileprivate func observerGesture() {
        let longTap = UILongPressGestureRecognizer.init(target: self, action: #selector(longtap))
        self.contentScroll.addGestureRecognizer(longTap)
        let pinch = UIPinchGestureRecognizer.init(target: self, action: #selector(scaleScroll))
        self.contentScroll.addGestureRecognizer(pinch)
    }
}
