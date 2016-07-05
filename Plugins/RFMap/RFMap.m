//
//  RFMap.m
//  RFMap
//
//  Created by John Maunsell on 12/30/04.
//  Copyright 2004. All rights reserved.
//

#import "RF.h"
#import "RFMap.h"
#import "RFSummaryController.h"
#import "RFXTController.h"

#define kPI          		(atan(1) * 4)
#define kDegPerRadian		(180.0 / kPI)
#define kPositionUpdateS	0.25

NSString *RFAcquireMSKey = @"RFAcquireMS";
NSString *RFDisplayModeKey = @"RFDisplayMode";
NSString *RFDisplayUnitsKey = @"RFDisplayUnits";
NSString *RFDoFixateKey = @"RFDoFixate";
NSString *RFDoGridKey = @"RFDoGrid";
NSString *RFDoSoundsKey = @"RFDoSounds";
NSString *RFFixateMSKey = @"RFFixateMS";
NSString *RFFixSpotAzimuthDegKey = @"RFFixSpotAzimuthDeg";
NSString *RFFixSpotElevationDegKey = @"RFFixSpotElevationDeg";
NSString *RFFixSpotRadiusDegKey = @"RFFixSpotRadiusDeg";
NSString *RFFixWindowWidthDegKey = @"RFFixWindowWidthDeg";
NSString *RFGridSpacingDegKey = @"RFGridSpacingDeg";
NSString *RFIntertrialMSKey = @"RFIntertrialMS";
NSString *RFMeanFixateMSKey = @"RFMeanFixateMS";
NSString *RFRewardMSKey = @"RFRewardMS";
NSString *RFStimTypeKey = @"RFStimType";
NSString *RFTaskStatusKey = @"RFTaskStatus";

// Stimulus Settings

NSString *RFDoMouseGateKey = @"RFDoMouseGate";
NSString *RFOrientationStepDegKey = @"RFOrientationStepDeg";
NSString *RFSizeFactorKey = @"RFSizeFactor";
NSString *RFWidthFactorKey = @"RFWidthFactor";

long					behaviorMode = kBehaviorRunning;
BOOL					resetFlag = NO;
LLScheduleController	*scheduler = nil;
RFMapStimuli			*stimuli = nil;

DataAssignment eyeDataAssignment[] = {
									{@"eyeData",	@"Synthetic", 0, 5.0},
									{nil,			@"Synthetic", 1, 5.0}};
DataAssignment leverDataAssignment = {@"leverData",	@"Synthetic", 0, 1};	
DataAssignment VBLDataAssignment = {@"VBLData",	@"Synthetic", 1, 1};	
DataAssignment spikeDataAssignment = {@"spikeData", @"Synthetic", 2, 1};

LLDataDef stimCenterStructDef[] = {
	{@"float",	@"azimuthDeg", 1, offsetof(StimCenter, azimuthDeg)},
	{@"float",	@"elevationDeg", 1, offsetof(StimCenter, elevationDeg)},
	{nil}};

EventDefinition RFEvents[] = {
	{@"stimCenter",			sizeof(StimCenter),	{@"struct", @"stimCenter", 1, 0, sizeof(StimCenter), stimCenterStructDef}},
	{@"stimulusType", 		sizeof(long),			{@"long"}},
	{@"taskMode", 			sizeof(long),			{@"long"}},
	{@"reset",				sizeof(long),			{@"long"}},
};

LLTaskPlugIn	*task = nil;

@implementation RFMap

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
	
// Erase the stimulus display

	[stimuli erase];
	
// Create on-line display windows

	[dataDoc defineEvents:[LLStandardDataEvents eventsWithDataDefs] count:[LLStandardDataEvents countOfEventsWithDataDefs]];
	[[task dataDoc] defineEvents:RFEvents count:(sizeof(RFEvents) / sizeof(EventDefinition))];

	[[controlPanel window] orderFront:self];
	
    eyeXYController = [[RFEyeXYController alloc] init];
    [[task dataDoc] addObserver:eyeXYController];

    summaryController = [[RFSummaryController alloc] init];
    [[task dataDoc] addObserver:summaryController];
 
	xtController = [[RFXTController alloc] init];
    [[task dataDoc] addObserver:xtController];
	[dataController assignGroupedSampleData:eyeDataAssignment groupCount:2];
	[dataController assignTimestampData:VBLDataAssignment];
	[dataController assignTimestampData:spikeDataAssignment];
	[dataController assignDigitalInputDevice:@"Synthetic"];
	[dataController assignDigitalOutputDevice:@"Synthetic"];
	collectorTimer = [NSTimer scheduledTimerWithTimeInterval:kSamplePeriodS target:self 
			selector:@selector(dataCollect:) userInfo:nil repeats:YES];

	[[task dataDoc] addObserver:stateSystem];
    [stateSystem startWithCheckIntervalMS:5];				// Start the experiment state system
	
