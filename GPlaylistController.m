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

@synthesize playlistDirty;

- (void) awakeFromNib
{
	playlist = [[NSMutableArray alloc] initWithCapacity:0];
	playlistDirty = NO;
    [playlistView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
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

- (BOOL) savePlaylist:(NSURL *)url
{
	// Set up the namespace.
	NSXMLNode *XSPFNamespace = [[NSXMLNode alloc] initWithKind:NSXMLNamespaceKind];
	[XSPFNamespace setName:@""];
	[XSPFNamespace setStringValue:@"http://xspf.org/ns/0/"];

	// Why do I have to create a separate NSXMLNode for every single
	// attribute? Meh.
	NSXMLNode *XSPFVersion = [[NSXMLNode alloc] initWithKind:NSXMLAttributeKind];
	[XSPFVersion setName:@"version"];
	[XSPFVersion setStringValue:@"1.0"];
	
	// Create root element.
	NSXMLElement *XSPFRoot = [[NSXMLElement alloc] initWithName:@"playlist"];
	[XSPFRoot addNamespace:XSPFNamespace];
	[XSPFRoot addAttribute:XSPFVersion];
	
	// Create the actual document.
	NSXMLDocument *XSPFDoc = [[NSXMLDocument alloc] initWithRootElement:XSPFRoot];
	[XSPFDoc setVersion:@"1.0"];
	[XSPFDoc setCharacterEncoding:@"UTF-8"];
	
	NSXMLElement *XSPFTrackList = [[NSXMLElement alloc] initWithName:@"trackList"];
	[XSPFRoot addChild:XSPFTrackList];

	NSXMLElement *XSPFTrack;
	NSXMLElement *XSPFLocation;

	// It might be a good idea to check if the playlist is being saved in the
	// same directory as the music files. If yes, then we can use relative
	// paths instead of absolute paths.
	for (GTrack *track in playlist) {
		XSPFTrack = [[NSXMLElement alloc] initWithName:@"track"];
		[XSPFTrackList addChild:XSPFTrack];

		XSPFLocation = [[NSXMLElement alloc] initWithName:@"location"];
		[XSPFLocation setStringValue:[track path]];
		[XSPFTrack addChild:XSPFLocation];
	}

	// Write data to file.
	NSData *XMLData = [XSPFDoc XMLDataWithOptions:NSXMLNodePrettyPrint];
	if ([XMLData writeToFile:[url absoluteString] atomically:NO]) {
		[mainWindow setDocumentEdited:NO];
		return YES;
	}

	return NO;
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

- (NSDragOperation) tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info 
                  proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    NSLog(@"In validateDrop now");
    return NSDragOperationEvery;
}

- (BOOL) tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row 
     dropOperation:(NSTableViewDropOperation)dropOperation
{
    NSLog(@"In acceptDrop now");
    return YES;
}

@end
