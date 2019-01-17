# Kline

本项目是模仿富途牛牛的k线图，部分功能不完善，目前已经开发的功能包括, 由于每个公司的需求不一，所以很难做成pod模板。


![效果图](https://github.com/yaxunliu/KLine/blob/master/screenCapture.gif?raw=true)

***
+ k线绘制
+ 分时图绘制
+ 移动手势, 缩放手势 和长按手势
+ Macd KDJ 和交易量柱状图的绘制 
***

## 实现原理
+ StockProviderView
    - 一个视图容器 将baseLineView 和 component进行组装 可以进行滚动操作 也可以禁止滚动
    - 全局监听长按手势, 拖动手势 和 缩放手势, 根据不同的手势去刷新容器内的子视图内容
+ StockBaseLineView:
    - 绘制由ProviderView提供的数据模型 
    - 目前可以绘制k线和分时图数据
+ StockComponent:
    - 绘制由ProviderView提供的指标数据模型
    - macd kdj vol 等都是继承自StockComponent

+ 绘制的方法使用的是CAShapeLayer+UIBezierPath


## Author
liuyaxun, 1175222300@qq.com
## License
Kline is available under the MIT license. See the LICENSE file for more info.
