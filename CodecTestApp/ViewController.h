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
    FILE *fpyuv;
    FILE *fpWithPath;
    
    
}
@property (weak, nonatomic) IBOutlet UIButton *TestButton;



- (IBAction)TestButtonAction:(id)sender;

- (void)StartOperation;

-(void)WriteToFile:(unsigned char *)pData  withLen:(int)iLen;
-(void)WriteToFileWithPath:(unsigned char *)pData  withLen:(int)iLen withPath:(string)sPath;
long long  CurrentTimestamp();

@end

