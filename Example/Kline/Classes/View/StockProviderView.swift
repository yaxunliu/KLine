
//
//  KLineWrapperView.swift
//  Kline_Example
//
//  Created by yaxun on 2019/1/14.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class StockProviderView: UIView {
    /// 最外层的视图
    fileprivate lazy var contentView: UIScrollView = {
        let contentView = UIScrollView.init(frame: .zero)
        contentView.layer.masksToBounds = true
        return contentView
    }()
    /// 滚动的视图
    fileprivate lazy var contentScroll: UIScrollView = {
        let scroll = UIScrollView.init()
        scroll.delegate = self
//        scroll.showsVerticalScrollIndicator = false
//        scroll.showsHorizontalScrollIndicator = false
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
    /// 当前绘制的第一个下标
    fileprivate var candleIndex: Int = 0 {
        didSet {
            self.contentScroll.setContentOffset(CGPoint.init(x: CGFloat(self.candleIndex) * self.candleWidth, y: 0), animated: false)
        }
    }
    
    /// 数据源协议
    var dataSource: StockProviderViewDataSource? = nil
    /// 当前k线最大的绘制开始下标
    fileprivate var _maxDrawIndex: Int = 0
    /// 默认视图
    fileprivate lazy var klineView: StockLineView = { return StockLineView.init(KLineConfig.shareConfig, self._isHorizon) }()
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
    fileprivate var components: [UIView] = []
    
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
    
    init(_ isHorizon: Bool, _ scale: CGFloat) {
        self._isHorizon = isHorizon
        self._scale = scale
        super.init(frame: .zero)
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
        observerGesture()
    }
    
    fileprivate func setupUI() {
        contentView.frame = self.bounds
        contentScroll.frame = self.bounds
        self.addSubview(contentView)
        self.addSubview(contentScroll)
        self.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        contentView.contentSize = self.bounds.size
        klineView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 230)
        contentView.addSubview(klineView)
    }
    
    /// 手势进行监听
    fileprivate func observerGesture() {
        let longTap = UILongPressGestureRecognizer.init(target: self, action: #selector(longtap))
        self.addGestureRecognizer(longTap)
        let pinch = UIPinchGestureRecognizer.init(target: self, action: #selector(scaleScroll))
        self.addGestureRecognizer(pinch)
    }
    
}
//
extension StockProviderView {
    /// 刷新数据
    public func reloadData() {
        /// 计算contentSize
        guard let count = dataSource?.numberOfCandles(self) else { return }
        self._candlesCount = count
        self.willDrawCandle(self._maxDrawIndex, count - 1)
    }

    /// 插入子视图
    public func insertSubview() {

    }
    
    /// 移除子视图
    public func deleteSubview() {
    
    }
    
    fileprivate func willDrawCandle(_ began: Int, _ end: Int) {
        self.candleIndex = began
        guard let models = dataSource?.willShowCandles(self, began, end) else { return }
        self.klineView.reloadData(self._candlesOfScreen, self.candleWidth, models, self._scale == self._minScale, self._scale)
    }
}

extension StockProviderView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.isScaling { return }
        let offsetx = scrollView.contentOffset.x
        let beginIndex = Int((offsetx / self.candleWidth).rounded())
        if offsetx < 0 { // 往右边偏移
            self.klineView.transform(-offsetx)
            if self.candleIndex == 0 { return }
            var end: Int = self._candlesOfScreen - 1
            if end >= self._candlesCount {
                end = self._candlesCount - 1
            }
            self.willDrawCandle(0, end)
        } else if offsetx >= scrollView.contentSize.width - scrollView.bounds.width { // 往左边偏移
            self.klineView.transform(-(offsetx + scrollView.bounds.width - scrollView.contentSize.width))
            if self.candleIndex == self._maxDrawIndex { return }
            self.willDrawCandle(self._maxDrawIndex, self._candlesCount - 1)
        } else {
            if beginIndex == self.candleIndex { return }
            var endIndex = beginIndex + self._candlesOfScreen
            endIndex = endIndex >= self._candlesCount ? self._candlesCount - 1 : endIndex
            self.willDrawCandle(beginIndex, endIndex)
        }
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x < 0 || scrollView.contentOffset.x + scrollView.bounds.width > scrollView.contentSize.width { return }
        scrollView.setContentOffset(CGPoint.init(x: CGFloat(self.candleIndex) * candleWidth, y: 0), animated: false)
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
        self.contentScroll.contentSize = CGSize.init(width: width, height: height)
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
//        let p = event.location(in: self.drawBoardView)
//        var index = Int(p.x / self.candleWidth)
//        if index < 0 {
//            index = self.candleIndex
//        } else if index > self._candlesOfScreen - 1 {
//            index = self._candlesOfScreen - 1 + self.candleIndex
//        } else {
//            index += self.candleIndex
//        }
//        if index > self._candlesCount - 1 {
//            index = self._candlesCount - 1
//        }
    }
    
    /// 手势缩放
    @objc func scaleScroll(_ event: UIPinchGestureRecognizer) {
        let p = event.location(in: self.contentView)
        let canScale = self.caculateScale(event)
        if !canScale { return }
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
}
