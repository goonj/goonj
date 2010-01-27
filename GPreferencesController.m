/*
    File: GPreferenceController.m
    Description: The Goonj preferences window delegate (implementation).

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

#import "GPreferencesController.h"


@implementation GPreferencesController

- (void) awakeFromNib
{
    locations = [[NSMutableArray alloc]
                 initWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"LibraryFolderLocations"]];
}

- (IBAction) addLibraryLocation:(id)sender
{
    NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setCanChooseDirectories:YES];
    [op setCanChooseFiles:NO];
    [op setAllowsMultipleSelection:NO];
    [op beginSheetForDirectory:nil file:nil
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
}

- (void) openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton)
	{
        NSString *selectedURL = [[panel URL] path];
        selectedURL = [selectedURL stringByAbbreviatingWithTildeInPath];
        [locations addObject:selectedURL];
        [[NSUserDefaults standardUserDefaults] setObject:locations forKey:@"LibraryFolderLocations"];
        [libraryLocations reloadData];
	}
}

- (IBAction) removeLibraryLocations:(id)sender
{
    NSInteger row = [libraryLocations selectedRow];
    if (row >= 0) {
        [locations removeObjectAtIndex:row];
        [[NSUserDefaults standardUserDefaults] setObject:locations forKey:@"LibraryFolderLocations"];
        [libraryLocations reloadData];
    }
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
    return [locations count];
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn
                                                                row:(NSInteger)row
{
    return [locations objectAtIndex:row];
}

@end
