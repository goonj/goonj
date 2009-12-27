/*	Copyright © 2007 Apple Inc. All Rights Reserved.
	
	Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
			Apple Inc. ("Apple") in consideration of your agreement to the
			following terms, and your use, installation, modification or
			redistribution of this Apple software constitutes acceptance of these
			terms.  If you do not agree with these terms, please do not use,
			install, modify or redistribute this Apple software.
			
			In consideration of your agreement to abide by the following terms, and
			subject to these terms, Apple grants you a personal, non-exclusive
			license, under Apple's copyrights in this original Apple software (the
			"Apple Software"), to use, reproduce, modify and redistribute the Apple
			Software, with or without modifications, in source and/or binary forms;
			provided that if you redistribute the Apple Software in its entirety and
			without modifications, you must retain this notice and the following
			text and disclaimers in all such redistributions of the Apple Software. 
			Neither the name, trademarks, service marks or logos of Apple Inc. 
			may be used to endorse or promote products derived from the Apple
			Software without specific prior written permission from Apple.  Except
			as expressly stated in this notice, no other rights or licenses, express
			or implied, are granted by Apple herein, including but not limited to
			any patent rights that may be infringed by your derivative works or by
			other works in which the Apple Software may be incorporated.
			
			The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
			MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
			THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
			FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
			OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
			
			IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
			OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
			SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
			INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
			MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
			AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
			STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
			POSSIBILITY OF SUCH DAMAGE.
*/
#include <AudioToolbox/AudioQueue.h>
#include <AudioToolbox/AudioFile.h>

// helpers
#include "CAXException.h"
#include "CAStreamBasicDescription.h"

static const int kNumberBuffers = 3;
static UInt32 gIsRunning = 0;


struct AQTestInfo {
	AudioFileID						mAudioFile;
	CAStreamBasicDescription		mDataFormat;
	AudioQueueRef					mQueue;
	AudioQueueBufferRef				mBuffers[kNumberBuffers];
	SInt64							mCurrentPacket;
	UInt32							mNumPacketsToRead;
	AudioStreamPacketDescription *	mPacketDescs;
	bool							mDone;
};

static void AQTestBufferCallback(void *					inUserData,
								AudioQueueRef			inAQ,
								AudioQueueBufferRef		inCompleteAQBuffer) 
{
	AQTestInfo * myInfo = (AQTestInfo *)inUserData;
	if (myInfo->mDone) return;
		
	UInt32 numBytes;
	UInt32 nPackets = myInfo->mNumPacketsToRead;

	XThrowIfError (AudioFileReadPackets(myInfo->mAudioFile, false, &numBytes, myInfo->mPacketDescs, myInfo->mCurrentPacket, &nPackets, 
								inCompleteAQBuffer->mAudioData), "AudioFileReadPackets failed");
		
	if (nPackets > 0) {
		inCompleteAQBuffer->mAudioDataByteSize = numBytes;		

		AudioQueueEnqueueBuffer(inAQ, inCompleteAQBuffer, (myInfo->mPacketDescs ? nPackets : 0), myInfo->mPacketDescs);
		
		myInfo->mCurrentPacket += nPackets;
	} else {
		XThrowIfError(AudioQueueStop(myInfo->mQueue, false), "AudioQueueStop(false) failed");
			// reading nPackets == 0 is our EOF condition
		myInfo->mDone = true;
	}
}

static void usage()
{
	fprintf(stderr,
			"Usage:\n"
			"%s [option...] audio_file\n\n"
			"Options: (may appear before or after arguments)\n"
			"  {-v | --volume} VOLUME\n"
			"    set the volume for playback of the file\n"
			"  {-h | --help}\n"
			"    print help\n"
			, "aqplay");
	exit(1);
}

void	MissingArgument()
{
	fprintf(stderr, "Missing argument\n");
	usage();
}

