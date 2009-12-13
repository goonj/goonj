/*
	File: GM3UPlaylist.m
	Description: M3U playlist support for Goonj (implementation).

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

#import "GM3UPlaylist.h"


@implementation GM3UPlaylist

- (id) initWithFile:(NSString *)aURL
{
    if (self = [super init])
    {
        trackList = [[NSMutableArray alloc] initWithCapacity:0];
        aURL = [aURL stringByExpandingTildeInPath];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:aURL] == YES)
            [self loadPlaylist:aURL];
        
        return self;
    }
    return nil;
}

- (void) addTrack:(GTrack *)track
{
    [trackList addObject:track];
}

- (void) addTrack:(GTrack *)track atIndex:(NSUInteger)index
{
    [trackList insertObject:track atIndex:index];
}

- (void) removeTrackAtIndex:(NSUInteger)index
{
    [trackList removeObjectAtIndex:index];
}

- (void) clearPlaylist
{
    [trackList removeAllObjects];
}

- (NSUInteger) count
{
    return [trackList count];
}

- (GTrack *) trackAtIndex:(NSUInteger)index
{
    return [trackList objectAtIndex:index];
}

- (BOOL) savePlaylistAs:(NSString *)aURL
{
    
    return NO;
}

- (BOOL) loadPlaylist:(NSString *)aURL
{
    NSError *err; NSStringEncoding encoding;
    GTrack *track;
    NSArray *lines = [[NSString stringWithContentsOfFile:aURL usedEncoding:&encoding error:&err] componentsSeparatedByString:@"\n"];

    for (NSString *tmp in lines) {
        if (!([tmp characterAtIndex:0] == '#')) {
            track = [[GTrack alloc] initWithFile:tmp];
            [self addTrack:track];
        }
    }
    return YES;
}

@end
