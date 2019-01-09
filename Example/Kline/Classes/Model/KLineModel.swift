//
//  KLineModel.swift
//  Kline_Example
//
//  Created by yaxun on 2019/1/9.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

struct KLineModel: BaseKLineModel {
    var time: TimeInterval
    /// 开盘价
    var openingPrice: CGFloat
    /// 收盘价
    var closingPrice: CGFloat
    /// 最高价
    var highestPrice: CGFloat
    /// 最低价
    var lowestPrice: CGFloat
    /// 成交额
    var volume: CGFloat
    /// 涨跌幅
    var quoteChange: CGFloat
    /// 涨跌额
    var riseAndFall: CGFloat
}