void	MyAudioQueuePropertyListenerProc (  void *              inUserData,
										AudioQueueRef           inAQ,
										AudioQueuePropertyID    inID)
{
	UInt32 size = sizeof(gIsRunning);
	XThrowIfError (AudioQueueGetProperty (inAQ, kAudioQueueProperty_IsRunning, &gIsRunning, &size), "is running");
}

	// we only use time here as a guideline
	// we're really trying to get somewhere between 16K and 64K buffers, but not allocate too much if we don't need it
void CalculateBytesForTime (CAStreamBasicDescription & inDesc, UInt32 inMaxPacketSize, Float64 inSeconds, UInt32 *outBufferSize, UInt32 *outNumPackets)
{
	static const int maxBufferSize = 0x10000; // limit size to 64K
	static const int minBufferSize = 0x4000; // limit size to 16K

	if (inDesc.mFramesPerPacket) {
		Float64 numPacketsForTime = inDesc.mSampleRate / inDesc.mFramesPerPacket * inSeconds;
		*outBufferSize = numPacketsForTime * inMaxPacketSize;
	} else {
		// if frames per packet is zero, then the codec has no predictable packet == time
		// so we can't tailor this (we don't know how many Packets represent a time period
		// we'll just return a default buffer size
		*outBufferSize = maxBufferSize > inMaxPacketSize ? maxBufferSize : inMaxPacketSize;
	}
	
		// we're going to limit our size to our default
	if (*outBufferSize > maxBufferSize && *outBufferSize > inMaxPacketSize)
		*outBufferSize = maxBufferSize;
	else {
		// also make sure we're not too small - we don't want to go the disk for too small chunks
		if (*outBufferSize < minBufferSize)
			*outBufferSize = minBufferSize;
	}
	*outNumPackets = *outBufferSize / inMaxPacketSize;
}


