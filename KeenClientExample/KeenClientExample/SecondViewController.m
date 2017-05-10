//
//  SecondViewController.m
//  KeenClientExample
//
//  Created by Daniel Kador on 2/13/12.
//  Copyright (c) 2012 Keen Labs. All rights reserved.
//

#import "SecondViewController.h"
#import "KeenClient.h"

@implementation SecondViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Second", @"Second");
        self.tabBarItem.image = [UIImage imageNamed:@"second"];
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSDictionary *event =
        [NSDictionary dictionaryWithObjectsAndKeys:@"second view", @"view_name", @"going to", @"action", nil];
    [[KeenClient sharedClient] addEvent:event toEventCollection:@"tab_views" error:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    NSDictionary *event =
        [NSDictionary dictionaryWithObjectsAndKeys:@"second view", @"view_name", @"leaving from", @"action", nil];
    [[KeenClient sharedClient] addEvent:event toEventCollection:@"tab_views" error:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
