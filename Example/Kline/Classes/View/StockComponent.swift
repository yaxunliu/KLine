//
//  StockComponent.swift
//  Kline_Example
//
//  Created by yaxun on 2019/1/15.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class StockComponent: UIView, StockComponentDelegate {
    /// 内边距
    var contentInset: UIEdgeInsets = UIEdgeInsets.init(top: 24, left: 10, bottom: 10, right: 10)
    /// 平均值
    fileprivate var averageY: CGFloat = 0
    /// 内容
    lazy var contentView: UIView = {
        let v = UIView.init()
        v.layer.masksToBounds = true
        return v
    }()
    /// 画板
    lazy var drawBoardView: UIView = {
        let board = UIView.init()
        board.layer.masksToBounds = true
        return board
    }()
    /// y轴值
    var markString: [CATextLayer] = []
    /// 指标线名称
    let indexNames: [String]
    init(_ bounds: CGRect, _ indexs: [String]) {
        indexNames = indexs
        super.init(frame: bounds)
        setupUI()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        addSubview(contentView)
        contentView.frame = CGRect.init(x: contentInset.left, y: 0, width: self.bounds.width - contentInset.left - contentInset.right, height: self.bounds.height )
        drawBoardView.frame = CGRect.init(x: 0, y: contentInset.top, width: contentView.bounds.width, height: self.bounds.height - contentInset.top - contentInset.bottom)
        contentView.addSubview(drawBoardView)
        /// 绘制边框
        let borderPath = UIBezierPath.drawRect(nil, drawBoardView.frame)
        self.contentView.layer.addSublayer(CAShapeLayer.drawLayer(self.contentView.bounds, borderPath, KLineConfig.shareConfig.seperatorColor, false, 1))
        self.setupMarks()
    }
    
    func setupMarks() {
        self.markString = [
            CATextLayer.initWithFrame(CGRect.init(x: self.drawBoardView.frame.minX, y: self.drawBoardView.frame.minY, width: 100, height: KLineConfig.shareConfig.tagFontSize) , KLineConfig.shareConfig.tagFontSize, KLineConfig.shareConfig.tagFontColor, "0.00"),
            CATextLayer.initWithFrame(CGRect.init(x: self.drawBoardView.frame.minX, y: self.drawBoardView.frame.midY - KLineConfig.shareConfig.tagFontSize * 0.5, width: 100, height: KLineConfig.shareConfig.tagFontSize) , KLineConfig.shareConfig.tagFontSize, KLineConfig.shareConfig.tagFontColor, "0.00"),
            CATextLayer.initWithFrame(CGRect.init(x: self.drawBoardView.frame.minX, y: self.drawBoardView.frame.maxY - KLineConfig.shareConfig.tagFontSize, width: 100, height: KLineConfig.shareConfig.tagFontSize) , KLineConfig.shareConfig.tagFontSize, KLineConfig.shareConfig.tagFontColor, "0.00")]
        self.markString.forEach{ self.contentView.layer.addSublayer($0) }
    }
    
    func reloadData(_ nums: Int, _ candleWidth: CGFloat, _ datas: [BaseKLineModel], _ isMin: Bool, _ scale: CGFloat) {
        
    }
    
    func touchLocationY(_ p: CGPoint) -> CGFloat? {
        return nil
    }
    func transform(_ tx: CGFloat) {
        self.drawBoardView.transform = CGAffineTransform.init(translationX: tx, y: 0)
    }
}
extension StockComponent {
    
    fileprivate func lineColor(_ name: String) -> UIColor {
        var lineColors: [String : UIColor] = [
            "k": UIColor.init(red: 190 / 255.0, green: 120 / 255.0, blue: 46 / 255.0, alpha: 1),
            "d": UIColor.init(red: 47 / 255.0, green: 165 / 255.0, blue: 206 / 255.0, alpha: 1),
            "j": UIColor.init(red: 208 / 255.0, green: 126 / 255.0, blue: 187 / 255.0, alpha: 1),
            ]
        return lineColors[name] ?? .red
    }
    
}
