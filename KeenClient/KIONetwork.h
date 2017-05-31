//
//  KIONetwork.h
//  KeenClient
//
//  Created by Brian Baumhover on 3/22/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KeenClientConfig.h"
#import "KIONSURLSessionFactory.h"

// Class for handling network operations
@interface KIONetwork : NSObject

// Get a default shared instance of the object
+ (instancetype)sharedInstance;

// Initialize the object
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithURLSessionFactory:(id<KIONSURLSessionFactory>)urlSessionFactory andStore:(KIODBStore *)store;

// Configure a proxy server
- (BOOL)setProxy:(NSString *)host port:(NSString *)port;

// Upload events to keen
- (void)sendEvents:(NSData *)data
               config:(KeenClientConfig *)config
    completionHandler:(AnalysisCompletionBlock)completionHandler;

// Run an analysis request
- (void)runQuery:(KIOQuery *)keenQuery
               config:(KeenClientConfig *)config
    completionHandler:(AnalysisCompletionBlock)completionHandler;

// Run a multi-analysis request
- (void)runMultiAnalysisWithQueries:(NSArray *)keenQueries
                             config:(KeenClientConfig *)config
                  completionHandler:(AnalysisCompletionBlock)completionHandler;

// Run a saved/cached query request
- (void)runSavedAnalysis:(NSString *)queryName
                  config:(KeenClientConfig *)config
       completionHandler:(AnalysisCompletionBlock)completionHandler;

// Run a dataset-based query request
- (void)runDatasetQuery:(NSString *)datasetName
             indexValue:(NSString *)indexValue
              timeframe:(NSString *)timeframe
                 config:(KeenClientConfig *)config
      completionHandler:(AnalysisCompletionBlock)completionHandler;

// The maximum number of times to try a query before stop attempting it.
@property int maxQueryAttempts;

// The number of seconds before deleting a failed query from the database.
@property int queryTTL;

// The NSURLSession instance to use for requests
@property (nonatomic, readonly) NSURLSession *urlSession;

// The current proxy configuration, if set. To set the configuration, use setProxy:port:.
@property (nonatomic, readonly) NSString *proxyHost;
@property (nonatomic, readonly) NSString *proxyPort;

@end
