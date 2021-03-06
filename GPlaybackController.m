/*
    File: GPlaybackController.m
    Description: The Goonj playback controller (implementation).

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
    Copyright 2010 Nandeep Mali.
*/

#import "GPlaybackController.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation GPlaybackController

- (IBAction) playButtonWasClicked:(id)sender
{
    NSLog(@"Play was clicked.");
    NSLog(@"%@", [playlistViewController selectedPlaylistLocation]);
}

- (IBAction) nextButtonWasClicked:(id)sender
{
}

- (IBAction) previousButtonWasClicked:(id)sender
{
}

@end
