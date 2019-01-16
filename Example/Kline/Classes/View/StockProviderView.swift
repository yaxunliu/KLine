
//
//  KLineWrapperView.swift
//  Kline_Example
//
//  Created by yaxun on 2019/1/14.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

public enum StcokLineType {
    case minute
    case kline
}


class StockProviderView: UIView {

    /// 滚动的视图
    fileprivate lazy var contentScroll: UIScrollView = {
        let scroll = UIScrollView.init()
        scroll.backgroundColor = KLineConfig.shareConfig.bgColor
        return scroll
    }()
    /// 开始缩放时的中心index
    fileprivate var _beganScaleCenterIndex: Int = 0
    /// 记录上一次缩放的比例
    fileprivate var preScale: CGFloat = 1
    /// 是否正在缩放
    fileprivate var isScaling: Bool = false
    /// 最小缩放比
    fileprivate let _minScale: CGFloat = 0.4
    /// 最大缩放比
    fileprivate let _maxScale: CGFloat = 1
    /// 开始拖拽的offset
    fileprivate var _beganOffset: CGPoint = .zero
    /// 内容宽度
    fileprivate var contentSize: CGSize = .zero
    /// 开始的位置
    fileprivate var _beginCandleIndex: Int = 0
    /// 当前绘制的第一个下标
    fileprivate var candleIndex: Int = -1
    /// 十字线layer
    fileprivate var crossLineLayer: CAShapeLayer? = nil
    /// 数据源协议
    var dataSource: StockProviderViewDataSource? = nil
    /// 当前k线最大的绘制开始下标
    fileprivate var _maxDrawIndex: Int = 0
    /// 默认视图
    fileprivate lazy var klineView: StockBaseLineView = {
        return StockBaseLineView.init(KLineConfig.shareConfig, _isHorizon)
    }()
    /// 股票的类型
    fileprivate var type: StcokLineType = .kline
    
    // MARK: 计算属性
    /// 蜡烛图的宽度 (动态变化, 会随着手势变化而变化)
    var candleWidth: CGFloat {
        get {
            return self.klineView.drawboardWidth / CGFloat(self._candlesOfScreen)
        }
    }
    /// 当前屏幕绘制的蜡烛数量 (动态变化 随着缩放值变化而变化)
    var _candlesOfScreen: Int {
        get {
            return self.candlesOfScale(self._scale)
        }
    }
    /// 子组件(指标视图)
    fileprivate var components: [StockComponent] = []
    /// 开始拖拽的点
    fileprivate var beginPanPoint: CGPoint = .zero
    
    fileprivate var _scale: CGFloat = 0.5 {
        didSet {
            self.recaculateContentSize()
        }
    }
    fileprivate var _candlesCount: Int = 0 {
        didSet {
            self.recaculateContentSize()
        }
    }
    fileprivate let _isHorizon: Bool
    
