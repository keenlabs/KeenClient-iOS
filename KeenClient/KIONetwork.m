//
//  KIONetwork.m
//  KeenClient
//
//  Created by Brian Baumhover on 3/22/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import "KeenConstants.h"
#import "KeenClient.h"
#import "KIONetwork.h"
#import "KIOFileStore.h"
#import "KIODBStore.h"
#import "HTTPCodes.h"
#import "KIOUtil.h"
#import "KIONSURLSessionFactory.h"
#import "KIODefaultNSURLSessionFactory.h"

typedef NS_ENUM(NSInteger, KeenHTTPMethod) { KeenHTTPMethodUnknown, KeenHTTPMethodPost, KeenHTTPMethodGet };

@interface KIONetwork ()

/**
 Handles the HTTP response from the Keen Query API.
 @param response The response from the server.
 @param responseData The data returned from the server.
 @param query The query that was passed to the Keen API.
 @param error The error returned with the response.
 */
- (void)handleQueryAPIResponse:(NSURLResponse *)response
                       andData:(NSData *)responseData
                      andQuery:(KIOQuery *)query
                  andProjectID:(NSString *)projectID
                      andError:(NSError *)error;

- (NSString *)getProjectURL:(KeenClientConfig *)config;

@property (nonatomic, readwrite) id<KIONSURLSessionFactory> urlSessionFactory;

@property (nonatomic) KIODBStore *store;

// Internal read/write versions of proxy host and port
@property (nonatomic, readwrite) NSString *proxyHost;
@property (nonatomic, readwrite) NSNumber *proxyPort;

@end

@implementation KIONetwork

+ (instancetype)sharedInstance {
    static KIONetwork *s_sharedInstance;

    // This black magic ensures this block
    // is dispatched only once over the lifetime
    // of the program. It's nice because
    // this works even when there's a race
    // between threads to create the object,
    // as both threads will wait synchronously
    // for the block to complete.
    static dispatch_once_t predicate = {0};
    dispatch_once(&predicate, ^{
        s_sharedInstance = [[KIONetwork alloc] initWithURLSessionFactory:[KIODefaultNSURLSessionFactory new]
                                                                andStore:[KIODBStore sharedInstance]];
    });

    return s_sharedInstance;
}

- (instancetype)initWithURLSessionFactory:(id<KIONSURLSessionFactory>)urlSessionFactory andStore:(KIODBStore *)store {
    self = [super init];

    if (self) {
        self.maxQueryAttempts = 10;
        self.queryTTL = 3600;
        self.urlSessionFactory = urlSessionFactory;
        self.store = store;
    }

    return self;
}

- (BOOL)setProxy:(NSString *)host port:(NSNumber *)port {
    BOOL success = NO;

    if ((nil == host) != (nil == port)) {
        // host is nil, but port is set
        // port is nil, but host is set
        KCLogError(@"setProxy: host and port must both be nil or both be set");
        success = NO;
    } else {
        if (!host || !port) {
            self.proxyHost = nil;
            self.proxyPort = nil;
        } else {
            self.proxyHost = host;
            self.proxyPort = port;
        }
        success = YES;
    }

    return success;
}

- (NSMutableURLRequest *)createRequestWithUrl:(NSString *)urlString
                                    andMethod:(KeenHTTPMethod)eHttpMethod
                                      andBody:(NSData *)body
                                       andKey:(NSString *)key {
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request =
        [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0f];
    NSString *httpMethod;
    switch (eHttpMethod) {
        case KeenHTTPMethodGet: {
            httpMethod = @"GET";
            break;
        }
        case KeenHTTPMethodPost: {
            httpMethod = @"POST";
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [request setValue:[NSString stringWithFormat:@"%lud", (unsigned long)[body length]]
                forHTTPHeaderField:@"Content-Length"];
            [request setHTTPBody:body];
            break;
        }
        default: {
            KCLogError(@"Inavlid eHttpMethod: %@", [NSNumber numberWithInt:eHttpMethod]);
            return nil;
        }
    }
    [request setHTTPMethod:httpMethod];
    [request setValue:key forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:kKeenSdkVersionWithPlatform forHTTPHeaderField:kKeenSdkVersionHeader];
    return request;
}

