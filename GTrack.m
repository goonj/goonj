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
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Goonj. If not, see <http://www.gnu.org/licenses/>.

    Copyright 2009 Pratul Kalia.
    Copyright 2009 Ankur Sethi.
*/

#import "/usr/local/include/taglib/taglib.h"
#import "/usr/local/include/taglib/fileref.h"
#import "/usr/local/include/taglib/tag.h"
#import "GTrack.h"


@implementation GTrack

@dynamic path;

- (id) initWithFile:(NSString *)aUrl
{
	self = [super init];

	if (self) {
		properties = [GTrack metadataForFile:aUrl];
		return self;
	}

	return nil;
}

- (NSString *) valueForKey:(NSString *)aKey
{
	return [properties objectForKey:aKey];
}

- (void) setValue:(NSString *)value forKey:(NSString *)key
{
    [properties setValue:value forKey:key];
}

- (NSString *)path
{
    return [self valueForKey:@"location"];
}

+ (NSMutableDictionary *) metadataForFile:(NSString *)aUrl
{
	NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];
	TagLib::FileRef fileRef([aUrl cStringUsingEncoding:NSUTF8StringEncoding]);
	TagLib::Tag *tag = fileRef.tag();
	TagLib::AudioProperties *audioProperties = fileRef.audioProperties();
	
	[metadata setValue:aUrl forKey:@"location"];
	
	[metadata setValue:[NSString stringWithCString:tag->title().toCString(true)
									  encoding:NSUTF8StringEncoding]
			forKey:@"name"];
	
	[metadata setValue:[NSString stringWithCString:tag->artist().toCString(true)
									  encoding:NSUTF8StringEncoding]
			forKey:@"artist"];
	
	[metadata setValue:[NSString stringWithCString:tag->album().toCString(true)
									  encoding:NSUTF8StringEncoding]
			forKey:@"album"];
	
	[metadata setValue:[NSString stringWithCString:tag->genre().toCString(true)
									  encoding:NSUTF8StringEncoding]
			forKey:@"genre"];
	
	[metadata setValue:[NSString stringWithCString:tag->comment().toCString(true)
									  encoding:NSUTF8StringEncoding]
			forKey:@"comment"];
	
	int length = audioProperties->length(), minutes = 0, seconds = 0;
	
	while (length > 60) {
		minutes++;
		length -= 60;
	}
	
	seconds = length;
	[metadata setValue:[NSString stringWithFormat:@"%d:%02d", minutes, seconds]
				forKey:@"time"];
	
	return metadata;
}

@end
