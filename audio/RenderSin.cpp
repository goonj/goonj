#include "RenderSin.h"

// THESE values can be read from your data source
// they're used to tell the DefaultOutputUnit what you're giving it
Float64			sSampleRate = 48000;
int				sNumChannels = 2;

int				sWhichFormat = kAsFloat;


UInt32			sSinWaveFrameCount = 0; // this keeps track of the number of frames you render

double			sAmplitude = 0.25;
double			sToneFrequency = 440.;

UInt32 theFormatID = kAudioFormatLinearPCM;

// these are set based on which format is chosen
UInt32 theFormatFlags = 0;
UInt32 theBytesInAPacket = 0;
UInt32 theBitsPerChannel = 0;
UInt32 theBytesPerFrame = 0;

// these are the same regardless of format
UInt32 theFramesPerPacket = 1; // this shouldn't change




UInt32 sampleNextPrinted = 0;//print first time (UInt32)gSampleRate;

// REALLY should have a different version for each of the 3 bit depths...

// simulates reading the UInt data from the disk
// returns the adjusted frame count
void RenderSin (UInt32 				startingFrameCount, 
				UInt32 				inFrames, 
				void*				inBuffer, 
				double 				inSampleRate, 
				double 				amplitude, 
				double 				frequency,
				int					inOutputFormat) 
{
	double j = startingFrameCount;
	double cycleLength = inSampleRate / frequency;

	// mNumberBuffers is the same as the kNumChannels
	
	for (UInt32 frame = 0; frame < inFrames; ++frame) 
	{
		// generate inFrames 32-bit floats
		Float32 nextFloat = sin(j / cycleLength * (M_PI * 2.0)) * amplitude;

		switch (inOutputFormat) {
			case kAsFloat:
				static_cast<Float32*>(inBuffer)[frame] = nextFloat;
				break;
			case kAs16Bit:
				static_cast<SInt16*>(inBuffer)[frame] = static_cast<SInt16>(nextFloat * 32768. + 0.5);
				break;
			case kAs24Bit:
				static_cast<UInt32*>(inBuffer)[frame] = static_cast<UInt32>(nextFloat * 8388608. + 0.5);
				break;
		}
		
		j += 1.0;
		if (j > cycleLength)
			j -= cycleLength;
	}
			
	
	if (startingFrameCount >= sampleNextPrinted) {
		printf ("Current Slice: inFrames=%d, startingFrameCount=%d\n", (int)inFrames, (int)startingFrameCount);
		sampleNextPrinted += (int)inSampleRate;
	}
}



char* usageStr = "usage: [-d 16,24,32] where 32 is float, [-c numChannels], [-s sampleRate in Hz] [-a amplitude (0 - 1)], [-f freuency Hz]";

int ParseArgsAndSetup (int argc, const char* argv[])
{
	for (int i = 1; i < argc; ++i)
	{
		const char* str = argv[i];
		if (!strcmp ("-h", str)) {
			printf ("%s\n", usageStr);
			return -1;
		}
		else if (!strcmp ("-d", str)) {
			sscanf (argv[++i], "%d", &sWhichFormat);
		} 
		else if (!strcmp ("-c", str)) {
			sscanf (argv[++i], "%d", &sNumChannels);
		}
		else if (!strcmp ("-s", str)) {
			sscanf (argv[++i], "%lf", &sSampleRate);
		}
		else if (!strcmp ("-a", str)) {
			sscanf (argv[++i], "%lf", &sAmplitude);
		}
		else if (!strcmp ("-f", str)) {
			sscanf (argv[++i], "%lf", &sToneFrequency);
		} else {
			printf ("%s\n", usageStr);
			return -1;
		}
	}
	
	printf ("generating sin wave at %f Hz, %f amplitude\n", sToneFrequency, sAmplitude);

	switch (sWhichFormat) {
		case kAsFloat:
			theFormatFlags =  kAudioFormatFlagsNativeFloatPacked
								| kAudioFormatFlagIsNonInterleaved;
			theBytesPerFrame = theBytesInAPacket = 4;
			theBitsPerChannel = 32;
			break;
		
		case kAs16Bit:
			theFormatFlags =  kLinearPCMFormatFlagIsSignedInteger 
								| kAudioFormatFlagsNativeEndian
								| kLinearPCMFormatFlagIsPacked
								| kAudioFormatFlagIsNonInterleaved;
			theBytesPerFrame = theBytesInAPacket = 2;
			theBitsPerChannel = 16;		
			break;
			
		case kAs24Bit:
			theFormatFlags =  kLinearPCMFormatFlagIsSignedInteger 
								| kAudioFormatFlagsNativeEndian
								| kAudioFormatFlagIsNonInterleaved;
			theBytesPerFrame = theBytesInAPacket = 4;
			theBitsPerChannel = 24;
			break;
		
		default:
			printf ("unknown format\n");
			return -1;
	}
	
	return 0;
}
