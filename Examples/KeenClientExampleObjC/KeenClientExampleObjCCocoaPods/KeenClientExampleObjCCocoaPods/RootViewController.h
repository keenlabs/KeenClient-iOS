//
//  RootViewController.h
//  KeenClientExampleObjCCocoaPods
//
//  Created by Brian Baumhover on 5/19/17.
//  Copyright © 2017 Keen IO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UIViewController <UIPageViewControllerDelegate>

@property (strong, nonatomic) UIPageViewController *pageViewController;

@end

