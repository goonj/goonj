#include <CoreServices/CoreServices.h>
#include <stdio.h>
#include <unistd.h>
#include <AudioUnit/AudioUnit.h>

#include <math.h>

#include <signal.h>

#include "RenderSin.h"


#ifdef __cplusplus
extern "C" {
#endif

#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>

#ifdef __cplusplus
}
#endif

AudioUnit	gOutputUnit;

typedef struct PacketQueue {
  AVPacketList *first_pkt, *last_pkt;
  int nb_packets;
  int size;
} PacketQueue;

PacketQueue audioq;

AVCodecContext  *aCodecCtx;

int quit = 0;

void packet_queue_init(PacketQueue *q) {
  memset(q, 0, sizeof(PacketQueue));
}
int packet_queue_put(PacketQueue *q, AVPacket *pkt) {
  AVPacketList *pkt1;
  if(av_dup_packet(pkt) < 0) {
    return -1;
  }
  pkt1 = (AVPacketList*) av_malloc(sizeof(AVPacketList));
  if (!pkt1)
    return -1;
  pkt1->pkt = *pkt;
  pkt1->next = NULL;



  if (!q->last_pkt)
    q->first_pkt = pkt1;
  else
    q->last_pkt->next = pkt1;
  q->last_pkt = pkt1;
  q->nb_packets++;
  q->size += pkt1->pkt.size;

  return 0;
}
static int packet_queue_get(PacketQueue *q, AVPacket *pkt, int block)
{
  AVPacketList *pkt1;
  int ret;

  for(;;) {

    if(quit) {
      ret = -1;
      break;
    }

    pkt1 = q->first_pkt;
    if (pkt1) {
      q->first_pkt = pkt1->next;
      if (!q->first_pkt)
					q->last_pkt = NULL;
      q->nb_packets--;
      q->size -= pkt1->pkt.size;
      *pkt = pkt1->pkt;
      av_free(pkt1);
      ret = 1;
      break;
    } else if (!block) {
      ret = 0;
      break;
    } else {
    }
  }
  return ret;
}


int audio_decode_frame(AVCodecContext *aCodecCtx, uint8_t *audio_buf, int buf_size) {

  static AVPacket pkt;
  static uint8_t *audio_pkt_data = NULL;
  static int audio_pkt_size = 0;

  int len1, data_size;

  for(;;) {
    while(audio_pkt_size > 0) {
      data_size = buf_size;
      len1 = avcodec_decode_audio3(aCodecCtx, (int16_t *)audio_buf, &data_size, &pkt);
      if(len1 < 0) {
	/* if error, skip frame */
	audio_pkt_size = 0;
	break;
      }
      audio_pkt_data += len1;
      audio_pkt_size -= len1;
      if(data_size <= 0) {
	/* No data yet, get more frames */
	continue;
      }
      /* We have data, return it and come back for more later */
      return data_size;
    }


    if(quit) {
      return -1;
    }

    if(packet_queue_get(&audioq, &pkt, 1) < 0) {
      return -1;
    }
    audio_pkt_data = pkt.data;
    audio_pkt_size = pkt.size;
  }
}

