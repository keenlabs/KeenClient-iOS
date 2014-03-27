//
//  EventStore.m
//  KeenClient
//
//  Created by Cory Watson on 3/26/14.
//  Copyright (c) 2014 Keen Labs. All rights reserved.
//

#import "KeenClient.h"
#import "EventStore.h"

@implementation EventStore {
    sqlite3 *keen_dbname;
    sqlite3_stmt *insert_stmt;
    sqlite3_stmt *find_stmt;
    sqlite3_stmt *count_all_stmt;
    sqlite3_stmt *count_pending_stmt;
    sqlite3_stmt *make_pending_stmt;
    sqlite3_stmt *reset_pending_stmt;
    sqlite3_stmt *purge_stmt;
}

- (id)init {
    self = [super init];

    if(self) {
        // First, let's open the database.
        if ([self openDB]) {
            // Then try and create the table.
            if(![self createTable]) {
                KCLog(@"Failed to create SQLite table!");
                // XXX What to do here?
            }

            // Now we'll init prepared statements for all the things we might do.

            // This statement inserts events into the table.
            char *insert_sql = "INSERT INTO events (eventData, pending) VALUES (?, 0)";
            if(sqlite3_prepare_v2(keen_dbname, insert_sql, -1, &insert_stmt, NULL) != SQLITE_OK) {
                KCLog(@"Failed to prepare insert statement!");
                [self closeDB];
            }
            
            // This statement finds non-pending events in the table.
            char *find_sql = "SELECT id, eventData FROM events WHERE pending=0";
            if(sqlite3_prepare_v2(keen_dbname, find_sql, -1, &find_stmt, NULL) != SQLITE_OK) {
                KCLog(@"Failed to prepare find statement!");
                [self closeDB];
            }

            // This statement counts the total number of events (pending or not)
            char *count_all_sql = "SELECT count(*) FROM events";
            if(sqlite3_prepare_v2(keen_dbname, count_all_sql, -1, &count_all_stmt, NULL) != SQLITE_OK) {
                KCLog(@"Failed to prepare count all statement!");
                [self closeDB];
            }

            // This statement counts the number of pending events.
            char *count_pending_sql = "SELECT count(*) FROM events WHERE pending=1";
            if(sqlite3_prepare_v2(keen_dbname, count_pending_sql, -1, &count_pending_stmt, NULL) != SQLITE_OK) {
                KCLog(@"Failed to prepare count pending statement!");
                [self closeDB];
            }

            // This statement marks an event as pending.
            char *make_pending_sql = "UPDATE events SET pending=1 WHERE id=?";
            if(sqlite3_prepare_v2(keen_dbname, make_pending_sql, -1, &make_pending_stmt, NULL) != SQLITE_OK) {
                KCLog(@"Failed to prepare pending statement!");
                [self closeDB];
            }
            
            // This statement resets pending events back to normal.
            char *reset_pending_sql = "UPDATE events SET pending=0";
            if(sqlite3_prepare_v2(keen_dbname, reset_pending_sql, -1, &reset_pending_stmt, NULL) != SQLITE_OK) {
                KCLog(@"Failed to prepare reset pending statement!");
                [self closeDB];
            }

            // This statement purges all pending events.
            char *purge_sql = "DELETE FROM events WHERE pending=1";
            if(sqlite3_prepare_v2(keen_dbname, purge_sql, -1, &purge_stmt, NULL) != SQLITE_OK) {
                KCLog(@"Failed to prepare purge statement!");
                [self closeDB];
            }
        }
    }
    return self;
}

- (BOOL)addEvent:(NSString *)eventData  {
    BOOL wasAdded = NO;

    // TODO Add error message?
    // Not sure if TRANSIENT or STATIC is best here.
    // TODO This is a blob, not a string!
    if (sqlite3_bind_text(insert_stmt, 1, [eventData UTF8String], -1, SQLITE_TRANSIENT) != SQLITE_OK) {
        KCLog(@"Failed to bind insert event!");
        [self closeDB];
    }
    
    if (sqlite3_step(insert_stmt) != SQLITE_DONE) {
        KCLog(@"Failed to insert event!");
        [self closeDB];
    } else {
        wasAdded = YES;
    }

    sqlite3_reset(insert_stmt);
    sqlite3_clear_bindings(insert_stmt);

    return wasAdded;
}

