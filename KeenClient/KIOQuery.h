//
//  KIOQuery.h
//  KeenClient
//
//  Created by Heitor Sergent on 4/21/15.
//  Copyright (c) 2015 Keen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KIOQuery : NSObject

@property (nonatomic) NSString *queryType;
@property (nonatomic) NSString *queryName;
@property (nonatomic) NSDictionary *propertiesDictionary;

- (id)initWithQuery:(NSString *)queryType andPropertiesDictionary:(NSDictionary *)propertiesDictionary;
- (id)initWithQuery:(NSString *)queryType
               andQueryName:(NSString *)queryName
    andPropertiesDictionary:(NSDictionary *)propertiesDictionary;

- (NSData *)convertQueryToData;

@end
