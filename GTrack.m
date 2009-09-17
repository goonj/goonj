/*
	File: GTrack.m
	Description: A track in the Goonj library/playlist. Stores ID3 tags in
	a NSMutableDictionary. In the future, use initWithFile to read in the
	tags (implementation).

	This file is part of Goonj.

	Goonj is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	Goonj is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with Goonj.  If not, see <http://www.gnu.org/licenses/>.

	Copyright 2009 Ankur Sethi.
*/


#import "GTrack.h"


@implementation GTrack

-(id)init
{
	if (self = [super init]) {
		properties = [[NSMutableDictionary alloc] initWithCapacity:0];
	}

	return self;
}


-(NSString *)valueForKey:(NSString *)key
{
	return [properties objectForKey:key];
}


-(void)setValue:(NSString *)value forKey:(NSString *)key
{
	[properties setObject:value forKey:key];
}

@end
