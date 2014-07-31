//
//  SNAppDelegate.m
//  SNReference
//
//  Created by Ryan Mannion on 11/17/11.
//  Copyright (c) 2011 Sonic Notify, Inc. All rights reserved.
//



#define LOG_OUTPUT(format, ...)             [self performSelectorOnMainThread:@selector(appendLog:) withObject:[NSString stringWithFormat:@"%@\n", [NSString stringWithFormat: format, ## __VA_ARGS__]] waitUntilDone:NO];
                                            


#ifdef DEBUG
#define LOG(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define LOG(format, ...) 
#endif

#import <Sonic/SonicContent.h>
#import <Sonic/SonicAudioHeardCode.h>
#import <Sonic/SonicBluetoothCodeHeard.h>
#import <Sonic/SonicCodeHeard.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/AudioServices.h>



@implementation NSMutableArray (ContainsString)
-(BOOL) containsString:(NSString*)string
{
	for (NSString* str in self) {
		if ([str isEqualToString:string])
			return YES;
	}
	return NO;
}
@end

@implementation SNAppDelegate

///////////////////////////
//  Default UI stuff    //
/////////////////////////
@synthesize window = _window;
@synthesize viewController = _viewController;

///////////////////////////
//  Customize UI stuff  //
/////////////////////////
@synthesize audioHeard = _audioHeard;           // Lable displaying audio heard
@synthesize bluetoothHeard = _bluetoothHeard;   // Lable displaying bluetooth heard
@synthesize apiSent = _apiSent;                 // Lable displaying API sent time
@synthesize startBtn = _startBtn;               // Button for starting listener
@synthesize stopBtn = _stopBtn;                 // Button for stopping listener

///////////////////////
//  Global Variable //
//////////////////////
@synthesize ApiCooldown = _ApiCooldown;             // Last API sent time
@synthesize AudioCooldown = _AudioCooldown;         // Last audio heard time
@synthesize BluetoothCooldown = _BluetoothCooldown; // Last Bluetooth heard time
@synthesize SId = _SId;                             // Last heard Sonic ID
@synthesize color = _color;                         // Last display color [Depricated]
@synthesize HeardStack = _HeardStack;               // Stack of heard Sonic ID, clears when API sent

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////
//  Start Button //
//////////////////
- (IBAction)start:(id)sender {
    [[Sonic sharedInstance] startListening];
    [self.startBtn setEnabled:false];
    [self.stopBtn setEnabled:true];
    LOG_OUTPUT(@"Started listening");
}

///////////////////
//  Stop Button //
/////////////////
- (IBAction)stop:(id)sender {
    [[Sonic sharedInstance] stopListening];
    [self.startBtn setEnabled:true];
    [self.stopBtn setEnabled:false];
    LOG_OUTPUT(@"Stopped listening");
}

///////////////////////////////////////////////////////////////////
//  Slider action: change the threshold and displaying lable    //
/////////////////////////////////////////////////////////////////
- (IBAction)sliderValueChanged:(id)sender {
    if (sender == _blueSlider) {
        _BlueThreshold = (double)_blueSlider.value;
        _blueValue.text = [NSString stringWithFormat:@"%d", (int)_blueSlider.value];
    }
    if (sender == _audioSlider) {
        _AudioThreshold = (double)_audioSlider.value;
        _audioValue.text = [NSString stringWithFormat:@"%d", (int)_audioSlider.value];
    }
    if (sender == _rssiSlider) {
        _rssiThreshold = (int)_rssiSlider.value;
        _rssiValue.text = [NSString stringWithFormat:@"%d", (int)_rssiSlider.value];
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
* The goal of this sample is to illustrate the power of the SonicCore SDK and illustrate the lifecycle of callbacks.
*
* @param launchOptions includes a disctionary of all the parameters used for launch
*/
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    /** This is the call that starts everything, simply pass your application GUID and off you go **/
    [[Sonic sharedInstance] initializeWithApplicationGUID:@"M2IyZmE4MzktYmQzNC00MWJiLWFhOWEtMGZhNjRmNWQ3NWNj"
                                              andDelegate:self];

    [[Sonic sharedInstance] startListening];
    
    // Custom initializer
    [self.startBtn setEnabled:false];
    _BlueThreshold = 10;    //Default bluetooth threshold time
    _AudioThreshold = 3;    //Default audio threshold time
    _rssiThreshold = -63;   ////Default rssi threshold
    _blueSlider.value = _BlueThreshold;
    _audioSlider.value = _AudioThreshold;
    _blueValue.text = [NSString stringWithFormat:@"%d", (int)_blueSlider.value];
    _audioValue.text = [NSString stringWithFormat:@"%d", (int)_audioSlider.value];
	self.HeardStack = [[NSMutableArray alloc] init];



    
    /** If you want to enable remote notifications then you should add this additional call **/
    //[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge |UIRemoteNotificationTypeSound)];

	/** If you are licensed to use custom payloads then the following code serves as an example of registering for those notifications **/
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedCustomPayload:) name:SonicNotificationCustomPayload object:nil];

    [self.window addSubview:self.viewController.view];
    [self.window makeKeyAndVisible];
    
	return YES;
}

