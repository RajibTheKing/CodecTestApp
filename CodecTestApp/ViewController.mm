//
//  ViewController.m
//  CodecTestApp
//
//  Created by Rajib Chandra Das on 6/21/16.
//  Copyright © 2016 Rajib Chandra Das. All rights reserved.
//

#import "ViewController.h"
#include "CodecAPI.hpp"
#include "ts.h"


using namespace ts;


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
    fpInputFile = NULL;
    fpOutputFile = NULL;
    
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
        
        
        /*NSString *dataFile = [[NSBundle mainBundle] pathForResource:@"lowRes" ofType:@"ts"];
        NSLog(@"%@",dataFile);
        std::string filePath = std::string([dataFile UTF8String]);
        
        
        NSFileHandle *handle;
        NSArray *Docpaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [Docpaths objectAtIndex:0];
        NSString *filePathyuv = [documentsDirectory stringByAppendingPathComponent:@"lowRes.264"];
        handle = [NSFileHandle fileHandleForUpdatingAtPath:filePathyuv];
        //char *filePathcharyuv = (char*)[filePathyuv UTF8String];
        
        
        
        
        demuxer *dm = new demuxer();
        double fps = 30;
        dm->demux_file(filePath.c_str(), &fps);*/
        
    });
    
    
}

- (void)StartOperation
{
    m_iWidth = 352;
    m_iHeight = 288;
    
    for(int k=0;k<3;k++)
    {
        memset(m_ucaDummmyFrame[k], 0, sizeof(m_ucaDummmyFrame[k]));
        
        for(int i=0;i<m_iHeight;i++)
        {
            int color = rand()%255;
            for(int j = 0; j < m_iWidth; j ++)
            {
                m_ucaDummmyFrame[k][i * m_iWidth + j ] = color;
            }
            
        }
    }
    
    //NSString *dataFile = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"h264"];
    //NSLog(@"%@",dataFile);
    //std::string filePath = std::string([dataFile UTF8String]);
    
    std::string filePath = "/Users/RajibTheKing/Desktop/VideoDump/newDump/1058021496838398237.h264";
    fpInputFile = fopen(filePath.c_str(), "rb");
    
    //NSString *dataFileOutput = [[NSBundle mainBundle] pathForResource:@"TestOutput" ofType:@"wb"];
    //NSLog(@"%@",dataFileOutput);
    //string sOutputFilePath = string([dataFileOutput UTF8String]);
    
    std::string sOutputFilePath = "/Users/RajibTheKing/Desktop/VideoDump/newDump/1058021496838398237_Processed.yuv420";
    fpOutputFile = fopen(sOutputFilePath.c_str(), "wb");
    
    
    //[self OpenFileByName:&fpInputFile withFileName:@"test.h264"];
    long long  iTotalDataLen = [self GetDataLenFromFile:&fpInputFile];
    cout<<"TheKing--> iTotalDataLen = "<<iTotalDataLen<<endl;
    fread(m_ucaInputData, iTotalDataLen, 1, fpInputFile);
    

    
    CCodecAPI::GetInstance()->CreateVideoEncoder(m_iHeight, m_iWidth, 30, 15);
    CCodecAPI::GetInstance()->CreateVideoDecoder();
    
    long long start_time = CurrentTimestamp();
    
    [self EncodeDecodeFromH264File:m_ucaInputData withLen:(int)iTotalDataLen];
    //[self EncodeDecodeFromYUVFile];
    
    fclose(fpOutputFile);
    fclose(fpInputFile);
    fclose(fpyuv);
    long long totalExecutionTime = CurrentTimestamp()- start_time;
    printf("Completion time = %lld\n", totalExecutionTime);
    avgCounter++;
    sum+=(double)totalExecutionTime;
    avg = sum/avgCounter;
    printf("Counter = %d, Completion time average = %lf\n", avgCounter,  avg);
}

- (void)OpenFileByName:(FILE **)fp withFileName:(NSString *)fileName
{
    NSFileHandle *handle;
    NSArray *Docpaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [Docpaths objectAtIndex:0];
    NSString *filePathyuv = [documentsDirectory stringByAppendingPathComponent:fileName];
    handle = [NSFileHandle fileHandleForUpdatingAtPath:filePathyuv];
    char *filePathcharyuv = (char*)[filePathyuv UTF8String];
    printf("FilePath = %s\n", filePathcharyuv);
    
    *fp = fopen(filePathcharyuv, "rb");
    
    printf("Here fp = %d, *fp = %d\n", *fp, **fp);
    
    if(*fp==NULL)
    {
        printf("OpenFileByName Error!!!!!!\n");
    }
}

-(long long)GetDataLenFromFile:(FILE **)fp
{
    long long i_size = 0;
    if (*fp != NULL)
    {
        if (!fseek(*fp, 0, SEEK_END))
        {
            i_size = ftell(*fp);
            fseek(*fp, 0, SEEK_SET);
        }
    }
    else
    {
        cout << "file open error\n";
    }
    return i_size;
}

