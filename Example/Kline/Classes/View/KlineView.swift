//
//  KlineView.swift
//  Kline_Example
//
//  Created by yaxun on 2018/7/19.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit

class KlineView: UIView {
    
    var timeModels: [KlineTimeModel] = [] {
        didSet {
            drawTimeLine()
        }
    }
    fileprivate var _lastPoint = CGPoint.zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(pan(_:)))
        pan.delaysTouchesBegan = true
        addGestureRecognizer(pan)
        
        self.backgroundColor = UIColor.lightGray

        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    lazy var _timelayer: CALayer = {
        let layer = CALayer.init()
        layer.frame = self.bounds
        layer.backgroundColor = UIColor.clear.cgColor
        self.layer.addSublayer(layer)
        return layer
    }()
    

    
    
    
    
}


/// 分时图
extension KlineView {
    @objc func pan(_ pan: UIPanGestureRecognizer) {
        let currentPoint = pan.location(in: self)
        if _lastPoint.x != 0 {
            let moveDistance = (currentPoint.x - _lastPoint.x) * 0.8
            self._timelayer.frame = CGRect(x: self._timelayer.frame.origin.x + moveDistance, y: 0, width: self.frame.width, height: self.frame.height)
        }
        if pan.state == .ended {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.3)
            self._timelayer.frame.origin = .zero
            CATransaction.commit()
            _lastPoint = .zero
        } else if pan.state == .began {
            print("begin")
        } else if pan.state == .cancelled {
            print("cacel")
        } else if pan.state == .changed {
            print("changed")
            _lastPoint = currentPoint
        }
    }
    
    
    func drawTimeLine() {
        // 1.计算出最大值和最小值
        sort()
        // 2.确定间距和坐标点
        
       
        
        
        
        
        
        
        
        
        
        
        // 3.开始绘制分时线
    }
    
    func sort() {
        let sort = timeModels.sorted { (model1, model2) -> Bool in
            return model1.minutePrice > model2.minutePrice
        }
        let max = sort[0].minutePrice + 0.5
        let min = sort[sort.count - 1].minutePrice - 0.5
        let averagePrice = (max - min) / 8
        self.drawPrice(max: max, min: min, average: averagePrice)
    }
    
    func drawPrice(max: Double, min: Double, average: Double) {
        
        let averageH = (self.frame.height - 30.0) / 8
        let sysfont = UIFont.systemFont(ofSize: 10)
        let fontStr = sysfont.fontName as CFString
        let font = CGFont.init(fontStr)
        for i in 0..<8 {
            let value = max - Double(i) * average
            let priceLayer = CATextLayer.init()
            priceLayer.frame.origin = CGPoint(x: 10, y: averageH * CGFloat(i))
            priceLayer.frame.size = CGSize(width: 50.0, height: 50.0)
            priceLayer.string = "\(value)"
            priceLayer.foregroundColor = UIColor.red.cgColor
            priceLayer.font = font
            priceLayer.fontSize = sysfont.pointSize
            self.layer.addSublayer(priceLayer)
        }
        
        /// 每一分钱 占据的高度
        let height = (Double(self.frame.height) - 30.0) / (max - min)
        let width = Double(self.frame.width) / Double(timeModels.count)
        
        var points: [CGPoint] = []
        for (index, value) in timeModels.enumerated() {
            let y = (max - value.minutePrice) * height
            let x = width * Double(index)
            points.append(CGPoint(x: x, y: y))
        }
        let shape = CAShapeLayer.init()
        shape.strokeColor = UIColor.red.cgColor
        let path = UIBezierPath.init()
        
        for (index, point) in points.enumerated() {
            if index == 0 {
                path.move(to: point)
                continue
            }
            path.addLine(to: point)
        }
        
        shape.path = path.cgPath
        self._timelayer.addSublayer(shape)
        
        
    }
    
    
    
}

