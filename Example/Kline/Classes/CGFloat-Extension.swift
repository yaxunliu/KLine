
//
//  CGFloat-Extension.swift
//  Kline_Example
//
//  Created by yaxun on 2019/1/14.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

extension CGFloat {
    func roundTo(places: Int) -> CGFloat {
        let divisor = pow(10.0, CGFloat(places))
        return (self * divisor).rounded() / divisor
    }
}
