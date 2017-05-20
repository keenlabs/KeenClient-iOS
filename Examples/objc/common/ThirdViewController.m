//
//  ThirdViewController.m
//  KeenClientExample
//
//  Created by Heitor Sergent on 5/23/15.
//  Copyright (c) 2015 Keen Labs. All rights reserved.
//

#import "ThirdViewController.h"
#import <KeenClient/KeenClient.h>

@implementation ThirdViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Third", @"Third");
        self.tabBarItem.image = [UIImage imageNamed:@"third"];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [self setResultTextView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (IBAction)countQueryButtonPressed:(id)sender {
    void (^countQueryCompleted)(NSData *, NSURLResponse *, NSError *) = ^(NSData *responseData, NSURLResponse *returningResponse, NSError *error) {
        NSDictionary *responseDictionary = [NSJSONSerialization
                                            JSONObjectWithData:responseData
                                            options:kNilOptions
                                            error:nil];
        
        NSLog(@"response: %@", responseDictionary);
        NSLog(@"error: %@", [error localizedDescription]);
        
        NSNumber *result = [responseDictionary objectForKey:@"result"];
        
        NSLog(@"result: %@", result);
        
        // Get result value when querying with group_by property
        //NSNumber *resultValue = [[responseDictionary objectForKey:@"result"][0] objectForKey:@"result"];
        //NSLog(@"resultValue: %@", resultValue);
        
        if(error || [responseDictionary objectForKey:@"error_code"]) {
            self.resultTextView.text = [NSString stringWithFormat:@"Failure! 😞 \n\n error: %@\n\n response: %@", [error localizedDescription] ,[responseDictionary description]];
        } else {
            self.resultTextView.text = [NSString stringWithFormat:@"Success! 😄 \n\n response: %@", [responseDictionary description]];
        }
    };
    
    // Async querying
    KIOQuery *countQuery = [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{@"event_collection": @"collection", @"timeframe": @"this_7_days"}];
    
    [[KeenClient sharedClient] runAsyncQuery:countQuery block:countQueryCompleted];
    
    // Multi-analysis querying example
    /*
    KIOQuery *countUniqueQuery = [[KIOQuery alloc] initWithQuery:@"count_unique" andPropertiesDictionary:@{@"event_collection": @"collection", @"target_property": @"key", @"timeframe": @"this_7_days"}];
    
    [countQuery setQueryName:@"count_query"];
    [countUniqueQuery setQueryName:@"count_unique_query"];
    
    [[KeenClient sharedClient] runAsyncMultiAnalysisWithQueries:@[countQuery, countUniqueQuery] block:countQueryCompleted];
     */
    
    // Funnel example
    /*
    KIOQuery *funnelQuery = [[KIOQuery alloc] initWithQuery:@"funnel" andPropertiesDictionary:@{@"timeframe": @"this_7_days", @"steps": @[@{@"event_collection": @"user_signed_up",
            @"actor_property": @"user.id"},
          @{@"event_collection": @"user_completed_profile",
            @"actor_property": @"user.id"}]}];
    
    [[KeenClient sharedClient] runAsyncQuery:funnelQuery block:countQueryCompleted];
     */
}

@end