OSStatus audio_callback(void 												*inRefCon, 
												AudioUnitRenderActionFlags 	*ioActionFlags, 
												const AudioTimeStamp 				*inTimeStamp, 
												UInt32 											inBusNumber, 
												UInt32 											inNumberFrames, 
												AudioBufferList 						*ioData) 
{
	printf("soembodyalskdjaksljdlasjdklasjdl");

  //AVCodecContext *aCodecCtx = (AVCodecContext *) ioData->mBuffers[0].mData;
  int len1, audio_size;

	int len = sizeof(ioData->mBuffers[0].mData);

  static uint8_t audio_buf[(AVCODEC_MAX_AUDIO_FRAME_SIZE * 3) / 2];
  static unsigned int audio_buf_size = 0;
  static unsigned int audio_buf_index = 0;

  while(len > 0) {
    if(audio_buf_index >= audio_buf_size) {
      /* We have already sent all our data; get more */
      audio_size = audio_decode_frame(aCodecCtx, audio_buf, sizeof(audio_buf));
      if(audio_size < 0) {
				/* If error, output silence */
				printf("sadasds");
				audio_buf_size = 1024; // arbitrary?
				memset(audio_buf, 0, audio_buf_size);
      } else {
				audio_buf_size = audio_size;
      }
      audio_buf_index = 0;
    }
    len1 = audio_buf_size - audio_buf_index;
    if(len1 > len)
      len1 = len;
    memcpy(ioData->mBuffers[0].mData, (uint8_t *)audio_buf + audio_buf_index, len1);
    len -= len1;
    //stream += len1;
    audio_buf_index += len1;
  }

	return noErr;
}



// ________________________________________________________________________________
//
// CreateDefaultAU
//
void	CreateDefaultAU()
{
	OSStatus err = noErr;

	// Open the default output unit
	ComponentDescription desc;
	desc.componentType = kAudioUnitType_Output;
	desc.componentSubType = kAudioUnitSubType_DefaultOutput;
	desc.componentManufacturer = kAudioUnitManufacturer_Apple;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
	
	Component comp = FindNextComponent(NULL, &desc);
	if (comp == NULL) { printf ("FindNextComponent\n"); return; }
	
	err = OpenAComponent(comp, &gOutputUnit);
	if (comp == NULL) { printf ("OpenAComponent=%ld\n", (long int)err); return; }

	// Set up a callback function to generate output to the output unit
    AURenderCallbackStruct input;
	input.inputProc = audio_callback;
	input.inputProcRefCon = NULL;

	err = AudioUnitSetProperty (gOutputUnit, 
								kAudioUnitProperty_SetRenderCallback, 
								kAudioUnitScope_Input,
								0, 
								&input, 
								sizeof(input));
	if (err) { printf ("AudioUnitSetProperty-CB=%ld\n", (long int)err); return; }
    
}

// ________________________________________________________________________________
//
// TestDefaultAU
//
void	TestDefaultAU(AudioStreamBasicDescription streamFormat)
{
	OSStatus err = noErr;
    
	// We tell the Output Unit what format we're going to supply data to it
	// this is necessary if you're providing data through an input callback
	// AND you want the DefaultOutputUnit to do any format conversions
	// necessary from your format to the device's format.
	/*AudioStreamBasicDescription streamFormat;
		streamFormat.mSampleRate = sSampleRate;		//	the sample rate of the audio stream
		streamFormat.mFormatID = theFormatID;			//	the specific encoding type of audio stream
		streamFormat.mFormatFlags = theFormatFlags;		//	flags specific to each format
		streamFormat.mBytesPerPacket = theBytesInAPacket;	
		streamFormat.mFramesPerPacket = theFramesPerPacket;	
		streamFormat.mBytesPerFrame = theBytesPerFrame;		
		streamFormat.mChannelsPerFrame = sNumChannels;	
		streamFormat.mBitsPerChannel = theBitsPerChannel;	*/

	printf("Rendering source:\n\t");
	printf ("SampleRate=%f,", streamFormat.mSampleRate);
	printf ("BytesPerPacket=%ld,", (long int)streamFormat.mBytesPerPacket);
	printf ("FramesPerPacket=%ld,", (long int)streamFormat.mFramesPerPacket);
	printf ("BytesPerFrame=%ld,", (long int)streamFormat.mBytesPerFrame);
	printf ("BitsPerChannel=%ld,", (long int)streamFormat.mBitsPerChannel);
	printf ("ChannelsPerFrame=%ld\n", (long int)streamFormat.mChannelsPerFrame);
	
	err = AudioUnitSetProperty (gOutputUnit,
							kAudioUnitProperty_StreamFormat,
							kAudioUnitScope_Input,
							0,
							&streamFormat,
							sizeof(AudioStreamBasicDescription));
	if (err) { printf ("AudioUnitSetProperty-SF=%4.4s, %ld\n", (char*)&err, (long int)err); return; }
	
    // Initialize unit
	err = AudioUnitInitialize(gOutputUnit);
	if (err) { printf ("AudioUnitInitialize=%ld\n", (long int)err); return; }
    
	Float64 outSampleRate;
	UInt32 size = sizeof(Float64);
	err = AudioUnitGetProperty (gOutputUnit,
							kAudioUnitProperty_SampleRate,
							kAudioUnitScope_Output,
							0,
							&outSampleRate,
							&size);
	if (err) { printf ("AudioUnitSetProperty-GF=%4.4s, %ld\n", (char*)&err, (long int)err); return; }

	// Start the rendering
	// The DefaultOutputUnit will do any format conversions to the format of the default device
	err = AudioOutputUnitStart (gOutputUnit);
	if (err) { printf ("AudioOutputUnitStart=%ld\n", (long int)err); return; }
		  
	// we call the CFRunLoopRunInMode to service any notifications that the audio
	// system has to deal with
	//CFRunLoopRunInMode(kCFRunLoopDefaultMode, 2, false);

	// REALLY after you're finished playing STOP THE AUDIO OUTPUT UNIT!!!!!!	
	// but we never get here because we're running until the process is nuked...	
	verify_noerr (AudioOutputUnitStop (gOutputUnit));
	
  err = AudioUnitUninitialize (gOutputUnit);
	if (err) { printf ("AudioUnitUninitialize=%ld\n", (long int)err); return; }
}


