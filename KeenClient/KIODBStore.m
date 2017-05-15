//
//  KIODBStore.m
//  KeenClient
//
//  Created by Cory Watson on 3/26/14.
//  Copyright (c) 2014 Keen Labs. All rights reserved.
//

#import "KeenClient.h"
#import "KIODBStore.h"
#import "KIODBStorePrivate.h"
#import "keen_io_sqlite3.h"

@interface KIODBStore()

- (void)closeDB;

- (void)drainQueue;

// A dispatch queue used for sqlite.
@property (nonatomic) dispatch_queue_t dbQueue;

@end

@implementation KIODBStore {
    keen_io_sqlite3 *keen_dbname;
    BOOL dbIsOpen;
    NSLock* openLock;

    // Keen Event SQL Statements
    keen_io_sqlite3_stmt *insert_event_stmt;
    keen_io_sqlite3_stmt *find_event_stmt;
    keen_io_sqlite3_stmt *count_all_events_stmt;
    keen_io_sqlite3_stmt *count_pending_events_stmt;
    keen_io_sqlite3_stmt *make_pending_event_stmt;
    keen_io_sqlite3_stmt *reset_pending_events_stmt;
    keen_io_sqlite3_stmt *purge_events_stmt;
    keen_io_sqlite3_stmt *delete_event_stmt;
    keen_io_sqlite3_stmt *delete_all_events_stmt;
    keen_io_sqlite3_stmt *increment_event_attempts_statement;
    keen_io_sqlite3_stmt *delete_too_many_attempts_events_statement;
    keen_io_sqlite3_stmt *age_out_events_stmt;

    // Keen Query SQL Statements
    keen_io_sqlite3_stmt *insert_query_stmt;
    keen_io_sqlite3_stmt *count_all_queries_stmt;
    keen_io_sqlite3_stmt *get_query_stmt;
    keen_io_sqlite3_stmt *get_query_with_attempts_stmt;
    keen_io_sqlite3_stmt *increment_query_attempts_statement;
    keen_io_sqlite3_stmt *delete_all_queries_stmt;
    keen_io_sqlite3_stmt *age_out_queries_stmt;
}

- (instancetype)init {
    self = [super init];

    if (nil != self) {
        keen_dbname = NULL;
        dbIsOpen = NO;

        openLock = [[NSLock alloc] init];
        if (nil == openLock) {
            // Failed to create the lock, so let's fail init
            // Otherwise attempting to acquire the lock will silently do nothing
            self = nil;
        }

        if (nil != self) {
            [self openAndInitDB];
        }
    }
    return self;
}

+ (KIODBStore*)sharedInstance {
    static KIODBStore* s_sharedDBStore = nil;

    // This black magic ensures this block
    // is dispatched only once over the lifetime
    // of the program. It's nice because
    // this works even when there's a race
    // between threads to create the object,
    // as both threads will wait synchronously
    // for the block to complete.
    static dispatch_once_t predicate = {0};
    dispatch_once(&predicate, ^{
        s_sharedDBStore = [[KIODBStore alloc] init];
    });

    return s_sharedDBStore;
}

# pragma mark - Handle Database -

# pragma mark Database Methods

+ (NSString*)getSqliteFullFileName {
    NSString* libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [libraryPath stringByAppendingPathComponent:@"keenEvents.sqlite"];
}

- (BOOL)openDB {
    __block BOOL wasOpened = NO;

    NSString* dbFile = [self.class getSqliteFullFileName];
    KCLogInfo(@"%@", dbFile);

    // we're going to use a queue for all database operations, so let's create it
    self.dbQueue = dispatch_queue_create("io.keen.sqlite", DISPATCH_QUEUE_SERIAL);

    // we need to wait for the queue to finish because this method has a return value that we're manipulating in the queue
    dispatch_sync(self.dbQueue, ^{
        // initialize sqlite ourselves so we can config
        keen_io_sqlite3_shutdown();
        keen_io_sqlite3_config(SQLITE_CONFIG_MULTITHREAD);
        keen_io_sqlite3_initialize();

        int openDBResult = keen_io_sqlite3_open([dbFile UTF8String], &keen_dbname);
        if (openDBResult != SQLITE_OK) {
            if(openDBResult == SQLITE_CORRUPT) {
                wasOpened = [self deleteAndRecreateCorruptDB];
            }
            else {
                [self handleSQLiteFailure:@"create database"];
            }
        } else {
            wasOpened = YES;
        }
        dbIsOpen = wasOpened;
    });

    return wasOpened;
}

- (BOOL)deleteAndRecreateCorruptDB {
    BOOL wasOpened = NO;
    // Close the existing db if it's open
    if (NULL != keen_dbname)
    {
        keen_io_sqlite3_close(keen_dbname);
        keen_dbname = NULL;
    }

    NSString* dbFile = [self.class getSqliteFullFileName];
    KCLogError(@"Deleting corrupt db: %@", dbFile);
    [[NSFileManager defaultManager] removeItemAtPath:dbFile error:nil];

    // create new database file
    int secondOpenResult = keen_io_sqlite3_open([dbFile UTF8String], &keen_dbname);
    if (secondOpenResult != SQLITE_OK) {
        // Failed a second time
        [self handleSQLiteFailure:@"replace corrupt database"];
    } else {
        wasOpened = YES;
    }
    return wasOpened;
}

