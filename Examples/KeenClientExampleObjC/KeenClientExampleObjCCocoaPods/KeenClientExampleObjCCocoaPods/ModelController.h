//
//  ModelController.h
//  KeenClientExampleObjCCocoaPods
//
//  Created by Brian Baumhover on 5/19/17.
//  Copyright © 2017 Keen IO. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DataViewController;

@interface ModelController : NSObject <UIPageViewControllerDataSource>

- (DataViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard;
- (NSUInteger)indexOfViewController:(DataViewController *)viewController;

@end

