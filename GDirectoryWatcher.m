/*
    File: GDirectoryWatcher.m
    Description: Watches directories for changes. Implementation.

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

#import "GDirectoryWatcher.h"


void FSEventCallback(
    ConstFSEventStreamRef streamRef,
    void *clientCallbackInfo,
    size_t numEvents,
    void *eventPaths,
    const FSEventStreamEventFlags eventFlags[],
    const FSEventStreamEventId eventIds[])
{
    int i;
    char **paths = eventPaths;
    NSMutableArray *directoriesToScan = [[NSMutableArray alloc]
        initWithCapacity:numEvents];
    
    for(i = 0 ; i < numEvents ; i++) {
        NSLog(@"Changed: %s (event ID: %d)", paths[i], eventIds[i]);
        [directoriesToScan addObject:[NSString stringWithCString:paths[i]
                                                   encoding:NSUTF8StringEncoding]];
    }

    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"GoonjWatchDirectoriesChangedNotification"
                      object:directoriesToScan];
}

@implementation GDirectoryWatcher

- (id) initWithDirectories:(NSArray *)theDirectories
{
    if (self = [super init]) {
        watchedDirectories = theDirectories;
        // TODO: save the last fsevent ID to the plist.
        eventStream = FSEventStreamCreate(NULL, &FSEventCallback, NULL,
            (CFArrayRef)watchedDirectories, kFSEventStreamEventIdSinceNow,
            1, kFSEventStreamCreateFlagNone);

        return self;
    }
    return nil;
}

- (void) startWatching
{
    FSEventStreamScheduleWithRunLoop(eventStream,
        [[NSRunLoop currentRunLoop] getCFRunLoop],
        kCFRunLoopCommonModes);
    FSEventStreamStart(eventStream);
    [[NSRunLoop currentRunLoop] run];
}

@end