void init_ffmpeg(char *file) {
  AVFormatContext *pFormatCtx;
  int             i, videoStream, audioStream;
  AVCodecContext  *pCodecCtx;
  AVCodec         *pCodec;
  AVFrame         *pFrame;
  AVPacket        packet;
  int             frameFinished;
  float           aspect_ratio;

  AVCodecContext  *aCodecCtx;
  AVCodec         *aCodec;

  // Register all formats and codecs
  av_register_all();

  // Open video file
  if(av_open_input_file(&pFormatCtx, file, NULL, 0, NULL)!=0)
    return; // Couldn't open file

  // Retrieve stream information
  if(av_find_stream_info(pFormatCtx)<0)
    return; // Couldn't find stream information

  audioStream=-1;
  for(i=0; i<pFormatCtx->nb_streams; i++) {
    if(pFormatCtx->streams[i]->codec->codec_type==CODEC_TYPE_AUDIO &&
       audioStream < 0) {
      audioStream=i;
    }
  }
  if(audioStream==-1)
    return;

  aCodecCtx=pFormatCtx->streams[audioStream]->codec;

  aCodec = avcodec_find_decoder(aCodecCtx->codec_id);
  if(!aCodec) {
    fprintf(stderr, "Unsupported codec!\n");
    return;
  }
  avcodec_open(aCodecCtx, aCodec);

  dump_format(pFormatCtx, 0, file, 0);

  // audio_st = pFormatCtx->streams[index]
  packet_queue_init(&audioq);

	OSStatus err = noErr;

	AudioStreamBasicDescription streamFormat;
		streamFormat.mSampleRate = aCodecCtx->sample_rate;		//	the sample rate of the audio stream
		streamFormat.mFormatID = '.mp3';			//	the specific encoding type of audio stream
		streamFormat.mFormatFlags = theFormatFlags;		//	flags specific to each format
		streamFormat.mBytesPerPacket = theBytesInAPacket;	
		streamFormat.mFramesPerPacket = 1152;	
		streamFormat.mBytesPerFrame = theBytesPerFrame;		
		streamFormat.mChannelsPerFrame = aCodecCtx->channels;	
		streamFormat.mBitsPerChannel = theBitsPerChannel;

		printf("Rendering source:\n\t");
		printf ("SampleRate=%f,", streamFormat.mSampleRate);
		printf ("BytesPerPacket=%ld,", (long int)streamFormat.mBytesPerPacket);
		printf ("FramesPerPacket=%ld,", (long int)streamFormat.mFramesPerPacket);
		printf ("BytesPerFrame=%ld,", (long int)streamFormat.mBytesPerFrame);
		printf ("BitsPerChannel=%ld,", (long int)streamFormat.mBitsPerChannel);
		printf ("ChannelsPerFrame=%ld\n", (long int)streamFormat.mChannelsPerFrame);

		err = AudioUnitSetProperty (gOutputUnit,
								kAudioUnitProperty_StreamFormat,
								kAudioUnitScope_Input,
								0,
								&streamFormat,
								sizeof(AudioStreamBasicDescription));
		if (err) { printf ("AudioUnitSetProperty-SF=%4.4s, %ld\n", (char*)&err, (long int)err); return; }
		
	    // Initialize unit
		err = AudioUnitInitialize(gOutputUnit);
		if (err) { printf ("AudioUnitInitialize=%ld\n", (long int)err); return; }

		Float64 outSampleRate;
		UInt32 size = sizeof(Float64);
		err = AudioUnitGetProperty (gOutputUnit,
								kAudioUnitProperty_SampleRate,
								kAudioUnitScope_Output,
								0,
								&outSampleRate,
								&size);
		if (err) { printf ("AudioUnitSetProperty-GF=%4.4s, %ld\n", (char*)&err, (long int)err); return; }
		
		// Start the rendering
		// The DefaultOutputUnit will do any format conversions to the format of the default device
		err = AudioOutputUnitStart (gOutputUnit);
		if (err) { printf ("AudioOutputUnitStart=%ld\n", (long int)err); return; }

		int z = 0;
		while(av_read_frame(pFormatCtx, &packet)>=0 && quit == 0) {
				if(packet.stream_index==audioStream) {
					printf("Got Packet. %d \n", z++);
		      packet_queue_put(&audioq, &packet);
		  }
		}

		// we call the CFRunLoopRunInMode to service any notifications that the audio
		// system has to deal with
		// CFRunLoopRunInMode(kCFRunLoopDefaultMode, 2, false);

		// REALLY after you're finished playing STOP THE AUDIO OUTPUT UNIT!!!!!!	
		// but we never get here because we're running until the process is nuked...	
		verify_noerr (AudioOutputUnitStop (gOutputUnit));

	  err = AudioUnitUninitialize (gOutputUnit);
		if (err) { printf ("AudioUnitUninitialize=%ld\n", (long int)err); return; }

  // Close the codec
  avcodec_close(aCodecCtx);

  // Close the video file
  av_close_input_file(pFormatCtx);


  return;
}

void CloseDefaultAU ()
{
	// Clean up
	CloseComponent (gOutputUnit);
}

void CreateArgListFromString (int *ioArgCount, char **ioArgs, char *inString)
{
    int i, length;
    length = strlen (inString);
    
    // prime for first argument
    ioArgs[0] = inString;
    *ioArgCount = 1;
    
    // get subsequent arguments
    for (i = 0; i < length; i++) {
        if (inString[i] == ' ') {
            inString[i] = 0;		// terminate string
            ++(*ioArgCount);		// increment count
            ioArgs[*ioArgCount - 1] = inString + i + 1;	// set next arg pointer
        }
    }
}

void
leave(int sig) {
	quit = 1;
}

// ________________________________________________________________________________
//
// TestDefaultAU
//
int main(int argc, char * argv[])
{
	(void) signal(SIGINT,leave);
	
    CreateDefaultAU();

		init_ffmpeg(argv[1]);
    
    CloseDefaultAU();
    
    return 0;
}
