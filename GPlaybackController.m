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

#include <AudioToolbox/AudioToolbox.h>
#include "CAXException.h"
#include "CAStreamBasicDescription.h"
#include "CAAudioUnit.h"


@implementation GPlaybackController

AudioFileID audioFile;
AUGraph theGraph;
CAAudioUnit fileAU;
CAStreamBasicDescription fileFormat;
Float64 fileDuration;
UInt64 nPackets;

char *nowPlayingFile;

void Play(char *fileURL);
void Seek(float seconds);
void NextTrack(char *fileURL);
void Stop(char *fileURL);

bool isPlaying = false;

void PrepareFileAU (SInt64 startFrame);

void MakeSimpleGraph ();

- (IBAction) playButtonWasClicked:(id)sender
{
    NSLog(@"Play was clicked.");
}

- (IBAction) nextButtonWasClicked:(id)sender
{
    NSLog(@"Next was clicked.");
}

- (IBAction) previousButtonWasClicked:(id)sender
{
    NSLog(@"Previous was clicked");
}

void Play(char *fileURL)
{
    CFURLRef theURL = CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault, 
                                                              (UInt8*)fileURL, 
                                                              strlen(fileURL), 
                                                              false);
    
	XThrowIfError (AudioFileOpenURL (theURL, 
                                     kAudioFileReadPermission, 
                                     0, 
                                     &audioFile), 
                   "AudioFileOpenURL");
        
    // get the number of channels of the file
	UInt32 propsize = sizeof(CAStreamBasicDescription);
	XThrowIfError (AudioFileGetProperty(audioFile, 
                                        kAudioFilePropertyDataFormat, 
                                        &propsize, 
                                        &fileFormat), 
                   "AudioFileGetProperty");
	
	printf ("playing file: %s\n", fileURL);
	printf ("format: "); fileFormat.Print();
 
    // this makes the graph, the file AU and sets it all up for playing
	MakeSimpleGraph ();
        
    // calculate the duration
	UInt32 packetSize = sizeof(nPackets);
	XThrowIfError (AudioFileGetProperty(audioFile, 
                                        kAudioFilePropertyAudioDataPacketCount, 
                                        &packetSize, 
                                        &nPackets), 
                   "kAudioFilePropertyAudioDataPacketCount");
    
    fileDuration = (nPackets * fileFormat.mFramesPerPacket) / fileFormat.mSampleRate;
    
    // now we load the file contents up for playback before we start playing
    // this has to be done the AU is initialized and anytime it is reset or 
    // uninitialized
    PrepareFileAU (0);
    
	printf ("file duration: %f secs\n", fileDuration);
    
    // start playing
	XThrowIfError (AUGraphStart (theGraph), "AUGraphStart");
}

void Stop(char *fileURL)
{
    // lets clean up
	XThrowIfError (AUGraphStop (theGraph), "AUGraphStop");
	XThrowIfError (AUGraphUninitialize (theGraph), "AUGraphUninitialize");
	XThrowIfError (AudioFileClose (audioFile), "AudioFileClose");
	XThrowIfError (AUGraphClose (theGraph), "AUGraphClose");
}

void Seek(float seconds)
{    
    SInt64 startFrame = seconds * fileFormat.mSampleRate;
        
    // now we load the file contents up for playback before we start playing
    // this has to be done the AU is initialized and anytime it is reset or uninitialized
    PrepareFileAU (startFrame);
}



// This prepares the scheduling of the file playback. Used for starting the
// playback and seeking as well
void PrepareFileAU (SInt64 startFrame)
{	
    // Reset the Audio Unit to make sure all previous schedules are cleared
    fileAU.Reset(kAudioUnitScope_Global, 0);
    
    // Set up the scheduled region
	ScheduledAudioFileRegion rgn;
	memset (&rgn.mTimeStamp, 0, sizeof(rgn.mTimeStamp));
	rgn.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
	rgn.mTimeStamp.mSampleTime = 0;
	rgn.mCompletionProc = NULL;
	rgn.mCompletionProcUserData = NULL;
	rgn.mAudioFile = audioFile;
	rgn.mLoopCount = 1;
	rgn.mStartFrame = startFrame;
	rgn.mFramesToPlay = UInt32((nPackets - startFrame) * fileFormat.mFramesPerPacket);
    
    // tell the file player AU to play the scheduled region
	XThrowIfError (fileAU.SetProperty (kAudioUnitProperty_ScheduledFileRegion, 
                                       kAudioUnitScope_Global, 
                                       0,
                                       &rgn, 
                                       sizeof(rgn)), 
                   "kAudioUnitProperty_ScheduledFileRegion");
	
    // prime the fp AU with default values
	UInt32 defaultVal = 0;
	XThrowIfError (fileAU.SetProperty (kAudioUnitProperty_ScheduledFilePrime, 
                                       kAudioUnitScope_Global, 
                                       0, 
                                       &defaultVal, 
                                       sizeof(defaultVal)), 
                   "kAudioUnitProperty_ScheduledFilePrime");
    
    // tell the fp AU when to start playing (this ts is in the AU's render time 
    // stamps; -1 means next render cycle)
	AudioTimeStamp startTime;
	memset (&startTime, 0, sizeof(startTime));
	startTime.mFlags = kAudioTimeStampSampleTimeValid;
	startTime.mSampleTime = -1;
	XThrowIfError (fileAU.SetProperty(kAudioUnitProperty_ScheduleStartTimeStamp, 
                                      kAudioUnitScope_Global, 
                                      0, 
                                      &startTime, 
                                      sizeof(startTime)), 
                   "kAudioUnitProperty_ScheduleStartTimeStamp");
}


