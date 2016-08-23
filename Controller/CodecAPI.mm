//
//  NSObject_CodecAPI.h
//  CodecTestApp
//
//  Created by Rajib Chandra Das on 6/21/16.
//  Copyright © 2016 Rajib Chandra Das. All rights reserved.
//

#include "CodecAPI.hpp"
#include "pthread.h"

CCodecAPI::CCodecAPI()
{

}

CCodecAPI::~CCodecAPI()
{
    if(m_pCodecAPI!=NULL)
    {
        delete m_pCodecAPI;
    }
}

CCodecAPI* CCodecAPI::GetInstance()
{
    if(m_pCodecAPI == NULL)
    {
        m_pCodecAPI = new CCodecAPI();
    }
    return m_pCodecAPI;
}

int CCodecAPI::CreateVideoEncoder(int nVideoHeight, int nVideoWidth, int nFPS, int nIFrameInterval)
{
    m_nVideoHeight = nVideoHeight;
    m_nVideoWidth = nVideoWidth;
    m_nFPS = nFPS;
    m_nFrame_Intra_Period = nIFrameInterval;
    
    long nReturnedValueFromEncoder = WelsCreateSVCEncoder(&m_pSVCVideoEncoder);
    
    
    m_nVideoWidth = nVideoWidth;
    m_nVideoHeight = nVideoHeight;
    
    SEncParamExt encoderParemeters;
    
    memset(&encoderParemeters, 0, sizeof(SEncParamExt));
    
    m_pSVCVideoEncoder->GetDefaultParams(&encoderParemeters);
    
    encoderParemeters.iUsageType = CAMERA_VIDEO_REAL_TIME;
    encoderParemeters.iTemporalLayerNum = 0;
    encoderParemeters.uiIntraPeriod = nIFrameInterval;
    encoderParemeters.eSpsPpsIdStrategy = INCREASING_ID;
    encoderParemeters.bEnableSSEI = false;
    encoderParemeters.bEnableFrameCroppingFlag = true;
    encoderParemeters.iLoopFilterDisableIdc = 0;
    encoderParemeters.iLoopFilterAlphaC0Offset = 0;
    encoderParemeters.iLoopFilterBetaOffset = 0;
    encoderParemeters.iMultipleThreadIdc = 0;
    
    //encoderParemeters.iRCMode = RC_OFF_MODE;
    encoderParemeters.iRCMode = RC_BITRATE_MODE;
    encoderParemeters.iMinQp = 0;
    encoderParemeters.iMaxQp = 52;

    
    
    encoderParemeters.bEnableDenoise = false;
    encoderParemeters.bEnableSceneChangeDetect = false;
    encoderParemeters.bEnableBackgroundDetection = true;
    encoderParemeters.bEnableAdaptiveQuant = false;
    encoderParemeters.bEnableFrameSkip = true;
    encoderParemeters.bEnableLongTermReference = true;
    encoderParemeters.iLtrMarkPeriod = 20;
    encoderParemeters.bPrefixNalAddingCtrl = false;
    encoderParemeters.iSpatialLayerNum = 1;
    encoderParemeters.iEntropyCodingModeFlag = 1;
    
    
    SSpatialLayerConfig *spartialLayerConfiguration = &encoderParemeters.sSpatialLayers[0];
    
    spartialLayerConfiguration->uiProfileIdc = PRO_BASELINE;//;
    
    encoderParemeters.iPicWidth = spartialLayerConfiguration->iVideoWidth = m_nVideoWidth;
    encoderParemeters.iPicHeight = spartialLayerConfiguration->iVideoHeight = m_nVideoHeight;
    encoderParemeters.fMaxFrameRate = spartialLayerConfiguration->fFrameRate = (float)nFPS;
    
    encoderParemeters.iTargetBitrate = spartialLayerConfiguration->iSpatialBitrate = BITRATE_BEGIN;
    encoderParemeters.iTargetBitrate = spartialLayerConfiguration->iMaxSpatialBitrate = BITRATE_BEGIN;

    
    spartialLayerConfiguration->iDLayerQp = 24;
    //spartialLayerConfiguration->sSliceCfg.uiSliceMode = SM_SINGLE_SLICE;
    spartialLayerConfiguration->sSliceArgument.uiSliceMode = SM_SINGLE_SLICE;

    
    nReturnedValueFromEncoder = m_pSVCVideoEncoder->InitializeExt(&encoderParemeters);
    
    if (nReturnedValueFromEncoder != 0)
    {
        printf("OpenH264 InitializeExt Failed!!!\n");
        
        return 0;
    }
    
    printf("CVideoEncoder::CreateVideoEncoder OpenH264 video encoder initialized Successfully\n");
    return 1;
}

