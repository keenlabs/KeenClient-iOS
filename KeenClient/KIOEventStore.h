//
//  EventStore.h
//  KeenClient
//
//  Created by Cory Watson on 3/26/14.
//  Copyright (c) 2014 Keen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KIOEventStore : NSObject

// The project ID for this store.
@property (nonatomic, strong) NSString *projectId;

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
- (BOOL)addEvent: (NSData *)eventData collection: (NSString *)coll;

 /**
  Get a dictionary of events keyed by id that are ready to send to Keen. Events
  that are returned have been flagged as pending in the underlying store.
  */
- (NSMutableDictionary *)getEvents;

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

 /**
  Delete an event from the store
  */
- (void)deleteEvent: (NSNumber *)eventId;

/**
 Delete all events from the store
 */
- (void)deleteAllEvents;


/**
 Delete events starting at an offset. Helps to keep the "queue" bounded.
 */
- (void)deleteEventsFromOffset: (NSNumber *)offset;
@end
