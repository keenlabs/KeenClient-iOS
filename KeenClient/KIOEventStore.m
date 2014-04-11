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

@interface KIOEventStore()
- (void)closeDB;
@end

@implementation KIOEventStore {
    sqlite3 *keen_dbname;
    BOOL dbIsOpen;
    sqlite3_stmt *insert_stmt;
    sqlite3_stmt *find_stmt;
    sqlite3_stmt *count_all_stmt;
    sqlite3_stmt *count_pending_stmt;
    sqlite3_stmt *make_pending_stmt;
    sqlite3_stmt *reset_pending_stmt;
    sqlite3_stmt *purge_stmt;
    sqlite3_stmt *delete_stmt;
}

- (instancetype)init {
    NSAssert(NO, @"init not allowed, use initWithProjectId");
    [self release];
    return nil;
}

- (instancetype)initWithProjectId:(NSString *)pid {
    self = [super init];

    if(self) {
        dbIsOpen = NO;
        self.projectId = pid;
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
            if (sqlite3_prepare_v2(keen_dbname, insert_sql, -1, &insert_stmt, NULL) != SQLITE_OK) {
                [self handleSQLiteFailure:@"prepare insert statement"];
                [self closeDB];
            }
            
            // This statement finds non-pending events in the table.
            char *find_sql = "SELECT id, eventData FROM events WHERE pending=0 AND projectId=?";
            if(sqlite3_prepare_v2(keen_dbname, find_sql, -1, &find_stmt, NULL) != SQLITE_OK) {
                [self handleSQLiteFailure:@"prepare find statement"];
                [self closeDB];
            }

            // This statement counts the total number of events (pending or not)
            char *count_all_sql = "SELECT count(*) FROM events WHERE projectId=?";
            if(sqlite3_prepare_v2(keen_dbname, count_all_sql, -1, &count_all_stmt, NULL) != SQLITE_OK) {
                [self handleSQLiteFailure:@"prepare count all statement"];
                [self closeDB];
            }

            // This statement counts the number of pending events.
            char *count_pending_sql = "SELECT count(*) FROM events WHERE pending=1 AND projectId=?";
            if(sqlite3_prepare_v2(keen_dbname, count_pending_sql, -1, &count_pending_stmt, NULL) != SQLITE_OK) {
                [self handleSQLiteFailure:@"prepare count pending statement"];
                [self closeDB];
            }

            // This statement marks an event as pending.
            char *make_pending_sql = "UPDATE events SET pending=1 WHERE id=?";
            if(sqlite3_prepare_v2(keen_dbname, make_pending_sql, -1, &make_pending_stmt, NULL) != SQLITE_OK) {
                [self handleSQLiteFailure:@"prepare pending statement"];
                [self closeDB];
            }
            
            // This statement resets pending events back to normal.
            char *reset_pending_sql = "UPDATE events SET pending=0 WHERE projectId=?";
            if(sqlite3_prepare_v2(keen_dbname, reset_pending_sql, -1, &reset_pending_stmt, NULL) != SQLITE_OK) {
                [self handleSQLiteFailure:@"reset pending statement"];
                [self closeDB];
            }

            // This statement purges all pending events.
            char *purge_sql = "DELETE FROM events WHERE pending=1 AND projectId=?";
            if(sqlite3_prepare_v2(keen_dbname, purge_sql, -1, &purge_stmt, NULL) != SQLITE_OK) {
                [self closeDB];
            }

            // This statement deletes a specific event.
            char *delete_sql = "DELETE FROM events WHERE id=?";
            if(sqlite3_prepare_v2(keen_dbname, delete_sql, -1, &delete_stmt, NULL) != SQLITE_OK) {
                [self closeDB];
            }
        }
    }
    return self;
}

