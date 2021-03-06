/*
    File: GDirectoryWatcher.h
    Description: Watches directories for changes. Interface.

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

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>

void FSEventCallback(
    ConstFSEventStreamRef streamRef,
    void *clientCallbackInfo,
    size_t numEvents,
    void *eventPaths,
    const FSEventStreamEventFlags eventFlags[],
    const FSEventStreamEventId eventIds[]);

@interface GDirectoryWatcher : NSObject {
    NSMutableArray *watchedDirectories;
    FSEventStreamRef eventStream;
}

- (id) initWithDirectories:(NSArray *)theDirectories;
- (id) initWithDefaultWatchDirectories;
- (void) startWatching;

@end
