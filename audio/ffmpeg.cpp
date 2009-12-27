// tutorial03.c
// A pedagogical video player that will stream through every video frame as fast as it can
// and play audio (out of sync).
//
// Code based on FFplay, Copyright (c) 2003 Fabrice Bellard,
// and a tutorial by Martin Bohme (boehme@inb.uni-luebeckREMOVETHIS.de)
// Tested on Gentoo, CVS version 5/01/07 compiled with GCC 4.1.1
// Use
//
// gcc -o tutorial03 tutorial03.c -lavformat -lavcodec -lz -lm `sdl-config --cflags --libs`
// to build (assuming libavformat and libavcodec are correctly installed,
// and assuming you have sdl-config. Please refer to SDL docs for your installation.)
//
// Run using
// tutorial03 myvideofile.mpg
//
// to play the stream on your screen.

#ifdef __cplusplus
extern "C" {
#endif

#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>

#ifdef __cplusplus
}
#endif

#include <AudioUnit/AudioUnit.h>
#include <CoreAudio/CoreAudio.h>

#include <stdio.h>

typedef struct PacketQueue {
  AVPacketList *first_pkt, *last_pkt;
  int nb_packets;
  int size;
} PacketQueue;

PacketQueue audioq;

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

void audio_callback(void 												*inRefCon, 
										AudioUnitRenderActionFlags 	*ioActionFlags, 
										const AudioTimeStamp 				*inTimeStamp, 
										UInt32 											inBusNumber, 
										UInt32 											inNumberFrames, 
										AudioBufferList 						*ioData) 
{

  AVCodecContext *aCodecCtx = (AVCodecContext *) ioData->mBuffers[0].mData;
  int len1, audio_size;

	int len = ioData->mNumberBuffers;

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
}

int init(int argc, char *argv[]) {
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

  if(argc < 2) {
    fprintf(stderr, "Usage: test <file>\n");
    exit(1);
  }
  // Register all formats and codecs
  av_register_all();

  // Open video file
  if(av_open_input_file(&pFormatCtx, argv[1], NULL, 0, NULL)!=0)
    return -1; // Couldn't open file

  // Retrieve stream information
  if(av_find_stream_info(pFormatCtx)<0)
    return -1; // Couldn't find stream information

  audioStream=-1;
  for(i=0; i<pFormatCtx->nb_streams; i++) {
    if(pFormatCtx->streams[i]->codec->codec_type==CODEC_TYPE_AUDIO &&
       audioStream < 0) {
      audioStream=i;
    }
  }
  if(audioStream==-1)
    return -1;

  aCodecCtx=pFormatCtx->streams[audioStream]->codec;

  aCodec = avcodec_find_decoder(aCodecCtx->codec_id);
  if(!aCodec) {
    fprintf(stderr, "Unsupported codec!\n");
    return -1;
  }
  avcodec_open(aCodecCtx, aCodec);

  // audio_st = pFormatCtx->streams[index]
  //packet_queue_init(&audioq);

  dump_format(pFormatCtx, 0, argv[1], 0);

  // Close the codec
  avcodec_close(aCodecCtx);

  // Close the video file
  av_close_input_file(pFormatCtx);


  return 0;
}

