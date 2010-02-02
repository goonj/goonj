/*
    File: GLibraryManager.m
    Description: The Goonj library manager (implementation).

    This file is part of Goonj.

    Goonj is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Goonj is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Goonj. If not, see <http://www.gnu.org/licenses/>.

    Copyright 2009 Pratul Kalia.
    Copyright 2009 Ankur Sethi.
*/

#import "GLibraryManager.h"
#import "GUtilities.h"


@implementation GLibraryManager

- (id) initWithDefaultDatabase
{
	if (self = [super init]) {
        databasePath = [[GUtilities tracksDatabasePath] stringByExpandingTildeInPath];
		return self;
    }

    return nil;
}

- (BOOL) createInitialDatabase
{
    int err;
    err = sqlite3_open_v2([databasePath cStringUsingEncoding:NSUTF8StringEncoding],
	        &databaseConnection,
			SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE,
			NULL);

    if (err != SQLITE_OK)
        return NO;
	else if (![self createDatabaseSchema])
		return NO;

    return YES;
}

- (BOOL) createDatabaseSchema
{
	NSString *theStatement;

	theStatement = @"CREATE TABLE artists (\
		id INTEGER PRIMARY KEY,\
		name TEXT);";

	if (![self singleStepQuery:theStatement])
		return NO;

	theStatement = @"CREATE TABLE albums (\
		id INTEGER PRIMARY KEY,\
		name TEXT);";

	if (![self singleStepQuery:theStatement])
		return NO;

	theStatement = @"CREATE TABLE genres (\
		id INTEGER PRIMARY KEY,\
		name TEXT);";


	if (![self singleStepQuery:theStatement])
		return NO;

	// Should year be text?
	theStatement = @"CREATE TABLE tracks (\
		id INTEGER,\
		path TEXT,\
		title TEXT,\
		year TEXT,\
		rating INTEGER,\
		artist_id INTEGER,\
		album_id INTEGER,\
		genre_id INTEGER,\
		FOREIGN KEY (artist_id) REFERENCES artists(id),\
		FOREIGN KEY (album_id) REFERENCES albums(id),\
		FOREIGN KEY (genre_id) REFERENCES genres(id));";

	if (![self singleStepQuery:theStatement])
		return NO;

	return YES;
}

- (BOOL) singleStepQuery:(NSString *)aQueryString
{
	sqlite3_stmt *preparedStatement;
	int err;

	err = sqlite3_prepare_v2(databaseConnection,
							 [aQueryString cStringUsingEncoding:NSUTF8StringEncoding],
							 [aQueryString length],
							 &preparedStatement,
							 NULL);

	if (err == SQLITE_OK)
		err = sqlite3_step(preparedStatement);
	else
		return NO;

	if (err == SQLITE_DONE)
		sqlite3_finalize(preparedStatement);
	else
		return NO;

	return YES;
}

- (void) startManager
{
	if ([[NSFileManager defaultManager] fileExistsAtPath:databasePath]);
	else
		[self createInitialDatabase];

	// TODO: remove this once the rest of the manager works.
	sqlite3_close(databaseConnection);
}

@end