- (BOOL)openAndInitDB {

    // The database can be opened from the thread calling into the SDK,
    // or by the database queue thread if it has been closed, so open
    // needs to be protected with a lock.
    [openLock lock];
    @try {
        if (!dbIsOpen) {
            if (![self openDB]) {
                return false;
            } else {
                if(![self createTables]) {
                    KCLogError(@"Failed to create SQLite table!");
                    [self closeDB];
                    return false;
                }

                if (![self migrateTable]) {
                    KCLogError(@"Failed to migrate SQLite table!");
                    [self closeDB];
                    return false;
                }

                if (![self prepareAllSQLiteStatements]) {
                    return false;
                }
            }
        }
    } @finally {
        [openLock unlock];
    }

    return true;
}

- (void)closeDB {
    // Free all the prepared statements. This is safe on null pointers.
    if (dbIsOpen) {
        self.dbQueue = nil;

        keen_io_sqlite3_finalize(insert_event_stmt);
        keen_io_sqlite3_finalize(find_event_stmt);
        keen_io_sqlite3_finalize(count_all_events_stmt);
        keen_io_sqlite3_finalize(count_pending_events_stmt);
        keen_io_sqlite3_finalize(make_pending_event_stmt);
        keen_io_sqlite3_finalize(reset_pending_events_stmt);
        keen_io_sqlite3_finalize(purge_events_stmt);
        keen_io_sqlite3_finalize(delete_event_stmt);
        keen_io_sqlite3_finalize(delete_all_events_stmt);
        keen_io_sqlite3_finalize(increment_event_attempts_statement);
        keen_io_sqlite3_finalize(delete_too_many_attempts_events_statement);
        keen_io_sqlite3_finalize(age_out_events_stmt);

        keen_io_sqlite3_finalize(insert_query_stmt);
        keen_io_sqlite3_finalize(count_all_queries_stmt);
        keen_io_sqlite3_finalize(get_query_stmt);
        keen_io_sqlite3_finalize(increment_query_attempts_statement);
        keen_io_sqlite3_finalize(delete_all_queries_stmt);
        keen_io_sqlite3_finalize(get_query_with_attempts_stmt);
        keen_io_sqlite3_finalize(age_out_queries_stmt);

        // Free our DB. This is safe on null pointers.
        keen_io_sqlite3_close(keen_dbname);
        keen_dbname = NULL;
        // Reset state in case it matters.
        dbIsOpen = NO;
    }
}

- (void)drainQueue {
    if (dbIsOpen) {
        dispatch_group_t group = dispatch_group_create();
        
        // Add a task to be run after all other tasks
        dispatch_group_async(group, self.dbQueue, ^{
            KCLogVerbose(@"Queue complete");
        });
        
        // Wait for the task to be run, which means all other
        // queued tasks have run. Of note: if a task is added
        // after this one, the queue isn't going to be empty.
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    }
}

