//
//  KeenTestCaseBase.h
//  KeenClient
//
//  Created by Brian Baumhover on 4/27/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface KeenTestCaseBase : XCTestCase

- (NSDictionary*)buildResultWithSuccess:(BOOL)success
                            andErrorCode:(NSString*)errorCode
                          andDescription:(NSString*)description;

- (NSDictionary*)buildResponseJsonWithSuccess:(BOOL)success
                                  AndErrorCode:(NSString*)errorCode
                                AndDescription:(NSString*)description;

- (id)createClientWithRequestValidator:(BOOL (^)(id obj))validator;

- (id)createClientWithResponseData:(id)data
                     andStatusCode:(NSInteger)code;

- (id)createClientWithResponseData:(id)data
                     andStatusCode:(NSInteger)code
               andNetworkConnected:(NSNumber*)isNetworkConnected;

- (id)mockUrlSessionWithResponse:(NSHTTPURLResponse*)response
                 andResponseData:(NSData*)responseData
             andRequestValidator:(BOOL (^)(id requestObject))requestValidator;

- (id)createClientWithResponseData:(id)data
                     andStatusCode:(NSInteger)code
               andNetworkConnected:(NSNumber*)isNetworkConnected
               andRequestValidator:(BOOL (^)(id obj))requestValidator;

@end
