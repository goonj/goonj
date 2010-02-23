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
	NSLog(@"create initial db");
	int err;
    err = sqlite3_open_v2([databasePath cStringUsingEncoding:NSUTF8StringEncoding],
	        &databaseConnection,
			SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE,
			NULL);

    if (err != SQLITE_OK)
        return NO;

	[self createDatabaseSchema];
	[self performInitialScan];

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

- (BOOL) performInitialScan
{
	NSArray *watchDirectories = [[NSUserDefaults standardUserDefaults]
								 arrayForKey:@"LibraryFolderLocations"];


	for (NSString *directory in watchDirectories)
		[self addTracksFromDirectory:[directory stringByExpandingTildeInPath]];

	return YES;
}

- (void) addTracksFromDirectory:(NSString *)aDirectory
{
	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager]
									  enumeratorAtPath:aDirectory];

	NSString *fileName, *filePath;
	BOOL isDirectory;
	while (fileName = [dirEnum nextObject]) {
		filePath = [aDirectory stringByAppendingPathComponent:fileName];

		if ([GUtilities isHidden:filePath])
			continue;

		[[NSFileManager defaultManager] fileExistsAtPath:filePath
											 isDirectory:&isDirectory];

		if (isDirectory == YES)
			[self addTracksFromDirectory:filePath];
		else
			[self addTrack:filePath];
	}
}

- (NSInteger) artistId:(NSString *)artist
{
	NSString *statement;
	int err;
	sqlite3_stmt *preparedStatement;
	
	statement = [NSString stringWithFormat:@"SELECT id FROM artists WHERE name='%@'",
				 artist];

	err = sqlite3_prepare_v2(databaseConnection,
							 [statement cStringUsingEncoding:NSUTF8StringEncoding],
							 [statement length],
							 &preparedStatement,
							 NULL);
	
	if (err != SQLITE_OK)
		return -1;
	
	do {
		err = sqlite3_step(preparedStatement);
	} while (err == SQLITE_ROW && err != SQLITE_DONE);
	
	if (sqlite3_column_count(preparedStatement) == 0) {
		statement = [NSString stringWithFormat:@"INSERT INTO artists (name) VALUES (%@)", artist];
		sqlite3_finalize(preparedStatement);
		sqlite3_prepare_v2(databaseConnection,
						   [statement cStringUsingEncoding:NSUTF8StringEncoding],
						   [statement length],
						   &preparedStatement,
						   NULL);
		err = sqlite3_step(preparedStatement);
		
		if (err != SQLITE_OK)
			return -1;
		
		do {
			err = sqlite3_step(preparedStatement);
		} while (err == SQLITE_ROW && err != SQLITE_DONE);
		
		sqlite3_finalize(preparedStatement);
		return -1; // TODO: return an actual ID from here.
	} else
		NSLog(@"artist already in table");
}

- (void) addTrack:(NSString *)aURL
{
	
	NSDictionary *metadata = [GTrack metadataForFile:aURL];
	NSString *temp, *statement;
	sqlite3_stmt *preparedStatement;
	int err;
	
	// 1. Check to see if artist exists in database.
	//    Yes? Then get the ID. No? Insert him and get the ID.
	temp = [metadata valueForKey:@"artist"];
	[self artistId:temp];

	// 2. Check to see if album exists in database.
	//    Yes? Then get the ID. No? Insert it and get the ID.

	// 3. Check to see if genre exists in database.
	//    Yes? Then get the ID. No? Insert it and get the ID.
	
	// 4. Insert the track.
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
