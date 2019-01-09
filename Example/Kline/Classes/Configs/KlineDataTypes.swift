//
//  KlineDataTypes.swift
//  Kline_Example
//
//  Created by yaxun on 2019/1/9.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

/// 指标类型
enum KlineIndicatorType {
    case vol            // 成交量
    case macd
    case kdj
    case rsi
}

/// 股票股息调整类型
enum KlineAdjustType {
    case unadjust       // 不复权
    case before         // 前复权
    case after          // 后复权
}

