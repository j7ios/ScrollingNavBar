//  Created by Jack7 on 30/08/16.
//  Copyright © 2016 GiacomoB. All rights reserved.
//

import UIKit

/*
 Scrolling Navigation Bar delegate protocol
 */

@objc public protocol ScrollingNavigationControllerDelegate: NSObjectProtocol {
    
  @objc optional func scrollingNavigationController(_ controller: ScrollingNavigationController, didChangeState state: NavigationBarState)
    
  @objc optional func scrollingNavigationController(_ controller: ScrollingNavigationController, willChangeState state: NavigationBarState)

}

@objc public enum NavigationBarState: Int {
  case collapsed, expanded, scrolling
}

open class ScrollingNavigationController: UINavigationController, UIGestureRecognizerDelegate {
    
  open fileprivate(set) var state: NavigationBarState = .expanded {
    willSet {
      if state != newValue {
        scrollingNavbarDelegate?.scrollingNavigationController?(self, willChangeState: newValue)
      }
    }
    didSet {
      if state != oldValue {
        scrollingNavbarDelegate?.scrollingNavigationController?(self, didChangeState: state)
      }
    }
  }

  open var shouldScrollWhenContentFits = false
  open var expandOnActive = true
  open var scrollingEnabled = true
  open weak var scrollingNavbarDelegate: ScrollingNavigationControllerDelegate?

  open fileprivate(set) var gestureRecognizer: UIPanGestureRecognizer?
  var delayDistance: CGFloat = 0
  var maxDelay: CGFloat = 0
  var scrollableView: UIView?
  var lastContentOffset = CGFloat(0.0)

