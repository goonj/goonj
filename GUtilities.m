/*
	File: Utilities.m
	Description: Some utility functions in C that don't fit into any class
	(implementation).
 
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

@end