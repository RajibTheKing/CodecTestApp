//
//  ViewController.h
//  CodecTestApp
//
//  Created by Rajib Chandra Das on 6/21/16.
//  Copyright © 2016 Rajib Chandra Das. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <iostream>
#include <string>
using namespace std;

@interface ViewController : UIViewController
{
    unsigned char m_ucaDummmyFrame[10][352*288*3/2];
    unsigned char m_ucEncodedData[352*288*3/2];
    unsigned char m_ucDecodedData[352*288*3/2];
    unsigned char m_ucaInputData[1000*1000*90]; //almost 90 MB  size
    FILE *fpInputFile;
    FILE *fpOutputFile;
    FILE *fpyuv;
    FILE *fpWithPath;
    
    int m_iHeight;
    int m_iWidth;
    
    
}
@property (weak, nonatomic) IBOutlet UIButton *TestButton;



- (IBAction)TestButtonAction:(id)sender;

- (void)StartOperation;

-(void)WriteToFile:(unsigned char *)pData  withLen:(int)iLen;
- (void)OpenFileByName:(FILE **)fp withFileName:(NSString *)fileName;
-(long long)GetDataLenFromFile:(FILE **)fp;
-(void)EncodeDecodeFromH264File:(unsigned char *)pData withLen:(int) ilen;

-(void)EncodeDecodeFromYUVFile;

long long  CurrentTimestamp();

@end