- (BOOL)createTables {
    __block BOOL wasCreated = NO;

    if (!dbIsOpen) {
        KCLogError(@"DB is closed, skipping createTable");
        return wasCreated;
    }

    // we need to wait for the queue to finish because this method has a return value that we're manipulating in the queue
    dispatch_sync(self.dbQueue, ^{
        //create events table
        char *eventsError;
        NSString *createEventsTableSQL = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS 'events' (ID INTEGER PRIMARY KEY AUTOINCREMENT, collection TEXT, projectID TEXT, eventData BLOB, pending INTEGER, dateCreated TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"];
        int result = SQLITE_FAIL;
        for (int i = 0; i < 2; ++i)
        {
            // The database is loaded on demand and this is the first time we use it, so here
            // is where we're likely to actually notice corruption. Handle it by deleting the
            // corrupt db and creating a new one.
            result = keen_io_sqlite3_exec(keen_dbname, [createEventsTableSQL UTF8String], NULL, NULL, &eventsError);
            if (result == SQLITE_CORRUPT) {
                if (![self deleteAndRecreateCorruptDB])
                {
                    KCLogError(@"Failed to replace corrupt db while creating events table: %@", [NSString stringWithCString:eventsError encoding:NSUTF8StringEncoding]);
                    keen_io_sqlite3_free(eventsError); // Free that error message
                    [self closeDB];
                    break;
                }
                // If deleting and recreating the db was successful, continue the loop to create the events table
            } else if (result != SQLITE_OK) {
                KCLogError(@"Failed to create events table: %@", [NSString stringWithCString:eventsError encoding:NSUTF8StringEncoding]);
                keen_io_sqlite3_free(eventsError); // Free that error message
                [self closeDB];
            }
        }

        if (SQLITE_OK == result) {
            //create queries table
            char *queriesError;
            NSString *createQueriesTableSQL = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS 'queries' (ID INTEGER PRIMARY KEY AUTOINCREMENT, collection TEXT, projectID TEXT, queryData BLOB, queryType TEXT, attempts INTEGER DEFAULT 0, dateCreated TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"];
            if (keen_io_sqlite3_exec(keen_dbname, [createQueriesTableSQL UTF8String], NULL, NULL, &queriesError) != SQLITE_OK) {
                KCLogError(@"Failed to create queries table: %@", [NSString stringWithCString:queriesError encoding:NSUTF8StringEncoding]);
                keen_io_sqlite3_free(queriesError); // Free that error message
                [self closeDB];
            } else {
                wasCreated = YES;
            }
        }
    });


    return wasCreated;
}

- (int)queryUserVersion {
    int databaseVersion = 0;

    // get current database version of schema
    static keen_io_sqlite3_stmt *stmt_version;

    if(keen_io_sqlite3_prepare_v2(keen_dbname, "PRAGMA user_version;", -1, &stmt_version, NULL) != SQLITE_OK) {
        return -1;
    }

    while(keen_io_sqlite3_step(stmt_version) == SQLITE_ROW) {
        databaseVersion = keen_io_sqlite3_column_int(stmt_version, 0);
    }
    keen_io_sqlite3_finalize(stmt_version);

    // -1 means error, >= 1 is a real version number, otherwise it's unversioned
    if (databaseVersion != -1 && !(databaseVersion >= 1)) {
        return 0;
    }

    return databaseVersion;
}

- (BOOL)setUserVersion: (int)userVersion {
    char *err;
    NSString *sql = [NSString stringWithFormat:@"PRAGMA user_version = %d;", userVersion];
    if (keen_io_sqlite3_exec(keen_dbname, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK) {
        KCLogError(@"failed to set user_version: %@", [NSString stringWithCString:err encoding:NSUTF8StringEncoding]);
        keen_io_sqlite3_free(err); // Free that error message
        return NO;
    }

    return YES;
}

- (BOOL)migrateTable {
    __block BOOL wasMigrated = NO;

    if (!dbIsOpen) {
        KCLogError(@"DB is closed, skipping migrateTable");
        return NO;
    }

    // we need to wait for the queue to finish because this method has a return value
    // that we're manipulating in the queue
    dispatch_sync(self.dbQueue, ^{
        int userVersion = [self queryUserVersion];
        KCLogInfo(@"Preparing to migrate DB, current version: %d", userVersion);
        wasMigrated = [self migrateFromVersion:userVersion];
    });

    return wasMigrated;
}

-(BOOL)migrateFromVersion: (int)userVersion {
    // this is really more of a while loop, but we use a for loop with a limit to avoid
    // getting stuck in an infinite loop if there is a bug in the loop breaking logic
    for(int i = 0; i < 1000; i++) {
        if(![self beginTransaction]) {
            // deal with error?
            KCLogError(@"Migration failed to begin a transaction with userVersion = %d.", userVersion);
            return NO;
        }

        int migrationResult = [self runMigration:userVersion];
        if (migrationResult == 0) {
            // we didn't migrate anything, because we're current.
            if (![self endTransaction]) {
                KCLogError(@"Migration failed to end a transaction with userVersion = %d.", userVersion);
                return NO;
            }
            return YES;
        }

        if (migrationResult < 0) {
            // error
            if (![self rollbackTransaction]) {
                KCLogError(@"Migration failed to rollback a transaction with userVersion = %d.", userVersion);
                // yeesh, couldn't rollback
            }
            return NO;
        }

        // we migrated, so increment PRAGMA user_version
        if (![self setUserVersion:userVersion+1]) {
            KCLogError(@"Migration failed to set the user_version to %d.", userVersion);
            if (![self rollbackTransaction]) {
                KCLogError(@"Migration failed to rollback a transaction after failing to set user_version (with userVersion = %d).", userVersion);
                // whoa, double bad news
            }
            return NO;
        }

        // ok, let's commit this step
        if (![self commitTransaction]) {
            KCLogError(@"Migration failed to commit a transaction with userVersion = %d.", userVersion);
            return NO;
        }

        userVersion++;

        // there might be more migrations, so we loop around again
    }

    KCLogError(@"Migration loop maxed out after 1000 iterations. This is almost certainly a bug. Version %d", [self queryUserVersion]);

    return NO;
}

- (int)runMigration: (int)forVersion {
    char *err;

    if (forVersion < 0) {
        // versions less than 0 are an error
        return -1;
    } else if (forVersion == 0) {
        // first migration does nothing, just adds adds a real version number (1).
        return YES;
    } else if (forVersion == 1) {
        NSString *sql = @"ALTER TABLE events ADD COLUMN attempts INTEGER DEFAULT 0;";
        if (keen_io_sqlite3_exec(keen_dbname, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK) {
            KCLogError(@"Failed to add attempts column: %@", [NSString stringWithCString:err encoding:NSUTF8StringEncoding]);
            keen_io_sqlite3_free(err); // Free that error message
            return -1;
        }
        return YES;
    } else if (forVersion == 2) {
        // This is the current version. To add a migration, increment the value of the
        // RHS of the above if statement and add another else if statement in between
        // to handle the new version number.
        // e.g. change `forVersion == 2` to `forVersion == 3`, and then add an
        // explicit block for handling the forVersion == 2 migration that looks like
        // the forVersion == 1 block above.

        // IMPORTANT: never remove any existing migration blocks!

        return 0;
    }

    // versions that aren't integers or are greater than the max version we know about
    // are errors
    return -1;
}

# pragma mark Transaction Methods

- (BOOL)doTransaction:(NSString *)sqlTransaction {
    char *err;
    NSString *sql = sqlTransaction;
    if (keen_io_sqlite3_exec(keen_dbname, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK) {
        KCLogError(@"failed to do transaction:%@, with error: %@", sqlTransaction, [NSString stringWithCString:err encoding:NSUTF8StringEncoding]);
        keen_io_sqlite3_free(err); // Free that error message
        return NO;
    }
    return YES;
}

- (BOOL)beginTransaction {
    return [self doTransaction:@"BEGIN IMMEDIATE TRANSACTION;"];
}

- (BOOL)commitTransaction {
    return [self doTransaction:@"COMMIT TRANSACTION;"];
}

- (BOOL)rollbackTransaction {
    return [self doTransaction:@"ROLLBACK TRANSACTION;"];
}

- (BOOL)endTransaction {
    return [self doTransaction:@"END TRANSACTION;"];
}

# pragma mark - Handle Events -

- (BOOL)addEvent:(NSData *)eventData collection:(NSString *)eventCollection projectID:(NSString *)projectID {
    __block BOOL wasAdded = NO;

    if(![self checkOpenDB:@"DB is closed, skipping addEvent"]) {
        return wasAdded;
    }

    const char *projectIDUTF8 = projectID.UTF8String;
    const char *eventCollectionUTF8 = eventCollection.UTF8String;
    // we need to wait for the queue to finish because this method has a return value that we're manipulating in the queue
    dispatch_sync(self.dbQueue, ^{
        if (keen_io_sqlite3_bind_text(insert_event_stmt, 1, projectIDUTF8, -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind pid to add event statement"];
            return;
        }

        if (keen_io_sqlite3_bind_text(insert_event_stmt, 2, eventCollectionUTF8, -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind coll to add event statement"];
            return;
        }

        if (keen_io_sqlite3_bind_blob(insert_event_stmt, 3, [eventData bytes], (int) [eventData length], SQLITE_TRANSIENT) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind insert statement"];
            return;
        }

        if (keen_io_sqlite3_step(insert_event_stmt) != SQLITE_DONE) {
            [self handleSQLiteFailure:@"insert event"];
            return;
        }

        wasAdded = YES;

        [self resetSQLiteStatement:insert_event_stmt];
    });

    return wasAdded;
}

- (NSMutableDictionary *)getEventsWithMaxAttempts:(int)maxAttempts andProjectID:(NSString *)projectID {
    // Create a dictionary to hold the contents of our select.
    __block NSMutableDictionary *events = [NSMutableDictionary dictionary];

    if(![self checkOpenDB:@"DB is closed, skipping getEvents"]) {
        return events;
    }

    // reset pending events, if necessary
    if([self hasPendingEventsWithProjectID:projectID]) {
        [self resetPendingEventsWithProjectID:projectID];
    }

    const char *projectIDUTF8 = projectID.UTF8String;
    // we need to wait for the queue to finish because this method has a return value that we're manipulating in the queue
    dispatch_sync(self.dbQueue, ^{
        if (keen_io_sqlite3_bind_text(find_event_stmt, 1, projectIDUTF8, -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind pid to find statement"];
            return;
        }

        if(keen_io_sqlite3_bind_int64(find_event_stmt, 2, maxAttempts) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind coll to add event statement"];
            return;
        }


        while (keen_io_sqlite3_step(find_event_stmt) == SQLITE_ROW) {
            // Fetch data out the statement
            long long eventId = keen_io_sqlite3_column_int64(find_event_stmt, 0);

            NSString *coll = [NSString stringWithUTF8String:(char *)keen_io_sqlite3_column_text(find_event_stmt, 1)];

            const void *dataPtr = keen_io_sqlite3_column_blob(find_event_stmt, 2);
            int dataSize = keen_io_sqlite3_column_bytes(find_event_stmt, 2);

            NSData *data = [[NSData alloc] initWithBytes:dataPtr length:dataSize];

            // Bind and mark the event pending.
            if(keen_io_sqlite3_bind_int64(make_pending_event_stmt, 1, eventId) != SQLITE_OK) {
                [self handleSQLiteFailure:@"bind int for make pending"];
                return;
            }
            if (keen_io_sqlite3_step(make_pending_event_stmt) != SQLITE_DONE) {
                [self handleSQLiteFailure:@"mark event pending"];
                return;
            }

            // Reset the pendifier
            [self resetSQLiteStatement:make_pending_event_stmt];

            if ([events objectForKey:coll] == nil) {
                // We don't have an entry in the dictionary yet for this collection
                // so create one.
                [events setObject:[NSMutableDictionary dictionary] forKey:coll];
            }

            [[events objectForKey:coll] setObject:data forKey:[NSNumber numberWithUnsignedLongLong:eventId]];
        }

        [self resetSQLiteStatement:find_event_stmt];
    });

    return events;
}

- (void)resetPendingEventsWithProjectID:(NSString *)projectID {
    if(![self checkOpenDB:@"DB is closed, skipping resetPendingEvents"]) {
        return;
    }

    const char *projectIDUTF8 = projectID.UTF8String;
    dispatch_async(self.dbQueue, ^{
        if (keen_io_sqlite3_bind_text(reset_pending_events_stmt, 1, projectIDUTF8, -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind pid to reset pending statement"];
            return;
        }
        if (keen_io_sqlite3_step(reset_pending_events_stmt) != SQLITE_DONE) {
            [self handleSQLiteFailure:@"reset pending events"];
            return;
        }

        [self resetSQLiteStatement:reset_pending_events_stmt];
    });
}

- (BOOL)hasPendingEventsWithProjectID:(NSString *)projectID {
    BOOL hasRows = NO;

    if(![self checkOpenDB:@"DB is closed, skipping hasPendingEvents"]) {
        return hasRows;
    }

    if ([self getPendingEventCountWithProjectID:projectID] > 0) {
        hasRows = TRUE;
    }
    return hasRows;
}

- (NSUInteger)getPendingEventCountWithProjectID:(NSString *)projectID {
    __block NSUInteger eventCount = 0;

    if(![self checkOpenDB:@"DB is closed, skipping getPendingEventcount"]) {
        return eventCount;
    }

    const char *projectIDUTF8 = projectID.UTF8String;
    // we need to wait for the queue to finish because this method has a return value that we're manipulating in the queue
    dispatch_sync(self.dbQueue, ^{
        if (keen_io_sqlite3_bind_text(count_pending_events_stmt, 1, projectIDUTF8, -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind pid to count pending statement"];
            return;
        }
        if (keen_io_sqlite3_step(count_pending_events_stmt) == SQLITE_ROW) {
            eventCount = (NSInteger) keen_io_sqlite3_column_int(count_pending_events_stmt, 0);
        } else {
            [self handleSQLiteFailure:@"get count of pending rows"];
            return;
        }

        [self resetSQLiteStatement:count_pending_events_stmt];
    });

    return eventCount;
}

- (NSUInteger)getTotalEventCountWithProjectID:(NSString *)projectID {
    __block NSUInteger eventCount = 0;

    if(![self checkOpenDB:@"DB is closed, skipping getTotalEventCount"]) {
        return eventCount;
    }

    const char *projectIDUTF8 = projectID.UTF8String;
    // we need to wait for the queue to finish because this method has a return value that we're manipulating in the queue
    dispatch_sync(self.dbQueue, ^{
        if (keen_io_sqlite3_bind_text(count_all_events_stmt, 1, projectIDUTF8, -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind pid to total event statement"];
            return;
        }
        if (keen_io_sqlite3_step(count_all_events_stmt) == SQLITE_ROW) {
            eventCount = (NSInteger) keen_io_sqlite3_column_int(count_all_events_stmt, 0);
        } else {
            [self handleSQLiteFailure:@"get count of total rows"];
            return;
        }

        [self resetSQLiteStatement:count_all_events_stmt];
    });

    return eventCount;
}

- (void)deleteEvent:(NSNumber *)eventId {
    if(![self checkOpenDB:@"DB is closed, skipping deleteEvent"]) {
        return;
    }

    dispatch_async(self.dbQueue, ^{
        if (keen_io_sqlite3_bind_int64(delete_event_stmt, 1, [eventId unsignedLongLongValue]) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind eventid to delete statement"];
            return;
        }
        if (keen_io_sqlite3_step(delete_event_stmt) != SQLITE_DONE) {
            [self handleSQLiteFailure:@"delete event"];
            return;
        };

        [self resetSQLiteStatement:delete_event_stmt];
    });
}

- (void)deleteAllEvents {
    if(![self checkOpenDB:@"DB is closed, skipping deleteEvent"]) {
        return;
    }

    dispatch_async(self.dbQueue, ^{
        if (keen_io_sqlite3_step(delete_all_events_stmt) != SQLITE_DONE) {
            [self handleSQLiteFailure:@"delete all events"];
            return;
        };

        [self resetSQLiteStatement:delete_all_events_stmt];
    });
}

- (void)deleteEventsFromOffset:(NSNumber *)offset {
    if(![self checkOpenDB:@"DB is closed, skipping deleteEvent"]) {
        return;
    }

    dispatch_async(self.dbQueue, ^{
        if (keen_io_sqlite3_bind_int64(age_out_events_stmt, 1, [offset unsignedLongLongValue]) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind offset to ageOut statement"];
            return;
        }
        if (keen_io_sqlite3_step(age_out_events_stmt) != SQLITE_DONE) {
            [self handleSQLiteFailure:@"delete all events"];
            return;
        };

        [self resetSQLiteStatement:age_out_events_stmt];
    });
}

- (void)incrementEventUploadAttempts:(NSNumber *)eventId {
    if(![self checkOpenDB:@"DB is closed, skipping incrementAttempts"]) {
        return;
    }

    dispatch_async(self.dbQueue, ^{
        if (keen_io_sqlite3_bind_int64(increment_event_attempts_statement, 1, [eventId unsignedLongLongValue]) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind eventid to increment attempts statement"];
            return;
        }
        if (keen_io_sqlite3_step(increment_event_attempts_statement) != SQLITE_DONE) {
            [self handleSQLiteFailure:@"increment attempts"];
            return;
        };

        [self resetSQLiteStatement:increment_event_attempts_statement];
    });
}

- (void)purgePendingEventsWithProjectID:(NSString *)projectID {
    if(![self checkOpenDB:@"DB is closed, skipping purgePendingEvents"]) {
        return;
    }

    const char *projectIDUTF8 = [projectID UTF8String];
    dispatch_async(self.dbQueue, ^{
        if (keen_io_sqlite3_bind_text(purge_events_stmt, 1, projectIDUTF8, -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind pid to purge statement"];
            return;
        }
        if (keen_io_sqlite3_step(purge_events_stmt) != SQLITE_DONE) {
            [self handleSQLiteFailure:@"purge pending events"];
            return;
        };

        [self resetSQLiteStatement:purge_events_stmt];
    });
}

# pragma mark - Handle Queries

- (BOOL)addQuery:(NSData *)queryData queryType:(NSString *)queryType collection:(NSString *)eventCollection projectID:(NSString *)projectID {
    __block BOOL wasAdded = NO;

    if(![self checkOpenDB:@"DB is closed, skipping addQuery"]) {
        return wasAdded;
    }

    const char *projectIDUTF8 = projectID.UTF8String;
    const char *eventCollectionUTF8 = eventCollection.UTF8String;
    const char *queryTypeUTF8 = queryType.UTF8String;
    // we need to wait for the queue to finish because this method has a return value that we're manipulating in the queue
    dispatch_sync(self.dbQueue, ^{
        if (keen_io_sqlite3_bind_text(insert_query_stmt, 1, projectIDUTF8, -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind pid to add event statement"];
            return;
        }

        if (keen_io_sqlite3_bind_text(insert_query_stmt, 2, eventCollectionUTF8, -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind coll to add event statement"];
            return;
        }

        if (keen_io_sqlite3_bind_blob(insert_query_stmt, 3, [queryData bytes], (int) [queryData length], SQLITE_TRANSIENT) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind insert statement"];
            return;
        }

        if (keen_io_sqlite3_bind_text(insert_query_stmt, 4, queryTypeUTF8, -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind query type to add event statement"];
            return;
        }

        if (keen_io_sqlite3_step(insert_query_stmt) != SQLITE_DONE) {
            [self handleSQLiteFailure:@"insert query"];
            return;
        }

        wasAdded = YES;

        [self resetSQLiteStatement:insert_query_stmt];
    });

    return wasAdded;
}

- (NSMutableDictionary *)getQuery:(NSData *)queryData queryType:(NSString *)queryType collection:(NSString *)eventCollection projectID:(NSString *)projectID {
    // Create a dictionary to hold the contents of our select.
    __block NSMutableDictionary *query = nil;

    if(![self checkOpenDB:@"DB is closed, skipping getQuery"]) {
        return query;
    }

    const char *projectIDUTF8 = projectID.UTF8String;
    const char *eventCollectionUTF8 = eventCollection.UTF8String;
    const char *queryTypeUTF8 = queryType.UTF8String;
    // we need to wait for the queue to finish because this method has a return value that we're manipulating in the queue
    dispatch_sync(self.dbQueue, ^{
        if (keen_io_sqlite3_bind_text(get_query_stmt, 1, projectIDUTF8, -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind pid to get query statement"];
            return;
        }

        if (keen_io_sqlite3_bind_text(get_query_stmt, 2, eventCollectionUTF8, -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind collection to get query statement"];
            return;
        }

        if (keen_io_sqlite3_bind_blob(get_query_stmt, 3, [queryData bytes], (int)[queryData length], SQLITE_TRANSIENT) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind query data to get query statement"];
            return;
        }

        if (keen_io_sqlite3_bind_text(get_query_stmt, 4, queryTypeUTF8, -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind query type to get query statement"];
            return;
        }

        int result = keen_io_sqlite3_step(get_query_stmt);
        if (SQLITE_ROW == result) {
            // Fetch data out the statement
            query = [NSMutableDictionary dictionary];

            NSNumber *queryID = [NSNumber numberWithUnsignedLongLong:keen_io_sqlite3_column_int64(get_query_stmt, 0)];

            NSString *eventCollection = [NSString stringWithUTF8String:(char *)keen_io_sqlite3_column_text(get_query_stmt, 1)];

            const void *dataPtr = keen_io_sqlite3_column_blob(get_query_stmt, 2);
            int dataSize = keen_io_sqlite3_column_bytes(get_query_stmt, 2);

            NSData *data = [[NSData alloc] initWithBytes:dataPtr length:dataSize];

            NSString *queryType = [NSString stringWithUTF8String:(char *)keen_io_sqlite3_column_text(get_query_stmt, 3)];

            NSNumber *attempts = [NSNumber numberWithUnsignedLong:keen_io_sqlite3_column_int(get_query_stmt, 4)];

            [query setObject:queryID forKey:@"queryID"];
            [query setObject:eventCollection forKey:@"event_collection"];
            [query setObject:data forKey:@"queryData"];
            [query setObject:queryType forKey:@"queryType"];
            [query setObject:attempts forKey:@"attempts"];
        } else if (SQLITE_DONE != result) {
            // SQLITE_DONE just means there weren't any results, which isn't a db error.
            // If we got anything else, we treat it as an error here.
            [self handleSQLiteFailure:@"find query"];
            return;
        }

        [self resetSQLiteStatement:get_query_stmt];
    });

    return query;
}

- (BOOL)incrementQueryAttempts:(NSNumber *)queryID {
    __block BOOL wasUpdated = NO;

    if(![self checkOpenDB:@"DB is closed, skipping query increment attempt"]) {
        return wasUpdated;
    }

    dispatch_sync(self.dbQueue, ^{
        if (keen_io_sqlite3_bind_int64(increment_query_attempts_statement, 1, [queryID unsignedLongLongValue]) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind eventid to increment attempts statement"];
            return;
        }
        if (keen_io_sqlite3_step(increment_query_attempts_statement) != SQLITE_DONE) {
            [self handleSQLiteFailure:@"increment attempts"];
            return;
        };

        wasUpdated = YES;

        [self resetSQLiteStatement:increment_query_attempts_statement];
    });

    return wasUpdated;
}

- (void)findOrUpdateQuery:(NSData *)queryData queryType:(NSString *)queryType collection:(NSString *)eventCollection projectID:(NSString *)projectID {
    NSMutableDictionary *returnedQuery = [self getQuery:queryData queryType:queryType collection:eventCollection projectID:projectID];
    if(returnedQuery != nil) {
        // if query is found, update query attempts
        [self incrementQueryAttempts:[returnedQuery objectForKey:@"queryID"]];
    } else {
        // else add it to the database
        [self addQuery:queryData queryType:queryType collection:eventCollection projectID:projectID];
    }
}

- (NSUInteger)getTotalQueryCountWithProjectID:(NSString *)projectID {
    __block NSUInteger queryCount = 0;

    if(![self checkOpenDB:@"DB is closed, skipping getTotalQueryCount"]) {
        return queryCount;
    }

    const char *projectIDUTF8 = projectID.UTF8String;
    // we need to wait for the queue to finish because this method has a return value that we're manipulating in the queue
    dispatch_sync(self.dbQueue, ^{
        if (keen_io_sqlite3_bind_text(count_all_queries_stmt, 1, projectIDUTF8, -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind pid to total query statement"];
            return;
        }
        if (keen_io_sqlite3_step(count_all_queries_stmt) == SQLITE_ROW) {
            queryCount = (NSInteger) keen_io_sqlite3_column_int(count_all_queries_stmt, 0);
        } else {
            [self handleSQLiteFailure:@"get count of total query rows"];
            return;
        }

        [self resetSQLiteStatement:count_all_queries_stmt];
    });

    return queryCount;
}

- (BOOL)hasQueryWithMaxAttempts:(NSData *)queryData
                      queryType:(NSString *)queryType
                     collection:(NSString *)eventCollection
                      projectID:(NSString *)projectID
                    maxAttempts:(int)maxAttempts
                       queryTTL:(int)queryTTL {

    __block BOOL hasFoundQueryWithMaxAttempts = NO;

    if(![self checkOpenDB:@"DB is closed, skipping hasQueryWithMaxAttempts"]) {
        return hasFoundQueryWithMaxAttempts;
    }

    // clear query database based on timespan
    [self deleteQueriesOlderThan:[NSNumber numberWithInt:queryTTL]];

    const char *projectIDUTF8 = projectID.UTF8String;
    const char *eventCollectionUTF8 = eventCollection.UTF8String;
    const char *queryTypeUTF8 = queryType.UTF8String;
    // we need to wait for the queue to finish because this method has a return value that we're manipulating in the queue
    dispatch_sync(self.dbQueue, ^{
        if (keen_io_sqlite3_bind_text(get_query_with_attempts_stmt, 1, projectIDUTF8, -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind pid to has query with max attempts statement"];
            return;
        }

        if (keen_io_sqlite3_bind_text(get_query_with_attempts_stmt, 2, eventCollectionUTF8, -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind collection to has query with max attempts statement"];
            return;
        }

        if (keen_io_sqlite3_bind_blob(get_query_with_attempts_stmt, 3, [queryData bytes], (int)[queryData length], SQLITE_TRANSIENT) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind query data to has query with max attempts statement"];
            return;
        }

        if (keen_io_sqlite3_bind_text(get_query_with_attempts_stmt, 4, queryTypeUTF8, -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind query type to has query with max attempts statement"];
            return;
        }

        if (keen_io_sqlite3_bind_int64(get_query_with_attempts_stmt, 5, maxAttempts) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind attempts to has query with max attempts statement"];
        }

        int result = keen_io_sqlite3_step(get_query_with_attempts_stmt);
        if (SQLITE_ROW == result) {
            hasFoundQueryWithMaxAttempts = YES;
        } else if (SQLITE_DONE != result) {
            // SQLITE_DONE just means there weren't any results, which is the common case.
            // If we got anything else, we treat it as an error here.
            [self handleSQLiteFailure:@"find query with max attempts"];
            return;
        }

        [self resetSQLiteStatement:get_query_with_attempts_stmt];
    });

    return hasFoundQueryWithMaxAttempts;
}

- (void)deleteAllQueries {
    if(![self checkOpenDB:@"DB is closed, skipping deleteAllQueries"]) {
        return;
    }

    dispatch_async(self.dbQueue, ^{
        if (keen_io_sqlite3_step(delete_all_queries_stmt) != SQLITE_DONE) {
            [self handleSQLiteFailure:@"delete all queries"];
            return;
        };

        [self resetSQLiteStatement:delete_all_queries_stmt];
    });
}

- (void)deleteQueriesOlderThan:(NSNumber *)seconds {
    if(![self checkOpenDB:@"DB is closed, skipping deleteQueries"]) {
        return;
    }

    const char *secondsSQLUTF8String = [[NSString stringWithFormat:@"-%@ seconds", seconds] UTF8String];
    dispatch_sync(self.dbQueue, ^{
        if (keen_io_sqlite3_bind_text(age_out_queries_stmt, 1, secondsSQLUTF8String, -1, SQLITE_STATIC) != SQLITE_OK) {
            [self handleSQLiteFailure:@"bind seconds to delete query statement"];
            return;
        }

        if (keen_io_sqlite3_step(age_out_queries_stmt) != SQLITE_DONE) {
            [self handleSQLiteFailure:@"delete old queries"];
            return;
        };

        [self resetSQLiteStatement:age_out_queries_stmt];
    });
}

# pragma mark - Helper Methods -

- (BOOL)checkOpenDB:(NSString *)failureMessage {
    if(![self openAndInitDB]) {
        KCLogError(@"%@", failureMessage);
        return false;
    }

    return true;
}

- (BOOL)prepareSQLStatement:(keen_io_sqlite3_stmt **)sqlStatement sqlQuery:(char *)sqlQuery failureMessage:(NSString *)failureMessage {
    if(keen_io_sqlite3_prepare_v2(keen_dbname, sqlQuery, -1, sqlStatement, NULL) != SQLITE_OK) {
        [self handleSQLiteFailure:failureMessage];
        return NO;
    }
    return YES;
}

- (void)resetSQLiteStatement:(keen_io_sqlite3_stmt *)sqliteStatement {
    keen_io_sqlite3_reset(sqliteStatement);
    keen_io_sqlite3_clear_bindings(sqliteStatement);
}

- (BOOL)prepareAllSQLiteStatements {

    // EVENT STATEMENTS

    // This statement inserts events into the table.
    if(![self prepareSQLStatement:&insert_event_stmt sqlQuery:"INSERT INTO events (projectID, collection, eventData, pending, attempts) VALUES (?, ?, ?, 0, 0)" failureMessage:@"prepare insert event statement"]) return NO;

    // This statement finds non-pending events in the table.
    if(![self prepareSQLStatement:&find_event_stmt sqlQuery:"SELECT id, collection, eventData FROM events WHERE pending=0 AND projectID=? AND attempts<?" failureMessage:@"prepare find non-pending events statement"]) return NO;

    // This statement counts the total number of events (pending or not)
    if(![self prepareSQLStatement:&count_all_events_stmt sqlQuery:"SELECT count(*) FROM events WHERE projectID=?" failureMessage:@"prepare count all events statement"]) return NO;

    // This statement counts the number of pending events.
    if(![self prepareSQLStatement:&count_pending_events_stmt sqlQuery:"SELECT count(*) FROM events WHERE pending=1 AND projectID=?" failureMessage:@"prepare count pending events statement"]) return NO;

    // This statement marks an event as pending.
    if(![self prepareSQLStatement:&make_pending_event_stmt sqlQuery:"UPDATE events SET pending=1 WHERE id=?" failureMessage:@"prepare mark event as pending statement"]) return NO;

    // This statement resets pending events back to normal.
    if(![self prepareSQLStatement:&reset_pending_events_stmt sqlQuery:"UPDATE events SET pending=0 WHERE projectID=?" failureMessage:@"prepare reset pending statement"]) return NO;

    // This statement purges all pending events.
    if(![self prepareSQLStatement:&purge_events_stmt sqlQuery:"DELETE FROM events WHERE pending=1 AND projectID=?" failureMessage:@"prepare purge pending events statement"]) return NO;

    // This statement deletes a specific event.
    if(![self prepareSQLStatement:&delete_event_stmt sqlQuery:"DELETE FROM events WHERE id=?" failureMessage:@"prepare delete specific event statement"]) return NO;

    // This statement deletes all events.
    if(![self prepareSQLStatement:&delete_all_events_stmt sqlQuery:"DELETE FROM events" failureMessage:@"prepare delete all events statement"]) return NO;

    // This statement deletes old events at a given offset.
    if(![self prepareSQLStatement:&age_out_events_stmt sqlQuery:"DELETE FROM events WHERE id <= (SELECT id FROM events ORDER BY id DESC LIMIT 1 OFFSET ?)" failureMessage:@"prepare delete old events at offset statement"]) return NO;

    // This statement increments the attempts count of an event.
    if(![self prepareSQLStatement:&increment_event_attempts_statement sqlQuery:"UPDATE events SET attempts = attempts + 1 WHERE id=?" failureMessage:@"prepare event increment attempt statement"]) return NO;

    // This statement deletes events exceeding a max attempt limit.
    if(![self prepareSQLStatement:&delete_too_many_attempts_events_statement sqlQuery:"DELETE FROM events WHERE attempts >= ?" failureMessage:@"prepare delete max attempts events statement"]) return NO;


    // QUERY STATEMENTS

    // This statement inserts queries into the table.
    if(![self prepareSQLStatement:&insert_query_stmt sqlQuery:"INSERT INTO queries (projectID, collection, queryData, queryType, attempts) VALUES (?, ?, ?, ?, 0)" failureMessage:@"prepare insert query statement"]) return NO;

    // This statement counts the total number of queries
    if(![self prepareSQLStatement:&count_all_queries_stmt sqlQuery:"SELECT count(*) FROM queries WHERE projectID=?" failureMessage:@"prepare count all queries statement"]) return NO;

    // This statement searches for and returns a query.
    if(![self prepareSQLStatement:&get_query_stmt sqlQuery:"SELECT id, collection, queryData, queryType, attempts FROM queries WHERE projectID=? AND collection=? AND queryData=? AND queryType=?" failureMessage:@"prepare find query statement"]) return NO;

    // This statement searches for and returns a query given an attempts value.
    if(![self prepareSQLStatement:&get_query_with_attempts_stmt sqlQuery:"SELECT id FROM queries WHERE projectID=? AND collection=? AND queryData=? AND queryType=? AND attempts >=?" failureMessage:@"prepare find query with attempts statement"]) return NO;

    // This statement increments the attempts count of a query.
    if(![self prepareSQLStatement:&increment_query_attempts_statement sqlQuery:"UPDATE queries SET attempts = attempts + 1 WHERE id=?" failureMessage:@"prepare query increment attempt statement"]) return NO;

    // This statement deletes all queries.
    if(![self prepareSQLStatement:&delete_all_queries_stmt sqlQuery:"DELETE FROM queries" failureMessage:@"prepare delete all queries statement"]) return NO;

    // This statement deletes old queries at a given time.
    if(![self prepareSQLStatement:&age_out_queries_stmt sqlQuery:"DELETE FROM queries WHERE dateCreated <= datetime('now', ?)" failureMessage:@"prepare delete old queries at seconds statement"]) return NO;

    return YES;
}

- (void)handleSQLiteFailure:(NSString *) msg {
    KCLogError(@"Failed to %@: %@",
          msg, [NSString stringWithCString:keen_io_sqlite3_errmsg(keen_dbname) encoding:NSUTF8StringEncoding]);
    int result = keen_io_sqlite3_errcode(keen_dbname);
    [self closeDB];
    if (SQLITE_CORRUPT == result)
    {
        NSString* dbFile = [self.class getSqliteFullFileName];
        KCLogError(@"Deleting corrupt db: %@", dbFile);
        [[NSFileManager defaultManager] removeItemAtPath:dbFile error:nil];
    }
}

@end
