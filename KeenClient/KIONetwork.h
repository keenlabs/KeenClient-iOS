//
//  KIONetwork.h
//  KeenClient
//
//  Created by Brian Baumhover on 3/22/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KeenClientConfig.h"

// Class for handling network operations
@interface KIONetwork : NSObject

// Get a default shared instance of the object
+ (instancetype)sharedInstance;

// Initialize the object
- (instancetype)initWithURLSession:(NSURLSession*)urlSession
                          andStore:(KIODBStore*)store;

// Upload events to keen
- (void)sendEvents:(NSData*)data
            config:(KeenClientConfig*)config
 completionHandler:(AnalysisCompletionBlock)completionHandler;

// Run an analysis request
- (void)runQuery:(KIOQuery*)keenQuery config:(KeenClientConfig*)config
                           completionHandler:(AnalysisCompletionBlock)completionHandler;

// Run a multi-analysis request
- (void)runMultiAnalysisWithQueries:(NSArray*)keenQueries
                             config:(KeenClientConfig*)config
                  completionHandler:(AnalysisCompletionBlock)completionHandler;

// Run a saved/cached query request
- (void)runAsyncSavedAnalysis:(NSString*)queryName
                       config:(KeenClientConfig*)config
            completionHandler:(AnalysisCompletionBlock)completionHandler;


// The maximum number of times to try a query before stop attempting it.
@property int maxQueryAttempts;

// The number of seconds before deleting a failed query from the database.
@property int queryTTL;

// The NSURLSession instance to use for requests
@property (nonatomic, readonly) NSURLSession* urlSession;

@end
