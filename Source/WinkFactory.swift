//
//  WinkFactory.swift
//  Pods
//
//  Created by Dmytro Hubskyi on 13.03.17.
//
//

import UIKit

let winkView = WinkView()

open class WinkView: UIView {

    let animationVelocity: CGFloat =  0.35 / 60

    public struct Dimensions {
        public static let imageSize: CGFloat = 48
        public static let imageOffset: CGFloat = 18
        public static var height: CGFloat = UIApplication.shared.isStatusBarHidden ? 55 : 65
        public static var textOffset: CGFloat = 75
    }

  

    open fileprivate(set) lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorList.Wink.background
        view.alpha = 0.98
        view.clipsToBounds = true

        return view
    }()

    fileprivate var topConstraint: NSLayoutConstraint?

    open fileprivate(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontList.Wink.title
        label.textColor = ColorList.Wink.title
        label.numberOfLines = 2
        label.textAlignment = .center

        return label
    }()

    open fileprivate(set) lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = FontList.Wink.subtitle
        label.textColor = ColorList.Wink.subtitle
        label.numberOfLines = 0
        label.textAlignment = .center

        return label
    }()

    open fileprivate(set) lazy var tapGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(WinkView.handleTapGestureRecognizer))

        return gesture
    }()

  open fileprivate(set) var announcement: Announcement?
  open fileprivate(set) var displayTimer = Timer()
  open fileprivate(set) var panGestureActive = false
  open fileprivate(set) var shouldSilent = false
  open fileprivate(set) var completion: (() -> ())?

  private var subtitleLabelOriginalHeight: CGFloat = 0

  // MARK: - Initializers

  public override init(frame: CGRect) {
    super.init(frame: frame)

    addSubview(backgroundView)
    [titleLabel, subtitleLabel].forEach {
      backgroundView.addSubview($0) }

    clipsToBounds = true
    isUserInteractionEnabled = true
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOffset = CGSize(width: 0, height: 0.5)
    layer.shadowOpacity = 0.1
    layer.shadowRadius = 0.5

    addGestureRecognizer(tapGestureRecognizer)

    setupFrames()

  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {

  }

  // MARK: - Configuration

  open func craft(_ announcement: Announcement, to: UIViewController, completion: (() -> ())?) {

    panGestureActive = false
    shouldSilent = false
    configureView(announcement)
    shout(to: to)

    self.completion = completion
  }

  open func configureView(_ announcement: Announcement) {
    self.announcement = announcement
    titleLabel.text = announcement.title
    subtitleLabel.text = announcement.subtitle
    
    backgroundView.backgroundColor = announcement.backgroundColor
    titleLabel.textColor = announcement.textColor
    subtitleLabel.textColor = announcement.textColor

    displayTimer.invalidate()
    displayTimer = Timer.scheduledTimer(timeInterval: announcement.duration,
      target: self, selector: #selector(WinkView.displayTimerDidFire), userInfo: nil, repeats: false)


  }

    
    open func shout(to controller: UIViewController) {
        let width = UIScreen.main.bounds.width
        var topOffset: CGFloat = 0
        if let nvc = controller as? UINavigationController, !nvc.isNavigationBarHidden {
            let navFrame = nvc.navigationBar.frame
            let navFrameInTopVC = nvc.navigationBar.superview!.convert(navFrame, to: nvc.topViewController!.view)
            nvc.topViewController!.view.addSubview(self)
            topOffset = navFrameInTopVC.maxY
        } else if let window = controller.view.window {
            window.addSubview(self)
            topOffset = UIApplication.shared.isStatusBarHidden ? 0 : 20
        } else {
            controller.view.addSubview(self)
        }


        frame = CGRect(x: 0, y: topOffset - 70, width: width, height: 70)
        self.layoutIfNeeded()
        let height = self.backgroundView.frame.height
        frame.origin.y = topOffset - height
        frame.size.height = height

        let springWithDamping: CGFloat = 0.5
        let initialSpringVelocity: CGFloat = 3 / CGFloat(height / 70)
        
        UIView.animate(withDuration: TimeInterval(animationVelocity * height), delay: 0, usingSpringWithDamping: springWithDamping, initialSpringVelocity: initialSpringVelocity, options: .curveEaseInOut, animations: {
            self.frame.origin.y = topOffset
            //self.layoutIfNeeded()
        } , completion: {_ in })
    }

  // MARK: - Actions

  open func silent() {

    let height = self.backgroundView.frame.height

    UIView.animate(withDuration: TimeInterval(animationVelocity * height), animations: {
        self.frame.origin.y -= height
    }, completion: { finished in
        self.completion?()
        self.displayTimer.invalidate()
        self.removeFromSuperview()
    })
  }

    
  

  // MARK: - Setup

    func setupBackgroundContraints() {
        topConstraint = backgroundView.topAnchor.constraint(equalTo: self.topAnchor)
        topConstraint?.isActive = true
        backgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
    }

    func setupTitleContraints() {
        let textOffsetX: CGFloat =  18
        let textOffsetY: CGFloat =  10

        titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: textOffsetY).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: textOffsetX).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -18).isActive = true
    }

    func setupSubtitleContraints() {
        subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2.5).isActive = true
        subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).isActive = true
        subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor).isActive = true
        subtitleLabel.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -10).isActive = true
    }

  public func setupFrames() {

    [titleLabel, backgroundView, subtitleLabel].forEach { (view) in
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    setupBackgroundContraints()
    setupTitleContraints()
    setupSubtitleContraints()

  }


  // MARK: - Timer methods

  open func displayTimerDidFire() {
    shouldSilent = true

    if panGestureActive { return }
    silent()
  }

  // MARK: - Gesture methods

  @objc fileprivate func handleTapGestureRecognizer() {
    guard let announcement = announcement else { return }
    announcement.action?()
    silent()
  }

}