/*
 Makes a very simple audio graph which connects the output of the file node to 
 the input of an Output Node that outputs the audio to the default audio device 
 that the user has selected in the System Preferences. This function also takes 
 care of audio channel layouts. Probably don't need to bother with that right 
 now. 
*/
void MakeSimpleGraph ()
{
    // Create a new graph
	XThrowIfError (NewAUGraph (&theGraph), "NewAUGraph");
	
	CAComponentDescription cd;
    
	// output node description
	cd.componentType = kAudioUnitType_Output;
	cd.componentSubType = kAudioUnitSubType_DefaultOutput;
	cd.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Add the Output node to the Graph
	AUNode outputNode;
	XThrowIfError (AUGraphAddNode (theGraph, &cd, &outputNode), 
                   "AUGraphAddNode");
	
	// file AU node description
	cd.componentType = kAudioUnitType_Generator;
	cd.componentSubType = kAudioUnitSubType_AudioFilePlayer;
	
    // Add the file node to the graph
	AUNode fileNode;
	XThrowIfError (AUGraphAddNode (theGraph, &cd, &fileNode), 
                   "AUGraphAddNode");
	
	// connect & setup
	XThrowIfError (AUGraphOpen (theGraph), "AUGraphOpen");
	
	// install overload listener to detect when something is wrong
	AudioUnit anAU;
	XThrowIfError (AUGraphNodeInfo(theGraph, fileNode, NULL, &anAU), 
                   "AUGraphNodeInfo");
	
	fileAU = CAAudioUnit (fileNode, anAU);
    
    // prepare the file AU for playback
    // set its output channels
	XThrowIfError (fileAU.SetNumberChannels (kAudioUnitScope_Output, 
                                             0, 
                                             fileFormat.NumberChannels()), 
                   "SetNumberChannels");
    
    // set the output sample rate of the file AU to be the same as the file:
	XThrowIfError (fileAU.SetSampleRate (kAudioUnitScope_Output, 
                                         0, 
                                         fileFormat.mSampleRate), 
                   "SetSampleRate");
    
    // load in the file 
	XThrowIfError (fileAU.SetProperty(kAudioUnitProperty_ScheduledFileIDs, 
                                      kAudioUnitScope_Global, 
                                      0, 
                                      &audioFile, 
                                      sizeof(audioFile)), 
                   "SetScheduleFile");
        
    // Connect the fileNode to outputNode
	XThrowIfError (AUGraphConnectNodeInput (theGraph, 
                                            fileNode, 
                                            0, 
                                            outputNode, 
                                            0), 
                   "AUGraphConnectNodeInput");
    
    // AT this point we make sure we have the file player AU initialized
    // this also propogates the output format of the AU to the output unit
	XThrowIfError (AUGraphInitialize (theGraph), "AUGraphInitialize");
	
	// workaround a race condition in the file player AU
	usleep (10 * 1000);
    
    // if we have a surround file, then we should try to tell the output AU what
    // the order of the channels will be
	if (fileFormat.NumberChannels() > 2) {
		UInt32 layoutSize = 0;
		OSStatus err;
        
        // Get the size of the layout
		XThrowIfError (err = AudioFileGetPropertyInfo (audioFile, 
                                                       kAudioFilePropertyChannelLayout, 
                                                       &layoutSize, 
                                                       NULL),
                       "kAudioFilePropertyChannelLayout");
		
        // If everything went well go further
		if (!err && layoutSize) {
			char* layout = new char[layoutSize];
			            
			err = AudioFileGetProperty(audioFile, 
                                       kAudioFilePropertyChannelLayout, 
                                       &layoutSize, 
                                       layout);
            
			XThrowIfError (err, "Get Layout From AudioFile");
			
			// ok, now get the output AU and set its layout
			XThrowIfError (AUGraphNodeInfo(theGraph, 
                                           outputNode, 
                                           NULL, 
                                           &anAU), 
                           "AUGraphNodeInfo");
        
            err = AudioUnitSetProperty (anAU, 
                                        kAudioUnitProperty_AudioChannelLayout, 
                                        kAudioUnitScope_Input, 
                                        0, 
                                        layout, 
                                        layoutSize);
            
			XThrowIfError (err, "kAudioUnitProperty_AudioChannelLayout");
			
			delete [] layout;
		}
	}
}

@end
