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
    brightness =  [[UIScreen mainScreen] brightness];
    
    self.central = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    self.data = [[NSMutableData alloc] init];

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
//****************** MOTION DETECTION RELATIVE
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
- (void)startDeviceMotion
{
    self.motionManager.accelerometerUpdateInterval  = 1.0/10.0; // Update at 10Hz
    if (self.motionManager.accelerometerAvailable) {
        NSLog(@"Accelerometer avaliable");
        queue = [NSOperationQueue currentQueue];
        [self.motionManager startDeviceMotionUpdatesToQueue:queue
                                            withHandler:^(CMDeviceMotion *motionData, NSError *error) {
                                                CMAcceleration userAcceleration = motionData.userAcceleration;

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
//*********** UI RELATED
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
-(void) createAndDisplayMPVolumeView
{
    [self.volumeView setBackgroundColor: [UIColor clearColor]];
    MPVolumeView *myVolumeView = [[MPVolumeView alloc] initWithFrame: self.volumeView.bounds];
    [self.volumeView addSubview: myVolumeView];
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
    [[UIScreen mainScreen] setBrightness: brightness];
}
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
//    CGPoint location = [recognizer locationInView:[recognizer.view superview]];
    if(isBlack==1)
    {
        if(tapCount>=4)
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
//******************** CBCENTRALMANAGER RELATED
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if ([central state] == CBCentralManagerStatePoweredOff) {
        NSLog(@"CoreBluetooth BLE hardware is powered off");
    }
    else if ([central state] == CBCentralManagerStatePoweredOn) {
        NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
        [self.central scanForPeripheralsWithServices:nil options:nil];
    }
    else if ([central state] == CBCentralManagerStateUnauthorized) {
        NSLog(@"CoreBluetooth BLE state is unauthorized");
    }
    else if ([central state] == CBCentralManagerStateUnknown) {
        NSLog(@"CoreBluetooth BLE state is unknown");
    }
    else if ([central state] == CBCentralManagerStateUnsupported) {
        NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
    }
}
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    
    if (self.peripheral != peripheral) {
        // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
        self.peripheral = peripheral;
        
        // And connect
        NSLog(@"Connecting to peripheral %@", peripheral);
        [self.central connectPeripheral:peripheral options:nil];
    }
}
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Failed to connect");
    [self cleanup];
}
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Connected");
    
    [self.central stopScan];
    NSLog(@"Scanning stopped");
    
    [self.data setLength:0];
    
    peripheral.delegate = self;
    
    [peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
   // [peripheral discoverServices:nil];
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        [self cleanup];
        return;
    }
    
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]] forService:service];
    //    [peripheral discoverCharacteristics:nil forService:service];
    }
    // Discover other characteristics
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        [self cleanup];
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error");
        return;
    }
    
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    // Have we got everything we need?
    if ([stringFromData isEqualToString:@"EOM"]) {
        
     //   [_textview setText:[[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding]];
        
        [peripheral setNotifyValue:NO forCharacteristic:characteristic];
        
        [self.central cancelPeripheralConnection:peripheral];
        
    }
    
    [self.data appendData:characteristic.value];
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
        return;
    }
    
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    } else {
        // Notification has stopped
        [self.central cancelPeripheralConnection:peripheral];
    }
}
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    self.peripheral = nil;
    
    [self.central scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
    //[self.central scanForPeripheralsWithServices:nil options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
}

- (void)cleanup {
    
    // See if we are subscribed to a characteristic on the peripheral
    if (self.peripheral.services != nil) {
        for (CBService *service in self.peripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
                        if (characteristic.isNotifying) {
                            [self.peripheral setNotifyValue:NO forCharacteristic:characteristic];
                            return;
                        }
                    }
                }
            }
        }
    }
    
    [self.central cancelPeripheralConnection:self.peripheral];
}
//******************* VIEWCONTROLLER RELATED
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
@end
