//
//  PageView.swift
//  PPT
//
//  Created by jasnig on 16/4/2.
//  Copyright © 2016年 ZeroJ. All rights reserved.
//
// github: https://github.com/jasnig
// 简书: http://www.jianshu.com/users/fb31a3d1ec30/latest_articles
import UIKit

class PPTImageView: UIView {
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.white
        titleLabel.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        titleLabel.font = UIFont.systemFont(ofSize: 14.0)
        
        return titleLabel
    }()
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        /// 剪去多余的部分
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        addSubview(titleLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        titleLabel.frame = CGRect(x: 0, y: bounds.height - 28.0, width: bounds.width, height: 28.0)
        
    }
}

open class PPTView: UIView {
    // 滚动方向
    public enum Direction {
        /// 当前的图片向左移
        case left
        
        /// 当前的图片向右移
        case right
        
    }
    
    // PageControl位置
    public enum PageControlPosition {
        case topCenter
        case bottomLeft
        case bottomRight
        case bottomCenter
    }
    
    public typealias PageDidClickAction = (_ clickedIndex: Int) -> Void
    public typealias SetupImageAndTitle = (_ titleLabel: UILabel, _ imageView: UIImageView, _ index: Int) -> Void
    public typealias ImagesCount = () -> Int
    //MARK:- 可供外部修改的属性
    // pageControl的位置 默认为底部中间
    open var pageControlPosition: PageControlPosition = .bottomCenter
    
    // 点击响应
    open var pageDidClick:PageDidClickAction?
    
    // 设置图片和标题, 同时可以设置相关的控件的属性
    open var setupImageAndTitle: SetupImageAndTitle?
    
    // 滚动间隔
    open var timerInterval = 3.0
    
    /// 图片总数, 需要在初始化的时候指定*
    var imagesCount: ImagesCount!
    /// 总页数
    fileprivate var pageCount: Int {
        return self.imagesCount()
    }
    /// 其他page的颜色
    open var pageIndicatorTintColor = UIColor.white {
        willSet {
            pageControl.pageIndicatorTintColor = newValue
        }
    }
    
    /// 当前page的颜色
    open var currentPageIndicatorTintColor = UIColor.white {
        willSet {
            pageControl.currentPageIndicatorTintColor = newValue
        }
    }
    
    /// 是否自动滚动, 默认为自动滚动
    open var autoScroll = true {
        willSet {
            if !newValue {
                stopTimer()
            }
        }
    }
    
    //MARK:- 私有属性
    fileprivate var scrollDirection: Direction = .left
    
    fileprivate var currentIndex = -1
    fileprivate var leftIndex = -1
    fileprivate var rightIndex = 1
    
    /// 计时器
    fileprivate var timer: Timer?
    
    fileprivate lazy var scrollView: UIScrollView = { [weak self] in
        let scroll = UIScrollView(frame: CGRect.zero)
        
        if let strongSelf = self {
            scroll.delegate = strongSelf
            
        }
        scroll.bounces = false
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.isPagingEnabled = true
        return scroll
        }()
    
    fileprivate lazy var pageControl: UIPageControl = {
        let pageC = UIPageControl()
        pageC.currentPage = 0
        pageC.hidesForSinglePage = true
        pageC.isUserInteractionEnabled = false
        
        return pageC
    }()
    
    lazy var currentPPTImageView: PPTImageView = {
        let imageView = PPTImageView()
        return imageView
    }()
    
    lazy var rightPPTImageView = PPTImageView()
    lazy var leftPPTImageView = PPTImageView()
    
    // MARK: - 可链式调用
    open class func PPTViewWithImagesCount(_ imagesCount: @escaping ImagesCount) -> PPTView {
        return PPTView(imagesCount: imagesCount)
    }
    open func setupImageAndTitle(_ setupImageAndTitle: @escaping SetupImageAndTitle) -> Self {
        self.setupImageAndTitle = setupImageAndTitle
        return self
    }
    open func setupPageDidClickAction(_ pageDidClick: PageDidClickAction?) -> Self {
        self.pageDidClick = pageDidClick
        return self
    }
    
    //MARK:- 初始化
    // 遍历构造器, 不监控点击事件的时候可以使用
    public convenience init(imagesCount: @escaping ImagesCount, setupImageAndTitle: @escaping SetupImageAndTitle) {
        self.init(imagesCount: imagesCount, setupImageAndTitle: setupImageAndTitle, pageDidClick: nil)
    }
    
    fileprivate init(imagesCount: @escaping ImagesCount) {
        self.imagesCount = imagesCount
        super.init(frame: CGRect.zero)
        initialization()
    }
    
    public init(imagesCount: @escaping ImagesCount, setupImageAndTitle: @escaping SetupImageAndTitle, pageDidClick: PageDidClickAction?) {
        
        // 这个Closure 处理点击
        self.pageDidClick = pageDidClick
        // 这个Closure获取图片 相当于UITableView的cellForRow...方法
        self.setupImageAndTitle = setupImageAndTitle
        // 相当于UITableView的numberOfRows...方法
        self.imagesCount = imagesCount
        
        super.init(frame: CGRect.zero)
        // 这里面添加了各个控件, 和设置了初始的图片和title
        initialization()
        
    }
    
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- 初始设置和内部函数
    