  open func followScrollView(_ scrollableView: UIView, delay: Double = 0) {
    self.scrollableView = scrollableView

    gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ScrollingNavigationController.handlePan(_:)))
    gestureRecognizer?.maximumNumberOfTouches = 1
    gestureRecognizer?.delegate = self
    scrollableView.addGestureRecognizer(gestureRecognizer!)

    NotificationCenter.default.addObserver(self, selector: #selector(ScrollingNavigationController.didBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(ScrollingNavigationController.didRotate(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)

    maxDelay = CGFloat(delay)
    delayDistance = CGFloat(delay)
    scrollingEnabled = true
  }

  public func hideNavbar(animated: Bool = true, duration: TimeInterval = 0.1) {
    guard let _ = self.scrollableView, let visibleViewController = self.visibleViewController else { return }

    if state == .expanded {
      self.state = .scrolling
      UIView.animate(withDuration: animated ? duration : 0, animations: { () -> Void in
        self.scrollWithDelta(self.fullNavbarHeight)
        visibleViewController.view.setNeedsLayout()
        if self.navigationBar.isTranslucent {
          let currentOffset = self.contentOffset
          self.scrollView()?.contentOffset = CGPoint(x: currentOffset.x, y: currentOffset.y + self.navbarHeight)
        }
      }) { _ in
        self.state = .collapsed
      }
    } else {
      updateNavbarAlpha()
    }
  }

  public func showNavbar(animated: Bool = true, duration: TimeInterval = 0.1) {
    guard let _ = self.scrollableView, let visibleViewController = self.visibleViewController else { return }

    if state == .collapsed {
      gestureRecognizer?.isEnabled = false
      self.state = .scrolling
      UIView.animate(withDuration: animated ? duration : 0.0, animations: {
        self.lastContentOffset = 0;
        self.delayDistance = -self.fullNavbarHeight
        self.scrollWithDelta(-self.fullNavbarHeight)
        visibleViewController.view.setNeedsLayout()
        if self.navigationBar.isTranslucent {
          let currentOffset = self.contentOffset
          self.scrollView()?.contentOffset = CGPoint(x: currentOffset.x, y: currentOffset.y - self.navbarHeight)
        }
      }) { _ in
        self.state = .expanded
        self.gestureRecognizer?.isEnabled = true
      }
    } else {
      updateNavbarAlpha()
    }
  }

  public func stopFollowingScrollView() {
    showNavbar(animated: false)
    if let gesture = gestureRecognizer {
      scrollableView?.removeGestureRecognizer(gesture)
    }
    scrollableView = .none
    gestureRecognizer = .none
    scrollingNavbarDelegate = .none
    scrollingEnabled = false

    let center = NotificationCenter.default
    center.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    center.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
  }

  // MARK: - Gesture recognizer

  func handlePan(_ gesture: UIPanGestureRecognizer) {
    if gesture.state != .failed {
      if let superview = scrollableView?.superview {
        let translation = gesture.translation(in: superview)
        let delta = lastContentOffset - translation.y
        lastContentOffset = translation.y

        if shouldScrollWithDelta(delta) {
          scrollWithDelta(delta)
        }
      }
    }

    if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
      checkForPartialScroll()
      lastContentOffset = 0
    }
  }

  // MARK: - Rotation handler

  func didRotate(_ notification: Notification) {
    showNavbar()
  }
    
  open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    showNavbar()
  }

  // MARK: - Notification handler

  func didBecomeActive(_ notification: Notification) {
    if expandOnActive {
      showNavbar(animated: false)
    }
  }

  /// Handles when the status bar changes
  func willChangeStatusBar() {
    showNavbar(animated: true)
  }

  // MARK: - Scrolling functions

  private func shouldScrollWithDelta(_ delta: CGFloat) -> Bool {

    if delta < 0 {
      if let scrollableView = scrollableView , contentOffset.y + scrollableView.frame.size.height > contentSize.height && scrollableView.frame.size.height < contentSize.height {
        return false
      }
    } else {
      if contentOffset.y < 0 {
        return false
      }
    }
    return true
  }

  private func scrollWithDelta(_ delta: CGFloat) {
    var scrollDelta = delta
    let frame = navigationBar.frame

    if scrollDelta > 0 {
      delayDistance -= scrollDelta

      if delayDistance > 0 {
        return
      }

      if !shouldScrollWhenContentFits && state != .collapsed &&
        (scrollableView?.frame.size.height)! >= contentSize.height {
        return
      }

      if frame.origin.y - scrollDelta < -deltaLimit {
        scrollDelta = frame.origin.y + deltaLimit
      }

      if frame.origin.y <= -deltaLimit {
        state = .collapsed
        delayDistance = maxDelay
      } else {
        state = .scrolling
      }
    }

    if scrollDelta < 0 {
      delayDistance += scrollDelta

      if delayDistance > 0 && maxDelay < contentOffset.y {
        return
      }

      if frame.origin.y - scrollDelta > statusBarHeight {
        scrollDelta = frame.origin.y - statusBarHeight
      }

      if frame.origin.y >= statusBarHeight {
        state = .expanded
        delayDistance = maxDelay
      } else {
        state = .scrolling
      }
    }

    updateSizing(scrollDelta)
    updateNavbarAlpha()
    restoreContentOffset(scrollDelta)
  }

  private func updateSizing(_ delta: CGFloat) {
    guard let topViewController = self.topViewController else { return }

    var frame = navigationBar.frame

    frame.origin = CGPoint(x: frame.origin.x, y: frame.origin.y - delta)
    navigationBar.frame = frame

    if !navigationBar.isTranslucent {
      let navBarY = navigationBar.frame.origin.y + navigationBar.frame.size.height
      frame = topViewController.view.frame
      frame.origin = CGPoint(x: frame.origin.x, y: navBarY)
      frame.size = CGSize(width: frame.size.width, height: view.frame.size.height - (navBarY) - tabBarOffset)
      topViewController.view.frame = frame
    } else {
      adjustContentInsets()
    }
  }

  private func adjustContentInsets() {
    if let view = scrollView() as? UICollectionView {
      view.contentInset.top = navigationBar.frame.origin.y + navigationBar.frame.size.height
      view.setContentOffset(CGPoint(x: contentOffset.x, y: contentOffset.y - 0.1), animated: false)
    }
  }

  private func restoreContentOffset(_ delta: CGFloat) {
    if navigationBar.isTranslucent || delta == 0 {
      return
    }

    if let scrollView = scrollView() {
      scrollView.setContentOffset(CGPoint(x: contentOffset.x, y: contentOffset.y - delta), animated: false)
    }
  }

  private func checkForPartialScroll() {
    let frame = navigationBar.frame
    var duration = TimeInterval(0)
    var delta = CGFloat(0.0)
    let distance = delta / (frame.size.height / 2)

    // Scroll back down
    let threshold = statusBarHeight - (frame.size.height / 2)
    if navigationBar.frame.origin.y >= threshold {
      delta = frame.origin.y - statusBarHeight
      duration = TimeInterval(abs(distance * 0.2))
      state = .expanded
    } else {
      // Scroll up
      delta = frame.origin.y + deltaLimit
      duration = TimeInterval(abs(distance * 0.2))
      state = .collapsed
    }

    delayDistance = maxDelay

    UIView.animate(withDuration: duration, delay: 0, options: UIViewAnimationOptions.beginFromCurrentState, animations: {
      self.updateSizing(delta)
      self.updateNavbarAlpha()
      }, completion: nil)
  }

  private func updateNavbarAlpha() {
    guard let navigationItem = visibleViewController?.navigationItem else { return }

    let frame = navigationBar.frame
    let alpha = (frame.origin.y + deltaLimit) / frame.size.height

    navigationItem.titleView?.alpha = alpha
    navigationBar.tintColor = navigationBar.tintColor.withAlphaComponent(alpha)
    if let titleColor = navigationBar.titleTextAttributes?[NSForegroundColorAttributeName] as? UIColor {
      navigationBar.titleTextAttributes?[NSForegroundColorAttributeName] = titleColor.withAlphaComponent(alpha)
    } else {
      navigationBar.titleTextAttributes?[NSForegroundColorAttributeName] = UIColor.black.withAlphaComponent(alpha)
    }

    func shouldHideView(_ view: UIView) -> Bool {
      let className = view.classForCoder.description()
      return className == "UINavigationButton" ||
        className == "UINavigationItemView" ||
        className == "UIImageView" ||
        className == "UISegmentedControl"
    }
    navigationBar.subviews
      .filter(shouldHideView)
      .forEach { $0.alpha = alpha }

    navigationItem.leftBarButtonItem?.customView?.alpha = alpha
    if let leftItems = navigationItem.leftBarButtonItems {
      leftItems.forEach { $0.customView?.alpha = alpha }
    }

    navigationItem.rightBarButtonItem?.customView?.alpha = alpha
    if let leftItems = navigationItem.rightBarButtonItems {
      leftItems.forEach { $0.customView?.alpha = alpha }
    }
  }

  // MARK: - UIGestureRecognizerDelegate

  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }

  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    return scrollingEnabled
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

}