- (NSMutableArray *)getEvents{

    // Create an array to hold the contents of our select.
    // XXX fwict I don't need to release this. That confuses me.
    NSMutableArray *events = [NSMutableArray array];

    // This method has no bindings, so can just step it immediately.
    while (sqlite3_step(find_stmt) == SQLITE_ROW) {
        // Fetch data out the statement
        int eventId = sqlite3_column_int(find_stmt, 0);
        const void *ptr = sqlite3_column_blob(find_stmt, 1);
        int size = sqlite3_column_bytes(find_stmt, 1);

        // Bind and mark the event pending.
        int poop = sqlite3_bind_int(make_pending_stmt, 1, eventId);
        if (poop != SQLITE_OK) {
            // XXX What to do here?
            KCLog(@"Failed to bind int for make pending!");
        }
        if (sqlite3_step(make_pending_stmt) != SQLITE_DONE) {
            // XXX Or here?
            KCLog(@"Failed to mark event pending");
        }

        // Reset the pendifier
        sqlite3_reset(make_pending_stmt);
        sqlite3_clear_bindings(make_pending_stmt);

        // Add the event to the array.
        // XXX What frees this?
        NSData *data = [[NSData alloc] initWithBytes:ptr length:size];
        [events addObject:data];
    }

    // Reset things
    sqlite3_reset(find_stmt);

    return events;
}

- (void)resetPendingEvents {
    if (sqlite3_step(reset_pending_stmt) != SQLITE_DONE) {
        KCLog(@"Failed to reset pending events!");
    }
    sqlite3_reset(reset_pending_stmt);
}

- (BOOL)hasPendingEvents {
    BOOL hasRows = NO;
    int eventCount = [self getPendingEventCount];
    if (eventCount > 0) {
        hasRows = TRUE;
    }
    return hasRows;
}

- (int)getPendingEventCount {
    int eventCount = 0;
    int gotDemRows = sqlite3_step(count_pending_stmt);
    if (gotDemRows == SQLITE_ROW) {
        eventCount = sqlite3_column_int(count_pending_stmt, 0);
    } else {
        KCLog(@"Failed to get count of pending rows.");
    }
    sqlite3_reset(count_pending_stmt);
    return eventCount;
}

- (int)getTotalEventCount {
    int eventCount = 0;
    int gotDemRows = sqlite3_step(count_all_stmt);
    if (gotDemRows == SQLITE_ROW) {
        eventCount = sqlite3_column_int(count_all_stmt, 0);
    } else {
        KCLog(@"Failed to get count total rows.");
    }
    sqlite3_reset(count_all_stmt);
    return eventCount;
}

- (void)purgePendingEvents {
    if (sqlite3_step(purge_stmt) != SQLITE_DONE) {
        KCLog(@"Failed to purge pending events.");
        // What to do here?
    };
    sqlite3_reset(purge_stmt);
}

- (BOOL)openDB {
    BOOL wasOpened = NO;
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *my_sqlfile = [libraryPath stringByAppendingPathComponent:@"keenEvents.sqlite"];
    if (sqlite3_open([my_sqlfile UTF8String], &keen_dbname) == SQLITE_OK) {
        wasOpened = YES;
    } else {
        KCLog(@"Failed to create database");
    }
    return wasOpened;
}

- (BOOL)createTable {
    BOOL wasCreated = NO;
    char *err;
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS 'events' (ID INTEGER PRIMARY KEY AUTOINCREMENT, eventData BLOB, pending INTEGER);"];
    if (sqlite3_exec(keen_dbname, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK) {
        [self closeDB];
    } else {
        wasCreated = YES;
    }

    return wasCreated;
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

    // Free our DB. This is safe on null pointers.
    sqlite3_close(keen_dbname);
    // Reset state in case it matters.
}

- (void)dealloc {
    [self closeDB];
    [super dealloc];
}

@end
