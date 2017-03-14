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

  public struct Dimensions {
    public static let indicatorHeight: CGFloat = 6
    public static let indicatorWidth: CGFloat = 50
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

  open fileprivate(set) lazy var indicatorView: UIView = {
    let view = UIView()
    view.backgroundColor = ColorList.Wink.dragIndicator
    view.layer.cornerRadius = Dimensions.indicatorHeight / 2
    view.isUserInteractionEnabled = true

    return view
    }()

  open fileprivate(set) lazy var imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.layer.cornerRadius = Dimensions.imageSize / 2
    imageView.clipsToBounds = true
    imageView.contentMode = .scaleAspectFill

    return imageView
    }()

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

    open fileprivate(set) lazy var panGestureRecognizer: UIPanGestureRecognizer = { [unowned self] in
        let gesture = UIPanGestureRecognizer()
        gesture.addTarget(self, action: #selector(WinkView.handlePanGestureRecognizer))

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
    [indicatorView, imageView, titleLabel, subtitleLabel].forEach {
      backgroundView.addSubview($0) }

    clipsToBounds = false
    isUserInteractionEnabled = true
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOffset = CGSize(width: 0, height: 0.5)
    layer.shadowOpacity = 0.1
    layer.shadowRadius = 0.5

    addGestureRecognizer(tapGestureRecognizer)
    addGestureRecognizer(panGestureRecognizer)

  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {

  }

  // MARK: - Configuration

  open func craft(_ announcement: Announcement, to: UIViewController, completion: (() -> ())?) {
    Dimensions.height = UIApplication.shared.isStatusBarHidden ? 70 : 80

    panGestureActive = false
    shouldSilent = false
    configureView(announcement)
    shout(to: to)

    self.completion = completion
  }

  open func configureView(_ announcement: Announcement) {
    self.announcement = announcement
    imageView.image = announcement.image
    titleLabel.text = announcement.title
    subtitleLabel.text = announcement.subtitle
    
    backgroundView.backgroundColor = announcement.backgroundColor
    titleLabel.textColor = announcement.textColor
    subtitleLabel.textColor = announcement.textColor

    displayTimer.invalidate()
    displayTimer = Timer.scheduledTimer(timeInterval: announcement.duration,
      target: self, selector: #selector(WinkView.displayTimerDidFire), userInfo: nil, repeats: false)

    setupFrames()
  }

    
    open func shout(to controller: UIViewController) {
        let width = UIScreen.main.bounds.width
//        if let nvc = controller as? UINavigationController {
//            nvc.topViewController?.view.addSubview(self)
//        } else
        if let window = controller.view.window {
            window.addSubview(self)
        } else {
            controller.view.addSubview(self)
        }
        
        frame = CGRect(x: 0, y: -Dimensions.height, width: width, height: Dimensions.height)

        self.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 3, options: .curveEaseInOut, animations: {
            self.frame.origin.y = 0
        } , completion: {_ in })
    }

    
  

  // MARK: - Setup

    func setupBackgroundContraints() {
        backgroundView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        backgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
    }
    func setupImageViewContraints() {
        let topOffset: CGFloat = 5
        let imageSize: CGFloat = imageView.image != nil ? Dimensions.imageSize : 0

        imageView.widthAnchor.constraint(equalToConstant: imageSize).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: imageSize).isActive = true
        imageView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: Dimensions.imageOffset).isActive = true
        imageView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant:  (Dimensions.height - imageSize) / 2 + topOffset).isActive = true


    }
    func setupTitleContraints() {
        let textOffsetX: CGFloat = imageView.image != nil ? Dimensions.textOffset : 18
        let textOffsetY = imageView.image != nil ? imageView.frame.origin.x + 3 : textOffsetX + 5

        titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: textOffsetY).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: textOffsetX).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -18).isActive = true
    }

    func setupSubtitleContraints() {
        subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2.5).isActive = true
        subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).isActive = true
        subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor).isActive = true
    }

    func setupIndicatorContraints() {
        indicatorView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5).isActive = true
        indicatorView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        indicatorView.widthAnchor.constraint(equalToConstant: Dimensions.indicatorWidth).isActive = true
        indicatorView.heightAnchor.constraint(equalToConstant: Dimensions.indicatorHeight).isActive = true
    }

  public func setupFrames() {
    Dimensions.height = UIApplication.shared.isStatusBarHidden ? 55 : 65

    let totalWidth = UIScreen.main.bounds.width
    let offset: CGFloat = UIApplication.shared.isStatusBarHidden ? 2.5 : 5
    let textOffsetX: CGFloat = imageView.image != nil ? Dimensions.textOffset : 18
    let imageSize: CGFloat = imageView.image != nil ? Dimensions.imageSize : 0


    [indicatorView, titleLabel, backgroundView, subtitleLabel, imageView].forEach { (view) in
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    setupBackgroundContraints()
    setupImageViewContraints()
    setupTitleContraints()
    setupSubtitleContraints()
    setupIndicatorContraints()

    Dimensions.height += subtitleLabel.frame.height

  }

  // MARK: - Actions

  open func silent() {
    UIView.animate(withDuration: 0.35, animations: {
      self.frame.origin.y = -self.frame.height
      }, completion: { finished in
        self.completion?()
        self.displayTimer.invalidate()
        self.removeFromSuperview()
    })
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
  
  @objc private func handlePanGestureRecognizer() {
    let translation = panGestureRecognizer.translation(in: self)
    var duration: TimeInterval = 0

    if panGestureRecognizer.state == .began {
      subtitleLabelOriginalHeight = subtitleLabel.bounds.size.height
      subtitleLabel.numberOfLines = 0
      subtitleLabel.sizeToFit()
    } else if panGestureRecognizer.state == .changed {
      panGestureActive = true
      
      let maxTranslation = subtitleLabel.bounds.size.height - subtitleLabelOriginalHeight
      
      if translation.y >= maxTranslation {
        frame.size.height = Dimensions.height + maxTranslation + (translation.y - maxTranslation) / 25
      } else {
        frame.size.height = Dimensions.height + translation.y
      }
    } else {
      panGestureActive = false
      let height = translation.y < -5 || shouldSilent ? 0 : Dimensions.height

      duration = 0.2
      subtitleLabel.numberOfLines = 2
      subtitleLabel.sizeToFit()
      
      UIView.animate(withDuration: duration, animations: {
        self.frame.size.height = height
        }, completion: { _ in if translation.y < -5 { self.completion?(); self.removeFromSuperview() }})
    }

//    UIView.animate(withDuration: duration, animations: {
//      //self.backgroundView.frame.size.height = self.frame.height
//      self.indicatorView.frame.origin.y = self.frame.height - Dimensions.indicatorHeight - 5
//    })
  }

}
