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
    /// 指标数据
    var indexDict: [String : CGFloat] { get set }
    /// 指标的颜色
    var indexColor: [String: UIColor] { get set }
}

protocol BaseKlineMinuteModel {
    var time: TimeInterval { get set }
    var minutePrice: CGFloat { get set }
    var volume: CGFloat { get set }
}


protocol StockProviderViewDataSource {
    func numberOfCandles(_ view: StockProviderView) -> Int
    func willShowCandles(_ view: StockProviderView, _ begin: Int, _ end: Int) -> [BaseKLineModel]
    func providerDataType(_ view: StockProviderView) -> StcokLineType
    func loadMinuteData(_ view: StockProviderView) -> [KLineMinuteModel]
}

protocol StockComponentDelegate {
    /// 手势缩放 刷新
    func reloadData(_ nums: Int, _ candleWidth: CGFloat, _ datas: [BaseKLineModel], _ isMin: Bool, _ scale: CGFloat)
    /// 长按手势的时候对应的y值
    func touchLocationY(_ p: CGPoint) -> CGFloat?
    /// 偏移
    func transform(_ tx: CGFloat)

}
