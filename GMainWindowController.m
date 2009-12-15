/*
	File: GMainWindowController.m
	Description: The Goonj main window controller. For now, this controller 
	manages most interface elements. Some functionality should be moved out
	later. File's Owner and delegate of MainWindow.nib (interface).

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

#import "GMainWindowController.h"


@implementation GMainWindowController

- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	if ([anItem action] == @selector(closeWindow:))
		if ([[self window] isVisible] == YES)
			return YES;
		else
			return NO;
	
	// Return YES by default.
	return YES;
}

- (IBAction) newPlaylist:(id)sender
{
	[playlistController clearPlaylist];
}

- (IBAction) loadPlaylist:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
   [openPanel setCanChooseDirectories:NO];
   [openPanel setAllowsMultipleSelection:NO];
   [openPanel runModal];

   NSString *URL = [[[openPanel URLs] objectAtIndex:0] path];
   [playlistController loadPlaylist:URL];
}

- (IBAction) savePlaylist:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setTitle:@"Save Playlist"];
    [savePanel setAllowedFileTypes:[NSArray arrayWithObjects:@"m3u", @"xspf", nil]];
    [savePanel runModal];
    [playlistController savePlaylist:[[savePanel URL] path]];
}

- (IBAction) toggleWindow:(id)sender
{
	if ([[self window] isVisible] == NO)
		[[self window] makeKeyAndOrderFront:self];
	else
		[[self window] close];
}

@end
