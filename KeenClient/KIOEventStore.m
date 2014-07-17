//
//  KIOEventStore.m
//  KeenClient
//
//  Created by Cory Watson on 3/26/14.
//  Copyright (c) 2014 Keen Labs. All rights reserved.
//

#import "KeenClient.h"
#import "KIOEventStore.h"
#import "KIOEventStore_PrivateMethods.h"
#import "keen_io_sqlite3.h"

@interface KIOEventStore()
- (void)closeDB;

// A dispatch queue used for sqlite.
@property (nonatomic) dispatch_queue_t dbQueue;

@end

@implementation KIOEventStore {
    keen_io_sqlite3 *keen_dbname;
    BOOL dbIsOpen;
    keen_io_sqlite3_stmt *insert_stmt;
    keen_io_sqlite3_stmt *find_stmt;
    keen_io_sqlite3_stmt *count_all_stmt;
    keen_io_sqlite3_stmt *count_pending_stmt;
    keen_io_sqlite3_stmt *make_pending_stmt;
    keen_io_sqlite3_stmt *reset_pending_stmt;
    keen_io_sqlite3_stmt *purge_stmt;
    keen_io_sqlite3_stmt *delete_stmt;
    keen_io_sqlite3_stmt *delete_all_stmt;
    keen_io_sqlite3_stmt *age_out_stmt;
    keen_io_sqlite3_stmt *convert_date_stmt;
}

- (instancetype)init {
    self = [super init];

    if(self) {
        dbIsOpen = NO;
        // First, let's open the database.
        if ([self openDB]) {
            // Then try and create the table.
            if(![self createTable]) {
                KCLog(@"Failed to create SQLite table!");
                [self closeDB];
            }

            // Now we'll init prepared statements for all the things we might do.

            // This statement inserts events into the table.
            char *insert_sql = "INSERT INTO events (projectId, collection, eventData, pending) VALUES (?, ?, ?, 0)";
            if (keen_io_sqlite3_prepare_v2(keen_dbname, insert_sql, -1, &insert_stmt, NULL) != SQLITE_OK) {
                [self handleSQLiteFailure:@"prepare insert statement"];
                [self closeDB];
            }
            
            // This statement finds non-pending events in the table.
            char *find_sql = "SELECT id, collection, eventData FROM events WHERE pending=0 AND projectId=?";
            if(keen_io_sqlite3_prepare_v2(keen_dbname, find_sql, -1, &find_stmt, NULL) != SQLITE_OK) {
                [self handleSQLiteFailure:@"prepare find statement"];
                [self closeDB];
            }

            // This statement counts the total number of events (pending or not)
            char *count_all_sql = "SELECT count(*) FROM events WHERE projectId=?";
            if(keen_io_sqlite3_prepare_v2(keen_dbname, count_all_sql, -1, &count_all_stmt, NULL) != SQLITE_OK) {
                [self handleSQLiteFailure:@"prepare count all statement"];
                [self closeDB];
            }

            // This statement counts the number of pending events.
            char *count_pending_sql = "SELECT count(*) FROM events WHERE pending=1 AND projectId=?";
            if(keen_io_sqlite3_prepare_v2(keen_dbname, count_pending_sql, -1, &count_pending_stmt, NULL) != SQLITE_OK) {
                [self handleSQLiteFailure:@"prepare count pending statement"];
                [self closeDB];
            }

            // This statement marks an event as pending.
            char *make_pending_sql = "UPDATE events SET pending=1 WHERE id=?";
            if(keen_io_sqlite3_prepare_v2(keen_dbname, make_pending_sql, -1, &make_pending_stmt, NULL) != SQLITE_OK) {
                [self handleSQLiteFailure:@"prepare pending statement"];
                [self closeDB];
            }
            
            // This statement resets pending events back to normal.
            char *reset_pending_sql = "UPDATE events SET pending=0 WHERE projectId=?";
            if(keen_io_sqlite3_prepare_v2(keen_dbname, reset_pending_sql, -1, &reset_pending_stmt, NULL) != SQLITE_OK) {
                [self handleSQLiteFailure:@"reset pending statement"];
                [self closeDB];
            }

            // This statement purges all pending events.
            char *purge_sql = "DELETE FROM events WHERE pending=1 AND projectId=?";
            if(keen_io_sqlite3_prepare_v2(keen_dbname, purge_sql, -1, &purge_stmt, NULL) != SQLITE_OK) {
                [self closeDB];
            }

            // This statement deletes a specific event.
            char *delete_sql = "DELETE FROM events WHERE id=?";
            if(keen_io_sqlite3_prepare_v2(keen_dbname, delete_sql, -1, &delete_stmt, NULL) != SQLITE_OK) {
                [self closeDB];
            }

            // This statement deletes all events.
            char *delete_all_sql = "DELETE FROM events";
            if(keen_io_sqlite3_prepare_v2(keen_dbname, delete_all_sql, -1, &delete_all_stmt, NULL) != SQLITE_OK) {
                [self closeDB];
            }

            // This statement deletes old events at a given offset.
            char *age_out_sql = "DELETE FROM events WHERE id <= (SELECT id FROM events ORDER BY id DESC LIMIT 1 OFFSET ?)";
            if(keen_io_sqlite3_prepare_v2(keen_dbname, age_out_sql, -1, &age_out_stmt, NULL) != SQLITE_OK) {
                [self closeDB];
            }
            
            // This statement converts an NSDate to an ISO-8601 formatted date/time string (we use sqlite because NSDateFormatter isn't thread-safe)
            char *convert_date_sql = "SELECT strftime('%Y-%m-%dT%H:%M:%S',datetime(?,'unixepoch','localtime'))";
            if(keen_io_sqlite3_prepare_v2(keen_dbname, convert_date_sql, -1, &convert_date_stmt, NULL) != SQLITE_OK) {
                [self closeDB];
            }
        }
    }
    return self;
}

