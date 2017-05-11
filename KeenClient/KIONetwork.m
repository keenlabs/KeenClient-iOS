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


@interface KIONetwork ()

/**
 Handles the HTTP response from the Keen Query API.
 @param response The response from the server.
 @param responseData The data returned from the server.
 @param query The query that was passed to the Keen API.
 */
- (void)handleQueryAPIResponse:(NSURLResponse *)response
                       andData:(NSData *)responseData
                      andQuery:(KIOQuery *)query
                  andProjectID:(NSString *)projectID;

@property (nonatomic, readwrite) NSURLSession *urlSession;

@property (nonatomic) KIODBStore *store;

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
        s_sharedInstance = [[KIONetwork alloc] initWithURLSession:[NSURLSession sharedSession]
                                                         andStore:[KIODBStore sharedInstance]];
    });

    return s_sharedInstance;
}

- (instancetype)initWithURLSession:(NSURLSession *)urlSession
                          andStore:(KIODBStore *)store {
    self = [super init];
    if (self) {
        self.maxQueryAttempts = 10;
        self.queryTTL = 3600;
        self.urlSession = urlSession;
        self.store = store;
    }
    return self;
}

- (NSMutableURLRequest *)createRequestWithUrl:(NSString *)urlString
                                     andBody:(NSData *)body
                                      andKey:(NSString *)key {
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:30.0f];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:key forHTTPHeaderField:@"Authorization"];
    [request setValue:[NSString stringWithFormat:@"%lud",(unsigned long) [body length]] forHTTPHeaderField:@"Content-Length"];
    [request setValue:kKeenSdkVersionWithPlatform forHTTPHeaderField:kKeenSdkVersionHeader];
    [request setHTTPBody:body];
    return request;
}

- (void)executeRequest:(NSURLRequest *)request
     completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    [[self.urlSession dataTaskWithRequest:request completionHandler:completionHandler] resume];
}

- (BOOL)hasQueryReachedMaxAttempts:(KIOQuery *)keenQuery withProjectID:(NSString *)projectID {
    return [self.store hasQueryWithMaxAttempts:[keenQuery convertQueryToData]
                                     queryType:keenQuery.queryType
                                    collection:[keenQuery.propertiesDictionary objectForKey:@"event_collection"]
                                     projectID:projectID
                                   maxAttempts:self.maxQueryAttempts
                                      queryTTL:self.queryTTL];
}

# pragma mark Sync methods

- (void)sendEvents:(NSData *)data
     withProjectID:(NSString *)projectID
      withWriteKey:(NSString *)writeKey
 completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/projects/%@/events",
                           kKeenServerAddress, kKeenApiVersion, projectID];
    KCLogVerbose(@"Sending request to: %@", urlString);

    NSMutableURLRequest *request = [self createRequestWithUrl:urlString
                                                      andBody:data
                                                       andKey:writeKey];

    [self executeRequest:request completionHandler:completionHandler];
}


- (void)runQuery:(KIOQuery *)keenQuery withProjectID:(NSString *)projectID
                                        withReadKey:(NSString *)readKey
                                  completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    BOOL hasQueryWithMaxAttempts = [self hasQueryReachedMaxAttempts:keenQuery withProjectID:projectID];
    if (hasQueryWithMaxAttempts) {
        KCLogWarn(@"Not running query because it failed over %d times", self.maxQueryAttempts);
        return;
    }

    NSString *urlString = [NSString stringWithFormat:@"%@/%@/projects/%@/queries/%@",
                           kKeenServerAddress, kKeenApiVersion, projectID, keenQuery.queryType];
    KCLogVerbose(@"Sending request to: %@", urlString);

    NSMutableURLRequest *request = [self createRequestWithUrl:urlString
                                                      andBody:[keenQuery convertQueryToData]
                                                       andKey:readKey];

    [self executeRequest:request
       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
           [self handleQueryAPIResponse:response
                                andData:data
                               andQuery:keenQuery
                           andProjectID:projectID];
           completionHandler(data, response, error);
       }];
}

- (void)handleQueryAPIResponse:(NSURLResponse *)response
                       andData:(NSData *)responseData
                      andQuery:(KIOQuery *)query
                  andProjectID:(NSString *)projectID {
    // Check if call to the Query API failed
    if (!responseData) {
        KCLogError(@"responseData was nil for some reason.  That's not great.");
        KCLogError(@"response status code: %ld", (long)[((NSHTTPURLResponse*)response) statusCode]);
        return;
    }

    NSInteger responseCode = [((NSHTTPURLResponse *)response) statusCode];

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



- (void)runMultiAnalysisWithQueries:(NSArray *)keenQueries
                      withProjectID:(NSString *)projectID
                        withReadKey:(NSString *)readKey
                  completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/projects/%@/queries/%@",
                           kKeenServerAddress, kKeenApiVersion, projectID, @"multi_analysis"];
    KCLogVerbose(@"Sending request to: %@", urlString);

    NSDictionary *multiAnalysisDictionary = [self prepareQueriesDictionaryForMultiAnalysis:keenQueries];
    if (multiAnalysisDictionary == nil) {
        return;
    }

    //convert the resulting dictionary to data and set it as HTTPBody
    NSError *dictionarySerializationError;
    NSData *multiAnalysisData = [NSJSONSerialization dataWithJSONObject:multiAnalysisDictionary options:0 error:&dictionarySerializationError];
    if (dictionarySerializationError) {
        KCLogError(@"error with dictionary serialization");
        return;
    }

    NSMutableURLRequest *request = [self createRequestWithUrl:urlString
                                                      andBody:multiAnalysisData
                                                       andKey:readKey];

    [self executeRequest:request completionHandler:completionHandler];
}


# pragma mark Helper Methods

- (NSDictionary *)prepareQueriesDictionaryForMultiAnalysis:(NSArray *)keenQueries {
    NSMutableDictionary* multiAnalysisDictionary = [@{@"event_collection": [NSNull null],
                                                      @"filters": [NSNull null],
                                                      @"timeframe": [NSNull null],
                                                      @"timezone": [NSNull null],
                                                      @"group_by": [NSNull null],
                                                      @"interval": [NSNull null]} mutableCopy];
    NSMutableDictionary *queriesDictionary = [NSMutableDictionary dictionary];
    for (int i = 0; i < keenQueries.count; i++) {
        if (![keenQueries[i] isKindOfClass:[KIOQuery class]]) {
            KCLogError(@"keenQueries array contain objects that are not of class KIOQuery");
            return nil;
        }

        KIOQuery *query = keenQueries[i];
        NSMutableDictionary *queryMutablePropertiesDictionary = [[query propertiesDictionary] mutableCopy];

        //check that Keen queries have the same parameters
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

        NSString *queryName = [query queryName] ? : [[NSString alloc] initWithFormat:@"query%d", i];
        [queriesDictionary setObject:queryMutablePropertiesDictionary forKey:queryName];
    }

    [multiAnalysisDictionary setObject:queriesDictionary forKey:@"analyses"];

    return [multiAnalysisDictionary copy];
}


@end