/**
* When your application terminates it is important that you call stopListening, in the
* SonicUI library this is done for you, but not in the core library.
*
* @param application that is terminating
*/ 
- (void) applicationWillTerminate:(UIApplication *)application {
    [[Sonic sharedInstance] stopListening];
}

/**
* Cleanup the window and remove appropriate references, etc
*/ 
- (void)dealloc {
	self.window = nil;
    self.viewController = nil;
	self.textView = nil;
    
    [_startBtn release];
    [_stopBtn release];
    [_blueSlider release];
    [_audioSlider release];
    [_blueValue release];
    [_audioValue release];
    [_rssiSlider release];
    [_rssiValue release];
    [_vibrateSwitch release];
    [_rssiLevel release];
	[super dealloc];
}

#pragma mark Remote/Local Notification configuration

/**
* This is the callback that apple calls when a user successfully registers for remote notifications.  Once
* Apple responds, the token should be relayed to Sonic as shown below
* 
* @param app instance that the token was delivered for
* @param deviceTokenData is the raw data representation of the users device token used for push notifications
*/
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceTokenData { 
	[[Sonic sharedInstance] setRemoteNotificationToken:deviceTokenData];
}




/**
* If the user declines remote notifications then this method is called, Sonic does not need to know about this, but
* you should keep track
* 
* @param app is the instance that the failure occured for (opt-out)
* @param err the failure information
*/
 
- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err { 
	NSLog(@"ERROR: Remote notification registration failed - %@", err);
}


/**
 * When an iOS application receives a remote Notification this is the method that is called.  This needs to be relayed to Sonic so
 * that Sonic can monitor for pushes from the Sonic system and trigger the correct content.
 * 
 * @param application that triggered the call
 * @param userInfo that was received or triggered
 */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	[[Sonic sharedInstance] didReceiveRemoteNotification:userInfo];
}

#pragma mark Logging UI

- (void) appendLog: (NSString *) log {
    log = [NSString stringWithFormat:@"%@%@", log, self.textView.text];
    if ([log length] > 5000) 
        log = [log substringToIndex: 5000]; 

    self.textView.text = log;
    [self.textView setContentOffset:CGPointMake(0, 0) animated:YES];
}


#pragma mark Custopm Payload Example

- (void) receivedCustomPayload: (NSNotification *) notification {
    NSDictionary * userInfo = notification.userInfo;
    if ([userInfo objectForKey: SonicUserInfoChannelCode] && [userInfo objectForKey: SonicUserInfoCustomPayload]) {
		SonicId code = [[userInfo objectForKey: SonicUserInfoChannelCode] unsignedLongLongValue];
		int payload = [[userInfo objectForKey: SonicUserInfoCustomPayload] integerValue];
        LOG_OUTPUT(@"Received code %lld and custom payload %d", code, payload);
    }
}

#pragma mark Sonic Notify Delegate Implementation

// Depricated
- (void) flashApiBar
{
    while(true)
    {
        self.apiSent.backgroundColor = [UIColor redColor];
        usleep(500000);
        self.apiSent.backgroundColor = [UIColor grayColor];
        usleep(500000);
    }
}