-(void)EncodeDecodeFromH264File:(unsigned char *)pFileArray withLen:(int) iLen;
{
    int frameCounterTemp = 0;
    for (int i = 0; i < iLen - 3;)
    {
        if (pFileArray[i] == 0 && pFileArray[i + 1] == 0 && pFileArray[i + 2] == 0 && pFileArray[i + 3] == 1) //found the start of a frame
        {
            //cout << "i = " << i << "\n";
            int iFrameSize = 0;
            int j;
            for (j = i + 3;; j++)
            {
                if (j == iLen - 1 || (pFileArray[j] == 0 && pFileArray[j + 1] == 0 && pFileArray[j + 2] == 0 && pFileArray[j + 3] == 1 )) //found the end of a frame
                {
                    //cout << "j = " << j << "\n";
                    if (j == iLen - 1)
                    {
                        break;
                    }
                    iFrameSize = j - i;
                    if (iFrameSize < 100)
                    {
                        continue;
                    }
                    
                    break;
                }
            }
            
            int nalType = pFileArray[i + 2] == 1 ? (pFileArray[i + 3] & 0x1f) : (pFileArray[i + 4] & 0x1f);
            if (nalType == 7)
            {
                
                printf("it is a i frame frameCounterTemp = %d\n", frameCounterTemp);
                frameCounterTemp = 0;
            }
            
            int iDecodedWidth, iDecodedHeight;
            int iDecodedLen = CCodecAPI::GetInstance()->DecodeVideoFrame(pFileArray+i, iFrameSize, m_ucDecodedData, iDecodedWidth, iDecodedHeight);
            
            if (iDecodedLen > 0)
            {
                fwrite(m_ucDecodedData, 1, iDecodedWidth * iDecodedHeight * 3 / 2, fpOutputFile);
                //[self WriteToFile:m_ucDecodedData withLen:iDecodedLen];
            }
            
            printf("\nit is a decodedFrame -- size = %d, H:W = %d:%d\n", iDecodedLen, iDecodedHeight, iDecodedWidth);
            
            
            i = j;
        }
        else
        {
            cout << "Entered Else\n";
            i++;
        }
    }
}

-(void)EncodeDecodeFromYUVFile
{
    
     
    int EncodedIfreshCounter = 0;
    int NumberOfFrameOperation = 1000;
    int iRecvHeight,iRecvWidth;
    unsigned char ucVideoData[m_iHeight*m_iWidth*3];
    
    for(int i=0;;i++)
    {
        //usleep(66*1000);
        size_t iRett = fread(ucVideoData, m_iHeight*m_iWidth*3/2, 1, fpInputFile);
        if(iRett==0) break;
        
        int iEncodedLen = CCodecAPI::GetInstance()->EncodeVideoFrame(ucVideoData, m_iHeight*m_iWidth*3/2, m_ucEncodedData);
        fwrite(m_ucEncodedData, iEncodedLen, 1, fpOutputFile);
        
        unsigned char *p = m_ucEncodedData;
        
        int nalType = p[2] == 1 ? (p[3] & 0x1f) : (p[4] & 0x1f);
        printf("nalType = %d\n", nalType);
        
        if(nalType == 7)
        {
            EncodedIfreshCounter++;
        }
        
        
        if(EncodedIfreshCounter>2 && nalType ==7)
        {
            for(int i=iEncodedLen-1000; i<iEncodedLen;i++)
            {
                m_ucEncodedData[i]=rand()%127;
            }
        }
        
        
        unsigned short psEncoded[100];
        memcpy(psEncoded, m_ucEncodedData, 100);
        
        printf("Real Encoded Data: ");
        for(int i=0;i<50;i++)
        {
            printf("%d ", psEncoded[i]);
        }
        printf("\n");
        
        
        
        /*
        unsigned char c = m_ucEncodedData[0];
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
        
        //int iDecodedLen = CCodecAPI::GetInstance()->DecodeVideoFrame(m_ucEncodedData, iEncodedLen, m_ucDecodedData, iRecvHeight, iRecvWidth);
        
        //[self WriteToFile:m_ucDecodedData withLen:iDecodedLen];
        
        //[self WriteToFileWithPath:m_ucDecodedData withLen:iDecodedLen withPath:sOutputFilePath]; //can't get write access, ios doesn't permit
        int iDecodedLen;
        //fwrite(m_ucDecodedData, iDecodedLen, 1, fpOutputFile);
        
        printf("%d-->  iEncodedLen = %d, iDecodedLen = %d iHeight = %d, iWidth = %d\n", i, iEncodedLen, iDecodedLen,  iRecvHeight, iRecvWidth);
        
        //break;
        //if(i>300) break;
        
    }
     
    
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
        NSString *filePathyuv = [documentsDirectory stringByAppendingPathComponent:@"OutPut.yuv"];
        handle = [NSFileHandle fileHandleForUpdatingAtPath:filePathyuv];
        char *filePathcharyuv = (char*)[filePathyuv UTF8String];
        fpyuv = fopen(filePathcharyuv, "wb");
    }
    
    
    printf("Writing to yuv, iLen = %d\n", iLen);
    fwrite(pData, 1, iLen, fpyuv);
    
    
}

@end