- (BOOL)addEvent:(NSData *)eventData collection: (NSString *)coll {
    BOOL wasAdded = NO;

    if (!dbIsOpen) {
        KCLog(@"DB is closed, skipping addEvent");
        return wasAdded;
    }

    if (sqlite3_bind_text(insert_stmt, 1, [self.projectId UTF8String], -1, SQLITE_STATIC) != SQLITE_OK) {
        [self handleSQLiteFailure:@"bind pid to add event statement"];
        [self closeDB];
    }

    if (sqlite3_bind_text(insert_stmt, 2, [coll UTF8String], -1, SQLITE_STATIC) != SQLITE_OK) {
        [self handleSQLiteFailure:@"bind coll to add event statement"];
        [self closeDB];
    }

    if (sqlite3_bind_blob(insert_stmt, 3, [eventData bytes], -1, SQLITE_STATIC) != SQLITE_OK) {
        [self handleSQLiteFailure:@"bind insert statement"];
        [self closeDB];
    }

    if (sqlite3_step(insert_stmt) != SQLITE_DONE) {
        [self handleSQLiteFailure:@"insert event"];
        [self closeDB];
    } else {
        wasAdded = YES;
    }

    // You must reset before the commit happens in SQLite. Doing this now!
    sqlite3_reset(insert_stmt);
    // Clears off the bindings for future uses.
    sqlite3_clear_bindings(insert_stmt);

    return wasAdded;
}

- (NSMutableDictionary *)getEvents{

    // Create an array to hold the contents of our select.
    NSMutableDictionary *events = [NSMutableDictionary dictionary];

    if (!dbIsOpen) {
        KCLog(@"DB is closed, skipping getEvents");
        // Return an empty array so we don't break anything. No nulls here!
        return events;
    }

    if (sqlite3_bind_text(find_stmt, 1, [self.projectId UTF8String], -1, SQLITE_STATIC) != SQLITE_OK) {
        [self handleSQLiteFailure:@"bind pid to find statement"];
    }

    while (sqlite3_step(find_stmt) == SQLITE_ROW) {
        // Fetch data out the statement
        long long eventId = sqlite3_column_int64(find_stmt, 0);
        const void *dataPtr = sqlite3_column_blob(find_stmt, 1);
        int dataSize = sqlite3_column_bytes(find_stmt, 1);

        // Bind and mark the event pending.
        if(sqlite3_bind_int64(make_pending_stmt, 1, eventId) != SQLITE_OK) {
            // XXX What to do here?
            [self handleSQLiteFailure:@"bind int for make pending"];
        }
        if (sqlite3_step(make_pending_stmt) != SQLITE_DONE) {
            [self handleSQLiteFailure:@"mark event pending"];
        }

        // Reset the pendifier
        sqlite3_reset(make_pending_stmt);
        sqlite3_clear_bindings(make_pending_stmt);

        // Add the event to the array.
        // XXX What frees this?
        NSData *data = [[[NSData alloc] initWithBytes:dataPtr length:dataSize] autorelease];
        [events setObject:data forKey:[NSNumber numberWithUnsignedLongLong:eventId]];
    }

    // Reset things
    sqlite3_reset(find_stmt);
    sqlite3_clear_bindings(find_stmt);

    return events;
}

- (void)resetPendingEvents{

    if (!dbIsOpen) {
        KCLog(@"DB is closed, skipping resetPendingEvents");
        return;
    }

    if (sqlite3_bind_text(reset_pending_stmt, 1, [self.projectId UTF8String], -1, SQLITE_STATIC) != SQLITE_OK) {
        [self handleSQLiteFailure:@"bind pid to reset pending statement"];
    }
    if (sqlite3_step(reset_pending_stmt) != SQLITE_DONE) {
        [self handleSQLiteFailure:@"reset pending events"];
    }
    sqlite3_reset(reset_pending_stmt);
    sqlite3_clear_bindings(reset_pending_stmt);
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
    NSUInteger eventCount = 0;

    if (!dbIsOpen) {
        KCLog(@"DB is closed, skipping getPendingEventcount");
        return eventCount;
    }

    if (sqlite3_bind_text(count_pending_stmt, 1, [self.projectId UTF8String], -1, SQLITE_STATIC) != SQLITE_OK) {
        [self handleSQLiteFailure:@"bind pid to count pending statement"];
    }
    if (sqlite3_step(count_pending_stmt) == SQLITE_ROW) {
        eventCount = (NSInteger) sqlite3_column_int(count_pending_stmt, 0);
    } else {
        [self handleSQLiteFailure:@"get count of pending rows"];
    }
    sqlite3_reset(count_pending_stmt);
    sqlite3_clear_bindings(count_pending_stmt);
    return eventCount;
}