int main (int argc, const char * argv[]) 
{
	const char *fpath = NULL;
	Float32 volume = 1;
	
	for (int i = 1; i < argc; ++i) {
		const char *arg = argv[i];
		if (arg[0] != '-') {
			if (fpath != NULL) {
				fprintf(stderr, "may only specify one file to play\n");
				usage();
			}
			fpath = arg;
		} else {
			arg += 1;
			if (arg[0] == 'v' || !strcmp(arg, "-volume")) {
				if (++i == argc)
					MissingArgument();
				arg = argv[i];
				sscanf(arg, "%f", &volume);
			} else if (arg[0] == 'h' || !strcmp(arg, "-help")) {
				usage();
			} else {
				fprintf(stderr, "unknown argument: %s\n\n", arg - 1);
				usage();
			}
		}
	}

	if (fpath == NULL)
		usage();
	
	printf ("Playing file: %s\n", fpath);
	
	try {
		AQTestInfo myInfo;
		
		CFURLRef sndFile = CFURLCreateFromFileSystemRepresentation (NULL, (const UInt8 *)fpath, strlen(fpath), false);
		if (!sndFile) XThrowIfError (!sndFile, "can't parse file path");
			
		OSStatus result = AudioFileOpenURL (sndFile, 0x1/*fsRdPerm*/, 0/*inFileTypeHint*/, &myInfo.mAudioFile);
		CFRelease (sndFile);
						
		XThrowIfError(result, "AudioFileOpen failed");
			
		UInt32 size = sizeof(myInfo.mDataFormat);
		XThrowIfError(AudioFileGetProperty(myInfo.mAudioFile, 
									kAudioFilePropertyDataFormat, &size, &myInfo.mDataFormat), "couldn't get file's data format");
		
		printf ("File format: "); myInfo.mDataFormat.Print();

		XThrowIfError(AudioQueueNewOutput(&myInfo.mDataFormat, AQTestBufferCallback, &myInfo, 
									CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &myInfo.mQueue), "AudioQueueNew failed");

		UInt32 bufferByteSize;
		
		// we need to calculate how many packets we read at a time, and how big a buffer we need
		// we base this on the size of the packets in the file and an approximate duration for each buffer
		{
			bool isFormatVBR = (myInfo.mDataFormat.mBytesPerPacket == 0 || myInfo.mDataFormat.mFramesPerPacket == 0);
			
			// first check to see what the max size of a packet is - if it is bigger
			// than our allocation default size, that needs to become larger
			UInt32 maxPacketSize;
			size = sizeof(maxPacketSize);
			XThrowIfError(AudioFileGetProperty(myInfo.mAudioFile, 
									kAudioFilePropertyPacketSizeUpperBound, &size, &maxPacketSize), "couldn't get file's max packet size");
			
			// adjust buffer size to represent about a half second of audio based on this format
			CalculateBytesForTime (myInfo.mDataFormat, maxPacketSize, 0.5/*seconds*/, &bufferByteSize, &myInfo.mNumPacketsToRead);
			
			if (isFormatVBR)
				myInfo.mPacketDescs = new AudioStreamPacketDescription [myInfo.mNumPacketsToRead];
			else
				myInfo.mPacketDescs = NULL; // we don't provide packet descriptions for constant bit rate formats (like linear PCM)
				
			printf ("Buffer Byte Size: %d, Num Packets to Read: %d\n", (int)bufferByteSize, (int)myInfo.mNumPacketsToRead);
		}

		// (2) If the file has a cookie, we should get it and set it on the AQ
		size = sizeof(UInt32);
		result = AudioFileGetPropertyInfo (myInfo.mAudioFile, kAudioFilePropertyMagicCookieData, &size, NULL);

		if (!result && size) {
			char* cookie = new char [size];		
			XThrowIfError (AudioFileGetProperty (myInfo.mAudioFile, kAudioFilePropertyMagicCookieData, &size, cookie), "get cookie from file");
			XThrowIfError (AudioQueueSetProperty(myInfo.mQueue, kAudioQueueProperty_MagicCookie, cookie, size), "set cookie on queue");
			delete [] cookie;
		}

		// channel layout?
		OSStatus err = AudioFileGetPropertyInfo(myInfo.mAudioFile, kAudioFilePropertyChannelLayout, &size, NULL);
		if (err == noErr && size > 0) {
			AudioChannelLayout *acl = (AudioChannelLayout *)malloc(size);
			XThrowIfError(AudioFileGetProperty(myInfo.mAudioFile, kAudioFilePropertyChannelLayout, &size, acl), "get audio file's channel layout");
			XThrowIfError(AudioQueueSetProperty(myInfo.mQueue, kAudioQueueProperty_ChannelLayout, acl, size), "set channel layout on queue");
			free(acl);
		}

		// prime the queue with some data before starting
		myInfo.mDone = false;
		myInfo.mCurrentPacket = 0;
		for (int i = 0; i < kNumberBuffers; ++i) {
			XThrowIfError(AudioQueueAllocateBuffer(myInfo.mQueue, bufferByteSize, &myInfo.mBuffers[i]), "AudioQueueAllocateBuffer failed");

			AQTestBufferCallback (&myInfo, myInfo.mQueue, myInfo.mBuffers[i]);
			
			if (myInfo.mDone) break;
		}	
			// set the volume of the queue
		XThrowIfError (AudioQueueSetParameter(myInfo.mQueue, kAudioQueueParam_Volume, volume), "set queue volume");
		
		XThrowIfError (AudioQueueAddPropertyListener (myInfo.mQueue, kAudioQueueProperty_IsRunning, MyAudioQueuePropertyListenerProc, NULL), "add listener");
		
			// lets start playing now - stop is called in the AQTestBufferCallback when there's
			// no more to read from the file
		XThrowIfError(AudioQueueStart(myInfo.mQueue, NULL), "AudioQueueStart failed");

		do {
			CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.25, false);
		} while (!myInfo.mDone /*|| gIsRunning*/);
			
		CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, false);

		XThrowIfError(AudioQueueDispose(myInfo.mQueue, true), "AudioQueueDispose(true) failed");
		XThrowIfError(AudioFileClose(myInfo.mAudioFile), "AudioQueueDispose(false) failed");
		delete [] myInfo.mPacketDescs;
	}
	catch (CAXException e) {
		char buf[256];
		fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
	}
	
    return 0;
}
