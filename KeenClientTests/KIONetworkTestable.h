//
//  KIONetworkTestable.h
//  KeenClient
//
//  Created by Brian Baumhover on 4/27/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

@interface KIONetwork (Testable)

- (void)handleQueryAPIResponse:(NSURLResponse *)response
                       andData:(NSData *)responseData
                      andQuery:(KIOQuery *)query
                  andProjectID:(NSString *)projectID;

@end
