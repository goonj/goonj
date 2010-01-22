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

    Copyright 2009 Pratul Kalia.
    Copyright 2009 Ankur Sethi.
*/

#import "GPlaylistViewController.h"


@implementation GPlaylistViewController

- (void) awakeFromNib
{
    // Set up the context menu for the table headers.
    NSArray *columnStore = [[NSUserDefaults standardUserDefaults] arrayForKey:@"ColumnsUserDefault"];
    NSMenu *tableHeaderContextMenu = [[NSMenu alloc] initWithTitle:@""];
    [[playlistView headerView] setMenu:tableHeaderContextMenu];

    NSArray *tableColumns = [NSArray arrayWithArray:[playlistView tableColumns]];
    for (NSTableColumn *column in tableColumns)
    {
        NSString *title = [[column headerCell] title];
        NSMenuItem *item = [tableHeaderContextMenu addItemWithTitle:title
                                                             action:@selector(contextMenuSelected:)
                                                      keyEquivalent:@""];
        [item setTarget:self];
        [item setRepresentedObject:column];
        [item setState:columnStore ? NSOffState : NSOnState];
        if (columnStore) [playlistView removeTableColumn:column];
    }

    NSTableColumn *column;
	for (NSDictionary *colinfo in columnStore)
    {
        NSMenuItem *item = [tableHeaderContextMenu itemWithTitle:[colinfo objectForKey:@"title"]];
        if (!item) continue;
        [item setState:NSOnState];
        column = [item representedObject];
        [column setWidth:[[colinfo objectForKey:@"width"] floatValue]];
        [playlistView addTableColumn:column];
    }

    // Setup notification observers.
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self
                      selector:@selector(saveTableColumns)
                          name:NSTableViewColumnDidMoveNotification
                        object:playlistView];

    [defaultCenter addObserver:self
                      selector:@selector(saveTableColumns)
                          name:NSTableViewColumnDidResizeNotification
                        object:playlistView];

    [defaultCenter addObserver:self
                      selector:@selector(performFinalCleanup)
                          name:@"GoonjWillTerminateNotification"
                        object:nil];

    // Load Now Playing list.
    playlist = [GM3UPlaylist loadNowPlaying];
	[playlistView reloadData];
    [playlistView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, @"internalTableRows", nil]];
}

- (void) contextMenuSelected:(id)sender
{
    BOOL on = ([sender state] == NSOnState);
    [sender setState:on ? NSOffState : NSOnState];
    NSTableColumn *column = [sender representedObject];

    if (on)
    {
        [playlistView removeTableColumn:column];
        [playlistView sizeLastColumnToFit];
    } else {
        [playlistView addTableColumn:column];
        [playlistView sizeToFit];
    }

    [playlistView setNeedsDisplay:YES];
}

- (void) saveTableColumns
{
    NSMutableArray *cols = [NSMutableArray array];
    for (NSTableColumn *column in [playlistView tableColumns])
    {
        [cols addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                         [[column headerCell] title], @"title",
                         [NSNumber numberWithFloat:[column width]], @"width",
                         nil]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:cols forKey:@"ColumnsUserDefault"];
}

- (void) addTrack:(GTrack *)aTrack
{
    [playlist addTrack:aTrack];
    [mainWindow setDocumentEdited:YES];
    [playlistView reloadData];
}

- (void) addTracksFromDirectory:(NSString *)aDirectory
{
	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager]
		enumeratorAtPath:aDirectory];

	NSString *fileName, *filePath;
	GTrack *track;
	BOOL isDirectory;
	while (fileName = [dirEnum nextObject]) {
		filePath = [aDirectory stringByAppendingPathComponent:fileName];

        if ([GUtilities isHidden:filePath])
            continue;

        [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];

		if (isDirectory == YES)
			[self addTracksFromDirectory:filePath];
		else {
			track = [[GTrack alloc] initWithFile:filePath];
			[playlist addTrack:track];
		}
	}
}

