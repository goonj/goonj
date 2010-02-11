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
            [self loadCollection:aURL];

        return self;
    }

	return nil;
}

- (id) initWithTrackList:(NSArray *)aTrackList
{
	if (self = [super init])
	{
		trackList = [[NSMutableArray alloc] initWithArray:aTrackList];
		return self;
	}

	return nil;
}

- (void) addTrack:(GTrack *)track
{
    if (track)
        [trackList addObject:track];
}

- (void) addTrack:(GTrack *)track atIndex:(NSUInteger)index
{
    if (track)
        [trackList insertObject:track atIndex:index];
}

- (void) removeTrack:(GTrack *)track
{
    [trackList removeObject:track];
}

- (void) removeTrackAtIndex:(NSUInteger)index
{
    [trackList removeObjectAtIndex:index];
}

- (void) removeTracksAtIndexes:(NSIndexSet *)indexes
{
	[trackList removeObjectsAtIndexes:indexes];
}

- (void) moveTrackFromIndex:(NSUInteger)initIndex toIndex:(NSUInteger)endIndex
{
    id something = [trackList objectAtIndex:initIndex];
    [trackList removeObjectAtIndex:initIndex];
    [trackList insertObject:something atIndex:endIndex];
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

- (BOOL) saveCollectionAs:(NSString *)aURL
{
    aURL = [aURL stringByExpandingTildeInPath];
    NSError *err;
    NSString *write = [NSString string];

    for (GTrack *track in trackList)
    {
        NSString *current = [track valueForKey:@"location"];
        write = [write stringByAppendingString:current];
        write = [write stringByAppendingString:@"\n"];
    }

    // Atomic writes are safer.
    [write writeToFile:aURL atomically:YES encoding:4 error:&err];
    return YES;
}

- (BOOL) loadCollection:(NSString *)aURL
{
    NSError *err; NSStringEncoding encoding;
    GTrack *track;
    NSArray *lines = [[NSString stringWithContentsOfFile:aURL usedEncoding:&encoding error:&err] componentsSeparatedByString:@"\n"];
    for (NSString *temp in lines)
    {
        temp = [temp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        // Currently, we are ignoring any lines with comments.
        // TODO write the extm3u parser.
        if (([temp length] > 0) && [temp characterAtIndex:0] != '#') {
            track = [[GTrack alloc] initWithFile:temp];
            [self addTrack:track];
        }
    }
    return YES;
}

- (BOOL) isLocalCollection
{
    return YES;
}

+ (id < GOrderedMutableCollection >) loadNowPlaying
{
    id < GOrderedMutableCollection > listArray = [[GM3UPlaylist alloc] initWithFile:[GUtilities nowPlayingPath]];
    return listArray;
}

@end
