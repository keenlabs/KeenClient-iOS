//
//  KIOQuery.m
//  KeenClient
//
//  Created by Heitor Sergent on 4/21/15.
//  Copyright (c) 2015 Keen Labs. All rights reserved.
//

#import "KIOQuery.h"

@implementation KIOQuery

- (id)initWithQuery:(NSString *)queryType andEventCollection:(NSString *)eventCollection {
    if (![KIOQuery validateQueryType:queryType]) {
        return nil;
    }
    
    self = [self init];
    
    if (self) {
        self.queryType = queryType;
        self.eventCollection = eventCollection;
    }
    
    return self;
}

+ (BOOL)validateQueryType:(NSString *)queryType {
    // validate that project ID is acceptable
    if (!queryType || [queryType length] == 0) {
        return NO;
    }
    return YES;
}

- (NSData *)convertQueryToData {
    NSError *error = nil;
    
    NSMutableDictionary *requestDict = [NSMutableDictionary dictionary];
    
    [requestDict setObject:self.eventCollection forKey:@"event_collection"];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:requestDict options:0 error:&error];
    
    NSString *strData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    
    NSLog(@"data: %@", strData);
    
    return data;
}

@end
