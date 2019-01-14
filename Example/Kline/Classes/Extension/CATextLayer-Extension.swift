//
//  CATextLayer-Extension.swift
//  Kline_Example
//
//  Created by yaxun on 2019/1/9.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

extension CATextLayer {

    
    static func initWithFrame(_ frame: CGRect, _ fontSize: CGFloat, _ fontColor: UIColor, _ str: String = "0.00") -> CATextLayer {
        let textLayer = CATextLayer.init()
        textLayer.frame = frame
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.fontSize = fontSize
        textLayer.foregroundColor = fontColor.cgColor
        textLayer.string = str
        return textLayer
    }
    
}