- (NSUInteger)getTotalEventCount {
    NSUInteger eventCount = 0;

    if (!dbIsOpen) {
        KCLog(@"DB is closed, skipping getTotalEventCount");
        return eventCount;
    }

    if (sqlite3_bind_text(count_all_stmt, 1, [self.projectId UTF8String], -1, SQLITE_STATIC) != SQLITE_OK) {
        [self handleSQLiteFailure:@"bind pid to total event statement"];
    }
    if (sqlite3_step(count_all_stmt) == SQLITE_ROW) {
        eventCount = (NSInteger) sqlite3_column_int(count_all_stmt, 0);
    } else {
        [self handleSQLiteFailure:@"get count of total rows"];
    }
    sqlite3_reset(count_all_stmt);
    sqlite3_clear_bindings(count_all_stmt);
    return eventCount;
}

- (void)deleteEvent: (NSNumber *)eventId {

    if (!dbIsOpen) {
        KCLog(@"DB is closed, skipping deleteEvent");
        return;
    }
    if (sqlite3_bind_int64(delete_stmt, 1, [eventId unsignedLongLongValue]) != SQLITE_OK) {
        [self handleSQLiteFailure:@"bind eventid to delete statement"];
    }
    if (sqlite3_step(delete_stmt) != SQLITE_DONE) {
        [self handleSQLiteFailure:@"delete event"];
        // XXX What to do here?
    };
    sqlite3_reset(delete_stmt);
    sqlite3_clear_bindings(delete_stmt);
}

- (void)purgePendingEvents {

    if (!dbIsOpen) {
        KCLog(@"DB is closed, skipping purgePendingEvents");
        return;
    }

    if (sqlite3_bind_text(purge_stmt, 1, [self.projectId UTF8String], -1, SQLITE_STATIC) != SQLITE_OK) {
        [self handleSQLiteFailure:@"bind pid to purge statement"];
    }
    if (sqlite3_step(purge_stmt) != SQLITE_DONE) {
        [self handleSQLiteFailure:@"purge pending events"];
        // XXX What to do here?
    };
    sqlite3_reset(purge_stmt);
    sqlite3_clear_bindings(purge_stmt);
}

- (BOOL)openDB {
    BOOL wasOpened = NO;
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *my_sqlfile = [libraryPath stringByAppendingPathComponent:@"keenEvents.sqlite"];
    if (sqlite3_open([my_sqlfile UTF8String], &keen_dbname) == SQLITE_OK) {
        wasOpened = YES;
    } else {
        [self handleSQLiteFailure:@"create database"];
    }
    dbIsOpen = wasOpened;
    return wasOpened;
}

- (BOOL)createTable {
    BOOL wasCreated = NO;

    if (!dbIsOpen) {
        KCLog(@"DB is closed, skipping createTable");
        return wasCreated;
    }

    char *err;
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS 'events' (ID INTEGER PRIMARY KEY AUTOINCREMENT, collection TEXT, projectId TEXT, eventData BLOB, pending INTEGER, dateCreated TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"];
    if (sqlite3_exec(keen_dbname, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK) {
        KCLog(@"Failed to create table: %@", [NSString stringWithCString:err encoding:NSUTF8StringEncoding]);
        sqlite3_free(err); // Free that error message
        [self closeDB];
    } else {
        wasCreated = YES;
    }

    return wasCreated;
}

- (void)handleSQLiteFailure: (NSString *) msg {
    NSLog(@"Failed to %@: %@",
          msg, [NSString stringWithCString:sqlite3_errmsg(keen_dbname) encoding:NSUTF8StringEncoding]);
}

- (void)closeDB {
    // Free all the prepared statements. This is safe on null pointers.
    sqlite3_finalize(insert_stmt);
    sqlite3_finalize(find_stmt);
    sqlite3_finalize(count_all_stmt);
    sqlite3_finalize(count_pending_stmt);
    sqlite3_finalize(make_pending_stmt);
    sqlite3_finalize(reset_pending_stmt);
    sqlite3_finalize(purge_stmt);
    sqlite3_finalize(delete_stmt);

    // Free our DB. This is safe on null pointers.
    sqlite3_close(keen_dbname);
    // Reset state in case it matters.
    dbIsOpen = NO;
}

- (void)dealloc {
    [self closeDB];
    [super dealloc];
}

@end
