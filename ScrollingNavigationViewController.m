//  Created by Jack7 on 30/08/16.
//  Copyright © 2016 GiacomoB. All rights reserved.
//

#import "ScrollingNavigationViewController.h"

@interface ScrollingNavigationViewController ()

@end

@implementation ScrollingNavigationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
    
    
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    ScrollingNavigationController *scrollNav = (ScrollingNavigationController *)self.navigationController;
    
    if ([scrollNav isKindOfClass:[ScrollingNavigationController class]])
    {
        [scrollNav showNavbarWithAnimated:YES duration:0.1];
    }
    
}
    
- (void)viewWillDisappear:(BOOL)animated{
    
    [super viewDidDisappear:animated];
        
    ScrollingNavigationController *scrollNav = (ScrollingNavigationController *)self.navigationController;
    
    if ([scrollNav isKindOfClass:[ScrollingNavigationController class]])
    {
        [scrollNav stopFollowingScrollView];
    }
}
    
    
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView{
    ScrollingNavigationController *scrollNav = (ScrollingNavigationController *)self.navigationController;
    
    if (scrollNav)
    {
        [scrollNav showNavbarWithAnimated:YES duration:0.1];
    }

    return YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
