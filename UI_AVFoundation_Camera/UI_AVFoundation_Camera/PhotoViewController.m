//
//  PhotoViewController.m
//  UI_AVFoundation_Camera
//
//  Created by vincent on 16/3/1.
//  Copyright © 2016年 Vincent. All rights reserved.
//

#import "PhotoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
@interface PhotoViewController ()
@property (retain) AVCaptureSession *session;
@property (nonatomic,retain)AVCaptureDeviceInput *deviceInput;
@property (retain) AVCaptureStillImageOutput *captureOutput;
@property (retain) UIImage *image;
@property (assign) UIImageOrientation image_orientation;
@property (assign) AVCaptureVideoPreviewLayer *preview;
@property (weak, nonatomic) IBOutlet UIView *cameraView;

- (void) startRunning;
- (void) stopRunning;


@end

@implementation PhotoViewController


- (void) initialize
{
    //1.创建会话层
    self.session = [[AVCaptureSession alloc] init];
    [self.session setSessionPreset:AVCaptureSessionPresetPhoto];
    
    
    //2.创建、配置输入设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
#if 1
    int flags = NSKeyValueObservingOptionNew; //监听自动对焦
    [device addObserver:self forKeyPath:@"adjustingFocus" options:flags context:nil];
#endif
    
    NSError *error;
    self.deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (!self.deviceInput)
    {
        NSLog(@"Error: %@", error);
        return;
    }
    [self.session addInput:self.deviceInput];
    
    
    //3.创建、配置输出
    _captureOutput = [[AVCaptureStillImageOutput alloc] init] ;
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
    [_captureOutput setOutputSettings:outputSettings];
    

    [self.session addOutput:_captureOutput];
}
//对焦回调
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if( [keyPath isEqualToString:@"adjustingFocus"] ){
        BOOL adjustingFocus = [ [change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1] ];
        NSLog(@"Is adjusting focus? %@", adjustingFocus ? @"YES" : @"NO" );
        NSLog(@"Change dictionary: %@", change);
       
    }
}

-(void) embedPreview{
    if (!_session) return;
    //设置取景
    _preview = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _preview.frame = self.view.bounds;
    
    _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.cameraView.layer addSublayer: _preview];
}

//切换摄像头
-(void)toggleCamera:(AVCaptureDevicePosition)curDevicePosition{
    
    if (curDevicePosition == AVCaptureDevicePositionBack) {
        AVCaptureDevice *changeDevice;
        for (AVCaptureDevice *theDevice in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
            if (theDevice.position == AVCaptureDevicePositionFront) {
                changeDevice = theDevice;
            }
        }
        [_session beginConfiguration];
        [_session removeInput:self.deviceInput];
        
        self.deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:changeDevice error:nil];
        if ([_session canAddInput:self.deviceInput]) {
            [_session addInput:self.deviceInput];
        }
        
        [_session commitConfiguration];
        
    }else if(curDevicePosition == AVCaptureDevicePositionFront){
        AVCaptureDevice *changeDevice;
        for (AVCaptureDevice *theDevice in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
            if (theDevice.position == AVCaptureDevicePositionBack) {
                changeDevice = theDevice;
            }
        }
        [_session beginConfiguration];
        [_session removeInput:self.deviceInput];
        
        self.deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:changeDevice error:nil];
        if ([_session canAddInput:self.deviceInput]) {
            [_session addInput:self.deviceInput];
        }
        [_session commitConfiguration];
    }else{
        AVCaptureDevice *changeDevice;
        for (AVCaptureDevice *theDevice in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
            if (theDevice.position == AVCaptureDevicePositionBack) {
                changeDevice = theDevice;
            }
        }
        [_session beginConfiguration];
        [_session removeInput:self.deviceInput];
        
        self.deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:changeDevice error:nil];
        if ([_session canAddInput:self.deviceInput]) {
            [_session addInput:self.deviceInput];
        }
        [_session commitConfiguration];
    }
    
}

-(void)touchLightWithFlashMode:(AVCaptureFlashMode)flashMode{
    //改变设备的所有设置之前必须要加此句代码：_device lockForConfiguration:&error
    NSError *error;
    if ( [self.deviceInput.device lockForConfiguration:&error]) {
        [self.deviceInput.device setFlashMode:flashMode];
        
    }else{
        NSLog(@"error = %@",error.debugDescription);
    }
    
}

-(void)startRunning{
    
    [self.session startRunning];
}
-(void)stopRunning{
    
    [self.self stopRunning];
}

- (void)changePreviewOrientation:(UIDeviceOrientation)interfaceOrientation
{
    if (!_preview) {
        return;
    }
    [CATransaction begin];
    if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        _image_orientation = UIImageOrientationUp;
        _preview.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        
    }else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight){
        _image_orientation = UIImageOrientationDown;
        _preview.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
        
    }else if (interfaceOrientation == UIDeviceOrientationPortrait){
        _image_orientation = UIImageOrientationRight;
        _preview.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        
    }else if (interfaceOrientation == UIDeviceOrientationPortraitUpsideDown){
        _image_orientation = UIImageOrientationLeft;
        _preview.connection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
    }
    [CATransaction commit];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initialize];
    [self embedPreview];
    [self startRunning];
    
}



-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    [self changePreviewOrientation:[UIDevice currentDevice].orientation];
    
}
- (IBAction)exChangeAction:(id)sender {
    if (self.deviceInput.device.position == AVCaptureDevicePositionBack) {
        [self toggleCamera:AVCaptureDevicePositionBack];
    }else if(self.deviceInput.device.position == AVCaptureDevicePositionFront){
        [self toggleCamera:AVCaptureDevicePositionFront];
    }
    
}
- (IBAction)blinkLight:(id)sender {
    [self touchLightWithFlashMode:AVCaptureFlashModeOn];
    
}


- (IBAction)takePhoto:(id)sender {
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in _captureOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) { break; }
    }
    
    //get UIImage
    [_captureOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:
     ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
         CFDictionaryRef exifAttachments =
         CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
         if (exifAttachments) {
             // Do something with the attachments.
         }
         
         // Continue as appropriate.
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         UIImage *t_image = [UIImage imageWithData:imageData];
         UIImage * image = [[UIImage alloc]initWithCGImage:t_image.CGImage scale:1.0 orientation:_image_orientation];
         NSLog(@"image = %@",image);
         
         
     }];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
