import UIKit

public enum WhistleAction {
  case present
  case show(TimeInterval)
}

let whistleFactory = WhistleFactory()

open class WhistleFactory: UIViewController {
    
  let topSpacerHeight = UIApplication.shared.statusBarFrame.height > 20.0 ? UIApplication.shared.statusBarFrame.height : 0.0 //iPhone X height > 20
    
  var whistleHeight:CGFloat  { return topSpacerHeight + titleLabelHeight}

  open lazy var whistleWindow: UIWindow = UIWindow()

  open lazy var titleLabelHeight = CGFloat(20.0)

  open lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center

    return label
  }()
    
  open fileprivate(set) lazy var tapGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
      let gesture = UITapGestureRecognizer()
      gesture.addTarget(self, action: #selector(WhistleFactory.handleTapGestureRecognizer))
        
      return gesture
  }()

  open fileprivate(set) var murmur: Murmur?
  open var viewController: UIViewController?
  open var hideTimer = Timer()

  // MARK: - Initializers

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nil, bundle: nil)

    setupWindow()
    view.clipsToBounds = true
    view.addSubview(titleLabel)
    
    view.addGestureRecognizer(tapGestureRecognizer)

    NotificationCenter.default.addObserver(self, selector: #selector(WhistleFactory.orientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
  }

  // MARK: - Configuration

  open func whistler(_ murmur: Murmur, action: WhistleAction) {
    self.murmur = murmur
    titleLabel.text = murmur.title
    titleLabel.font = murmur.font
    titleLabel.textColor = murmur.titleColor
    view.backgroundColor = murmur.backgroundColor
    whistleWindow.backgroundColor = murmur.backgroundColor

//    guard whistleWindow.isHidden else {return}
    hideTimer.invalidate()
    whistleWindow.layer.removeAllAnimations()
    moveWindowToFront()
    setupFrames()

    switch action {
    case .show(let duration):
      show(duration: duration)
    default:
      present()
    }
  }

  // MARK: - Setup

  open func setupWindow() {
    whistleWindow.addSubview(self.view)
    whistleWindow.clipsToBounds = true
    moveWindowToFront()
  }

  func moveWindowToFront() {
    whistleWindow.windowLevel = UIWindowLevelStatusBar
  }

  open func setupFrames() {
    whistleWindow = UIWindow()

    setupWindow()

    let labelWidth = UIScreen.main.bounds.width
    let defaultHeight = titleLabelHeight

    if let text = titleLabel.text {
      let neededDimensions =
        NSString(string: text).boundingRect(
          with: CGSize(width: labelWidth, height: CGFloat.infinity),
          options: NSStringDrawingOptions.usesLineFragmentOrigin,
          attributes: [NSAttributedStringKey.font: titleLabel.font],
          context: nil
        )
      titleLabelHeight = CGFloat(neededDimensions.size.height)
      titleLabel.numberOfLines = 0 // Allows unwrapping

      if titleLabelHeight < defaultHeight {
        titleLabelHeight = defaultHeight
      }
    } else {
      titleLabel.sizeToFit()
    }

    whistleWindow.frame = CGRect(x: 0, y: 0, width: labelWidth, height: whistleHeight)
    view.frame = whistleWindow.bounds
    titleLabel.frame = CGRect(x: view.bounds.origin.x, y: topSpacerHeight,  width: view.bounds.width, height:titleLabelHeight)
  }

  // MARK: - Movement methods

  public func show(duration: TimeInterval) {
    present()
    calm(after: duration)
  }

  public func present() {
    let initialOrigin = whistleWindow.frame.origin.y
    whistleWindow.frame.origin.y = initialOrigin - whistleWindow.bounds.height
    whistleWindow.isHidden = false
    whistleWindow.alpha = 0
    UIView.animate(withDuration: 0.2, animations: {
      self.whistleWindow.frame.origin.y = initialOrigin
      self.whistleWindow.alpha = 1
    })
  }

    public func hide() {
        let finalOrigin = view.frame.origin.y - whistleWindow.bounds.height
        UIView.animate(withDuration: 0.2, animations: {
          self.whistleWindow.frame.origin.y = finalOrigin
          self.whistleWindow.alpha = 0
        }, completion: { (finished) in
            if finished {
                self.whistleWindow.isHidden = true
            }
        })
    }

  public func calm(after: TimeInterval) {
    hideTimer.invalidate()
    hideTimer = Timer.scheduledTimer(timeInterval: after, target: self, selector: #selector(WhistleFactory.timerDidFire), userInfo: nil, repeats: false)
  }

  // MARK: - Timer methods

  @objc public func timerDidFire() {
    hide()
  }

  @objc func orientationDidChange() {
    if !whistleWindow.isHidden {
      updateFrames()
      //setupFrames()
      //hide()
    }
  }
    
  // MARK:
  open func updateFrames() {
    let labelWidth = UIScreen.main.bounds.width
    let defaultHeight = titleLabelHeight
        
    if let text = titleLabel.text {
        let neededDimensions =
            NSString(string: text).boundingRect(
                with: CGSize(width: labelWidth, height: CGFloat.infinity),
                options: NSStringDrawingOptions.usesLineFragmentOrigin,
                attributes: [NSAttributedStringKey.font: titleLabel.font],
                context: nil
        )
        
        titleLabelHeight = CGFloat(neededDimensions.size.height)
        titleLabel.numberOfLines = 0 // Allows unwrapping
            
        if titleLabelHeight < defaultHeight {
            titleLabelHeight = defaultHeight
        }
    } else {
        titleLabel.sizeToFit()
    }
        
    whistleWindow.frame = CGRect(x: 0, y: 0, width: labelWidth, height: whistleHeight)
    view.frame = whistleWindow.bounds
    titleLabel.frame = CGRect(x: view.bounds.origin.x, y: topSpacerHeight,  width: view.bounds.width, height:titleLabelHeight)
    whistleWindow.layoutIfNeeded()
  }
    
  // MARK: - Gesture methods
    
  @objc fileprivate func handleTapGestureRecognizer() {
      guard let murmur = murmur else { return }
      murmur.action?()
  }
}
