//
//  Date-Extension.swift
//  Kline_Example
//
//  Created by yaxun on 2019/1/10.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

extension Date {
    
    
    static func isSameMonth(_ m1: TimeInterval, _ m2: TimeInterval) -> Bool {
        let calendar = Calendar.current
        let m1Components = calendar.dateComponents([.day,.month,.year], from: Date.init(timeIntervalSince1970: m1))
        let m2Components = calendar.dateComponents([.weekday,.month,.year], from: Date.init(timeIntervalSince1970: m2))
        return (m1Components.year == m2Components.year) && (m1Components.month == m2Components.month)
    }
    
    static func isSameYear(_ m1: TimeInterval, _ m2: TimeInterval) -> Bool {
        let calendar = Calendar.current
        let m1Components = calendar.dateComponents([.day,.month,.year], from: Date.init(timeIntervalSince1970: m1))
        let m2Components = calendar.dateComponents([.weekday,.month,.year], from: Date.init(timeIntervalSince1970: m2))
        return (m1Components.year == m2Components.year)
    }
    
    static func transformStr(_ m1: TimeInterval) -> (Int, Int, Int) {
        let calendar = Calendar.current
        let m1Components = calendar.dateComponents([.day,.month,.year], from: Date.init(timeIntervalSince1970: m1))
        return (m1Components.year ?? 0, m1Components.month ?? 0, m1Components.day ?? 0)
    }
    
}
