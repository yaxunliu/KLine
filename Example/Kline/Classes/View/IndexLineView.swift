//
//  IndexLineView.swift
//  Kline_Example
//
//  Created by yaxun on 2019/1/11.
//  Copyright © 2019 CocoaPods. All rights reserved.
//  指标折线图

import UIKit


/// 参考系坐标值
///
/// - fixed: 固定
/// - free: 自由
enum IndexRefrenceSystem {
    case fixed(_ min: Int, _ max: Int)
    case free
}


class IndexLineView: UIView {
    /// 内边距 (需要去适配屏幕大小)
    var contentInset: UIEdgeInsets = UIEdgeInsets.init(top: 24, left: 10, bottom: 10, right: 10)
    var dataSource: IndexLineDataSource?
    /// 最外层的视图
    fileprivate lazy var contentView: UIView = {
        let contentView = UIView.init(frame: .zero)
        return contentView
    }()
    
    fileprivate lazy var drawBoardView: UIView = {
        let contentView = UIView.init(frame: .zero)
        return contentView
    }()
    
    /// 配置文件
    fileprivate let _config: IndexLineConfig
    /// 指数类型
    fileprivate var _type: IndexRefrenceSystem = .free
    /// 一个屏幕有多少蜡烛图
    fileprivate var _numsOfScreen: Int = 0
    /// 宽度
    fileprivate var _candleWidth: CGFloat = 0
    /// 指标名称
    fileprivate var _indexNames: [String] = []
    /// 最大值
    fileprivate var _highest: CGFloat = 0
    /// 最小值
    fileprivate var _lowest: CGFloat = 0
    /// 坐标标记文字
    fileprivate var _textLayers: [CATextLayer] = []
    /// 需要延迟刷新的操作
    fileprivate var lazyOperation: ((CGFloat) -> ())?

    
    init(_ config: IndexLineConfig) {
        _config = config
        super.init(frame: .zero)
        self.backgroundColor = UIColor.init(red: 0.9, green: 0.9, blue: 0.98, alpha: 1)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("initinal error")
    }
    
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if contentView.superview != nil { return }
        if self.constraints.count > 0 && self.frame.width == 0 || self.frame.height == 0 {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        setupUI()
        observerGesture()
    }
    
    fileprivate func setupUI() {
        contentView.frame = CGRect.init(x: self.contentInset.left, y: self.contentInset.top, width: self.bounds.width - self.contentInset.left - self.contentInset.right, height: self.bounds.height - self.contentInset.top - self.contentInset.bottom)
        addSubview(contentView)
        drawBoardView.frame = contentView.bounds
        contentView.addSubview(drawBoardView)
        
        let borderPath = UIBezierPath.drawRect(nil, contentView.bounds)
        let borderLayer = CAShapeLayer.drawLayer(contentView.bounds, borderPath, self._config.seperatorColor, true, 1)
        contentView.layer.addSublayer(borderLayer)
        
        /// 1.绘制横轴
        _type = dataSource?.indexRefrenceSystemType(self) ?? .free
        switch _type {
        case .fixed(let min, let max):
            self._highest = CGFloat(max)
            self._lowest = CGFloat(min)
            let path = UIBezierPath.drawLines([(CGPoint.init(x: 0, y: contentView.bounds.height / 10 * 2), CGPoint.init(x: contentView.bounds.width, y: contentView.bounds.height / 10 * 2)), (CGPoint.init(x: 0, y: contentView.bounds.height / 10 * 5), CGPoint.init(x: contentView.bounds.width, y: contentView.bounds.height / 10 * 5)), (CGPoint.init(x: 0, y: contentView.bounds.height / 10 * 8), CGPoint.init(x: contentView.bounds.width, y: contentView.bounds.height / 10 * 8))])
            let texts = [CATextLayer.initWithFrame(CGRect.init(x: 0, y: contentView.bounds.height / 10 * 2 - self._config.tagFontSize * 1.2 , width: 100, height: self._config.tagFontSize) , self._config.tagFontSize, self._config.tagFontColor, String.init(format: "%.02d", max / 10 * 2)),
                         CATextLayer.initWithFrame(CGRect.init(x: 0, y: contentView.bounds.height / 10 * 5 - self._config.tagFontSize * 1.2, width: 100, height: self._config.tagFontSize) , self._config.tagFontSize, self._config.tagFontColor, String.init(format: "%.02d", max / 10 * 5)),
                         CATextLayer.initWithFrame(CGRect.init(x: 0, y: contentView.bounds.height / 10 * 8 - self._config.tagFontSize * 1.2, width: 100, height: self._config.tagFontSize) , self._config.tagFontSize, self._config.tagFontColor, String.init(format: "%.02d", max / 10 * 8))]
            let shape = CAShapeLayer.drawLayer(contentView.bounds, path, self._config.tagFontColor, true, 1, .clear, true)
            contentView.layer.addSublayer(shape)
            texts.forEach { text in
                contentView.layer.addSublayer(text)
            }
            break
        default:
            break
        }
        
        // 2.绘制y轴 显示
        _textLayers = [CATextLayer.initWithFrame(CGRect.init(x: 0, y: self.contentView.bounds.height * 0, width: 100, height: self._config.tagFontSize) , self._config.tagFontSize, self._config.tagFontColor),
         CATextLayer.initWithFrame(CGRect.init(x: 0, y: self.contentView.bounds.height * 0.45, width: 100, height: self._config.tagFontSize) , self._config.tagFontSize, self._config.tagFontColor),
         CATextLayer.initWithFrame(CGRect.init(x: 0, y: self.contentView.bounds.height - self._config.tagFontSize - 2, width: 100, height: self._config.tagFontSize) , self._config.tagFontSize, self._config.tagFontColor)]
        
        _textLayers.forEach { text in
            self.contentView.layer.addSublayer(text)
        }
        
        // 3.处理延时操作
        if self.lazyOperation != nil {
            self.lazyOperation!(self.contentView.bounds.height / (self._highest - self._lowest))
        }
    }
    
