//
//  KeenClientConfig.m
//  KeenClient
//
//  Created by Brian Baumhover on 4/27/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import "KeenClientConfig.h"
#import "KIOUtil.h"
#import "KeenClient.h"
#import "KeenConstants.h"

@implementation KeenClientConfig

- (instancetype)initWithProjectID:(NSString *)projectID
                      andWriteKey:(NSString *)writeKey
                       andReadKey:(NSString *)readKey {
    return [self initWithProjectID:projectID
                       andWriteKey:writeKey
                        andReadKey:readKey
                   apiUrlAuthority:nil];
}

- (instancetype)initWithProjectID:(NSString *)projectID
                      andWriteKey:(NSString *)writeKey
                       andReadKey:(NSString *)readKey
                  apiUrlAuthority:(NSString *)apiUrlAuthority {
    if (nil == projectID || projectID.length <= 0) {
        KCLogError(@"You must provide a projectID.");
        return nil;
    }

    if (writeKey && writeKey.length <= 0) {
        KCLogError(@"Your writeKey cannot be an empty string.");
        return nil;
    }

    if (readKey && readKey.length <= 0) {
        KCLogError(@"Your readKey cannot be an empty string.");
        return nil;
    }

    if (nil != apiUrlAuthority && apiUrlAuthority.length <= 0) {
        KCLogError(@"A URL authority for the API cannot be zero length.");
        return nil;
    }

    if (nil == apiUrlAuthority) {
        apiUrlAuthority = kKeenDefaultApiUrlAuthority;
    }

    self = [super init];

    if (self) {
        self.projectID = projectID;
        self.writeKey = writeKey;
        self.readKey = readKey;
        self.apiUrlAuthority = apiUrlAuthority;
    }

    return self;
}

@end