int CCodecAPI::EncodeVideoFrame(unsigned char *ucaEncodingVideoFrameData, unsigned int unLenght, unsigned char *ucaEncodedVideoFrameData)
{
    //Locker lock(*m_pVideoEncoderMutex);
    
    //CLogPrinter_Write(CLogPrinter::INFO, "CVideoEncoder::Encode");
    
    if (NULL == m_pSVCVideoEncoder)
    {
        //CLogPrinter_Write("OpenH264 encoder NULL!");
        
        return 0;
    }
    
    SFrameBSInfo frameBSInfo;
    SSourcePicture sourcePicture;
    
    sourcePicture.iColorFormat = videoFormatI420;
    sourcePicture.uiTimeStamp = 0;
    sourcePicture.iPicWidth = m_nVideoWidth;
    sourcePicture.iPicHeight = m_nVideoHeight;
    
    sourcePicture.iStride[0] = m_nVideoWidth;
    sourcePicture.iStride[1] = sourcePicture.iStride[2] = sourcePicture.iStride[0] >> 1;
    
    sourcePicture.pData[0] = (unsigned char *)ucaEncodingVideoFrameData;
    sourcePicture.pData[1] = sourcePicture.pData[0] + (m_nVideoWidth * m_nVideoHeight);
    sourcePicture.pData[2] = sourcePicture.pData[1] + (m_nVideoWidth * m_nVideoHeight >> 2);
    
    int nReturnedValueFromEncoder = m_pSVCVideoEncoder->EncodeFrame(&sourcePicture, &frameBSInfo);
    
    if (nReturnedValueFromEncoder != 0)
    {
        printf("CVideoEncoder::EncodeAndTransfer Encode FAILED");
        
        return 0;
    }
    
    if (videoFrameTypeSkip == frameBSInfo.eFrameType || videoFrameTypeInvalid == frameBSInfo.eFrameType)
    {
        return 0;
    }
    
    int nEncodedVideoFrameSize = 0;
    
    for (int iLayer = 0, iCopyIndex = 0; iLayer < frameBSInfo.iLayerNum; iLayer++)
    {
        SLayerBSInfo* pLayerBsInfo = &frameBSInfo.sLayerInfo[iLayer];
        
        if (pLayerBsInfo)
        {
            int nLayerSize = 0;
            
            for (int iNalIndex = pLayerBsInfo->iNalCount - 1; iNalIndex >= 0; iNalIndex--)
            {
                nLayerSize += pLayerBsInfo->pNalLengthInByte[iNalIndex];
            }
            
            memcpy(ucaEncodedVideoFrameData + iCopyIndex, pLayerBsInfo->pBsBuf, nLayerSize);
            
            iCopyIndex += nLayerSize;
            nEncodedVideoFrameSize += nLayerSize;
        }
    }
    
    return nEncodedVideoFrameSize;
}