- (void)executeRequest:(NSURLRequest *)request completionHandler:(AnalysisCompletionBlock)completionHandler {
    NSURLSession *session;
    // Use proxy if one has been configured
    if (self.proxyHost && self.proxyPort) {
        // Create an NSURLSessionConfiguration that uses the proxy
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        configuration.connectionProxyDictionary = @{
            @"HTTPEnable": @(YES),
            (NSString *)kCFStreamPropertyHTTPProxyHost: self.proxyHost,
            (NSString *)kCFStreamPropertyHTTPProxyPort: self.proxyPort,
            @"HTTPSEnable": @(YES),
            (NSString *)kCFStreamPropertyHTTPSProxyHost: self.proxyHost,
            (NSString *)kCFStreamPropertyHTTPSProxyPort: self.proxyPort,
        };
        session = [self.urlSessionFactory sessionWithConfiguration:configuration];
    } else {
        session = [self.urlSessionFactory session];
    }
    [[session dataTaskWithRequest:request completionHandler:completionHandler] resume];
}

- (BOOL)hasQueryReachedMaxAttempts:(KIOQuery *)keenQuery withProjectID:(NSString *)projectID {
    return [self.store hasQueryWithMaxAttempts:[keenQuery convertQueryToData]
                                     queryType:keenQuery.queryType
                                    collection:[keenQuery.propertiesDictionary objectForKey:@"event_collection"]
                                     projectID:projectID
                                   maxAttempts:self.maxQueryAttempts
                                      queryTTL:self.queryTTL];
}

- (NSString *)getProjectURL:(KeenClientConfig *)config {
    return [NSString stringWithFormat:@"%@://%@/%@/projects/%@",
                                      kKeenApiUrlScheme,
                                      config.apiUrlAuthority,
                                      kKeenApiVersion,
                                      config.projectID];
}

#pragma mark Sync methods

- (void)sendEvents:(NSData *)data
               config:(KeenClientConfig *)config
    completionHandler:(AnalysisCompletionBlock)completionHandler {
    IF_STRING_EMPTY_COMPLETE(config.projectID);
    IF_STRING_EMPTY_COMPLETE(config.writeKey);
    IF_NIL_COMPLETE(data);

    NSString *urlString;
    if (config.meridianBrokerURL) {
       urlString = config.meridianBrokerURL;
    } else {
        urlString = [NSString stringWithFormat:@"%@/events", [self getProjectURL:config]];
    }
    KCLogVerbose(@"Sending request to: %@", urlString);

    NSMutableURLRequest *request =
        [self createRequestWithUrl:urlString andMethod:KeenHTTPMethodPost andBody:data andKey:config.writeKey];
    
    // Allow our delegate to make updates to the outgoing request
    if (config.networkDelegate) {
        [config.networkDelegate updateCollectionRequest:request];
    }

    [self executeRequest:request completionHandler:^(NSData *responseData, NSURLResponse *response, NSError *error) {
        // If we get a 401, attempt to reauth
        if (((NSHTTPURLResponse *)response).statusCode == 401 && config.networkDelegate) {
            [config.networkDelegate authenticateSessionWithCompletionHandler:^(NSError *error) {
                // For now just send back the original response (Keen will retry later because of the error)
                completionHandler(responseData, response, error);
            }];
        } else {
            completionHandler(responseData, response, error);
        }
    }];
}

