//
//  ViewController.m
//  iGuard
//
//  Created by Paulo Fernandes on 25/08/14.
//  Copyright (c) 2014 Paulo Fernandes. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // INITIALIZE FLAGS
    hasHorn = 0;
    counter = 5;
    tapCount = 0;
    isBlack = 0;
    viewColor = self.movingView.backgroundColor;
    
    self.central = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    self.data = [[NSMutableData alloc] init];
    [self.central scanForPeripheralsWithServices:nil options:nil];

    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [self.startBtn addTarget:self action:@selector(pressButton) forControlEvents:UIControlEventTouchUpInside];
    [self createAndDisplayMPVolumeView];
    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.movingView addGestureRecognizer:singleFingerTap];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(CMMotionManager *)motionManager
{
    CMMotionManager *motionManager = nil;
    
    id appDelegate = [UIApplication sharedApplication].delegate;
    
    if([appDelegate respondsToSelector:@selector(motionManager)])
    {
        motionManager = [appDelegate motionManager];
    }
    
    return motionManager;
}

- (void)startMyMotionDetect
{
    
    __block float stepMoveFactor = 15;
    
    [self.motionManager
     startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc] init]
     withHandler:^(CMAccelerometerData *data, NSError *error)
     {
         
         dispatch_async(dispatch_get_main_queue(),
                        ^{
                            
                            CGRect rect = self.movingView.frame;
                            
                            float movetoX = rect.origin.x + (data.acceleration.x * stepMoveFactor);
                            float maxX = self.view.frame.size.width - rect.size.width;
                            
                            float movetoY = (rect.origin.y + rect.size.height)
                            - (data.acceleration.y * stepMoveFactor);
                            
                            float maxY = self.view.frame.size.height;
                            
                        /*    self.labelX.text = [NSString stringWithFormat:@"%f", data.acceleration.x];
                            self.labelY.text = [NSString stringWithFormat:@"%f", data.acceleration.y];
                            self.labelZ.text = [NSString stringWithFormat:@"%f", data.acceleration.z];*/
                            
                            
                            if ( movetoX > 0 && movetoX < maxX ) {
                                rect.origin.x += (data.acceleration.x * stepMoveFactor);
                                
                            };
                            
                            if ( movetoY > 0 && movetoY < maxY ) {
                                rect.origin.y -= (data.acceleration.y * stepMoveFactor);
                            };
                            
                            [UIView animateWithDuration:0 delay:0
                                                options:UIViewAnimationCurveEaseInOut
                                             animations:
                             ^{
                                 self.movingView.frame = rect;
                             }
                                             completion:nil
                             ];
                            
                        }
                        );
     }
     ];
    
}
- (void)startDeviceMotion
{
    self.motionManager.accelerometerUpdateInterval  = 1.0/10.0; // Update at 10Hz
    if (self.motionManager.accelerometerAvailable) {
        NSLog(@"Accelerometer avaliable");
        queue = [NSOperationQueue currentQueue];
        [self.motionManager startDeviceMotionUpdatesToQueue:queue
                                            withHandler:^(CMDeviceMotion *motionData, NSError *error) {
//                                                CMAttitude *attitude = motionData.attitude;
  //                                              CMAcceleration gravity = motionData.gravity;
                                                CMAcceleration userAcceleration = motionData.userAcceleration;
    //                                            CMRotationRate rotate = motionData.rotationRate;
      //                                          CMCalibratedMagneticField field = motionData.magneticField;
                                                
                                                /*self.labelX.text = [NSString stringWithFormat:@"%f", userAcceleration.x];
                                                self.labelY.text = [NSString stringWithFormat:@"%f", userAcceleration.y];
                                                self.labelZ.text = [NSString stringWithFormat:@"%f", userAcceleration.z];*/
                                                
                                                if((userAcceleration.x > (self.sensitivitySlider.value/5) || userAcceleration.y > (self.sensitivitySlider.value/5) || userAcceleration.z > (self.sensitivitySlider.value/5)) && isRunning==1 )
                                                {
                                                    self.labelWarning.text = @"ALERT!";
                                                    self.labelWarning.textColor = [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:1.0f];
                                                    [self playHorn];
                                                }
                                                else if(isRunning==1){
                                                    self.labelWarning.text = @"OK";
                                                    self.labelWarning.textColor = [UIColor colorWithRed:0.0f green:1.0f blue:0.0f alpha:1.0f];
                                                }
//                                                 NSLog([NSString stringWithFormat:@"%f",gravity.x]);
                                            }];
        
    }
}
- (void)playHorn
{
    if(hasHorn==0 && isRunning==1){
        NSURL *soundURL = [[NSBundle mainBundle] URLForResource:@"siren"
                                                  withExtension:@"mp3"];
        avSound = [[AVAudioPlayer alloc]
                   initWithContentsOfURL:soundURL error:nil];
        [avSound setNumberOfLoops:100];
        [avSound setVolume:1.0];
        [avSound play];
        hasHorn=1;
        
        NSError *error;
        [[AVAudioSession sharedInstance] setActive: YES error: nil];
        BOOL success = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&error];
        if (!success) {
            //Handle error
            NSLog(@"%@", [error localizedDescription]);
        } else {
            // Yay! It worked!      
        }
    }
}
- (void)pressButton{
    if(isRunning==0)
    {
        timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerFired) userInfo:nil repeats:YES];
        [self.startBtn setTitle:@"STOP" forState:UIControlStateNormal];
    }
    else
    {
        if(hasHorn==1)
        {
            [avSound stop];
        }
        isRunning=0;
        hasHorn=0;
        counter = 5;
        [self.startBtn setTitle:@"STAY ALLERT" forState:UIControlStateNormal];
    }

}
-(void)timerFired
{
    if(counter>0)
    {
        self.labelWarning.text =[NSString stringWithFormat:@"%d", counter];
        counter--;
    }
    else{
        isRunning=1;
        [timer invalidate];
        self.labelWarning.text =@"OK";
        [self startDeviceMotion];
        counter=5;
        [self blackify];
    }
}
- (void)blackify{
    isBlack = 1;
    CGRect rect = self.movingView.frame;
    rect.origin.y=0;
    rect.size.height = [UIScreen mainScreen].bounds.size.height;
    self.movingView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f];
    [UIView animateWithDuration:0.5f animations:^{
       // self.movingView.frame = CGRectOffset(self.movingView.frame, 0, 50);
        self.movingView.frame = rect;
    }];
    [[UIScreen mainScreen] setBrightness: 0.0f];
    
}
-(void)unBlackify{
    isBlack = 0;
    CGRect rect = self.movingView.frame;
    rect.origin.y=[UIScreen mainScreen].bounds.size.height-13;
    rect.size.height = 13;
    self.movingView.backgroundColor = viewColor;
    [UIView animateWithDuration:0.5f animations:^{
        self.movingView.frame = rect;
    }];
    [[UIScreen mainScreen] setBrightness: 1.0f];
}
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
//    CGPoint location = [recognizer locationInView:[recognizer.view superview]];
    if(isBlack==1)
    {
        if(tapCount>=5)
        {
            [self unBlackify];
            tapCount=0;
        }
        else
        {
            tapCount++;
        }
    }
    
     NSLog(@"tapped");
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
   // [self setupLocalNotifications];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
}
- (void)viewDidDisappear:(BOOL)animated
{
    
    [super viewDidDisappear:animated];
    
    [self.motionManager stopAccelerometerUpdates];
    
}
- (void)applicationDidEnterBackground:(UIApplication *)application
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = [[NSDate date] dateByAddingTimeInterval:1];
    notification.alertBody = @"24 hours passed since last visit :(";
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}
- (void)setupLocalNotifications {
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    
    // current time plus 10 secs
    NSDate *now = [NSDate date];
    NSDate *dateToFire = [now dateByAddingTimeInterval:5];
    
    NSLog(@"now time: %@", now);
    NSLog(@"fire time: %@", dateToFire);
    
    localNotification.fireDate = dateToFire;
    localNotification.alertBody = @"Time to get up!";
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.applicationIconBadgeNumber = 1; // increment
    
    NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:@"Object 1", @"Key 1", @"Object 2", @"Key 2", nil];
    localNotification.userInfo = infoDict;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

-(void) createAndDisplayMPVolumeView
{
    // Create a simple holding UIView and give it a frame
  //  self.volumeView = [[UIView alloc] initWithFrame: CGRectMake(30, 100, 260, 20)];
    
    // set the UIView backgroundColor to clear.
    [self.volumeView setBackgroundColor: [UIColor clearColor]];
    
    // add the holding view as a subView of the main view
//    [self.view addSubview: volumeHolder];
    
    // Create an instance of MPVolumeView and give it a frame
    MPVolumeView *myVolumeView = [[MPVolumeView alloc] initWithFrame: self.volumeView.bounds];
    
    
    // Add myVolumeView as a subView of the volumeHolder
   [self.volumeView addSubview: myVolumeView];
}
@end