    fileprivate func observerGesture() {
        
    }
    
}

extension IndexLineView {
    
    func reloadData(_ numbers: Int, _ width: CGFloat) {
        if self.contentView.bounds.height == 0 {
            self.contentView.setNeedsLayout()
            self.contentView.layoutIfNeeded()
        }
        drawBoardView.layer.sublayers?.forEach({ layer in
            layer.removeFromSuperlayer()
        })
        _numsOfScreen = numbers
        _candleWidth = width
        guard let indexs = dataSource?.namesOfIndexLines(self) else { return }
        guard let models = dataSource?.willRenderLines(self) else { return }
        var _min: CGFloat = 0
        var _max: CGFloat = 0
        let linesValue = indexs.map { index -> [String:[CGFloat]] in
            let values = models.map{ $0.indexDict[index] ?? 0.0 }
            let minValue = values.min() ?? 0
            let maxValue = values.max() ?? 0
            if minValue < _min { _min = minValue }
            if maxValue > _max { _max = maxValue }
            return [index: values]
        }
        switch self._type {
        case .free:
            self._highest = _max > 0 ? _max * 1.2 : _max * 0.8
            self._lowest = _min > 0 ? _min * 0.1 : _min * 2
            break
        default:
            break
        }
        let texts = [String.init(format: "%.02f", self._highest), String.init(format: "%.02f", (self._highest - self._lowest) / 2), String.init(format: "%.02f", self._lowest)]
        zip(texts, _textLayers).forEach { (str, layer) in
            layer.string = str
        }
        
        if self.contentView.bounds.height == 0 {
            self.lazyOperation = { (height: CGFloat) in
                linesValue.forEach { dict in
                    guard let key = dict.keys.first else { return }
                    guard let value = dict[key] else { return }
                    self.drawLines(key, value, height)
                }
            }
            return
        }
        
        let averageH = self.contentView.bounds.height / (self._highest - self._lowest)
        linesValue.forEach { dict in
            guard let key = dict.keys.first else { return }
            guard let value = dict[key] else { return }
            self.drawLines(key, value, averageH)
        }
    }
    
    fileprivate func drawLines(_ indexName: String, _ v: [CGFloat], _ averageH: CGFloat) {
        let points = v.enumerated().map { (index, value) -> CGPoint in
            let x = (CGFloat(index) + 0.5) * self._candleWidth
            let y = (self._highest - value) * averageH
            return CGPoint.init(x: x, y: y)
        }
        let color = self._config.lineColors[indexName] ?? .red
        let path = UIBezierPath.drawLinePath(nil, points)
        let layer = CAShapeLayer.drawLayer(self.contentView.bounds, path, color, true, 1)
        self.drawBoardView.layer.addSublayer(layer)
    }
    
    
}
