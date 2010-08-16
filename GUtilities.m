/*
    File: GUtilities.m
    Description: Some utility class methods. (implementation).

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

#import "GUtilities.h"

@implementation GUtilities

// Use launch services to determine whether file is invisible.
+ (BOOL) isHidden:(NSString *)aPath
{
    NSURL *aURL = [NSURL fileURLWithPath:aPath];
    LSItemInfoRecord infoRecord;
    OSStatus error = noErr;

    error = LSCopyItemInfoForURL((CFURLRef)aURL, kLSRequestBasicFlagsOnly, &infoRecord);
    if (!error && ((infoRecord.flags & kLSItemInfoIsInvisible) || [[aPath lastPathComponent] hasPrefix:@"."]))
        return YES;

	return NO;
}

+ (id) initPlaylistWithFile:(NSString *)aURL
{
	NSString *ext = [aURL pathExtension];

	if ([ext caseInsensitiveCompare:@"xspf"] == NSOrderedSame)
		return [[GXSPFPlaylist alloc] initWithFile:aURL];
	else if ([ext caseInsensitiveCompare:@"m3u"] == NSOrderedSame)
		return [[GM3UPlaylist alloc] initWithFile:aURL];

	return nil;
}

+ (NSString *) applicationSupportPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
        NSUserDomainMask, NO);
    NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Goonj"];
	path = [path stringByExpandingTildeInPath];
	return path;
}

+ (NSString *) nowPlayingPath
{
    return [[self applicationSupportPath] stringByAppendingPathComponent:@"Now Playing.m3u"];
}

+ (NSString *) tracksDatabasePath
{
    return [[self applicationSupportPath] stringByAppendingPathComponent:@"tracks.db"];
}

+ (NSArray *) supportedFormats
{
    return [NSArray arrayWithObjects:
            @"mp3",
            @"aac", 
            nil];
}

@end
