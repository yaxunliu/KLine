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
    /// 数据源代理
    var dataSource: KLineDataSource?
    /// 时间传递代理
    var delegate: KLineDelegate?
    
    /// 当前索引
    fileprivate var _contentOffsetIndex: Int = 0
    /// 当前蜡烛图的总数
    fileprivate var _candlesCount: Int = 0
    /// 当前屏幕绘制的蜡烛数量
    fileprivate var _candlesOfScreen: Int = 0
    /// 当前屏幕的scale (根据scale来计算出当前一屏幕的宽度能绘制多少的蜡烛图)
    fileprivate var _scale: CGFloat = 1
    /// 当前展示的k线数据模型
    fileprivate var _showCandles: [BaseKLineModel] = []
    /// 当前展示的蜡烛图开始索引(只读属)
    private(set) var candleIndex: Int = 0
    // MARK: 计算属性
    /// 蜡烛图的宽度 (动态变化, 会随着手势变化而变化)
    fileprivate var candleWidth: CGFloat {
        get {
            return self.contentView.bounds.width / CGFloat(self._candlesOfScreen)
        }
    }
    // MARK: 初始化
    init(_ config: KLineConfig, _ isHorizon: Bool, _ scale: CGFloat) {
        _config = config
        _isHorizon = isHorizon
        _scale = scale
        super.init(frame: .zero)
        _candlesOfScreen = self.candlesOfScale(scale)
        self.backgroundColor = _config.bgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("error initinal")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        print("move to supview")
        if contentView.superview != nil { return }
        if self.constraints.count > 0 && self.frame.width == 0 || self.frame.height == 0 {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        setupUI()
        observerGesture()
    }
    
}

extension KLineView {
    
