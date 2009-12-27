
#ifndef __DO_RenderSin__
#define __DO_RenderSin__

#ifdef __cplusplus
extern "C" {
#endif

#include <CoreServices/CoreServices.h>
#include <CoreAudio/CoreAudio.h>

extern void RenderSin (UInt32 		startingFrameCount, 
				UInt32 				inFrames, 
				void*				inBuffer, 
				double 				inSampleRate, 
				double 				amplitude, 
				double 				frequency,
				int					inOutputFormat);

extern int ParseArgsAndSetup (int argc, const char* argv[]);

enum {
	kAsFloat = 32,
	kAs16Bit = 16,
	kAs24Bit = 24
};


// THESE values can be read from your data source
// they're used to tell the DefaultOutputUnit what you're giving it
extern Float64			sSampleRate;
extern int				sNumChannels;

extern int				sWhichFormat;


extern UInt32			sSinWaveFrameCount; // this keeps track of the number of frames you render

extern double			sAmplitude;
extern double			sToneFrequency;

extern UInt32 theFormatID;

// these are set based on which format is chosen
extern UInt32 theFormatFlags;
extern UInt32 theBytesInAPacket;
extern UInt32 theBitsPerChannel;
extern UInt32 theBytesPerFrame;

// these are the same regardless of format
extern UInt32 theFramesPerPacket; // this shouldn't change


#ifdef __cplusplus
}
#endif

#endif /* __DO_RenderSin__ */

