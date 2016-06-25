//
//  ViewController.m
//  CodecTestApp
//
//  Created by Rajib Chandra Das on 6/21/16.
//  Copyright © 2016 Rajib Chandra Das. All rights reserved.
//

#import "ViewController.h"
#include "CodecAPI.hpp"



@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    fpyuv = NULL;
    fpWithPath = NULL;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)TestButtonAction:(id)sender
{
    printf("TestButton\n");
    
    dispatch_queue_t OperationThreadQ = dispatch_queue_create("OperationThreadQ",DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(OperationThreadQ, ^{
        [self StartOperation];
    });
    
    
}

- (void)StartOperation
{
    for(int k=0;k<3;k++)
    {
        memset(m_ucaDummmyFrame[k], 0, sizeof(m_ucaDummmyFrame[k]));
        
        for(int i=0;i<352;i++)
        {
            int color = rand()%255;
            for(int j = 0; j < 288; j ++)
            {
                m_ucaDummmyFrame[k][i * 352 + j ] = color;
            }
            
        }
    }
    
    NSString *dataFile = [[NSBundle mainBundle] pathForResource:@"TestYUV" ofType:@"yuv"];
    NSLog(@"%@",dataFile);
    std::string filePath = std::string([dataFile UTF8String]);
    FILE *fp = fopen(filePath.c_str(), "rb");
    unsigned char ucVideoData[352*288*3];
    
    NSString *dataFileOutput = [[NSBundle mainBundle] pathForResource:@"TestOutput" ofType:@"wb"];
    NSLog(@"%@",dataFileOutput);
    string sOutputFilePath = string([dataFileOutput UTF8String]);
    
    int NumberOfFrameOperation = 100;
    int iRecvHeight,iRecvWidth;
    
    CCodecAPI::GetInstance()->CreateVideoEncoder(352, 288, 15, 8);
    CCodecAPI::GetInstance()->CreateVideoDecoder();
    
    for(int i=0;i<NumberOfFrameOperation;i++)
    {
        usleep(66*1000);
        fread(ucVideoData, 352*288*3/2, 1, fp);
        int iEncodedLen = CCodecAPI::GetInstance()->EncodeVideoFrame(ucVideoData, 352*288*3/2, m_ucEncodedData);
        
        int iDecodedLen = CCodecAPI::GetInstance()->DecodeVideoFrame(m_ucEncodedData, iEncodedLen, m_ucDecodedData, iRecvHeight, iRecvWidth);
        
        [self WriteToFile:m_ucDecodedData withLen:iDecodedLen];
        
        //[self WriteToFileWithPath:m_ucDecodedData withLen:iDecodedLen withPath:sOutputFilePath]; //can't get write access, ios doesn't permit
        
        printf("%d-->  iEncodedLen = %d, iDecodedLen = %d iHeight = %d, iWidth = %d\n", i, iEncodedLen, iDecodedLen,  iRecvHeight, iRecvWidth);
        
    }
}

-(void)WriteToFile:(unsigned char *)pData  withLen:(int)iLen
{
    
    if(fpyuv==NULL)
    {
        NSFileHandle *handle;
        NSArray *Docpaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [Docpaths objectAtIndex:0];
        NSString *filePathyuv = [documentsDirectory stringByAppendingPathComponent:@"NextDataCheck.yuv"];
        handle = [NSFileHandle fileHandleForUpdatingAtPath:filePathyuv];
        char *filePathcharyuv = (char*)[filePathyuv UTF8String];
        fpyuv = fopen(filePathcharyuv, "wb");
    }
    
    
    printf("Writing to yuv, iLen = %d\n", iLen);
    fwrite(pData, 1, iLen, fpyuv);
    
    
}

-(void)WriteToFileWithPath:(unsigned char *)pData  withLen:(int)iLen withPath:(string)sPath
{
    
    if(fpWithPath==NULL)
    {
        /*NSFileHandle *handle;
        NSArray *Docpaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [Docpaths objectAtIndex:0];
        NSString *filePathyuv = [documentsDirectory stringByAppendingPathComponent:@"NextDataCheck.yuv"];
        handle = [NSFileHandle fileHandleForUpdatingAtPath:filePathyuv];
        char *filePathcharyuv = (char*)[filePathyuv UTF8String];*/
        
        
        fpWithPath = fopen(sPath.c_str(), "wb");
    }
    
    
    printf("Writing to yuv, sPath = %s\n", sPath.c_str());
    fwrite(pData, 1, iLen, fpWithPath);
    
    
}

@end