    public func reloadData() {
        /// 1.计算scroll的ContentSize
        guard let num = dataSource?.numberOfCandles(self) else { return }
        guard let startIndex = dataSource?.startRenderIndex(self) else { return }
        if startIndex > num - 1 { return }
        self._contentOffsetIndex = startIndex
        self._candlesCount = num
        
        let width = CGFloat(num) * self.candleWidth + self._config.klinePaddingRight
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

// MARK: 绘制方法
extension KLineView {
    
    
    fileprivate func willDrawCandles(_ begin: Int, _ end: Int) {
        /// 0.移除之前绘制的
        self.drawBoardView.layer.sublayers?.forEach({ subLayer in
            subLayer.removeFromSuperlayer()
        })
        
        /// 1.取出数据模型
        guard let models = dataSource?.willShowCandles(self, begin, end) else { return }
        _showCandles = models
        
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
        var upPath: UIBezierPath? = nil
        var downPath: UIBezierPath? = nil
        
        for (index, model) in models.enumerated() {
            let isUp = model.closingPrice - model.openingPrice > 0
            let highestY = (highestPrice - model.highestPrice) * averageHeight + offsetY
            let lowestY = (highestPrice - model.lowestPrice) * averageHeight + offsetY
            let openY = (highestPrice - model.openingPrice) * averageHeight + offsetY
            let closeY = (highestPrice - model.closingPrice) * averageHeight + offsetY
            let y = isUp ? closeY : openY
            let w = self.candleWidth - 2
            let x = CGFloat(index) * self.candleWidth + 0.5
            let h = isUp ?  openY - closeY : closeY - openY
            let candleRect = CGRect.init(x: x, y: y, width: w, height: h)
            
            if isUp {
                upPath = UIBezierPath.drawCandle(upPath, candleRect, highestY, lowestY)
            } else {
                downPath = UIBezierPath.drawCandle(downPath, candleRect, highestY, lowestY)
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
    }
    
    
    
    
    
}

extension KLineView: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if self.reloadDraw.transform.tx != 0 { self.reloadDraw.transform = CGAffineTransform.init(translationX: 0, y: 0) }
//        if self.checkOutBounds(scroll) { return }
        
        let offsetx = scrollView.contentOffset.x
        
        if offsetx < 0 { // 往右边偏移
            
        } else if offsetx + scrollView.bounds.width > scrollView.contentSize.width { // 往左边偏移
            
        } else {
            let beginIndex = Int((scrollView.contentOffset.x / self.candleWidth).rounded())
            if beginIndex == self._contentOffsetIndex { return }
            var endIndex = beginIndex + self._candlesOfScreen
            endIndex = endIndex >= self._candlesCount ? self._candlesCount - 1 : endIndex
            
            self.willDrawCandles(beginIndex, endIndex)
        }
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
//        if scrollView.contentOffset.x < 0 || scrollView.contentOffset.x + scrollView.bounds.width > scrollView.contentSize.width {
//            self.reloadDraw.transform = CGAffineTransform.init(translationX: 0, y: 0)
//        } else {
//            self.scroll.setContentOffset(CGPoint.init(x: CGFloat(self.currentDrawIndex) * candleWidth, y: 0), animated: false)
//        }
    }
    
    
}


// MARK: 计算需要用到的函数
extension KLineView {
    /// 计算当前屏幕能绘制多少蜡烛图
    ///
    /// - Parameter scale: 缩放比例
    fileprivate func candlesOfScale(_ scale: CGFloat) -> Int {
        if _isHorizon {
            return Int(-25 * scale + 105)
        } 
        return Int(-21 * scale + 81)
    }
}



// MARK: k线图的UI初始化
extension KLineView {
    fileprivate func setupUI() {
        contentView.frame = CGRect.init(x: self.contentInset.left, y: self.contentInset.top, width: self.bounds.width - self.contentInset.left - self.contentInset.right, height: self.bounds.height - self.contentInset.top - self.contentInset.bottom)
        addSubview(contentView)
        drawBoardView.frame = contentView.bounds
        contentScroll.frame = contentView.bounds
        contentView.addSubview(drawBoardView)
        contentView.addSubview(contentScroll)
        
        /// 设置样式
        self.drawBoardView.backgroundColor = _config.bgColor
        let borderPath = UIBezierPath.drawRect(nil, drawBoardView.bounds)
        let borderLayer = CAShapeLayer.drawLayer(drawBoardView.bounds, borderPath, _config.seperatorColor, .clear, false, 0.5)
        self.drawBoardView.layer.addSublayer(borderLayer)
        
        let seperatorNum = _isHorizon ? _config.horizonSeperatorNum : _config.verticalSeperatorNum
        let paddingTop = (drawBoardView.bounds.height - _config.tagFontSize) / CGFloat(seperatorNum)
        var startY = _config.tagFontSize
        var points: [(CGPoint, CGPoint)] = []
        markStrings.append(CATextLayer.initWithFrame(CGRect.init(x: 0, y: startY - _config.tagFontSize, width: 40, height: _config.tagFontSize) , _config.tagFontSize, self._config.tagFontColor))
        for _ in 0..<seperatorNum {
            let startP = CGPoint.init(x: 0, y: startY)
            let endP = CGPoint.init(x: drawBoardView.frame.width, y: startY)
            points.append((startP, endP))
            startY += paddingTop
            markStrings.append(CATextLayer.initWithFrame(CGRect.init(x: 0, y: startY - _config.tagFontSize, width: 40, height: _config.tagFontSize) , _config.tagFontSize, self._config.tagFontColor))
        }
        let linePath = UIBezierPath.drawLines(points)
        let lineLayer = CAShapeLayer.drawLayer(drawBoardView.bounds, linePath, _config.seperatorColor, .clear, false, 1)
        self.drawBoardView.layer.addSublayer(lineLayer)
        
        markStrings.forEach { textLayer in
            self.contentView.layer.addSublayer(textLayer)
        }
    }
    
    /// 手势进行监听
    fileprivate func observerGesture() {
        

        
    }
}
