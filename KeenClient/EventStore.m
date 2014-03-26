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
            char *purge_sql = "DELETE FROM evnets WHERE pending=1";
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
    
    // Prepare our query for execution, clearing any previous state.
    if(sqlite3_reset(insert_stmt) != SQLITE_OK) {
        KCLog(@"Failed to reset insert statement!");
        [self closeDB];
    };
    // Some googling around indicates that this doesn't need an error check.
    sqlite3_clear_bindings(insert_stmt);
    
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

    return wasAdded;
}

- (void)getEvents:(NSMutableArray **)eventData {

    // Reset things
    sqlite3_reset(find_stmt);

    // Create an array to hold the contents of our select.
    NSMutableArray *events = [NSMutableArray array];

    // This method has no bindings, so can just step it immediately.
    while (sqlite3_step(find_stmt) == SQLITE_ROW) {
        // Fetch data out the statement
        int eventId = sqlite3_column_int(find_stmt, 1);
        const void *ptr = sqlite3_column_blob(find_stmt, 1);
        int size = sqlite3_column_bytes(find_stmt, 1);

        // Reset the pendifier
        sqlite3_reset(make_pending_stmt);
        sqlite3_clear_bindings(make_pending_stmt);
        // Bind and mark the event pending.
        if (sqlite3_bind_int(make_pending_stmt, eventId, SQLITE_TRANSIENT) != SQLITE_OK) {
            // XXX What to do here?
        }
        if(sqlite3_step(make_pending_stmt) != SQLITE_OK) {
            // XXX Or here?
        }

        // Add the event to the array.
        NSData *data = [[NSData alloc] initWithBytes:ptr length:size];
        [events addObject:data];
    }

    // Set the return.
    *eventData = events;
}

- (void)resetPendingEvents {
    sqlite3_reset(reset_pending_stmt);
    if (sqlite3_step(reset_pending_stmt) != SQLITE_DONE) {
        KCLog(@"Failed to reset pending events!");
    }
}

- (BOOL)hasPendingevents {
    sqlite3_reset(count_pending_stmt);
    BOOL hasRows = NO;
    int gotDemRows = sqlite3_step(count_pending_stmt);
    if(gotDemRows == SQLITE_ROW) {
        int eventCount = sqlite3_column_int(count_pending_stmt, 0);
        if(eventCount > 0) {
            hasRows = TRUE;
        }
    } else {
        KCLog(@"Failed to deterimine if we have pending rows.");
    }
    return hasRows;
}

- (void)purgePendingEvents {
    sqlite3_reset(purge_stmt);
    if (sqlite3_step(purge_stmt) != SQLITE_DONE) {
        KCLog(@"Failed to purge pending events.");
        // What to do here?
    };
}

- (BOOL)openDB {
    BOOL wasOpened = NO;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *my_sqlfile = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"events"];
    if (sqlite3_open([my_sqlfile UTF8String], &keen_dbname) == SQLITE_OK) {
        wasOpened = YES;
    }
    return wasOpened;
}

- (BOOL)createTable {
    BOOL wasCreated = NO;
    char *err;
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS 'events' (ID INTEGER PRIMARY KEY AUTOINCREMENT, eventData BLOB, pending INTEGER);"];
    if(sqlite3_exec(keen_dbname, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK) {
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