    fileprivate func initialization()  {
        let tapGuesture = UITapGestureRecognizer(target: self, action: #selector(self.imageTapdAction))
        tapGuesture.numberOfTapsRequired = 1
        currentPPTImageView.addGestureRecognizer(tapGuesture)
        setupPageControl()
        
        addSubview(scrollView)
        addSubview(pageControl)
        
        scrollView.addSubview(currentPPTImageView)
        scrollView.addSubview(leftPPTImageView)
        scrollView.addSubview(rightPPTImageView)
        // 添加初始化图片
        loadImages()
        ///
        startTimer()
    }
    
    fileprivate func setupPageControl() {
        
        pageControl.numberOfPages = pageCount
        pageControl.size(forNumberOfPages: pageCount)
    }
    
    
    open func reloadData() {
        currentIndex = -1
        setupPageControl()
        loadImages()
        startTimer()
    }
    override open func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
        let pageHeight:CGFloat = 28.0
        let width = bounds.size.width
        let height = bounds.size.height
        
        switch pageControlPosition {
        case .bottomLeft:
            pageControl.frame = CGRect(x: 0, y: height - pageHeight, width: width / 2, height: pageHeight)
            
        case .bottomCenter:
            pageControl.frame = CGRect(x: 0, y: height - pageHeight, width: width, height: pageHeight)
            
        case .bottomRight:
            pageControl.frame = CGRect(x: width / 2, y: height - pageHeight, width: width / 2, height: pageHeight)
            
        case .topCenter:
            pageControl.frame = CGRect(x: 0, y: 0, width: width, height: pageHeight)
        }
        
        currentPPTImageView.frame = CGRect(x: width, y: 0, width: width, height: height)
        leftPPTImageView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        rightPPTImageView.frame = CGRect(x: width * 2, y: 0, width: width, height: height)
        
        scrollView.contentOffset = CGPoint(x: width, y: 0)
        scrollView.contentSize = CGSize(width: 3 * width, height: 0)
        
    }
    
    /// 开启倒计时
    fileprivate func startTimer() {
        if timer == nil {
            timer = Timer(timeInterval: timerInterval, target: self, selector: #selector(self.timerAction), userInfo: nil, repeats: true)
            RunLoop.main.add(timer!, forMode: RunLoopMode.commonModes)
        }
    }
    
    /// 停止倒计时
    fileprivate func stopTimer() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        
    }
    
    /// 计时器响应方法
    func timerAction() {
        // 更新位置, 更换图片
        
        UIView.animate(withDuration: 3.0, animations: {
            self.scrollView.setContentOffset(CGPoint(x: self.bounds.size.width * 2, y: 0), animated: true)
            
            }, completion: nil)
        
    }
    
    func imageTapdAction() {
        pageDidClick?(currentIndex)
    }
    
    deinit {
        //        debugPrint("\(self.debugDescription) --- 销毁")
        stopTimer()
    }
    
    /// 当父view将释放的时候需要 释放掉timer以释放当前view
    override open func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil {
            stopTimer()
            
        }
    }
}

extension PPTView: UIScrollViewDelegate {
    
    // 手指触摸到时
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if autoScroll {
            stopTimer()
            
        }
    }
    
    // 松开手指时
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if autoScroll {
            scrollDirection = .left
            startTimer()
            
        }
    }
    
    /// 代码设置scrollview的contentOffSet滚动完成后调用
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        // 重新加载图片
        scrollDirection = .left
        loadImages()
        
    }
    
    /// scrollview的滚动是由拖拽触发的时候,在它将要停止时调用
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // 1/2屏
        if fabs(scrollView.contentOffset.x - scrollView.bounds.size.width) > scrollView.bounds.size.width / 2 {
            
            scrollDirection = scrollView.contentOffset.x > bounds.size.width ? .left : .right
            // 重新加载图片
            loadImages()
        }
        
        
    }
    
    
    fileprivate func loadImages() {
        
        if pageCount == 0 {
            return
        }
        // 根据滚动方向不同设置将要显示的图片下标
        switch scrollDirection {
            
        case .left:
            currentIndex = (currentIndex + 1) % pageCount
            
        case .right:
            
            currentIndex = (currentIndex - 1 + pageCount) % pageCount
            
        }
        
        leftIndex = (currentIndex - 1 + pageCount) % pageCount
        rightIndex = (currentIndex + 1) % pageCount
        
        setupImageAndTitle?(currentPPTImageView.titleLabel, currentPPTImageView.imageView, currentIndex)
        setupImageAndTitle?(rightPPTImageView.titleLabel, rightPPTImageView.imageView, rightIndex)
        setupImageAndTitle?(leftPPTImageView.titleLabel, leftPPTImageView.imageView, leftIndex)
        
        
        pageControl.currentPage = currentIndex
        
        // 将currentImageView显示在屏幕上
        scrollView.contentOffset = CGPoint(x: bounds.size.width, y: 0)
        
    }
}

