//
//  SNAppDelegate.h
//  SNReference
//
//  Created by Ryan Mannion on 11/17/11.
//  Copyright (c) 2011 Sonic Notify, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#import <Sonic/Sonic.h>

@interface SNAppDelegate : NSObject <UIApplicationDelegate, UINavigationControllerDelegate, SonicDelegate> {
	UIViewController * _viewController;
    UITextView * _textView;
    UIWindow * _window;
    
    
    UILabel * _audioHeard;
    UILabel * _bluetoothHeard;
    UILabel * _apiSent;
    UIButton *_startBtn;
    UIButton *_stopBtn;
    UISlider *_blueSlider;
    UISlider *_audioSlider;
    UISlider *_rssiSlider;
    UILabel *_blueValue;
    UILabel *_audioValue;
    UILabel *_rssiValue;
    UISwitch *_vibrateSwitch;
    UIProgressView *_rssiLevel;
    
    NSDate *_ApiCooldown;
    NSDate *_AudioCooldown;
    NSDate *_BluetoothCooldown;
    NSString *_SId;
    NSMutableArray *_HeardStack;
    BOOL *_color;
    double _BlueThreshold;
    double _AudioThreshold;
    int _rssiThreshold;
}


// Default IBOutlet
@property (nonatomic, retain) IBOutlet UIWindow * window;
@property (nonatomic, retain) IBOutlet UIViewController * viewController;
@property (nonatomic, retain) IBOutlet UITextView * textView;


////////////////////////////
//  Customize IBOutlet   //
//////////////////////////
@property (strong, nonatomic) IBOutlet UILabel *audioHeard;
@property (strong, nonatomic) IBOutlet UILabel *bluetoothHeard;
@property (strong, nonatomic) IBOutlet UILabel *apiSent;

@property (retain, nonatomic) IBOutlet UIButton *startBtn;
@property (retain, nonatomic) IBOutlet UIButton *stopBtn;

// Slider Group
@property (retain, nonatomic) IBOutlet UISlider *blueSlider;
@property (retain, nonatomic) IBOutlet UISlider *audioSlider;
@property (retain, nonatomic) IBOutlet UISlider *rssiSlider;
@property (retain, nonatomic) IBOutlet UILabel *blueValue;
@property (retain, nonatomic) IBOutlet UILabel *audioValue;
@property (retain, nonatomic) IBOutlet UILabel *rssiValue;

// Vibration switch
@property (retain, nonatomic) IBOutlet UISwitch *vibrateSwitch;

// Rssi ratio bar
@property (retain, nonatomic) IBOutlet UIProgressView *rssiLevel;

/////////////////////////
//  Global Variables  //
///////////////////////
@property (nonatomic, retain) NSDate *ApiCooldown;
@property (nonatomic, retain) NSDate *AudioCooldown;
@property (nonatomic, retain) NSDate *BluetoothCooldown;
@property (nonatomic, retain) NSString *SId;
@property (nonatomic, retain) NSMutableArray *HeardStack;
@property ( nonatomic) BOOL *color;

@end