int CCodecAPI::CreateVideoDecoder()
{
    long nReturnedValueFromDecoder = WelsCreateDecoder(&m_pSVCVideoDecoder);
    
    if (nReturnedValueFromDecoder != 0 || NULL == m_pSVCVideoDecoder)
    {
        printf("Unable to create OpenH264 decoder\n");
        return -1;
    }
    
    SVideoProperty sVideoProparty;
    sVideoProparty.eVideoBsType = VIDEO_BITSTREAM_AVC;
    
    SDecodingParam decoderParemeters = { 0 };
    decoderParemeters.sVideoProperty.size = sizeof(decoderParemeters.sVideoProperty);
    decoderParemeters.sVideoProperty  = sVideoProparty;
    decoderParemeters.uiTargetDqLayer = (uint8_t)-1;
    decoderParemeters.eEcActiveIdc = ERROR_CON_FRAME_COPY;
    decoderParemeters.sVideoProperty.eVideoBsType = VIDEO_BITSTREAM_DEFAULT;
    
    nReturnedValueFromDecoder = m_pSVCVideoDecoder->Initialize(&decoderParemeters);
    
    if (nReturnedValueFromDecoder != 0)
    {
        printf("Unable to initialize OpenH264 decoder\n");
        return -1;
    }
    
    /*if (SetDecoderOption(DECODER_OPTION_DATAFORMAT, videoFormatI420) != 0)
     {
     cout << "Error in setting option " << DECODER_OPTION_DATAFORMAT << " to OpenH264 decoder\n";
     }*/
    
    if (SetDecoderOption(DECODER_OPTION_END_OF_STREAM, 0) != 0)
    {
        cout << "Error in setting option " << DECODER_OPTION_END_OF_STREAM << " to OpenH264 decoder\n";
    }
    
    printf("CVideoDecoder::CreateVideoDecoder open h264 video decoder initialized Successfully\n");
    
    return 1;
}

int CCodecAPI::SetDecoderOption(int nKey, int nValue)
{
    return m_pSVCVideoDecoder->SetOption(DECODER_OPTION_END_OF_STREAM, &nValue);
}

int CCodecAPI::DecodeVideoFrame(unsigned char *ucaDecodingVideoFrameData, unsigned int unLength, unsigned char *ucaDecodedVideoFrameData, int &nrVideoHeight, int &nrVideoWidth)
{
    if (!m_pSVCVideoDecoder)
    {
        //CLogPrinter_Write(CLogPrinter::DEBUGS, "CVideoDecoder::Decode pSVCVideoDecoder == NULL");
        
        return 0;
    }
    
    int strides[2] = { 0 };
    unsigned char *outputPlanes[3] = { NULL };
    DECODING_STATE decodingState = m_pSVCVideoDecoder->DecodeFrame(ucaDecodingVideoFrameData, unLength, outputPlanes, strides, nrVideoWidth, nrVideoHeight);
    
    if (decodingState != 0)
    {
        printf("CVideoDecoder::Decode OpenH264 Decoding FAILEDDDDDDDDDD, %d\n", decodingState);
        return 0;
    }
    
    int decodedVideoFrameSize = 0;
    
    {
        int plane = 0;
        unsigned char *outputPlane = outputPlanes[plane];
        int stride = strides[0];
        
        for (int row = 0; row < nrVideoHeight; row++)
        {
            memcpy(ucaDecodedVideoFrameData + decodedVideoFrameSize, outputPlane, nrVideoWidth);
            
            decodedVideoFrameSize += nrVideoWidth;
            outputPlane += stride;
        }
    }
    
    for (int plane = 1; plane < 3; plane++)
    {
        unsigned char *outputPlane = outputPlanes[plane];
        int stride = strides[1];
        int halfiVideoHeight = nrVideoHeight >> 1;
        int halfiVideoWidth = nrVideoWidth >> 1;
        
        for (int row = 0; row < halfiVideoHeight; row++)
        {
            size_t stLength = halfiVideoWidth;
            
            memcpy(ucaDecodedVideoFrameData + decodedVideoFrameSize, outputPlane, stLength);
            
            decodedVideoFrameSize += stLength;
            outputPlane += stride;
        }
    }
    
    return decodedVideoFrameSize;
}



