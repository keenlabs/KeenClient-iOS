//
//  KIONetwork.h
//  KeenClient
//
//  Created by Brian Baumhover on 3/22/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

// Class for handling network operations
@interface KIONetwork : NSObject

// Get a default shared instance of the object
+ (instancetype)sharedInstance;

// Initialize the object
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithURLSession:(NSURLSession *)urlSession
                          andStore:(KIODBStore *)store;

// Upload events to keen
- (void)sendEvents:(NSData *)data
     withProjectID:(NSString *)projectID
      withWriteKey:(NSString *)writeKey
 completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

// Run an analysis request
- (void)runQuery:(KIOQuery *)keenQuery withProjectID:(NSString *)projectID
     withReadKey:(NSString *)readKey
completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

// Run a multi-analysis request
- (void)runMultiAnalysisWithQueries:(NSArray *)keenQueries
                      withProjectID:(NSString *)projectID
                        withReadKey:(NSString *)readKey
                  completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;


// The maximum number of times to try a query before stop attempting it.
@property int maxQueryAttempts;

// The number of seconds before deleting a failed query from the database.
@property int queryTTL;

// The NSURLSession instance to use for requests
@property (nonatomic, readonly) NSURLSession *urlSession;

@end
