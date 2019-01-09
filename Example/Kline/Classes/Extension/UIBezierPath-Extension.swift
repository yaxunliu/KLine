//
//  UIBezierPath-Extension.swift
//  Kline_Example
//
//  Created by yaxun on 2019/1/9.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

extension UIBezierPath {
    
    /// 绘制举行
    /// - Parameter frame: 矩形 的位置
    static func drawRect(_ bPath: UIBezierPath?, _ frame: CGRect) -> UIBezierPath {
        let path = bPath ?? UIBezierPath.init()
        let leftTopPoint = CGPoint.init(x: frame.minX, y: frame.minY)
        let leftBottomPoint = CGPoint.init(x: frame.minX, y: frame.maxY)
        let rightTopPoint = CGPoint.init(x: frame.maxX, y: frame.minY)
        let rightBottomPoint = CGPoint.init(x: frame.maxX, y: frame.maxY)
        path.move(to: leftTopPoint)
        path.addLine(to: leftBottomPoint)
        path.addLine(to: rightBottomPoint)
        path.addLine(to: rightTopPoint)
        path.close()
        return path
    }
    
    /// 绘制线段
    ///
    /// - Parameter points: 线段的起点和终点
    static func drawLines(_ points: [(CGPoint, CGPoint)]) -> UIBezierPath {
        let path = UIBezierPath.init()
        points.forEach { touple in
            let begin = touple.0
            let end = touple.1
            path.move(to: begin)
            path.addLine(to: end)
        }
        return path
    }
    
    /// 绘制蜡烛图
    ///
    /// - Parameters:
    ///   - rect: 蜡烛图矩形的frame
    ///   - hightesY: 最高点Y值
    ///   - lowestY: 最低点Y值
    static func drawCandle(_ bPath: UIBezierPath?, _ rect: CGRect, _ hightesY: CGFloat, _ lowestY: CGFloat) -> UIBezierPath {
        let path = self.drawRect(bPath, rect)
        path.move(to: CGPoint.init(x: rect.minX + rect.width * 0.5, y: rect.minY))
        path.addLine(to: CGPoint.init(x: rect.minX + rect.width * 0.5, y: hightesY))
        path.move(to: CGPoint.init(x: rect.minX + rect.width * 0.5, y: rect.maxY))
        path.addLine(to: CGPoint.init(x: rect.minX + rect.width * 0.5, y: lowestY))
        return path
    }
    
}
