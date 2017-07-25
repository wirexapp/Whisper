import UIKit

public func show(whisper message: Message, to navigationController: UINavigationController, action: WhisperAction = .show) {
    whisperFactory.craft(message, navigationController: navigationController, action: action)
}

public func show(shout announcement: Announcement, to navigationController: UIViewController, completion: (() -> Void)? = nil) {
    shoutView.craft(announcement, to: navigationController, completion: completion)
}

public func show(wink announcement: Announcement, to viewController: UIViewController, completion: (() -> Void)? = nil) {
    winkView.wink(announcement, to: viewController, completion: completion)
}

public func show(wink announcement: Announcement, in window: UIWindow, completion: (() -> Void)? = nil) {
    winkView.wink(announcement, in: window, completion: completion)
}

public func show(wink announcement: Announcement, over view: UIView, completion: (() -> Void)? = nil) {
    winkView.wink(announcement, over: view, completion: completion)
}

public func show(whistle murmur: Murmur, action: WhistleAction = .show(1.5)) {
    whistleFactory.whistler(murmur, action: action)
}

public func hideWishper(from navigationController: UINavigationController, after: TimeInterval = 0) {
    whisperFactory.silentWhisper(navigationController, after: after)
}

public func hideWhistle(after timeInterval: TimeInterval = 0) {
    whistleFactory.calm(after: timeInterval)
}

public func hideShout() {
    shoutView.silent()
}
