//
//  KLineDelegate.swift
//  Kline_Example
//
//  Created by yaxun on 2019/1/9.
//  Copyright © 2019 CocoaPods. All rights reserved.
//
import UIKit


protocol BaseKLineModel {
    var time: TimeInterval { get set }
    /// 开盘价
    var openingPrice: CGFloat { get set }
    /// 收盘价
    var closingPrice: CGFloat { get set }
    /// 最高价
    var highestPrice: CGFloat { get set }
    /// 最低价
    var lowestPrice: CGFloat { get set }
    /// 成交额
    var volume: CGFloat { get set }
    /// 涨跌幅
    var quoteChange: CGFloat { get set }
    /// 涨跌额
    var riseAndFall: CGFloat { get set }
}


protocol KLineDelegate {
    /// 长按屏幕
    func longPress(_ view: KLineView, _ index: Int, _ position: CGPoint, _ price: CGFloat?, _ isBegan: Bool, _ isEnd: Bool)
    /// 伸缩
    func scale(_ view: KLineView, _ scale: CGFloat, _ began: Int, _ end: Int, _ candleW: CGFloat)
    
}

protocol KLineDataSource {

    /// 一共多少个蜡烛图
    func numberOfCandles(_ view: KLineView) -> Int
    /// 初始化绘制的开始下标
    func startRenderIndex(_ view: KLineView) -> Int
    /// 当前显示的蜡烛图复权模型
    func currentCandlesType(_ view: KLineView) -> KlineAdjustType
    /// 返回将要显示的蜡烛图模型
    func willShowCandles(_ view: KLineView, _ begin: Int, _ end: Int) -> [BaseKLineModel]

}

