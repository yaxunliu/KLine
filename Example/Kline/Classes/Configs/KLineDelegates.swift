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

protocol BaseIndexLineModel {
    var time: TimeInterval { get set }
    var indexDict: [String : CGFloat] { get set }
}


protocol KLineDelegate {
    /// 长按屏幕
    func longPress(_ view: KLineView, _ index: Int, _ position: CGPoint, _ price: CGFloat?, _ isBegan: Bool, _ isEnd: Bool)
    /// 伸缩
    func scale(_ view: KLineView, _ scale: CGFloat, _ began: Int, _ end: Int, _ candleW: CGFloat)
    /// 开始展示
    func showCandles(_ view: KLineView, _ models: [BaseKLineModel])
    /// 偏移
    func transform(_ view: KLineView, _ tx: CGFloat)
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


protocol IndexLineDataSource {
    /// 需要绘制的指标名称
    func namesOfIndexLines(_ view: IndexLineView) -> [String]
    /// 初始化绘制的开始下标
    func startRenderIndex(_ view: IndexLineView) -> Int
    /// 将要渲染的折线的模型
    func willRenderLines(_ view: IndexLineView) -> [BaseIndexLineModel]
    /// 该指标是否渲染为折线 (或者柱状图)
    func isRenderLine(_ view: IndexLineView, _ indexName: String) -> Bool
    /// y轴坐标的值是固定还是自由分配
    func indexRefrenceSystemType(_ view: IndexLineView) -> IndexRefrenceSystem
}


protocol StockProviderViewDataSource {
    func numberOfCandles(_ view: StockProviderView) -> Int
    /// 返回将要显示的蜡烛图模型
    func willShowCandles(_ view: StockProviderView, _ begin: Int, _ end: Int) -> [BaseKLineModel]
}




protocol KLineWrapperDelegate {
    /// 手势缩放 刷新
    func reloadData(_ nums: Int, _ candleWidth: CGFloat, _ datas: [BaseKLineModel], _ isMin: Bool, _ scale: CGFloat)
    /// 长按手势的时候对应的y值
    func longPress(_ p: CGPoint) -> CGFloat

}