- (void) removeSelectedTracks
{
	NSIndexSet *selectedTracks = [playlistView selectedRowIndexes];
	[playlist removeTracksAtIndexes:selectedTracks];
	[playlistView reloadData];
}

- (void) clearPlaylist
{
	[playlist clearPlaylist];
	[mainWindow setDocumentEdited:NO];
	[playlistView reloadData];
}

- (BOOL) savePlaylist:(NSString *)aURL
{
    return [playlist saveCollectionAs:aURL];
}

- (BOOL) loadPlaylist:(NSString *)aURL
{
    // No need to clear the playlist before loading it, since
    // the GPlaylist will clear itself on successful load.
    [playlist loadCollection:aURL];
    [playlistView reloadData];
    return YES;
}

- (void) performFinalCleanup
{
    [self savePlaylist:[GUtilities nowPlayingPath]];
    [self saveTableColumns];
}

////
#pragma mark NSTableView delegate and data source methods
////

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
	return [playlist count];
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column
                                                                row:(NSInteger)row
{
	GTrack *track = [playlist trackAtIndex:row];
	NSString *identifier = [column identifier];
	NSString *objectValue = [track valueForKey:identifier];

	return objectValue ? objectValue : @"Unknown";
}

- (void) tableView:(NSTableView *)tableView setObjectValue:(id)object
                                            forTableColumn:(NSTableColumn *)tableColumn
                                                       row:(NSInteger)row
{
    GTrack *track;
    track = [playlist trackAtIndex:row];
    [track setValue:object forKey:[tableColumn identifier]];
}

- (BOOL) tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)column
                                                              row:(NSInteger)row
{
    if ([@"location" isEqualTo:[column identifier]]
        || [@"time" isEqualTo:[column identifier]])
        return NO;

    return YES;
}

////
#pragma mark Drag and drop operations
////

- (BOOL) tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes
                                                    toPasteboard:(NSPasteboard *)pboard
{
    // Copy the row numbers to the pasteboard.
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:@"internalTableRows"] owner:self];
    [pboard setData:data forType:@"internalTableRows"];
    return YES;
}

- (NSDragOperation) tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info
                                                        proposedRow:(NSInteger)row
                                              proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    if ([info draggingSource] == tableView)
    {
        return NSDragOperationMove;
    } else {
        return NSDragOperationCopy;
    }
}

- (BOOL) tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info
                                                   row:(NSInteger)row
                                         dropOperation:(NSTableViewDropOperation)dropOperation
{
    NSPasteboard *pboard = [info draggingPasteboard];
    NSArray *files;

    if ([pboard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]])
    {
        files = [pboard propertyListForType:NSFilenamesPboardType];

        GTrack *draggedTrack;
        BOOL isDirectory;
        for (NSString *currentFile in files)
        {
            [[NSFileManager defaultManager] fileExistsAtPath:currentFile
                                                 isDirectory:&isDirectory];

            if (isDirectory == NO)
            {
                draggedTrack = [[GTrack alloc] initWithFile:currentFile];
                [playlist addTrack:draggedTrack atIndex:row];
            } else
                [self addTracksFromDirectory:currentFile];
        }
    } else if ([pboard availableTypeFromArray:[NSArray arrayWithObject:@"internalTableRows"]])
    {
        NSData *rowdata = [pboard dataForType:@"internalTableRows"];
        NSIndexSet *rowindexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowdata];
        NSUInteger onerow;
        for (onerow = [rowindexes firstIndex]; onerow <= [rowindexes lastIndex];
            onerow = [rowindexes indexGreaterThanIndex:onerow])
        {
            if (row >= [playlist count]) {
                // Allow people to drop beyond the range of the playlist and shift
                // track to the last position.
                [playlist moveTrackFromIndex:onerow toIndex:row - 1];
            } else {
                [playlist moveTrackFromIndex:onerow toIndex:row];
            }
        }
    }

    [playlistView reloadData];
    return YES;
}

@end
