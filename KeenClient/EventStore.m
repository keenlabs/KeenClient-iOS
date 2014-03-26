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
    BOOL table_ok;
    BOOL db_open_status;
    sqlite3 *keen_dbname;
    sqlite3_stmt *insert_stmt;
    sqlite3_stmt *find_stmt;
    sqlite3_stmt *count_pending_stmt;
    sqlite3_stmt *find_pending_stmt;
    sqlite3_stmt *make_pending_stmt;
    sqlite3_stmt *reset_pending_stmt;
    sqlite3_stmt *delete_stmt;
}

- (id)init {
    self = [super init];
    if(self) {

        table_ok = NO;
        db_open_status = NO;
        
        if ([self openDB]) {
            db_open_status = YES;
            if(![self createTable]) {
                KCLog(@"Failed to create SQLite table!");
            } else {
                table_ok = YES;
            }
            
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
            
            // This statement returns pending events.
            char *find_pending_sql = "SELECT id, eventData FROM events WHERE pending=1";
            if(sqlite3_prepare_v2(keen_dbname, find_pending_sql, -1, &find_pending_stmt, NULL) != SQLITE_OK) {
                KCLog(@"Failed to prepare find pending statement!");
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
            
            // This statement deletes events by id.
            char *delete_sql = "DELETE FROM events WHERE id=?";
            if(sqlite3_prepare_v2(keen_dbname, delete_sql, -1, &delete_stmt, NULL) != SQLITE_OK) {
                KCLog(@"Failed to prepare delete statement!");
                [self closeDB];
            }
        }

    }
    return self;
}

#pragma sqlite methods
-(BOOL)openDB {
    BOOL wasOpened = NO;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *my_sqlfile = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"events"];
    if(sqlite3_open([my_sqlfile UTF8String], &keen_dbname) == SQLITE_OK) {
        wasOpened = YES;
    }
    return wasOpened;
}

-(BOOL)createTable {
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

-(BOOL) addEventToTable:(NSString *)eventData  {
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
    // TODO This is a blog, not a string!
    if(sqlite3_bind_text(insert_stmt, 1, [eventData UTF8String], -1, SQLITE_TRANSIENT) != SQLITE_OK) {
        KCLog(@"Failed to bind insert event!");
        [self closeDB];
    } else {
        wasAdded = YES;
    }
    
    if(sqlite3_step(insert_stmt) != SQLITE_DONE) {
        KCLog(@"Failed to insert event!");
        [self closeDB];
    }
    
    return wasAdded;
}

- (void)closeDB {
    sqlite3_finalize(insert_stmt);
    sqlite3_finalize(find_stmt);
    sqlite3_finalize(count_pending_stmt);
    sqlite3_finalize(find_pending_stmt);
    sqlite3_finalize(make_pending_stmt);
    sqlite3_finalize(reset_pending_stmt);
    sqlite3_finalize(delete_stmt);

    sqlite3_close(keen_dbname);
    db_open_status = NO;
    table_ok = NO;
}


- (void)dealloc {
    [self closeDB];
    [super dealloc];
}

@end
