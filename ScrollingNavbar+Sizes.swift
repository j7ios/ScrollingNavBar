//  Created by Jack7 on 30/08/16.
//  Copyright © 2016 GiacomoB. All rights reserved.
//

import UIKit

/*
 Implements the main functions providing constants values and computed ones
 */

extension ScrollingNavigationController {

  // MARK: - View sizing

  var fullNavbarHeight: CGFloat {
    return navbarHeight + statusBarHeight
  }

  var navbarHeight: CGFloat {
    return navigationBar.frame.size.height
  }

  var statusBarHeight: CGFloat {
    return UIApplication.shared.statusBarFrame.size.height
  }

  var tabBarOffset: CGFloat {
    if let tabBarController = tabBarController {
      return tabBarController.tabBar.isTranslucent ? 0 : tabBarController.tabBar.frame.height
    }
    return 0
  }

  func scrollView() -> UIScrollView? {
    if let webView = self.scrollableView as? UIWebView {
      return webView.scrollView
    } else {
      return scrollableView as? UIScrollView
    }
  }

  var contentOffset: CGPoint {
    return scrollView()?.contentOffset ?? CGPoint.zero
  }

  var contentSize: CGSize {
    return scrollView()?.contentSize ?? CGSize.zero
  }

  var deltaLimit: CGFloat {
    return navbarHeight - statusBarHeight
  }
}
