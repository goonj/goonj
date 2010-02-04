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

- (void) awakeFromNib
{
    // For some reason, this awakeFromNib is called twice, thus generating two
    // status menus if we don't check for its existence.
    if (!mItem) {
        mItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
        [mItem setImage:[NSImage imageNamed:@"GStatusBar"]];
        [mItem setAlternateImage:[NSImage imageNamed:@"GStatusBarAlternate"]];
        [mItem setHighlightMode:YES];
        [mItem setMenu:statusBarMenu];
    }

    lastFormatSelected = [[NSString alloc] init];

    NSNotificationCenter *defCenter = [NSNotificationCenter defaultCenter];
    [defCenter addObserver:self
                  selector:@selector(menuItemWasClicked:)
                      name:NSMenuDidSendActionNotification
                    object:fileFormatSelector];
}

- (IBAction) newPlaylist:(id)sender
{
	[playlistViewController clearPlaylist];
}

- (IBAction) loadPlaylist:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel beginSheetForDirectory:nil file:nil
                                types:[NSArray arrayWithObjects:@"m3u", @"xspf", nil]
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                          contextInfo:nil];
}

- (void) openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton)
	{
        NSString *URL = [[[panel URLs] objectAtIndex:0] path];
        [playlistViewController loadPlaylist:URL];
	}
}

- (IBAction) savePlaylist:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setTitle:@"Save Playlist"];
    [savePanel setNameFieldStringValue:@"My Playlist"];
    [savePanel setAllowedFileTypes:[NSArray arrayWithObjects:@"m3u", @"xspf", nil]];
    [savePanel setAllowsOtherFileTypes:NO];
    [savePanel setExtensionHidden:TRUE];
    [savePanel setAccessoryView:saveFileFormat];

    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger returnCode) {
        if (returnCode == NSOKButton) {
            [self saveAppropriatePlaylist:[[savePanel URL] path]];
        }
    }];
}

- (void) saveAppropriatePlaylist:(NSString *)path
{
    [playlistViewController savePlaylist:path];
}

- (void) menuItemWasClicked:(NSNotification *)notification
{
    NSMenu *clicked = [[notification userInfo] objectForKey:@"MenuItem"];

  	if ([[clicked title] caseInsensitiveCompare:@"M3U"] == NSOrderedSame)
        lastFormatSelected = [clicked title];
  	if ([[clicked title] caseInsensitiveCompare:@"XSPF"] == NSOrderedSame)
        lastFormatSelected = [clicked title];
}

- (IBAction) addTracksToPlaylist:(id)sender
{
	// Add track.
}

- (IBAction) removeSelectedTracksFromPlaylist:(id)sender
{
	[playlistViewController removeSelectedTracks];
}

- (IBAction) toggleWindow:(id)sender
{
	if ([[self window] isVisible] == NO)
		[[self window] makeKeyAndOrderFront:self];
	else
		[[self window] close];
}

@end
