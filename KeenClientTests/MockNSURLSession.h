//
//  MockNSURLSession.h
//  KeenClient
//
//  Created by Brian Baumhover on 6/7/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MockNSURLSession : NSObject

- (instancetype)initWithValidator:(BOOL (^)(id requestObject))validator data:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error;

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *_Nullable data,
                                                        NSURLResponse *_Nullable response,
                                                        NSError *_Nullable error))completionHandler;

@end

