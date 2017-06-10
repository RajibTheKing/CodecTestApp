//
//  NSObject_CodecAPI.h
//  CodecTestApp
//
//  Created by Rajib Chandra Das on 6/21/16.
//  Copyright © 2016 Rajib Chandra Das. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <iostream>
using namespace std;


//Including OpenH264 related Header Files
#include "codec_api.h"
#include "codec_app_def.h"
#include "codec_def.h"
#include "codec_ver.h"

#define DEFAULT_HEIGHT 352
#define DEFAULT_WIDTH 288
#define DEFAULT_FPS 30
#define DEFAULT_FRAME_INTRA_PERIOD 15

#define BITRATE_BEGIN 600000

class CCodecAPI
{
public:
    CCodecAPI();
    ~CCodecAPI();
    
    //Encoder API's
    static CCodecAPI* GetInstance();
    int CreateVideoEncoder(int nVideoHeight, int nVideoWidth, int nFPS, int nIFrameInterval);
    int EncodeVideoFrame(unsigned char *ucaEncodingVideoFrameData, unsigned int unLenght, unsigned char *ucaEncodedVideoFrameData);
    int UninitializeEncoder();
    
    
    //Decoder API's
    int CreateVideoDecoder();
    int SetDecoderOption(int nKey, int nValue);
    int DecodeVideoFrame(unsigned char *ucaDecodingVideoFrameData, unsigned int unLength, unsigned char *ucaDecodedVideoFrameData, int &nrVideoHeight, int &nrVideoWidth);
    int UninitializeDecoder();
    
    
    
    
    ISVCEncoder* m_pSVCVideoEncoder;
    
    ISVCDecoder* m_pSVCVideoDecoder;
    
    int m_nVideoWidth;
    int m_nVideoHeight;
    int m_nFPS;
    int m_nFrame_Intra_Period;
};

static CCodecAPI *m_pCodecAPI = NULL;
