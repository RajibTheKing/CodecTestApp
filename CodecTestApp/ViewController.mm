//
//  ViewController.m
//  CodecTestApp
//
//  Created by Rajib Chandra Das on 6/21/16.
//  Copyright © 2016 Rajib Chandra Das. All rights reserved.
//

#import "ViewController.h"
#include "CodecAPI.hpp"

#define TARGET_OS_IPHONE
double avg = 0;
double sum = 0;
int avgCounter = 0;

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
    
    /*NSString *dataFileOutput = [[NSBundle mainBundle] pathForResource:@"TestOutput" ofType:@"wb"];
    NSLog(@"%@",dataFileOutput);
    string sOutputFilePath = string([dataFileOutput UTF8String]);*/
    
    int NumberOfFrameOperation = 1000;

    int iRecvHeight,iRecvWidth;
    
    CCodecAPI::GetInstance()->CreateVideoEncoder(352, 288, 30, 15);
    CCodecAPI::GetInstance()->CreateVideoDecoder();
    
    long long start_time = CurrentTimestamp();
    
    for(int i=0;i<NumberOfFrameOperation;i++)
    {
        usleep(66*1000);
        fread(ucVideoData, 352*288*3/2, 1, fp);
        int iEncodedLen = CCodecAPI::GetInstance()->EncodeVideoFrame(ucVideoData, 352*288*3/2, m_ucEncodedData);
        unsigned char *p = m_ucEncodedData;
        
        int nalType = p[2] == 1 ? (p[3] & 0x1f) : (p[4] & 0x1f);
        
        printf("nalType = %d\n", nalType);
        
        
        printf("Real Encoded Data: ");
        for(int i=0;i<1000;i++)
        {
            printf("%02X ", m_ucEncodedData[i]);
            //if(i%288==0) printf("\n");
        }
        printf("\n");
        
        
        
        
        /*unsigned char c = m_ucEncodedData[0];
        printf("%d\n", c);
        for(int i=0;i<8;i++)
        {
            if(c&(1<<i)) printf("1");
            else    printf("0");
        }
        printf("\n");
        */
        
        //if((i)%19==0) continue;
        //[self WriteToFile:m_ucEncodedData withLen:iEncodedLen];
        
        int iDecodedLen = CCodecAPI::GetInstance()->DecodeVideoFrame(m_ucEncodedData, iEncodedLen, m_ucDecodedData, iRecvHeight, iRecvWidth);
        
        //[self WriteToFile:m_ucDecodedData withLen:iDecodedLen];
        
        //[self WriteToFileWithPath:m_ucDecodedData withLen:iDecodedLen withPath:sOutputFilePath]; //can't get write access, ios doesn't permit
       
        printf("%d-->  iEncodedLen = %d, iDecodedLen = %d iHeight = %d, iWidth = %d\n", i, iEncodedLen, iDecodedLen,  iRecvHeight, iRecvWidth);
        printf("\n\n");
        if(i>=5)
            break;
        
    }
    fclose(fpyuv);
    long long totalExecutionTime = CurrentTimestamp()- start_time;
    printf("Completion time = %lld\n", totalExecutionTime);
    avgCounter++;
    sum+=(double)totalExecutionTime;
    avg = sum/avgCounter;
    printf("Counter = %d, Completion time average = %lf\n", avgCounter,  avg);
    
}
long long  CurrentTimestamp()
{
    long long currentTime;
    
#if defined(TARGET_OS_WINDOWS_PHONE) || defined (_DESKTOP_C_SHARP_) || defined (_WIN32)
    
    currentTime = GetTickCount64();
    
#elif defined(TARGET_OS_IPHONE) || defined(__ANDROID__) || defined(TARGET_IPHONE_SIMULATOR)
    
    namespace sc = std::chrono;
    
    auto time = sc::system_clock::now(); // get the current time
    auto since_epoch = time.time_since_epoch(); // get the duration since epoch
    
    // I don't know what system_clock returns
    // I think it's uint64_t nanoseconds since epoch
    // Either way this duration_cast will do the right thing
    
    auto millis = sc::duration_cast<sc::milliseconds>(since_epoch);
    
    currentTime = millis.count(); // just like java (new Date()).getTime();
    
#elif defined(__linux__) || defined (__APPLE__)
    
    struct timeval te;
    
    gettimeofday(&te, NULL);
    
    currentTime = te.tv_sec* +te.tv_sec * 1000LL + te.tv_usec / 1000;
    
#else
    
    currentTime = 0;
    
#endif
    
    return currentTime;
    
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
