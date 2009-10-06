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

	Copyright 2009 Ankur Sethi.
*/

#import "GMainWindowController.h"


@implementation GMainWindowController

- (void) setupUI
{
	[closeWindowMenuItem setTarget:self];
	[closeWindowMenuItem setAction:@selector(closeMainWindow)];

	[goonjWindowMenuItem setTarget:self];
	[goonjWindowMenuItem setAction:@selector(showMainWindow)];

	[mainWindow setExcludedFromWindowsMenu:YES];
	[mainWindow makeMainWindow];
	[mainWindow setReleasedWhenClosed:NO];

	[playlistView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
	
	[self showMainWindow];
}

- (void) windowWillClose:(NSNotification *)notification
{
	[goonjWindowMenuItem setState:NSOffState];
	[goonjWindowMenuItem setAction:@selector(showMainWindow)];
}

- (void) windowDidBecomeKey:(NSNotification *)notification
{
	[goonjWindowMenuItem setState:NSOnState];
	[goonjWindowMenuItem setAction:@selector(closeMainWindow)];
}

- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
	if (menuItem == closeWindowMenuItem)
		return [mainWindow isVisible] ? YES : NO ;

	return YES;
}

- (void) closeMainWindow
{
	[mainWindow performClose:self];
}

- (void) showMainWindow
{
	[mainWindow makeKeyAndOrderFront:self];
}

@end