- (BOOL)addEvent:(NSData *)eventData collection: (NSString *)coll {
    __block BOOL wasAdded = NO;

    if (!dbIsOpen) {
        KCLog(@"DB is closed, skipping addEvent");
        return wasAdded;
    }
    
    // we need to wait for the queue to finish because this method has a return value that we're manipulating in the queue
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_async(self.dbQueue, ^{
        if (keen_io_sqlite3_bind_text(insert_stmt, 1, [self.projectId UTF8String], -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind pid to add event statement"];
            [self closeDB];
        }
        
        if (keen_io_sqlite3_bind_text(insert_stmt, 2, [coll UTF8String], -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind coll to add event statement"];
            [self closeDB];
        }
        
        if (keen_io_sqlite3_bind_blob(insert_stmt, 3, [eventData bytes], (int) [eventData length], SQLITE_TRANSIENT) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind insert statement"];
            [self closeDB];
        }
        
        if (keen_io_sqlite3_step(insert_stmt) != SQLITE_DONE) {
            [self handleSQLiteFailure:@"insert event"];
            [self closeDB];
        } else {
            wasAdded = YES;
        }
        
        // You must reset before the commit happens in SQLite. Doing this now!
        keen_io_sqlite3_reset(insert_stmt);
        // Clears off the bindings for future uses.
        keen_io_sqlite3_clear_bindings(insert_stmt);
        
        dispatch_semaphore_signal(sema);
    });
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_release(sema);
    
    return wasAdded;
}

- (NSMutableDictionary *)getEvents{

    // Create a dictionary to hold the contents of our select.
    __weak NSMutableDictionary *events = [NSMutableDictionary dictionary];

    if (!dbIsOpen) {
        KCLog(@"DB is closed, skipping getEvents");
        // Return an empty array so we don't break anything. No nulls here!
        return events;
    }
    
    // reset pending events, if necessary
    if([self hasPendingEvents]) {
        [self resetPendingEvents];
    }
    
    // we need to wait for the queue to finish because this method has a return value that we're manipulating in the queue
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_async(self.dbQueue, ^{
        if (keen_io_sqlite3_bind_text(find_stmt, 1, [self.projectId UTF8String], -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind pid to find statement"];
        }

        while (keen_io_sqlite3_step(find_stmt) == SQLITE_ROW) {
            // Fetch data out the statement
            long long eventId = keen_io_sqlite3_column_int64(find_stmt, 0);

            NSString *coll = [NSString stringWithUTF8String:(char *)keen_io_sqlite3_column_text(find_stmt, 1)];

            const void *dataPtr = keen_io_sqlite3_column_blob(find_stmt, 2);
            int dataSize = keen_io_sqlite3_column_bytes(find_stmt, 2);

            NSData *data = [[NSData alloc] initWithBytes:dataPtr length:dataSize];

            // Bind and mark the event pending.
            if(keen_io_sqlite3_bind_int64(make_pending_stmt, 1, eventId) != SQLITE_OK) {
                [self handleSQLiteFailure:@"bind int for make pending"];
            }
            if (keen_io_sqlite3_step(make_pending_stmt) != SQLITE_DONE) {
                [self handleSQLiteFailure:@"mark event pending"];
            }

            // Reset the pendifier
            keen_io_sqlite3_reset(make_pending_stmt);
            keen_io_sqlite3_clear_bindings(make_pending_stmt);

            if ([events objectForKey:coll] == nil) {
                // We don't have an entry in the dictionary yet for this collection
                // so create one.
                [events setObject:[NSMutableDictionary dictionary] forKey:coll];
            }

            [[events objectForKey:coll] setObject:data forKey:[NSNumber numberWithUnsignedLongLong:eventId]];
        }

        // Reset things
        keen_io_sqlite3_reset(find_stmt);
        keen_io_sqlite3_clear_bindings(find_stmt);
        
        dispatch_semaphore_signal(sema);
    });
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_release(sema);
    
    return events;
}

- (void)resetPendingEvents{

    if (!dbIsOpen) {
        KCLog(@"DB is closed, skipping resetPendingEvents");
        return;
    }
    
    dispatch_async(self.dbQueue, ^{
        if (keen_io_sqlite3_bind_text(reset_pending_stmt, 1, [self.projectId UTF8String], -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind pid to reset pending statement"];
        }
        if (keen_io_sqlite3_step(reset_pending_stmt) != SQLITE_DONE) {
            [self handleSQLiteFailure:@"reset pending events"];
        }
        keen_io_sqlite3_reset(reset_pending_stmt);
        keen_io_sqlite3_clear_bindings(reset_pending_stmt);
    });
}

- (BOOL)hasPendingEvents {
    BOOL hasRows = NO;

    if (!dbIsOpen) {
        KCLog(@"DB is closed, skipping hasPendingEvents");
        return hasRows;
    }

    if ([self getPendingEventCount] > 0) {
        hasRows = TRUE;
    }
    return hasRows;
}

- (NSUInteger)getPendingEventCount {
    __block NSUInteger eventCount = 0;

    if (!dbIsOpen) {
        KCLog(@"DB is closed, skipping getPendingEventcount");
        return eventCount;
    }

    // we need to wait for the queue to finish because this method has a return value that we're manipulating in the queue
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_async(self.dbQueue, ^{
        if (keen_io_sqlite3_bind_text(count_pending_stmt, 1, [self.projectId UTF8String], -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind pid to count pending statement"];
        }
        if (keen_io_sqlite3_step(count_pending_stmt) == SQLITE_ROW) {
            eventCount = (NSInteger) keen_io_sqlite3_column_int(count_pending_stmt, 0);
        } else {
            [self handleSQLiteFailure:@"get count of pending rows"];
        }
        keen_io_sqlite3_reset(count_pending_stmt);
        keen_io_sqlite3_clear_bindings(count_pending_stmt);
        dispatch_semaphore_signal(sema);
    });
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_release(sema);
    
    return eventCount;
}

- (NSUInteger)getTotalEventCount {
    __block NSUInteger eventCount = 0;

    if (!dbIsOpen) {
        KCLog(@"DB is closed, skipping getTotalEventCount");
        return eventCount;
    }

    // we need to wait for the queue to finish because this method has a return value that we're manipulating in the queue
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_async(self.dbQueue, ^{
        if (keen_io_sqlite3_bind_text(count_all_stmt, 1, [self.projectId UTF8String], -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind pid to total event statement"];
        }
        if (keen_io_sqlite3_step(count_all_stmt) == SQLITE_ROW) {
            eventCount = (NSInteger) keen_io_sqlite3_column_int(count_all_stmt, 0);
        } else {
            [self handleSQLiteFailure:@"get count of total rows"];
        }
        keen_io_sqlite3_reset(count_all_stmt);
        keen_io_sqlite3_clear_bindings(count_all_stmt);
        
        dispatch_semaphore_signal(sema);
    });
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_release(sema);
    
    return eventCount;
}

- (void)deleteEvent: (NSNumber *)eventId {

    if (!dbIsOpen) {
        KCLog(@"DB is closed, skipping deleteEvent");
        return;
    }
    
    dispatch_async(self.dbQueue, ^{
        if (keen_io_sqlite3_bind_int64(delete_stmt, 1, [eventId unsignedLongLongValue]) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind eventid to delete statement"];
        }
        if (keen_io_sqlite3_step(delete_stmt) != SQLITE_DONE) {
            [self handleSQLiteFailure:@"delete event"];
        };
        keen_io_sqlite3_reset(delete_stmt);
        keen_io_sqlite3_clear_bindings(delete_stmt);
    });
}

- (void)deleteAllEvents {

    if (!dbIsOpen) {
        KCLog(@"DB is closed, skipping deleteEvent");
        return;
    }
    
    dispatch_async(self.dbQueue, ^{
        if (keen_io_sqlite3_step(delete_all_stmt) != SQLITE_DONE) {
            [self handleSQLiteFailure:@"delete all events"];
        };
        keen_io_sqlite3_reset(delete_all_stmt);
        keen_io_sqlite3_clear_bindings(delete_all_stmt);
    });
}

- (void)deleteEventsFromOffset: (NSNumber *)offset {

    if (!dbIsOpen) {
        KCLog(@"DB is closed, skipping deleteEvent");
        return;
    }
    
    dispatch_async(self.dbQueue, ^{
        if (keen_io_sqlite3_bind_int64(age_out_stmt, 1, [offset unsignedLongLongValue]) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind offset to ageOut statement"];
        }
        if (keen_io_sqlite3_step(age_out_stmt) != SQLITE_DONE) {
            [self handleSQLiteFailure:@"delete all events"];
        };
        keen_io_sqlite3_reset(age_out_stmt);
        keen_io_sqlite3_clear_bindings(age_out_stmt);
    });
}


- (void)purgePendingEvents {

    if (!dbIsOpen) {
        KCLog(@"DB is closed, skipping purgePendingEvents");
        return;
    }

    dispatch_async(self.dbQueue, ^{
        if (keen_io_sqlite3_bind_text(purge_stmt, 1, [self.projectId UTF8String], -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind pid to purge statement"];
        }
        if (keen_io_sqlite3_step(purge_stmt) != SQLITE_DONE) {
            [self handleSQLiteFailure:@"purge pending events"];
            // XXX What to do here?
        };
        keen_io_sqlite3_reset(purge_stmt);
        keen_io_sqlite3_clear_bindings(purge_stmt);
    });
}

- (BOOL)openDB {
    __block BOOL wasOpened = NO;
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *my_sqlfile = [libraryPath stringByAppendingPathComponent:@"keenEvents.sqlite"];
    
    // we're going to use a queue for all database operations, so let's create it
    self.dbQueue = dispatch_queue_create("io.keen.sqlite", DISPATCH_QUEUE_SERIAL);
    
    // we need to wait for the queue to finish because this method has a return value that we're manipulating in the queue
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_async(self.dbQueue, ^{
        // initialize sqlite ourselves so we can config
        keen_io_sqlite3_shutdown();
        keen_io_sqlite3_config(SQLITE_CONFIG_MULTITHREAD);
        keen_io_sqlite3_initialize();
        
        if (keen_io_sqlite3_open([my_sqlfile UTF8String], &keen_dbname) == SQLITE_OK) {
            wasOpened = YES;
        } else {
            [self handleSQLiteFailure:@"create database"];
        }
        dbIsOpen = wasOpened;
        dispatch_semaphore_signal(sema);
    });
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_release(sema);
    
    return wasOpened;
}

- (BOOL)createTable {
    __block BOOL wasCreated = NO;

    if (!dbIsOpen) {
        KCLog(@"DB is closed, skipping createTable");
        return wasCreated;
    }
    
    // we need to wait for the queue to finish because this method has a return value that we're manipulating in the queue
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_async(self.dbQueue, ^{
        char *err;
        NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS 'events' (ID INTEGER PRIMARY KEY AUTOINCREMENT, collection TEXT, projectId TEXT, eventData BLOB, pending INTEGER, dateCreated TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"];
        if (keen_io_sqlite3_exec(keen_dbname, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK) {
            KCLog(@"Failed to create table: %@", [NSString stringWithCString:err encoding:NSUTF8StringEncoding]);
            keen_io_sqlite3_free(err); // Free that error message
            [self closeDB];
        } else {
            wasCreated = YES;
        }
        dispatch_semaphore_signal(sema);
    });
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_release(sema);


    return wasCreated;
}

- (void)handleSQLiteFailure: (NSString *) msg {
    NSLog(@"Failed to %@: %@",
          msg, [NSString stringWithCString:keen_io_sqlite3_errmsg(keen_dbname) encoding:NSUTF8StringEncoding]);
}

- (void)closeDB {
    // Free all the prepared statements. This is safe on null pointers.
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_async(self.dbQueue, ^{
        keen_io_sqlite3_finalize(insert_stmt);
        keen_io_sqlite3_finalize(find_stmt);
        keen_io_sqlite3_finalize(count_all_stmt);
        keen_io_sqlite3_finalize(count_pending_stmt);
        keen_io_sqlite3_finalize(make_pending_stmt);
        keen_io_sqlite3_finalize(reset_pending_stmt);
        keen_io_sqlite3_finalize(purge_stmt);
        keen_io_sqlite3_finalize(delete_stmt);
        keen_io_sqlite3_finalize(delete_all_stmt);
        keen_io_sqlite3_finalize(age_out_stmt);
        keen_io_sqlite3_finalize(convert_date_stmt);
        
        // Free our DB. This is safe on null pointers.
        keen_io_sqlite3_close(keen_dbname);
        // Reset state in case it matters.
        dbIsOpen = NO;
        
        dispatch_semaphore_signal(sema);
    });
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_release(sema);
}

- (id)convertNSDateToISO8601:(id)date {
    double offset = 0.0f;
    if([date isKindOfClass:[NSDate class]]) {
        offset = [[NSTimeZone localTimeZone] secondsFromGMTForDate:date] / 3600.00;  // need the offset
    }
    else if([date isKindOfClass:[NSString class]]) {
        offset = [[NSTimeZone localTimeZone] secondsFromGMT] / 3600.00;  // need the offset
    }
    NSArray *offsetArray = [[NSString stringWithFormat:@"%f",offset] componentsSeparatedByString:@"."]; // split it so we don't have to do math or numberformatting, which isn't thread-safe either
    NSString *hour = [[offsetArray objectAtIndex:0] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    NSString *minute = [[offsetArray objectAtIndex:1] substringToIndex:2];
    
    // ensure we have leading zeros where necessary
    while([hour length] < 2) {
        hour = [@"0" stringByAppendingString:hour];
    }
    
    // minute math
    if([minute isEqual: @"25"]) { minute = @"15"; }
    if([minute isEqual: @"50"]) { minute = @"30"; }
    if([minute isEqual: @"75"]) { minute = @"45"; }
    
    NSString *offsetString = [[hour stringByAppendingString:@":"] stringByAppendingString:minute];
    
    // are we + or -?
    if(offset >= 0) {
        offsetString = [@"+" stringByAppendingString:offsetString];
    } else {
        offsetString = [@"-" stringByAppendingString:offsetString];
    }
    
    // bind
    if (keen_io_sqlite3_bind_text(convert_date_stmt, 1, [[NSString stringWithFormat:@"%f", [date timeIntervalSince1970]] UTF8String], -1, SQLITE_STATIC) != SQLITE_OK) {
        [self handleSQLiteFailure:@"date conversion"];
        [self closeDB];
    }
    keen_io_sqlite3_step(convert_date_stmt);
    
    NSString *iso8601 = [[NSString stringWithUTF8String:(char *)keen_io_sqlite3_column_text(convert_date_stmt, 0)] stringByAppendingString:offsetString];
    
    // reset things
    keen_io_sqlite3_reset(convert_date_stmt);
    keen_io_sqlite3_clear_bindings(convert_date_stmt);
    
    return iso8601;
}


@end