///////////////////////////////////////////////////
//  Initializer for cooldowns and HeardStacks   //
/////////////////////////////////////////////////
- (void) coolDownUpdate
{
    NSDate *now = [NSDate date];
    NSString *init = @"-1";
    if (self.AudioCooldown == NULL)
    {
        self.AudioCooldown = [now dateByAddingTimeInterval:-10];
    }
    if (self.BluetoothCooldown == NULL)
    {
        self.BluetoothCooldown = [now dateByAddingTimeInterval:-10];
    }
    if (self.ApiCooldown == NULL)
    {
        self.ApiCooldown = [now dateByAddingTimeInterval:-10];
    }if(self.SId == NULL)
    {
        self.SId = init;
    }
    if(self.HeardStack == NULL)
    {
        self.HeardStack = [[NSMutableArray alloc] init];
    }
}

///////////////////////////////////////////////
//  Called when API was confirmed to send   //
//  type: AUDIO or BLUETOOTH               //
//  SonicHeard: Sonic ID                  //
///////////////////////////////////////////
- (void) apiCall:(NSString*) type with_code: (NSString *) SonicHeard
{
    // Format time sent for UI log
    NSDateFormatter *formatter;
    NSString        *dateString;
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    dateString = [formatter stringFromDate:[NSDate date]];
    
    // output: output to apiSent lable
    NSString *output = [NSString stringWithFormat:@"API sent in %@", dateString];
    self.apiSent.text = output;
    
    // logOutput: Augment output message and send to UI log
    NSString *logOutput = [NSString stringWithFormat:@"↓ %@ [%@]: %@", output, type, SonicHeard];
    LOG_OUTPUT(@"%@", logOutput);
    
    // If vibration switch is on AND in forground mode only, vibrate
    // Note: If app enter background and stop Sonic Listener, it cannot start again <- mic only, bluetooth still works
    BOOL forground = ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive);
    if (_vibrateSwitch.isOn && forground)
    {
        // If mic is on, vibration notification will not fire
        [[Sonic sharedInstance] stopListening];
        AudioServicesPlaySystemSound (1350); //RingerVibeChanged, works if currently silent
        AudioServicesPlaySystemSound (1351); //SilentVibeChanged, works if currently NOT silent
        [[Sonic sharedInstance] startListening];
    }
}


//////////////////////////////////////////////
//  Determine if it should send API or not //
//  type: AUDIO or BLUETOOTH              //
//  SonicHeard: Sonic ID                 //
//////////////////////////////////////////
- (void) apiSend: (NSString *) type with_code: (NSString *) SonicHeard
{
	[self coolDownUpdate]; // Initialization

	BOOL * tmp = false;
	tmp = [self.HeardStack containsString:SonicHeard];
    // In audio mode, if there is no previous identical ID heard, leave function
    if(false)//(![type isEqualToString:@"BLUETOOTH"] && tmp == NULL)
    {
		[self.HeardStack addObject:SonicHeard];
        return;
    }
    
	int SonicHeardInt = [SonicHeard integerValue];
	
	if((SonicHeardInt < 803000) ||  (SonicHeardInt > 805000))
	{
		LOG_OUTPUT(@"%@ is out of range(803XXX - 805XXX), drop", SonicHeard);
		return;
	}
	
    int flag = 0; // 0 = False, 1 = Audio, 2 = Bluetooth
    NSDate *now = [NSDate date];

    // Calculate time since last API sent from different mode
    double apiCool = [now timeIntervalSinceDate:self.ApiCooldown];
    double audioCool = [now timeIntervalSinceDate:self.AudioCooldown];
    double blueCool = [now timeIntervalSinceDate:self.BluetoothCooldown];
    
    // Only raise flag when it passes through the threshold time
    if (audioCool >= _AudioThreshold && [type isEqualToString:@"AUDIO"])
    {
        flag = 1;
    }else if (blueCool >= _BlueThreshold && [type isEqualToString:@"BLUETOOTH"])
    {
        flag = 2;
    }
    
    // Send API only if it is not the same ID of the last API sent or over 10 second threshold if it is the same ID
    if (apiCool >= 10 || ![self.SId isEqualToString:SonicHeard])
    {
        if (flag == 1)  // If it is audio
        {
            // Reset all cooldown time
            self.ApiCooldown = now;
            self.AudioCooldown = now;
            self.BluetoothCooldown = now;
            
            //  Send API
            [self apiCall:type with_code:SonicHeard];
            
            //  Release all heard stack and re-initialize
            [self.HeardStack release];
            self.HeardStack = [[NSMutableArray alloc] init];

            // Change API and corrisponding lable's color
            self.bluetoothHeard.backgroundColor = [UIColor grayColor];
            if ([self.SId isEqualToString:SonicHeard])  // If it is the same ID
            {
                    self.audioHeard.backgroundColor = [UIColor greenColor];
                    self.apiSent.backgroundColor = [UIColor greenColor];
                    self.color = false;
            }
            else    //  If it is a new ID
            {
                self.audioHeard.backgroundColor = [UIColor redColor];
                self.apiSent.backgroundColor = [UIColor redColor];

            }
            self.SId = SonicHeard; // Set last ID sent

        }else if (flag == 2)    // If it is bluetooth
        {
            // Reset all cooldown time
            self.ApiCooldown = now;
            self.AudioCooldown = now;
            self.BluetoothCooldown = now;
            
            //  Send API
            [self apiCall:type with_code:SonicHeard];
            
            //  Release all heard stack and re-initialize
            [self.HeardStack release];
            self.HeardStack = [[NSMutableArray alloc] init];


            
            self.audioHeard.backgroundColor = [UIColor grayColor];
            if ([self.SId isEqualToString:SonicHeard])  // If it is the same ID
            {
                    self.bluetoothHeard.backgroundColor = [UIColor greenColor];
                    self.apiSent.backgroundColor = [UIColor greenColor];
                    self.color = false;
            }else    // If it is a new ID
            {
                self.bluetoothHeard.backgroundColor = [UIColor redColor];
                self.apiSent.backgroundColor = [UIColor redColor];

            }
            self.SId = SonicHeard; // Set last ID sent


        }
    }else // Should not enter this case?
    {
        self.audioHeard.backgroundColor = [UIColor grayColor];
        self.bluetoothHeard.backgroundColor = [UIColor grayColor];
        self.apiSent.backgroundColor = [UIColor grayColor];
    }

    
}

