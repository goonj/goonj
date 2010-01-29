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
        if ([[NSFileManager defaultManager]
            fileExistsAtPath:[GUtilities tracksDatabasePath]])
            NSLog(@"db exists");
        else if ([self createInitialDatabase])
            return self;
    }
    
    return nil;
}

- (BOOL) createInitialDatabase
{
	int err;
/*
    err = sqlite3_open_v2([[GUtilities tracksDatabasePath]
        cStringUsingEncoding:NSUTF8StringEncoding],
	        &databaseConnection,
			SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE,
			NULL);

    if (err != SQLITE_OK)
        return NO;
	
	return YES;
*/
}

@end
