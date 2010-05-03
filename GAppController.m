/*
    File: GAppController.m
    Description: The Goonj application delegate (implementation).

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

#import "GAppController.h"
#import "GUtilities.h"


@implementation GAppController

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[mainWindowController initWithWindowNibName:@"MainWindow" owner:mainWindowController];
	[[mainWindowController window] setExcludedFromWindowsMenu:YES];
    [mainWindowController setShouldCascadeWindows:NO];
    [mainWindowController window];

    // Create Application Support folder if it doesn't exist.
    NSString *location = [GUtilities applicationSupportPath];
    BOOL isDir = [[NSFileManager defaultManager] fileExistsAtPath:location
                                                      isDirectory:&isDir];
    if (!isDir)
        [[NSFileManager defaultManager] createDirectoryAtPath:location
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:NO];

    directoryWatcher = [[GDirectoryWatcher alloc] initWithDefaultWatchDirectories];
    if (directoryWatcher)
		[NSThread detachNewThreadSelector:@selector(startWatching)
								 toTarget:directoryWatcher
							   withObject:nil];

	libraryManager = [[GLibraryManager alloc] initWithDefaultDatabase];
	[NSThread detachNewThreadSelector:@selector(startManager)
							 toTarget:libraryManager
						   withObject:nil];
}

- (void) applicationWillTerminate:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"GoonjWillTerminateNotification"
                  object:nil];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction) showPreferencesWindow:(id)sender
{
    [prefController initWithWindowNibName:@"Preferences"];
    [NSApp activateIgnoringOtherApps:YES];
    [[prefController window] makeKeyAndOrderFront:self];
}

- (IBAction) showMetadataEditor:(id)sender
{
    [metadataController initWithWindowNibName:@"MetaEditor" owner:metadataController];
    [[metadataController window] makeKeyAndOrderFront:self];
}

@end
