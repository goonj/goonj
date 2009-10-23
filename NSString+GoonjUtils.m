//
//  NSString+Utilities.m
//  Goonj
//
//  Created by Ankur Sethi on 23/10/09.
//  Copyright 2009 The Goonj Project. All rights reserved.
//

#import "NSString+GoonjUtils.h"


@implementation NSString (GoonjUtils)

- (BOOL) isHidden
{
    // Use launch services to determine whether file is invisible.
    NSURL *aURL = [NSURL fileURLWithPath:self];
    LSItemInfoRecord infoRecord;
    OSStatus error = noErr;

    error = LSCopyItemInfoForURL((CFURLRef)aURL, kLSRequestBasicFlagsOnly, &infoRecord);
    if (!error && ((infoRecord.flags & kLSItemInfoIsInvisible) || [[self lastPathComponent] hasPrefix:@"."]))
        return YES;

    return NO;
}

@end
