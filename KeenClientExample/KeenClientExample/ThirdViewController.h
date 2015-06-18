//
//  ThirdViewController.h
//  KeenClientExample
//
//  Created by Heitor Sergent on 5/23/15.
//  Copyright (c) 2015 Keen Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ThirdViewController : UIViewController

@property (retain, nonatomic) IBOutlet UITextView *resultTextView;

- (IBAction)countQueryButtonPressed:(id)sender;

@end
