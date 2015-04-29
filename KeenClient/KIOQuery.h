//
//  KIOQuery.h
//  KeenClient
//
//  Created by Heitor Sergent on 4/21/15.
//  Copyright (c) 2015 Keen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KIOQuery : NSObject

@property (nonatomic, strong) NSString *queryType;
@property (nonatomic, strong) NSString *eventCollection;

- (id)initWithQuery:(NSString *)queryType andEventCollection:(NSString *)eventCollection;

+ (BOOL)validateQueryType:(NSString *)queryType;

- (NSData *)convertQueryToData;

@end
