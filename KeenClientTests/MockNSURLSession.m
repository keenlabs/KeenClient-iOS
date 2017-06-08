//
//  MockNSURLSession.m
//  KeenClient
//
//  Created by Brian Baumhover on 6/7/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MockNSURLSession.h"

@interface MockNSURLSession ()

@property NSData* data;
@property NSURLResponse* response;
@property NSError* error;
@property BOOL (^validator)(id requestObject);

@end

@implementation MockNSURLSession

- (instancetype)initWithValidator:(BOOL (^)(id requestObject))validator data:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error {
    self = [super init];

    if (self) {
        self.validator = validator;
        self.data = data;
        self.response = response;
        self.error = error;
    }

    return self;
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *_Nullable data,
                                                        NSURLResponse *_Nullable response,
                                                        NSError *_Nullable error))completionHandler {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        if (self.validator) {
            if (!self.validator(request)) {
                [NSException raise:@"TestException" format:@"Request validator failed validation."];
            }
        }
        completionHandler(self.data, self.response, self.error);
    });

    return nil;
}

@end
