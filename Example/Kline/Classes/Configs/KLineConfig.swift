//
//  KLineConfig.swift
//  Kline_Example
//
//  Created by yaxun on 2019/1/9.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit


class BaseConfig {
    /// 背景色
    var bgColor: UIColor = UIColor.init(red: 31 / 255.0, green: 34 / 255.0, blue: 44 / 255.0, alpha: 1)
    //    var bgColor: UIColor = UIColor.init(red: 255.0 / 255.0, green: 255.0 / 255.0, blue: 255.0 / 255.0, alpha: 1)
    /// 分割线颜色
    var seperatorColor: UIColor = UIColor.init(red: 31 / 255.0, green: 27 / 255.0, blue: 47 / 255.0, alpha: 1)
    /// 下跌的颜色
    var downColor: UIColor = UIColor.init(red: 0 / 255.0, green: 172 / 255.0, blue: 59 / 255.0, alpha: 1)
    /// 十字线的颜色
    var crossLineColor: UIColor = UIColor.init(red: 143 / 255.0, green: 146 / 255.0, blue: 156 / 255.0, alpha: 1)
    /// 上涨的颜色
    var upColor: UIColor = UIColor.init(red: 234 / 255.0, green: 64 / 255.0, blue: 70 / 255.0, alpha: 1)
    /// 标签类文字的 字体大小
    var tagFontSize: CGFloat = 8
    /// 标签类文字颜色
    var tagFontColor: UIColor = UIColor.init(red: 132 / 255.0, green: 138 / 255.0, blue: 151 / 255.0, alpha: 1)
    /// 标记线颜色
    var markLineColor: UIColor = UIColor.init(red: 238 / 255.0, green: 139 / 255.0, blue: 67 / 255.0, alpha: 1)
}





class KLineConfig: BaseConfig {

    /// 折现颜色
    var lineColor: UIColor = UIColor.init(red: 54 / 255.0, green: 143 / 255.0, blue: 251 / 255.0, alpha: 1)
    /// 上涨的k线图填充色是否透明
    var upFillClear: Bool = false
    /// 下跌的k线图填充色是否透明
    var downFillClear: Bool = false
    /// 竖屏下分割线的数量
    var verticalSeperatorNum: Int = 6
    /// 横竖屏下分割线的数量
    var horizonSeperatorNum: Int = 10
    /// 分时背景颜色
    var minuteBgColor: UIColor = UIColor.init(red: 54 / 255.0, green: 143 / 255.0, blue: 251 / 255.0, alpha: 0.3)

    
    static var shareConfig: KLineConfig = KLineConfig.init()
    private override init() { }
    
}


class IndexLineConfig: BaseConfig {
    var lineColors: [String : UIColor] = [
        "k": UIColor.init(red: 190 / 255.0, green: 120 / 255.0, blue: 46 / 255.0, alpha: 1),
        "d": UIColor.init(red: 47 / 255.0, green: 165 / 255.0, blue: 206 / 255.0, alpha: 1),
        "j": UIColor.init(red: 208 / 255.0, green: 126 / 255.0, blue: 187 / 255.0, alpha: 1),
    ]
}