- (void)runQuery:(KIOQuery *)keenQuery
               config:(KeenClientConfig *)config
    completionHandler:(AnalysisCompletionBlock)completionHandler {
    IF_STRING_EMPTY_COMPLETE(config.projectID);
    IF_STRING_EMPTY_COMPLETE(config.readKey);
    IF_NIL_COMPLETE(keenQuery);

    BOOL hasQueryWithMaxAttempts = [self hasQueryReachedMaxAttempts:keenQuery withProjectID:config.projectID];
    if (hasQueryWithMaxAttempts) {
        KCLogWarn(@"Not running query because it failed over %d times", self.maxQueryAttempts);
        return;
    }

    NSString *urlString =
        [NSString stringWithFormat:@"%@/queries/%@", [self getProjectURL:config], keenQuery.queryType];
    KCLogVerbose(@"Sending request to: %@", urlString);

    NSMutableURLRequest *request = [self createRequestWithUrl:urlString
                                                    andMethod:KeenHTTPMethodPost
                                                      andBody:[keenQuery convertQueryToData]
                                                       andKey:config.readKey];
    // Capture config.projectID in case config changes someday
    NSString *projectID = config.projectID;
    [self executeRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            [self handleQueryAPIResponse:response
                                 andData:data
                                andQuery:keenQuery
                            andProjectID:projectID
                                andError:error];
            if (nil != completionHandler) {
                completionHandler(data, response, error);
            }
        }];
}

- (void)handleQueryAPIResponse:(NSURLResponse *)response
                       andData:(NSData *)responseData
                      andQuery:(KIOQuery *)query
                  andProjectID:(NSString *)projectID
                      andError:(NSError *)error {
    // Check if call to the Query API failed
    if (nil == responseData || nil != error) {
        KCLogError(@"Error reading response. error: %@\nresponse data: %@", error, responseData);
        KCLogError(@"response status code: %ld", (long)[((NSHTTPURLResponse *)response)statusCode]);
        return;
    }

    NSInteger responseCode = [((NSHTTPURLResponse *)response)statusCode];

    // if the query failed because of a client error, let's add it to the database
    if (query && [HTTPCodes httpCodeType:(responseCode)] == HTTPCode4XXClientError) {
        // log what happened
        KCLogError(@"Response code was 4xx Client Error. It was: %ld", (long)responseCode);
        NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        KCLogError(@"Response body was: %@", responseString);

        // check if query is inside the database, and if so increment attempts counter
        // if not, add it
        [self.store findOrUpdateQuery:[query convertQueryToData]
                            queryType:query.queryType
                           collection:[query.propertiesDictionary objectForKey:@"event_collection"]
                            projectID:projectID];
    }
}

- (NSDictionary *)prepareQueriesDictionaryForMultiAnalysis:(NSArray *)keenQueries {
    NSMutableDictionary *multiAnalysisDictionary = [@{
        @"event_collection": [NSNull null],
        @"filters": [NSNull null],
        @"timeframe": [NSNull null],
        @"timezone": [NSNull null],
        @"group_by": [NSNull null],
        @"interval": [NSNull null]
    } mutableCopy];
    NSMutableDictionary *queriesDictionary = [NSMutableDictionary dictionary];
    for (int i = 0; i < keenQueries.count; i++) {
        if (![keenQueries[i] isKindOfClass:[KIOQuery class]]) {
            KCLogError(@"keenQueries array contain objects that are not of class KIOQuery");
            return nil;
        }

        KIOQuery *query = keenQueries[i];
        NSMutableDictionary *queryMutablePropertiesDictionary = [[query propertiesDictionary] mutableCopy];

        // check that Keen queries have the same parameters
        for (NSString *key in [multiAnalysisDictionary allKeys]) {
            NSObject *queryProperty = [[query propertiesDictionary] objectForKey:key];
            if (queryProperty != nil) {
                if ([multiAnalysisDictionary objectForKey:key] == [NSNull null]) {
                    [multiAnalysisDictionary setObject:queryProperty forKey:key];
                } else if (![[multiAnalysisDictionary objectForKey:key] isEqual:queryProperty]) {
                    KCLogError(@"queries %@ property doesn't match", key);
                    return nil;
                }
                [queryMutablePropertiesDictionary removeObjectForKey:key];
            }
        }

        [queryMutablePropertiesDictionary setObject:[query queryType] forKey:@"analysis_type"];

        NSString *queryName = [query queryName] ?: [[NSString alloc] initWithFormat:@"query%d", i];
        [queriesDictionary setObject:queryMutablePropertiesDictionary forKey:queryName];
    }

    [multiAnalysisDictionary setObject:queriesDictionary forKey:@"analyses"];

    return [multiAnalysisDictionary copy];
}

