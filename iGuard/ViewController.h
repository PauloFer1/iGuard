//
//  ViewController.h
//  iGuard
//
//  Created by Paulo Fernandes on 25/08/14.
//  Copyright (c) 2014 Paulo Fernandes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "SERVICES.h"

@interface ViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate>
{
    NSOperationQueue *queue;
    SystemSoundID sound1;
    AVAudioPlayer *avSound;
    NSTimer *timer;
    UIColor *viewColor;
    BOOL shouldHideStatusBar;
    
    int hasHorn;
    int isRunning;
    int counter;
    int tapCount;
    int isBlack;
    float sensitivity;
    float brightness;
}

//@property (weak, nonatomic) IBOutlet UIView *movingView;
@property (weak, nonatomic) IBOutlet UIView *movingView;
@property (weak, nonatomic) IBOutlet UILabel *labelWarning;
@property (weak, nonatomic) IBOutlet UIButton *startBtn;
@property (weak, nonatomic) IBOutlet UIView *volumeView;
@property (weak, nonatomic) IBOutlet UISlider *sensitivitySlider;
@property (strong, nonatomic) CBCentralManager *central;
@property (strong, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) NSMutableData *data;

@end
