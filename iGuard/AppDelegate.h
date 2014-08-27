//
//  AppDelegate.h
//  iGuard
//
//  Created by Paulo Fernandes on 25/08/14.
//  Copyright (c) 2014 Paulo Fernandes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import <AudioToolbox/AudioToolbox.h>

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>{
    CMMotionManager * motionManager;
    
}

@property (readonly) CMMotionManager * motionManager;

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ViewController *viewController;

@end