- (void)runMultiAnalysisWithQueries:(NSArray *)keenQueries
                             config:(KeenClientConfig *)config
                  completionHandler:(AnalysisCompletionBlock)completionHandler {
    IF_STRING_EMPTY_COMPLETE(config.projectID);
    IF_STRING_EMPTY_COMPLETE(config.readKey);
    IF_NIL_COMPLETE(keenQueries);

    NSString *urlString =
        [NSString stringWithFormat:@"%@/queries/%@", [self getProjectURL:config], @"multi_analysis"];
    KCLogVerbose(@"Sending request to: %@", urlString);

    NSDictionary *multiAnalysisDictionary = [self prepareQueriesDictionaryForMultiAnalysis:keenQueries];
    if (multiAnalysisDictionary == nil) {
        return;
    }

    // convert the resulting dictionary to data and set it as HTTPBody
    NSError *dictionarySerializationError = nil;

    NSData *multiAnalysisData =
        [NSJSONSerialization dataWithJSONObject:multiAnalysisDictionary options:0 error:&dictionarySerializationError];

    if (dictionarySerializationError != nil) {
        KCLogError(@"error with dictionary serialization");
        return;
    }

    NSMutableURLRequest *request = [self createRequestWithUrl:urlString
                                                    andMethod:KeenHTTPMethodPost
                                                      andBody:multiAnalysisData
                                                       andKey:config.readKey];

    [self executeRequest:request completionHandler:completionHandler];
}

- (void)runSavedAnalysis:(NSString *)queryName
                  config:(KeenClientConfig *)config
       completionHandler:(AnalysisCompletionBlock)completionHandler {
    IF_STRING_EMPTY_COMPLETE(config.projectID);
    IF_STRING_EMPTY_COMPLETE(config.readKey);
    IF_STRING_EMPTY_COMPLETE(queryName);

    NSString *urlString =
        [NSString stringWithFormat:@"%@/queries/saved/%@/result", [self getProjectURL:config], queryName];
    KCLogVerbose(@"Sending request to: %@", urlString);

    NSMutableURLRequest *request =
        [self createRequestWithUrl:urlString andMethod:KeenHTTPMethodGet andBody:nil andKey:config.readKey];

    [self executeRequest:request completionHandler:completionHandler];
}

- (void)runDatasetQuery:(NSString *)datasetName
             indexValue:(NSString *)indexValue
              timeframe:(NSString *)timeframe
                 config:(KeenClientConfig *)config
      completionHandler:(AnalysisCompletionBlock)completionHandler {
    IF_STRING_EMPTY_COMPLETE(config.projectID);
    IF_STRING_EMPTY_COMPLETE(config.readKey);
    IF_STRING_EMPTY_COMPLETE(datasetName);
    IF_STRING_EMPTY_COMPLETE(indexValue);
    IF_STRING_EMPTY_COMPLETE(timeframe);

    // Could use NSURLComponents and NSURLQueryItem for building this URL once we drop iOS 7- support
    NSString *queryString = [[NSString stringWithFormat:@"index_by=%@&timeframe=%@", indexValue, timeframe]
        stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    NSString *urlString = [NSString
        stringWithFormat:@"%@/datasets/%@/results?%@", [self getProjectURL:config], datasetName, queryString];
    KCLogVerbose(@"Sending request to: %@", urlString);

    NSMutableURLRequest *request =
        [self createRequestWithUrl:urlString andMethod:KeenHTTPMethodGet andBody:nil andKey:config.readKey];

    [self executeRequest:request completionHandler:completionHandler];
}

@end
