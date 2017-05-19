//
//  DataViewController.h
//  KeenClientExampleObjCCarthage
//
//  Created by Brian Baumhover on 5/19/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DataViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *dataLabel;
@property (strong, nonatomic) id dataObject;

@end