// Most users want the fixation spot to hold still during RFMap, so we set it to zero 
// here, and restore it when we exit

	originalFixOffsetDeg = [[task eyeCalibrator] calibrationOffsetDeg];
	[[task eyeCalibrator] setCalibrationOffsetDeg:0.0];

// Set up a timer to display azimuth and elevation

	displayTimer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:kPositionUpdateS target:self 
			selector:@selector(displayPosition:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:displayTimer forMode:NSDefaultRunLoopMode];
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
	
	if ((data = [dataController dataOfType:@"eyeData"]) != nil) {
		[dataDoc putEvent:@"eyeData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
		pEyeData = (short *)([data bytes] + [data length] - 2 * sizeof(short));
		currentEyeDeg = [[task eyeCalibrator] degPointFromUnitPoint:NSMakePoint(pEyeData[0], pEyeData[1])];
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
	[collectorTimer invalidate];
	[displayTimer invalidate];
	[displayTimer release];
	
// Stop the state system, which will stop the stimulus

    [stateSystem stop];
	while ([stateSystem running]) {};

    [[task dataDoc] removeObserver:stateSystem];
    [[task dataDoc] removeObserver:eyeXYController];
    [[task dataDoc] removeObserver:summaryController];
    [[task dataDoc] removeObserver:xtController];
	[[task dataDoc] clearEventDefinitions];

// Remove Actions and Settings menus from menu bar
	 
	[[NSApp mainMenu] removeItem:settingsMenuItem];
	[[NSApp mainMenu] removeItem:actionsMenuItem];

// Release all the display windows

    [eyeXYController deactivate];								// requires a special method
    [eyeXYController release];
    [summaryController close];
    [summaryController release];
    [xtController close];
    [xtController release];
	[controlPanel displayText:@""];								// need to collapse control panel 
    [[controlPanel window] close];								//  for autosave frames to be correct

// Restore the eye calibration to its original value

	[[task eyeCalibrator] setCalibrationOffsetDeg:originalFixOffsetDeg];

	active = NO;
}

- (void)dealloc;
{
    while ([stateSystem running]) {};		// wait for state system to stop, then release it
    [[task dataDoc] removeObserver:stateSystem];
    [stateSystem release];

	[actionsMenuItem release];
	[settingsMenuItem release];
	[scheduler release];
	[stimuli release];
	[controlPanel release];
	[taskStatus release];
    [topLevelObjects release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self]; 

	[super dealloc];
}

- (void)displayPosition:(NSTimer*)theTimer;
{
	NSString *displayString;
	NSPoint stimCenterDeg =[stimWindow mouseLocationDeg];

	switch ([defaults boolForKey:RFDisplayUnitsKey]) {
	case kAzimuthElevation:
		displayString = [NSString stringWithFormat:@"Azimuth: %5.1f\nElevation: %5.1f",
							stimCenterDeg.x, stimCenterDeg.y];
		break;
	case kEccentricityAngle:
		displayString = [NSString stringWithFormat:@"Eccentricy: %5.1f\nAngle: %5ld",
				sqrt(stimCenterDeg.x * stimCenterDeg.x + stimCenterDeg.y * stimCenterDeg.y), 
				(long)(atan2(stimCenterDeg.y, stimCenterDeg.x) * kDegPerRadian) % 180];
		break;
	}
	[controlPanel displayText:displayString];
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
	
	juiceMS = [defaults integerForKey:RFRewardMSKey];
	[[task dataController] digitalOutputBitsOff:kRewardBit];
	[scheduler schedule:@selector(doJuiceOff) toTarget:self withObject:nil delayMS:juiceMS];
	if ([defaults boolForKey:RFDoSoundsKey]) {
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

// Run the settings dialog for the current stimulus

- (IBAction)doStimSettings:(id)sender;
{
	[stimuli doStimSettings];
}

- (BOOL)handleEvent:(NSEvent *)theEvent;
{
	BOOL handled = NO;
	
	if ([theEvent type] == NSKeyDown) {
		switch ([theEvent keyCode]) {
		case kKeyPad7KeyCode:						// make stimulus smaller
			[stimuli changeSize:1.0 / [[task defaults] floatForKey:RFSizeFactorKey]];
			handled = YES;
			break;
		case kKeyPad9KeyCode:						// make stimulus larger
			[stimuli changeSize:[[task defaults] floatForKey:RFSizeFactorKey]];
			handled = YES;
			break;
		case kKeyPad1KeyCode: 						// make stimulus narrow
			[stimuli changeWidth:1.0 / [[task defaults] floatForKey:RFWidthFactorKey]];
			handled = YES;
			break;
		case kKeyPad3KeyCode:						// make stimulus wider
			[stimuli changeWidth:[[task defaults] floatForKey:RFWidthFactorKey]];
			handled = YES;
			break;
		case kKeyPad6KeyCode:						// rotate CW
			[stimuli rotate:-[[task defaults] floatForKey:RFOrientationStepDegKey]];
			handled = YES;
			break;
		case kKeyPad4KeyCode:						// rotate CCW
			[stimuli rotate:[[task defaults] floatForKey:RFOrientationStepDegKey]];
			handled = YES;
			break;
		case kKeyPad0KeyCode:
		case kKeyPad2KeyCode:
		case kKeyPad5KeyCode:
		case kKeyPad8KeyCode:
		case kKeyPadPeriodKeyCode:
		case kKeyPadStarKeyCode:
		case kKeyPadPlusKeyCode:
		case kKeyPadClearKeyCode:
		case kKeyPadSlashKeyCode:
		case kKeyPadEnterKeyCode:
		case kKeyPadMinusKeyCode:
		case kKeyPadEqualsKeyCode:
			handled = YES;
			break;
		default:
			break;
		}
	}
	else if ([theEvent type] == NSLeftMouseDown) {
		handled = [stimuli mouseDown];
	}
	else if ([theEvent type] == NSLeftMouseUp) {
		handled = [stimuli mouseUp];
	}
	return handled;
}

- (BOOL)handlesEvents;
{
	return YES;										// declare that we want OS events
}

// After our -init is called, the host will provide essential pointers such as
// defaults, stimWindow, eyeCalibrator, etc.  Only after those are initialized, the
// following method will be called.  We therefore defer most of our initialization here

- (void)initializationDidFinish;
{
	LLMultiplierTransformer *transformer;
	
	task = self;

// Register our default settings. This should be done first thing, before the
// nib is loaded, because items in the nib are linked to defaults

	[LLSystemUtil registerDefaultsFromFilePath:
			[[NSBundle bundleForClass:[self class]] pathForResource:@"UserDefaults" ofType:@"plist"] defaults:defaults];
	
// Set up the value transformers that are needed for some of the key bindings

	transformer = [[[LLMultiplierTransformer alloc] init] autorelease];
	[transformer setMultiplier:100];
	[NSValueTransformer setValueTransformer:transformer forName:@"PercentTransformer"];

// Set up the task mode object.  We need to do this before loading the nib,
// because some items in the nib are bound to the task mode. We also need
// to set the mode, because the value in defaults will be the last entry made
// which is typically kTaskEnding.

	taskStatus = [[LLTaskStatus alloc] init];

// Load the items in the nib

    [[NSBundle bundleForClass:[self class]] loadNibNamed:@"RFMap" owner:self topLevelObjects:&topLevelObjects];
    [topLevelObjects retain];
		
// Initialize other task objects

	scheduler = [[LLScheduleController alloc] init];
	stateSystem = [[RFStateSystem alloc] init];

// Set up control panel and observer for control panel

	controlPanel = [[LLControlPanel alloc] init];
	[[controlPanel window] setFrameUsingName:@"RFControlPanel"];
	[controlPanel setWindowFrameAutosaveName:@"RFControlPanel"];
	[[controlPanel window] setTitle:@"RFMap"];
	[[NSNotificationCenter defaultCenter] addObserver:self 
		selector:@selector(doControls:) name:nil object:controlPanel];

// Modes are saved in defaults, and the last thing saved will be the kTaskEnding.
// We need to set ourselves to idle mode.

	stimuli = [[RFMapStimuli alloc] init];
}

- (long)mode;
{
	return [taskStatus mode];
}

- (NSString *)name;
{
	return @"RFMap";
}
/*
- (NSNumber *)pluginVersion; 
{
	return [NSNumber numberWithLong:kLLPluginVersion];
}
*/
// Post a notification of the stimulus position.  The position is sent as an NSPoint in an NSValue

- (IBAction)postPosition:(id)sender;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"RFMapStimulusPositionDeg"
		object:[NSValue valueWithPoint:[stimWindow mouseLocationDeg]]];
}

- (void)setMode:(long)newMode;
{
	[taskStatus setMode:newMode];
	[defaults setInteger:newMode forKey:RFTaskStatusKey];
	[controlPanel setTaskMode:[taskStatus mode]];
	[[task dataDoc] putEvent:@"taskMode" withData:&newMode];
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
			[controlPanel displayFileName:[[[[task dataDoc] filePath] lastPathComponent] 
												stringByDeletingPathExtension]];
			[controlPanel setResetButtonEnabled:NO];
		}
		else {
			[controlPanel displayFileName:@""];
			[controlPanel setResetButtonEnabled:YES];
		}
	}
}

- (RFMapStimuli *)stimuli;
{
	return stimuli;
}

@end