/**
 * This is called when a sonic signal is heard and provides a GUID which is specific to this particular signal
 * only during the currently running process and provides the time interval as well if the signal has relative time.
 *
 * NOTE: this does not mean content is available
 *
 * @param sonic instance that heard the signal
 * @param code SonicCodeHeard Object for the value of the beacon
 *
 * @return whether or not you are interested in receiving content for this signal, it is the implementers responsibility for throttling
 *
 */
- (BOOL)sonic:(Sonic *)sonic didHearCode:(SonicCodeHeard *) code {
    
    if ([code isKindOfClass:[SonicBluetoothCodeHeard class]]){  // If heard code was by bluetooth
        SonicBluetoothCodeHeard * blueHeard = (SonicBluetoothCodeHeard *) code;
        LOG_OUTPUT(@"Did hear code %ld with [rssi = %d] [proximity = %d] [accuracy = %f]", blueHeard.beaconCode, blueHeard.rssiValue, blueHeard.proximity, blueHeard.accuracy);
        
        // Custom logic starts
        
        // Ratio of the rssi value v.s. threshold
        float progress = ((float)_rssiThreshold)/((float)blueHeard.rssiValue);
        _rssiLevel.progress = progress;
        
        NSString *blueCode = [NSString stringWithFormat:@"%ld", blueHeard.beaconCode]; //String value for heard ID
        
        // Add ID to the heard stack
        [self.HeardStack addObject:blueCode];
        
        // Check if it passes the rssi threshold or not
        if((blueHeard.rssiValue < (_rssiThreshold)) && (blueHeard.proximity == 0 || blueHeard.proximity == 3))
        {
            self.bluetoothHeard.text = @"Too Far";
            self.bluetoothHeard.backgroundColor = [UIColor grayColor];
            self.audioHeard.backgroundColor = [UIColor grayColor];
            self.apiSent.backgroundColor = [UIColor grayColor];
        }
        else    // If pass, go and check for cooldown time
        {
            self.bluetoothHeard.text = blueCode;
            [self apiSend:@"BLUETOOTH" with_code:blueCode];
        }


    }else if ([code isKindOfClass:[SonicAudioHeardCode class]]){    // If heard code was by audio
        SonicAudioHeardCode * audioHeard = (SonicAudioHeardCode *) code;
        LOG_OUTPUT(@"Did hear audio code %ld", audioHeard.beaconCode);
        
        NSString *audioCode = [NSString stringWithFormat:@"%ld", audioHeard.beaconCode]; //String value for heard ID
        self.audioHeard.text = audioCode;

        // Go and check for cooldown time
        [self apiSend:@"AUDIO" with_code:audioCode];


    }else{ // Sholuld not enter this case?
        LOG_OUTPUT(@"Did hear code %ld?", code.beaconCode);
        self.apiSent.text = @"--";
    }

    return YES;
}

