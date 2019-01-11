//
//  IndexLineView.swift
//  Kline_Example
//
//  Created by yaxun on 2019/1/11.
//  Copyright © 2019 CocoaPods. All rights reserved.
//  指标折线图

import UIKit

class IndexLineView: UIView {
    /// 内边距 (需要去适配屏幕大小)
    var contentInset: UIEdgeInsets = UIEdgeInsets.init(top: 24, left: 10, bottom: 10, right: 10)
    var dataSource: KLineDataSource?
    
    
    /// 最外层的视图
    fileprivate lazy var contentView: UIView = {
        let contentView = UIView.init(frame: .zero)
        contentView.backgroundColor = .white
        return contentView
    }()

    
    /// 配置文件
    fileprivate let _config: IndexLineConfig
    /// 指标名称
    fileprivate var _indexNames: [String] = []
    
    init(_ config: IndexLineConfig) {
        _config = config
        super.init(frame: .zero)
        self.backgroundColor = .red
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("initinal error")
    }
    
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if contentView.superview != nil { return }
        if self.constraints.count > 0 && self.frame.width == 0 || self.frame.height == 0 {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        setupUI()
        observerGesture()
    }
    
    fileprivate func setupUI() {
        
        
    }
    
    fileprivate func observerGesture() {
        contentView.frame = CGRect.init(x: self.contentInset.left, y: self.contentInset.top, width: self.bounds.width - self.contentInset.left - self.contentInset.right, height: self.bounds.height - self.contentInset.top - self.contentInset.bottom)
        addSubview(contentView)
        
        
    }
    
    
    
}
