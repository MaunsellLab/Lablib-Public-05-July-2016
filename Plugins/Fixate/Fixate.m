//
//  Fixate.m
//  Fixate
//
//  Created by John Maunsell on 12/23/04.
//  Copyright 2004. All rights reserved.
//

#import "FT.h"
#import "Fixate.h"
#import "FTSummaryController.h"
#import "FTXTController.h"

NSString *FTAcquireMSKey = @"FTAcquireMS";
NSString *FTDoFixateKey = @"FTDoFixate";
NSString *FTDoSoundsKey = @"FTDoSounds";
NSString *FTFixateJitterPCKey = @"FTFixateJitterPC";
NSString *FTFixateMSKey = @"FTFixateMS";
NSString *FTFixForeColorKey = @"FTFixForeColor";
NSString *FTFixBackColorKey = @"FTFixBackColor";
NSString *FTFixWindowWidthDegKey = @"FTFixWindowWidthDeg";
NSString *FTIntertrialMSKey = @"FTIntertrialMS";
NSString *FTRewardMSKey = @"FTRewardMS";
NSString *FTTaskModeKey = @"FTTaskMode";

LLScheduleController	*scheduler = nil;
FTStimuli				*stimuli = nil;

DataAssignment eyeRXDataAssignment = {@"eyeRXData",     @"Synthetic", 2, 5.0};	
DataAssignment eyeRYDataAssignment = {@"eyeRYData",     @"Synthetic", 3, 5.0};	
DataAssignment eyeRPDataAssignment = {@"eyeRPData",     @"Synthetic", 4, 5.0};	
DataAssignment eyeLXDataAssignment = {@"eyeLXData",     @"Synthetic", 5, 5.0};	
DataAssignment eyeLYDataAssignment = {@"eyeLYData",     @"Synthetic", 6, 5.0};	
DataAssignment eyeLPDataAssignment = {@"eyeLPData",     @"Synthetic", 7, 5.0};	
DataAssignment VBLDataAssignment = {@"VBLData",	@"Synthetic", 1, 1};	
DataAssignment spikeDataAssignment = {@"spikeData", @"Synthetic", 2, 1};

EventDefinition FTEvents[] = {	
	{@"taskMode", 			sizeof(long),			{@"long"}},
	{@"reset", 				sizeof(long),			{@"long"}}, 
};

LLTaskPlugIn	*task = nil;

@implementation Fixate

+ (NSInteger)version;
{
	return kLLPluginVersion;
}

// Start the method that will collect data from the event buffer

- (void)activate;
{ 
	NSMenu *mainMenu = [NSApp mainMenu];
	
	if (active) {
		return;
	}

// Insert Actions and Settings menus into menu bar
	 
	[mainMenu insertItem:actionsMenuItem atIndex:([mainMenu indexOfItemWithTitle:@"Tasks"] + 1)];
	[mainMenu insertItem:settingsMenuItem atIndex:([mainMenu indexOfItemWithTitle:@"Tasks"] + 1)];
	
// Clear the stimulus

	[stimuli erase];
	
// Create on-line display windows

	[dataDoc defineEvents:[LLStandardDataEvents eventsWithDataDefs] count:[LLStandardDataEvents countOfEventsWithDataDefs]];
	[dataDoc defineEvents:FTEvents count:(sizeof(FTEvents) / sizeof(EventDefinition))];

	[[controlPanel window] orderFront:self];

    eyeXYController = [[FTEyeXYController alloc] init];
    [dataDoc addObserver:eyeXYController];

    summaryController = [[FTSummaryController alloc] init];
    [dataDoc addObserver:summaryController];
 
	xtController = [[FTXTController alloc] init];
    [dataDoc addObserver:xtController];


// Set up the data collector to handle our data types

	[dataController assignSampleData:eyeRXDataAssignment];
	[dataController assignSampleData:eyeRYDataAssignment];
	[dataController assignSampleData:eyeRPDataAssignment];
	[dataController assignSampleData:eyeLXDataAssignment];
	[dataController assignSampleData:eyeLYDataAssignment];
	[dataController assignSampleData:eyeLPDataAssignment];
//	[dataController assignTimestampData:leverDataAssignment];
	[dataController assignTimestampData:VBLDataAssignment];
	[dataController assignTimestampData:spikeDataAssignment];
	[dataController assignDigitalInputDevice:@"Synthetic"];
	[dataController assignDigitalOutputDevice:@"Synthetic"];

	collectorTimer = [NSTimer scheduledTimerWithTimeInterval:kSamplePeriodS target:self 
			selector:@selector(dataCollect:) userInfo:nil repeats:YES];

	[dataDoc addObserver:stateSystem];
    [stateSystem startWithCheckIntervalMS:5];				// Start the experiment state system
	
	active = YES;
}

