//
//  HeaderView.swift
//  Kline_Example
//
//  Created by yaxun on 2019/1/17.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class HeaderView: UIView {
    
    fileprivate lazy var closeButton: UIButton = {
        let btn = UIButton.init(frame: CGRect.init(x: self.bounds.width - 100, y: 10, width: 100, height: 44))
        btn.setTitle("dismiss", for: .normal)
        btn.setTitleColor(.red, for: .normal)
        btn.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        return btn
    }()
    
    fileprivate lazy var exchangeButton: UIButton = {
        let btn = UIButton.init(frame: CGRect.init(x: 40, y: 10, width: 120, height: 44))
        btn.setTitle("切换分时和k线", for: .normal)
        btn.setTitleColor(.red, for: .normal)
        btn.addTarget(self, action: #selector(exchange), for: .touchUpInside)
        return btn
    }()
    
    var exchangeType: (() -> ())? = nil
    
    fileprivate let _closeAction: (() -> ())
    init(_ frame: CGRect, _ closeAction: @escaping () -> ()) {
        _closeAction = closeAction
        super.init(frame: frame)
        self.backgroundColor = .white
        
        self.addSubview(closeButton)
        
        self.addSubview(exchangeButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc fileprivate func dismiss() {
        _closeAction()
    }
    
    @objc fileprivate func exchange() {
        exchangeType?()
    }
}
