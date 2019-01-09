//
//  CAShapeLayer-Extension.swift
//  Kline_Example
//
//  Created by yaxun on 2019/1/9.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

extension CAShapeLayer {
    static func drawLayer(_ rect: CGRect, _ path: UIBezierPath, _ stroke: UIColor, _ fill: UIColor, _ isAlpha: Bool, _ lineWidth: CGFloat) -> CAShapeLayer {
        let shaperLayer = CAShapeLayer.init()
        shaperLayer.frame = rect
        shaperLayer.strokeColor = stroke.cgColor
        shaperLayer.fillColor = fill.cgColor
        shaperLayer.isOpaque = isAlpha
        shaperLayer.lineWidth = lineWidth
        shaperLayer.path = path.cgPath
        return shaperLayer
    }
}