- (void)sonic:(Sonic *)sonic didGeoFencesUpdated:(NSArray *)locations
{
	LOG_OUTPUT(@"Geo Fence Updated");
}


- (void)sonic:(Sonic *)sonic didGeoFenceEntered:(SonicLocation *)location
{
	LOG_OUTPUT(@"Geo Fence Entered");
	
	UIApplicationState state = [[UIApplication sharedApplication] applicationState];
	if(true)// (state != UIApplicationStateActive)
	{
		NSDate *now = [NSDate new];
		UILocalNotification *localNotif = [[UILocalNotification alloc] init];
		localNotif.fireDate = now;
		
		localNotif.timeZone=[NSTimeZone defaultTimeZone];
		localNotif.alertBody = [NSString stringWithFormat: @"You are now entering a Geo Fence"];
		localNotif.soundName = UILocalNotificationDefaultSoundName;
		
		localNotif.alertAction = NSLocalizedString(@"View Details", nil);
		localNotif.hasAction = YES; //是否显示额外的按钮，为no时alertAction消失
		
		
		localNotif.applicationIconBadgeNumber = 0;
		[[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
	}
	[[Sonic sharedInstance] startListening];

	
}

- (void)sonic:(Sonic *)sonic didGeoFenceExited:(SonicLocation *)location
{
	LOG_OUTPUT(@"Geo Fence Exited");
	
	UIApplicationState state = [[UIApplication sharedApplication] applicationState];
	if(TRUE)// (state != UIApplicationStateActive)
	{
		NSDate *now = [NSDate new];
		UILocalNotification *localNotif = [[UILocalNotification alloc] init];
		localNotif.fireDate = now;
		
		localNotif.timeZone=[NSTimeZone defaultTimeZone];
		localNotif.alertBody = [NSString stringWithFormat: @"You are now exiting a Geo Fence"];
		localNotif.soundName = UILocalNotificationDefaultSoundName;
		
		localNotif.alertAction = NSLocalizedString(@"View Details", nil);
		localNotif.hasAction = YES; //是否显示额外的按钮，为no时alertAction消失
		
		
		localNotif.applicationIconBadgeNumber = 0;
		[[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
	}
	[[Sonic sharedInstance] startListening];

	
}

/**
 * Did receive activations is called after URL#sonic:didHearCode:withTimeInterval returns YES.
 *
 * The server is then queried (or offline content prepared) and activations delivered
 *
 * @param sonic instance that received content
 * @param activations instances of SonicActivation that contain, delivery time, content, etc
 */
- (void) sonic: (Sonic *)sonic didReceiveActivations: (NSArray *) activations {
//    LOG_OUTPUT(@"Did receive activations: %@", activations);
}

/**
 * When offline content is receive by Sonic and cached internally (sonic only caches the raw data)
 * it is then passed to the delegate to have the implementing system cache whatever data is required.
 *
 * @param sonic instance that received content
 * @param contents is an array of SonicContent that needs to have application level caching completed
 */
- (void) sonic: (Sonic *)sonic cacheOfflineContent: (NSArray *) contents {
//    LOG_OUTPUT(@"Cache offline content: %@", contents);
}

/**
 * When content is no longer required to be cached this method is executed for individual pieces of content
 *
 * @param sonic instance that received content
 * @param identifier for content, this will match the SonicContent.identifier value provided in cacheOfflineContent
 */
- (void) sonic: (Sonic *)sonic deletedContentWithIdentifier: (NSInteger) identifier {
    LOG_OUTPUT(@"Delete content with ID: %i", identifier);
}




@end
