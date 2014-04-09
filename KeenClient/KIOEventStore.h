//
//  EventStore.h
//  KeenClient
//
//  Created by Cory Watson on 3/26/14.
//  Copyright (c) 2014 Keen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface KIOEventStore : NSObject

// The project ID for this store.
@property (nonatomic, strong) NSString *projectId;

- (id)initWithProjectId:(NSString *)pid;

 /**
  Reset any pending events so they can be resent.
  */
- (void)resetPendingEvents;

 /**
  Determine if there are any pending events so the caller can decide what to
  do. See resetPendingEvents or purgePendingEvents.
  */
- (BOOL)hasPendingEvents;

 /**
  Add an event to the store.
  */
- (BOOL)addEvent: (NSString *)eventData;

 /**
  Get a list of events that are ready to send to Keen. Events that are
  returned have been flagged as pending in the underlying store.
  */
- (NSMutableArray *)getEvents;

 /**
  Get a count of pending events.
  */
- (NSUInteger)getPendingEventCount;

 /**
  Get a count of total events, pending or not.
  */
- (NSUInteger)getTotalEventCount;

 /**
  Purge pending events that were returned from a previous call to getEvents.
  */
- (void)purgePendingEvents;
@end