    init(_ lineBounds: CGRect, _ isHorizon: Bool, _ scale: CGFloat, _ componets: [StockComponent]) {
        self._isHorizon = isHorizon
        self._scale = scale
        self.components = componets
        super.init(frame: .zero)
        self.klineView.frame = lineBounds
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if contentScroll.superview != nil { return }
        if self.constraints.count > 0 && self.frame.width == 0 || self.frame.height == 0 {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        setupUI()
        observerGesture()
    }
    
    fileprivate func setupUI() {
        contentScroll.addSubview(klineView)
        contentScroll.frame = self.bounds
        contentScroll.contentSize = contentScroll.bounds.size
        self.addSubview(contentScroll)
    }
    
    /// 手势进行监听
    fileprivate func observerGesture() {
        let longTap = UILongPressGestureRecognizer.init(target: self, action: #selector(longtap))
        self.addGestureRecognizer(longTap)
        let pinch = UIPinchGestureRecognizer.init(target: self, action: #selector(scaleScroll))
        self.addGestureRecognizer(pinch)
        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(panScroll))
        self.addGestureRecognizer(pan)
    }
    
    
    
}
//
extension StockProviderView {
    
    /// 刷新数据
    public func reloadData() {
        guard let type = dataSource?.providerDataType(self) else { return }
        self.type = type
        self.crossLineLayer?.removeFromSuperlayer()
        self.crossLineLayer = nil
        if type == .kline {
            guard let count = dataSource?.numberOfCandles(self) else { return }
            self._candlesCount = count
            if self.candleIndex >= 0 {
                self.willDrawCandle(self.candleIndex, self.caculateEndIndex())
            } else {
                self.willDrawCandle(self._maxDrawIndex, count - 1)
            }
        } else {
            guard let minutes = dataSource?.loadMinuteData(self) else { return }
            self.klineView.reloadMinute(82.00, minutes)
        }
        
        self.updateComponents()
    }
    
    fileprivate func updateComponents() {
        self.recaculateContentSize()
        var preY: CGFloat = self.klineView.bounds.height
        self.components.forEach { component in
            component.frame = CGRect.init(x: 0, y: preY, width: component.bounds.width, height: component.bounds.height)
            preY += component.bounds.height
            if component.superview == nil {
                self.contentScroll.addSubview(component)
            }
        }
    }
    

    /// 插入子视图
    public func insertComponent(_ c: StockComponent) {
        self.components.append(c)
        updateComponents()
        self.willDrawCandle(self.candleIndex, caculateEndIndex())
        let offsetY = self.contentScroll.contentSize.height - self.contentScroll.bounds.height
        self.contentScroll.setContentOffset(CGPoint.init(x: 0, y: offsetY), animated: true)
    }
    
    /// 移除子视图
    public func deleteSubview(_ c: StockComponent) {
        guard let index = components.firstIndex(of: c) else { return }
        components.remove(at: index)
        self.recaculateContentSize()
        let offsetY = self.contentScroll.contentSize.height - self.contentScroll.bounds.height
        self.contentScroll.setContentOffset(CGPoint.init(x: 0, y: offsetY), animated: true)
    }
    
    /// 计算当前结尾下标
    fileprivate func caculateEndIndex() -> Int {
        let end = self.candleIndex + self._candlesOfScreen - 1
        if end > self._candlesCount - 1 {
            return self._candlesCount - 1
        }
        return end
    }
    
    /// 即将绘制的k线模型
    fileprivate func willDrawCandle(_ began: Int, _ end: Int) {
        self.candleIndex = began
        guard let models = dataSource?.willShowCandles(self, began, end) else { return }
        self.klineView.reloadData(self._candlesOfScreen, self.candleWidth, models, self._scale == self._minScale, self._scale)
        self.components.forEach { c in
            c.reloadData(self._candlesOfScreen, self.candleWidth, models, self._scale == self._minScale, self._scale)
        }
    }
    
    fileprivate func transform(_ tx: CGFloat) {
        self.klineView.transform(tx)
        self.components.forEach { c in
            c.transform(tx)
        }
    }
}



extension StockProviderView {
    /// 重新计算
    fileprivate func recaculateContentSize() {
        if self._candlesCount == 0 { return }
        var width = self.candleWidth * CGFloat(self._candlesCount + 1)
        if width <= self.contentScroll.bounds.width {
            width = self.contentScroll.bounds.width + 0.5
            self._maxDrawIndex = 0
        } else {
            self._maxDrawIndex = self._candlesCount + 1 - self._candlesOfScreen
        }
        let height = components.reduce(self.klineView.bounds.height) { (height, view) -> CGFloat in
            return height + view.bounds.height
        }
        
        self.contentSize = CGSize.init(width: width, height: 0)
        self.contentScroll.contentSize = CGSize.init(width: self.contentScroll.bounds.width, height: height)
    }
    
    /// 计算当前屏幕能绘制多少蜡烛图根据缩放比来计算
    fileprivate func candlesOfScale(_ scale: CGFloat) -> Int {
        if _isHorizon {
            return Int(-25 * scale + 105)
        }
        return Int(-266 * scale + 286)
    }
}

// MARK: 手势监听
extension StockProviderView {
    /// 长按手势监听
    @objc fileprivate func longtap(_ event: UILongPressGestureRecognizer) {
        let p = event.location(in: self.contentScroll)
        let paddingLeft = self.klineView.contentInset.left
        var offsetx = p.x - paddingLeft
        if offsetx < 0 {
            offsetx = 0
        } else if offsetx > self.klineView.maxBorderX {
            offsetx = self.klineView.maxBorderX
        }
        self.crossLineLayer?.removeFromSuperlayer()
        self.crossLineLayer = nil
        var touchX: CGFloat = 0
        self.touchYLocation(p)
        if self.type == .kline {
            touchX = self.touchXLocation(offsetx, self.candleWidth, paddingLeft, self.klineView.contentInset.right)
        } else {
            touchX = self.touchXLocation(offsetx, self.klineView.candleW, paddingLeft, self.klineView.contentInset.right)
        }
        let crossLinePath = UIBezierPath.drawLines([(CGPoint.init(x: touchX, y: 0), CGPoint.init(x: touchX, y: self.contentScroll.contentSize.height))])
        self.crossLineLayer = CAShapeLayer.drawLayer(CGRect.init(x: 0, y: 0, width: self.contentScroll.bounds.width, height: self.contentScroll.contentSize.height) , crossLinePath, KLineConfig.shareConfig.tagFontColor, false, 1)
        self.contentScroll.layer.addSublayer(self.crossLineLayer!)
        switch event.state {
        case .ended:
            self.crossLineLayer?.removeFromSuperlayer()
            self.crossLineLayer = nil
            break
        default:
            break
        }
    }
    
    fileprivate func touchXLocation(_ offsetx: CGFloat, _ candleW: CGFloat, _ paddingLeft: CGFloat, _ paddingRight: CGFloat) -> CGFloat {
        var touchX: CGFloat = 0
        let index = Int(offsetx / candleW)
        touchX = (CGFloat(index) + 0.5) * candleW + paddingLeft
        let minX = paddingLeft + candleW * 0.5
        let maxX = self.klineView.maxBorderX + paddingLeft
        if touchX < minX {
            touchX = minX
        } else if touchX > maxX {
            touchX = maxX
        }
        return touchX
    }
    
    fileprivate func touchYLocation(_ p: CGPoint) -> CGFloat {
        let contains = self.klineView.point(inside: p, with: nil)
        if contains {
           self.klineView
        }
        
    }
    
    
    /// 手势缩放
    @objc func scaleScroll(_ event: UIPinchGestureRecognizer) {
        let p = event.location(in: self.contentScroll)
        let canScale = self.caculateScale(event)
        if !canScale { return }
        if self.type != .kline { return }
        self.preScale = event.scale
        switch event.state {
        case .began:
            self.isScaling = true
            /// 2.计算出将要缩放的点
            _beganScaleCenterIndex = self.candleIndex + Int(p.x / self.candleWidth)
            break
        case .changed:
            self.isScaling = true
            /// 3.计算出缩放的开始位置和结束位置
            self.reloadScale(p)
            break
        case .ended:
            self.isScaling = false
            self.preScale = 1
            break
        default:
            self.isScaling = false
            break
        }
    }
    /// 计算比例来判断是否可以继续缩放s或者扩大
    fileprivate func caculateScale(_ event: UIPinchGestureRecognizer) -> Bool {
        let targetScale = self._scale + (event.scale - self.preScale > 0 ? 0.006 : -0.006)
        if targetScale < self._minScale {
            if self._scale == self._minScale {
                self.isScaling = false
                return false
            }
            self._scale = self._minScale
        } else if targetScale > self._maxScale {
            if self._scale == self._maxScale {
                self.isScaling = false
                return false
            }
            self._scale = self._maxScale
        } else {
            self._scale = targetScale
        }
        return true
    }
    
    /// 刷新手势缩放
    fileprivate func reloadScale(_ position: CGPoint) {
        var began = _beganScaleCenterIndex - self._candlesOfScreen / 2
        if began < 0 { began = 0 }
        var end = self._candlesOfScreen + began - 1
        if end > self._candlesCount - 1 {
            end = self._candlesCount - 1
            began = end + 1 - self._candlesOfScreen
            if began < 0 { began = 0 }
        }
        self.willDrawCandle(began, end)
    }
    /// 开始拖动
    @objc fileprivate func panScroll(_ pan: UIPanGestureRecognizer) {
        let p = pan.location(in: self)
        let offset = p.x - self.beginPanPoint.x
        switch pan.state {
        case .began:
            self.beginPanPoint = p
            self._beginCandleIndex = self.candleIndex
            break
        case .changed:
            if self.type == .kline {
                let offsetIndex = Int(offset / self.candleWidth)
                let begin = self._beginCandleIndex - offsetIndex
                self.handlePan(begin, offset)
            } else {
                self.klineView.transform(offset * 0.5)
            }
            break
        case .ended:
            if self.type == .kline {
                let offsetIndex = Int(offset / self.candleWidth)
                let begin = self._beginCandleIndex - offsetIndex
                if begin > self._maxDrawIndex || begin < 0 {
                    endPan()
                }
            } else {
                endPan()
            }
            break
        default:
            break
        }
    }
    /// 结束拖动
    fileprivate func endPan() {
        UIView.animate(withDuration: 0.5) {
            self.klineView.transform(0)
            self.components.forEach { c in
                c.transform(0)
            }
        }
    }
    /// 将要比最小值要小了
    fileprivate func willBoundsOfRange(_ offset: CGFloat) {
        self.klineView.transform(offset * 0.5)
        self.components.forEach { c in
            c.transform(offset * 0.5)
        }
    }
    /// 处理拖拽
    fileprivate func handlePan(_ begin: Int, _ offset: CGFloat) {
        if begin > self._maxDrawIndex {
            if self.candleIndex != self._maxDrawIndex {
                self.willDrawCandle(self._maxDrawIndex, self._candlesCount - 1)
            }
            self.willBoundsOfRange(offset)
        } else if begin < 0 {
            if self.candleIndex != 0 {
                self.willDrawCandle(0, self._candlesOfScreen)
            }
            self.willBoundsOfRange(offset)
        } else {
            let end = begin + self._candlesOfScreen - 1
            if begin == self._maxDrawIndex {
                self.willDrawCandle(self._maxDrawIndex, self._candlesCount - 1)
            } else {
                self.willDrawCandle(begin, end)
            }
        }
        
    }
}