// The following function is called after the nib has finished loading.  It is the correct
// place to initialize nib related components, such as menus.

- (void)awakeFromNib;
{
	if (actionsMenuItem == nil) {
		actionsMenuItem = [[NSMenuItem alloc] init]; 
		[actionsMenu setTitle:@"Actions"];
		[actionsMenuItem setSubmenu:actionsMenu];
		[actionsMenuItem setEnabled:YES];
	}
	if (settingsMenuItem == nil) {
		settingsMenuItem = [[NSMenuItem alloc] init]; 
		[settingsMenu setTitle:@"Settings"];
		[settingsMenuItem setSubmenu:settingsMenu];
		[settingsMenuItem setEnabled:YES];
	}
}

- (void)dataCollect:(NSTimer *)timer;
{
	NSData *data;
	short *pEyeData;
	
	if ((data = [dataController dataOfType:@"eyeLXData"]) != nil) {
		[dataDoc putEvent:@"eyeLXData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
		currentEyesUnits[kLeftEye].x = *(short *)([data bytes] + [data length] - sizeof(short));
	}
	if ((data = [dataController dataOfType:@"eyeLYData"]) != nil) {
		[dataDoc putEvent:@"eyeLYData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
		currentEyesUnits[kLeftEye].y = *(short *)([data bytes] + [data length] - sizeof(short));
		currentEyesDeg[kLeftEye] = [[task eyeCalibrator] degPointFromUnitPoint:currentEyesUnits[kLeftEye] forEye:kLeftEye];
	}
	if ((data = [dataController dataOfType:@"eyeLPData"]) != nil) {
		[dataDoc putEvent:@"eyeLPData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
	}
	if ((data = [dataController dataOfType:@"eyeRXData"]) != nil) {
		[dataDoc putEvent:@"eyeRXData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
		currentEyesUnits[kRightEye].x = *(short *)([data bytes] + [data length] - sizeof(short));
	}
	if ((data = [dataController dataOfType:@"eyeRYData"]) != nil) {
		[dataDoc putEvent:@"eyeRYData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
		currentEyesUnits[kRightEye].y = *(short *)([data bytes] + [data length] - sizeof(short));
		currentEyesDeg[kRightEye] = [[task eyeCalibrator] degPointFromUnitPoint:currentEyesUnits[kRightEye]
                                                                         forEye:kRightEye];
	}
	if ((data = [dataController dataOfType:@"eyeRPData"]) != nil) {
		[dataDoc putEvent:@"eyeRPData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
	}
	if ((data = [dataController dataOfType:@"VBLData"]) != nil) {
		[dataDoc putEvent:@"VBLData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
	}
	if ((data = [dataController dataOfType:@"spikeData"]) != nil) {
		[dataDoc putEvent:@"spikeData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
	}
}
		
- (void)deactivate:(id)sender;
{
	if (!active) {
		return;
	}
	
// Stop data collection

    [dataController setDataEnabled:[NSNumber numberWithBool:NO]];
    [stateSystem stop];
	[collectorTimer invalidate];
    [dataDoc removeObserver:stateSystem];
    [dataDoc removeObserver:eyeXYController];
    [dataDoc removeObserver:summaryController];
    [dataDoc removeObserver:xtController];
	[dataDoc clearEventDefinitions];

// Remove Actions and Settings menus from menu bar
	 
	[[NSApp mainMenu] removeItem:settingsMenuItem];
	[[NSApp mainMenu] removeItem:actionsMenuItem];

// Release all the display windows

    [eyeXYController deactivate];		// requires special method
    [eyeXYController release];
    [summaryController close];
    [summaryController release];
    [xtController close];
    [xtController release];
    [[controlPanel window] close];
	
	active = NO;
}

- (void)dealloc;
{
    while ([stateSystem running]) {};		// wait for state system to stop, then release it
    [stateSystem release];
	
	[actionsMenuItem release];
	[settingsMenuItem release];
	
	[scheduler release];
	[stimuli release];
	[controlPanel release];
    [topLevelObjects release];

	[[NSNotificationCenter defaultCenter] removeObserver:self]; 

	[super dealloc];
}

- (void)doControls:(NSNotification *)notification;
{
	if ([[notification name] isEqualToString:LLTaskModeButtonKey]) {
		[self doRunStop:self];
	}
	else if ([[notification name] isEqualToString:LLJuiceButtonKey]) {
		[self doJuice:self];
	}
	if ([[notification name] isEqualToString:LLResetButtonKey]) {
		[self doReset:self];
	}
}

- (IBAction)doFixSettings:(id)sender;
{
	[[stimuli fixSpot] runSettingsDialog];
}

- (IBAction)doJuice:(id)sender;
{
	long juiceMS;
	NSSound *juiceSound;
	
	juiceMS = [[NSUserDefaults standardUserDefaults] integerForKey:FTRewardMSKey];
	[[task dataController] digitalOutputBitsOff:kRewardBit];
	[scheduler schedule:@selector(doJuiceOff) toTarget:self withObject:Nil delayMS:juiceMS];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:FTDoSoundsKey]) {
		juiceSound = [NSSound soundNamed:@"Correct"];
		if ([juiceSound isPlaying]) {   // won't play again if it's still playing
			[juiceSound stop];
		}
		[juiceSound play];			// play juice sound
	}
}

- (void)doJuiceOff;
{
	[[task dataController] digitalOutputBitsOn:kRewardBit];
}

- (IBAction)doReset:(id)sender;
{
    long resetType = 0;
    
	[dataDoc putEvent:@"reset" withData:&resetType];
}

- (IBAction)doRunStop:(id)sender;
{
	long newMode;
	
    switch ([taskStatus mode]) {
    case kTaskIdle:
		newMode = kTaskRunning;
        break;
    case kTaskRunning:
		newMode = kTaskStopping;
        break;
    case kTaskStopping:
    default:
		newMode = kTaskIdle;
        break;
    }
	[self setMode:newMode];
}

// After our -init is called, the host will provide essential pointers such as
// defaults, stimWindow, eyeCalibrator, etc.  Only after those are initialized, the
// following method will be called.  We therefore defer most of our initialization here

- (void)initializationDidFinish;
{
	NSString *userDefaultsValuesPath;
    NSDictionary *userDefaultsValuesDict;
	
	task = self;
	
// Register our default settings. This should be done first thing, before the
// nib is loaded, because items in the nib are linked to defaults

	[LLSystemUtil registerDefaultsFromFilePath:
			[[NSBundle bundleForClass:[self class]] pathForResource:@"UserDefaults" ofType:@"plist"] defaults:defaults];

// Set up the task mode object.  We need to do this before loading the nib,
// because some items in the nib are bound to the task mode. We also need
// to set the mode, because the value in defaults will be the last entry made
// which is typically kTaskEnding.

	taskStatus = [[LLTaskStatus alloc] init];
	[taskStatus setMode:kTaskIdle];
	stimuli = [[FTStimuli alloc] init];

// Load the items in the nib

    [[NSBundle bundleForClass:[self class]] loadNibNamed:@"Fixate" owner:self topLevelObjects:&topLevelObjects];
    [topLevelObjects retain];
	
// Initialize other task objects

	scheduler = [[LLScheduleController alloc] init];
	stateSystem = [[FTStateSystem alloc] init];

// Set up control panel and observer for control panel

	controlPanel = [[LLControlPanel alloc] init];
	[controlPanel setWindowFrameAutosaveName:@"FTControlPanel"];
	[[controlPanel window] setFrameUsingName:@"FTControlPanel"];
	[[controlPanel window] setTitle:@"Fixate"];
	[[NSNotificationCenter defaultCenter] addObserver:self 
		selector:@selector(doControls:) name:nil object:controlPanel];
}

- (long)mode;
{
	return [taskStatus mode];
}

- (NSString *)name;
{
	return @"Fixate";
}
/*
- (NSNumber *)pluginVersion; 
{
	return [NSNumber numberWithLong:kLLPluginVersion];
}
*/
- (void)setMode:(long)newMode;
{
	[taskStatus setMode:newMode];
	[controlPanel setTaskMode:[taskStatus mode]];
	[dataDoc putEvent:@"taskMode" withData:&newMode];
	switch ([taskStatus mode]) {
	case kTaskRunning:
	case kTaskStopping:
		[runStopMenuItem setKeyEquivalent:@"."];
		break;
	case kTaskIdle:
		[runStopMenuItem setKeyEquivalent:@"r"];
		break;
	default:
		break;
	}
}
// Respond to changes in the stimulus settings

- (void)setWritingDataFile:(BOOL)state;
{
	if ([taskStatus dataFileOpen] != state) {
		[taskStatus setDataFileOpen:state];
		if ([taskStatus dataFileOpen]) {
//			announceEvents();
			[controlPanel displayFileName:[[[dataDoc filePath] lastPathComponent] 
												stringByDeletingPathExtension]];
			[controlPanel setResetButtonEnabled:NO];
		}
		else {
			[controlPanel displayFileName:@""];
			[controlPanel setResetButtonEnabled:YES];
		}
	}
}

- (FTStimuli *)stimuli;
{
	return stimuli;
}
@end
