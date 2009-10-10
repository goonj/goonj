/*
	File: GPlaylistController.h
	Description: The Goonj playlist controller. Data source and delegate for
	the NSTableView in MainWindow.xib (interface).

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

#import <Cocoa/Cocoa.h>
#import "GTrack.h"


@interface GPlaylistController : NSObject {
	// playlist is an array of GTrack instances.
	NSMutableArray *playlist;
	BOOL playlistDirty;
	
	IBOutlet NSWindow *mainWindow;
	IBOutlet NSTableView *playlistView;
}

- (void) addTrack:(GTrack *)track;
- (void) newPlaylist;
- (BOOL) savePlaylist:(NSURL *)url;
- (BOOL) loadPlaylist:(NSURL *)url;

// NSTableView delegate methods.
- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView;
- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row;
- (void) tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;

@property (readonly) BOOL playlistDirty;

@end
