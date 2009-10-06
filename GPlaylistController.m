/*
	File: GPlaylistController.m
	Description: The Goonj playlist controller. Data source and delegate for
	the NSTableView in MainWindow.xib (implementation).

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

	Copyright 2009 Ankur Sethi.
*/

#import "GPlaylistController.h"
#import "GTrack.h"


@implementation GPlaylistController

- (void) awakeFromNib
{
	playlist = [[NSMutableArray alloc] initWithCapacity:0];
	playlistPath = [[NSString alloc] init];
	playlistDirty = NO;
}

- (void) addTrack:(GTrack *)track
{
	[playlist addObject:track];
	playlistDirty = YES;
	[mainWindow setDocumentEdited:YES];
	[playlistView reloadData];
}

- (void) newPlaylist
{
	[playlist removeAllObjects];
	playlistDirty = NO;
	[mainWindow setDocumentEdited:NO];
	[playlistView reloadData];
}

- (void) savePlaylist:(NSURL *)url
{
	NSLog(@"save playlist");
}

- (void) loadPlaylist:(NSURL *)url
{
	NSLog(@"load playlist");
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
	return [playlist count];
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	GTrack *track = [playlist objectAtIndex:row];
	NSString *identifier = [column identifier];
	NSString *objectValue = [track valueForKey:identifier];
	
	return objectValue ? objectValue : @"Unknown";
}

@end
