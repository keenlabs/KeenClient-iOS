//
//  KIOQuery.m
//  KeenClient
//
//  Created by Heitor Sergent on 4/21/15.
//  Copyright (c) 2015 Keen Labs. All rights reserved.
//

#import "KIOQuery.h"

@implementation KIOQuery

- (id)initWithQuery:(NSString *)queryType andPropertiesDictionary:(NSDictionary *)propertiesDictionary {
    if (queryType == nil || queryType.length <= 0) {
        return nil;
    }
    
    self = [super init];
    
    if (self) {
        self.queryType = queryType;
        self.propertiesDictionary = propertiesDictionary;
    }
    
    return self;
}

- (id)initWithQuery:(NSString *)queryType andQueryName:(NSString *)queryName andPropertiesDictionary:(NSDictionary *)propertiesDictionary {
    if (queryType == nil || queryType.length <= 0) {
        return nil;
    }
    
    self = [super init];
    
    if (self) {
        self.queryType = queryType;
        self.queryName = queryName;
        self.propertiesDictionary = propertiesDictionary;
    }
    
    return self;
}

- (NSData *)convertQueryToData {
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.propertiesDictionary options:0 error:&error];
    
    return data;
}

@end
