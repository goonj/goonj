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

#import "GPlaylistController.h"
#import "GTrack.h"


@implementation GPlaylistController

- (void) awakeFromNib
{
    // Note that GPlaylist's initWithFile is a class method.
	playlist = [GPlaylist initWithFile:@"Test.xspf"];
    [playlistView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
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
		[[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];

		if (isDirectory == YES)
			[self addTracksFromDirectory:filePath];
		else {
			track = [[GTrack alloc] initWithFile:filePath];
			[playlist addTrack:track];
		}
	}
}

- (void) clearPlaylist
{
	[playlist clearPlaylist];
	[mainWindow setDocumentEdited:NO];
	[playlistView reloadData];
}

- (BOOL) savePlaylist:(NSString *)aURL
{
    return [playlist savePlaylistAs:aURL];
}

- (BOOL) loadPlaylist:(NSString *)aURL
{
	[self clearPlaylist];
    return YES;
}

////
#pragma mark NSTableView delegate methods
////

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
	return [playlist count];
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	GTrack *track = [playlist trackAtIndex:row];
	NSString *identifier = [column identifier];
	NSString *objectValue = [track valueForKey:identifier];

	return objectValue ? objectValue : @"Unknown";
}

- (void) tableView:(NSTableView *)tableView setObjectValue:(id)object
  forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    GTrack *track;
    track = [playlist trackAtIndex:row];
    [track setValue:object forKey:[tableColumn identifier]];
}

////
#pragma mark Drag and drop operations
////

- (NSDragOperation) tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info
                  proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    return NSDragOperationGeneric;
}

- (BOOL) tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row
     dropOperation:(NSTableViewDropOperation)dropOperation
{
    NSPasteboard *pboard = [info draggingPasteboard];
    NSArray *files;

    if ([[pboard types] containsObject:NSFilenamesPboardType])
        files = [pboard propertyListForType:NSFilenamesPboardType];

    GTrack *draggedTrack;
	BOOL isDirectory;
	for (NSString *currentFile in files) {
		[[NSFileManager defaultManager] fileExistsAtPath:currentFile isDirectory:&isDirectory];
        
		if (isDirectory == NO) {
			draggedTrack = [[GTrack alloc] initWithFile:currentFile];
        	[playlist addTrack:draggedTrack];
		} else
			[self addTracksFromDirectory:currentFile];
	}

    [playlistView reloadData];
    return YES;
}

@end
