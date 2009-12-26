/*
	File: GMainWindowController.h
	Description: The Goonj main window controller. For now, this controller 
	manages most interface elements. Some functionality should be moved out
	later. File's Owner and delegate of MainWindow.xib (interface).

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
#import "GPlaylistViewController.h"


@interface GMainWindowController : NSWindowController {
	IBOutlet NSTableView *playlistView;
	IBOutlet GPlaylistViewController *playlistViewController;
    IBOutlet NSView *saveFileFormat;
}

- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem;

// Actions.
- (IBAction) newPlaylist:(id)sender;
- (IBAction) loadPlaylist:(id)sender;
- (IBAction) savePlaylist:(id)sender;
- (IBAction) addTracksToPlaylist:(id)sender;
- (IBAction) removeSelectedTracksFromPlaylist:(id)sender;
- (IBAction) toggleWindow:(id)sender;

@end
