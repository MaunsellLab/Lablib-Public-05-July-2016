//
//  MTContrast.m
//  MTContrast
//
//  Copyright 2006. All rights reserved.
//

#import "MTC.h"
#import "MTContrast.h"
#import "MTCSummaryController.h"
#import "MTCBehaviorController.h"
#import "MTCSpikeController.h"
#import "MTCXTController.h"
#import "UtilityFunctions.h"

#define		kRewardBit				0x0001

// Behavioral parameters

NSString *MTCAcquireMSKey = @"MTCAcquireMS";
NSString *MTCBlockLimitKey = @"MTCBlockLimit";
NSString *MTCBreakPunishMSKey = @"MTCBreakPunishMS";
NSString *MTCCueMSKey = @"MTCCueMS";
NSString *MTCDoSoundsKey = @"MTCDoSounds";
NSString *MTCFixateKey = @"MTCFixate";
NSString *MTCFixateMSKey = @"MTCFixateMS";
NSString *MTCFixGraceMSKey = @"MTCFixGraceMS";
NSString *MTCFixWindowWidthDegKey = @"MTCFixWindowWidthDeg";
NSString *MTCIntertrialMSKey = @"MTCIntertrialMS";
NSString *MTCMaxTargetMSKey = @"MTCMaxTargetMS";
NSString *MTCMeanTargetMSKey = @"MTCMeanTargetMS";
NSString *MTCNontargetContrastPCKey = @"MTCNontargetContrastPC";
NSString *MTCNumInstructTrialsKey = @"MTCNumInstructTrials";
NSString *MTCPrecueMSKey = @"MTCPrecueMS";
NSString *MTCRelDistractorProbKey = @"MTCRelDistractorProb";
NSString *MTCRespSpotSizeDegKey = @"MTCRespSpotSizeDeg";
NSString *MTCRespTimeMSKey = @"MTCRespTimeMS";
NSString *MTCRespWindowWidthDegKey = @"MTCRespWindowWidthDeg";
NSString *MTCRewardMSKey = @"MTCRewardMS";
NSString *MTCSaccadeTimeMSKey = @"MTCSaccadeTimeMS";
NSString *MTCStimRepsPerBlockKey = @"MTCStimRepsPerBlock";
NSString *MTCStimulusSpeedDPSKey = @"MTCStimulusSpeedDPS";
NSString *MTCTargetSpeedDPSKey = @"MTCTargetSpeedDPS";
NSString *MTCTaskStatusKey = @"MTCTaskStatus";
NSString *MTCTooFastMSKey = @"MTCTooFastMS";
NSString *MTCTriesKey = @"MTCTries";

// Stimulus Parameters

NSString *MTCInterstimJitterPCKey = @"MTCInterstimJitterPC";
NSString *MTCInterstimMSKey = @"MTCInterstimMS";
NSString *MTCStimDurationMSKey = @"MTCStimDurationMS";
NSString *MTCStimJitterPCKey = @"MTCStimJitterPC";
NSString *MTCStimLeadMSKey = @"MTCStimLeadMS";

// Visual Stimulus Parameters 

NSString *MTCContrastFactorKey = @"MTCContrastFactor";
NSString *MTCContrastsKey = @"MTCContrasts";
NSString *MTCEccentricityDegKey = @"MTCEccentricityDeg";
NSString *MTCPolarAngleDegKey = @"MTCPolarAngleDeg";
NSString *MTCKdlPhiDegKey = @"MTCKdlPhiDeg";
NSString *MTCKdlThetaDegKey = @"MTCKdlThetaDeg";
NSString *MTCMaxContrastKey = @"MTCMaxContrast";
NSString *MTCDirectionDegKey = @"MTCDirectionDeg";
NSString *MTCRadiusDegKey = @"MTCRadiusDeg";
NSString *MTCSeparationDegKey = @"MTCSeparationDeg";
NSString *MTCSigmaDegKey = @"MTCSigmaDeg";
NSString *MTCSpatialFreqCPDKey = @"MTCSpatialFreqCPD";
NSString *MTCSpatialPhaseDegKey = @"MTCSpatialPhaseDeg";
NSString *MTCTemporalFreqHzKey = @"MTCTemporalFreqHz";


NSString *keyPaths[] = {@"values.MTCTries", @"values.MTCBlockLimit", @"values.MTCRespTimeMS", 
					@"values.MTCStimDurationMS", @"values.MTCInterstimMS", @"values.MTCContrasts", 
					@"values.MTCMaxContrast", @"values.MTCContrastFactor", @"values.MTCStimRepsPerBlock",
					nil};

LLScheduleController	*scheduler = nil;
MTCStimuli				*stimuli = nil;

LLDataDef gaborStructDef[] = kLLGaborEventDesc;
LLDataDef fixWindowStructDef[] = kLLEyeWindowEventDesc;
LLDataDef blockStatusDef[] = {
	{@"long",	@"attendLoc", 1, offsetof(BlockStatus, attendLoc)},
	{@"long",	@"instructsDone", 1, offsetof(BlockStatus, instructsDone)},
	{@"long",	@"presentationsPerLoc", 1, offsetof(BlockStatus, presentationsPerLoc)},
	{@"long",	@"presentationsDoneThisLoc", 1, offsetof(BlockStatus, presentationsDoneThisLoc)},
	{@"long",	@"locsPerBlock", 1, offsetof(BlockStatus, locsPerBlock)},
	{@"long",	@"locsDoneThisBlock", 1, offsetof(BlockStatus, locsDoneThisBlock)},
	{@"long",	@"blockLimit", 1, offsetof(BlockStatus, blockLimit)},
	{@"long",	@"blocksDone", 1, offsetof(BlockStatus, blocksDone)},
	{nil}};
LLDataDef stimParamsDef[] = {
	{@"long",	@"levels", 1, offsetof(StimParams, levels)},
	{@"float",	@"maxValue", 1, offsetof(StimParams, maxValue)},
	{@"float",	@"factor", 1, offsetof(StimParams, factor)},
	{nil}};
LLDataDef stimDescDef[] = {
	{@"long",	@"attendLoc", 1, offsetof(StimDesc, attendLoc)},
	{@"long",	@"stimOnFrame", 1, offsetof(StimDesc, stimOnFrame)},
	{@"long",	@"stimOffFrame", 1, offsetof(StimDesc, stimOffFrame)},
	{@"short",	@"type0", 1, offsetof(StimDesc, type0)},
	{@"short",	@"type1", 1, offsetof(StimDesc, type1)},
	{@"short",	@"contrastIndex", 1, offsetof(StimDesc, contrastIndex)},
	{@"float",	@"contrastPC", 1, offsetof(StimDesc, contrastPC)},
	{@"float",	@"speed0DPS", 1, offsetof(StimDesc, speed0DPS)},
	{@"float",	@"speed1DPS", 1, offsetof(StimDesc, speed1DPS)},
	{@"float",	@"direction0Deg", 1, offsetof(StimDesc, direction0Deg)},
	{@"float",	@"direction1Deg", 1, offsetof(StimDesc, direction1Deg)},
	{nil}};
LLDataDef trialDescDef[] = {
	{@"boolean",@"catchTrial", 1, offsetof(TrialDesc, catchTrial)},
	{@"long",	@"attendLoc", 1, offsetof(TrialDesc, attendLoc)},
	{@"long",	@"numStim", 1, offsetof(TrialDesc, numStim)},
	{@"long",	@"targetIndex", 1, offsetof(TrialDesc, targetIndex)},
	{@"long",	@"distIndex", 1, offsetof(TrialDesc, distIndex)},
	{@"long",	@"targetContrastIndex", 1, offsetof(TrialDesc, targetContrastIndex)},
	{@"float",	@"targetContrastPC", 1, offsetof(TrialDesc, targetContrastPC)},
	{@"float",	@"stimulusSpeed", 1, offsetof(TrialDesc, stimulusSpeed)},
	{@"float",	@"targetSpeed", 1, offsetof(TrialDesc, targetSpeed)},
	{@"float",	@"direction0Deg", 1, offsetof(TrialDesc, direction0Deg)},
	{@"float",	@"direction1Deg", 1, offsetof(TrialDesc, direction1Deg)},
	{nil}};
	
DataAssignment eyeXDataAssignment = {@"eyeXData",	@"Synthetic", 0, 5.0};	
DataAssignment eyeYDataAssignment = {@"eyeYData",	@"Synthetic", 1, 5.0};	
DataAssignment spikeDataAssignment = {@"spikeData", @"Synthetic", 2, 1};
DataAssignment VBLDataAssignment =   {@"VBLData",	@"Synthetic", 1, 1};	
	
EventDefinition MTCEvents[] = {
// recorded at start of file
	{@"gabor",				sizeof(Gabor),			{@"struct", @"gabor", 1, 0, sizeof(Gabor), gaborStructDef}},
	{@"eccentricityDeg",	sizeof(float),			{@"float"}},
	{@"polarAngleDeg",		sizeof(float),			{@"float"}},
	{@"separationDeg",		sizeof(float),			{@"float"}},
	{@"contrastStimParams", sizeof(StimParams),		{@"struct", @"contrastStimParams", 1, 0, sizeof(StimParams), stimParamsDef}},
// timing parameters
	{@"stimDurationMS",		sizeof(long),			{@"long"}},
	{@"interstimMS",		sizeof(long),			{@"long"}},
	{@"stimLeadMS",			sizeof(long),			{@"long"}},
	{@"responseTimeMS",		sizeof(long),			{@"long"}},
	{@"tooFastTimeMS",		sizeof(long),			{@"long"}},
	{@"tries",				sizeof(long),			{@"long"}},
	{@"stimRepsPerBlock",	sizeof(long),			{@"long"}},
	{@"blockStatus",		sizeof(BlockStatus),	{@"struct", @"blockStatus", 1, 0, sizeof(BlockStatus), blockStatusDef}},
// declared at start of each trial	
	{@"trial",				sizeof(TrialDesc),		{@"struct", @"trial", 1, 0, sizeof(TrialDesc), trialDescDef}},
	{@"responseWindow",		sizeof(FixWindowData),	{@"struct", @"fixWindowData", 1, 0, sizeof(FixWindowData), fixWindowStructDef}},
// marking the course of each trial
	{@"cueOn",				0,						{@"no data"}},
	{@"preStimuli",			0,						{@"no data"}},
	{@"stimulus",			sizeof(StimDesc),		{@"struct", @"stimDesc", 1, 0, sizeof(StimDesc), stimDescDef}},
	{@"postStimuli",		0,						{@"no data"}},
	{@"saccade",			0,						{@"no data"}},

	{@"taskMode", 			sizeof(long),			{@"long"}},
	{@"reset", 				sizeof(long),			{@"long"}}, 
};

BlockStatus		blockStatus;
BOOL			brokeDuringStim;
long			stimDone[kLocations][kMaxContrasts] = {};
LLTaskPlugIn	*task = nil;

@implementation MTContrast

+ (int)version;
{
	return kLLPluginVersion;
}

// Start the method that will collect data from the event buffer

- (void)activate;
{ 
	long longValue;
	NSMenu *mainMenu;
	
	if (active) {
		return;
	}

// Insert Actions and Settings menus into menu bar
	 
	mainMenu = [NSApp mainMenu];
	[mainMenu insertItem:actionsMenuItem atIndex:([mainMenu indexOfItemWithTitle:@"Tasks"] + 1)];
	[mainMenu insertItem:settingsMenuItem atIndex:([mainMenu indexOfItemWithTitle:@"Tasks"] + 1)];
	
// Erase the stimulus display

	[stimuli erase];
	
// Create on-line display windows

	
	[[controlPanel window] orderFront:self];
  
	behaviorController = [[MTCBehaviorController alloc] init];
    [dataDoc addObserver:behaviorController];

	spikeController = [[MTCSpikeController alloc] init];
    [dataDoc addObserver:spikeController];

    eyeXYController = [[MTCEyeXYController alloc] init];
    [dataDoc addObserver:eyeXYController];

    summaryController = [[MTCSummaryController alloc] init];
    [dataDoc addObserver:summaryController];
 
	xtController = [[MTCXTController alloc] init];
    [dataDoc addObserver:xtController];

// Set up data events (after setting up windows to receive them)

	[dataDoc defineEvents:[LLStandardDataEvents eventsWithDataDefs] count:[LLStandardDataEvents countOfEventsWithDataDefs]];
	[dataDoc defineEvents:MTCEvents count:(sizeof(MTCEvents) / sizeof(EventDefinition))];
	announceEvents();
	longValue = 0;
	[[task dataDoc] putEvent:@"reset" withData:&longValue];
	

// Set up the data collector to handle our data types

	[dataController assignSampleData:eyeXDataAssignment];
	[dataController assignSampleData:eyeYDataAssignment];
	[dataController assignTimestampData:spikeDataAssignment];
	[dataController assignTimestampData:VBLDataAssignment];
	[dataController assignDigitalInputDevice:@"Synthetic"];
	[dataController assignDigitalOutputDevice:@"Synthetic"];
	collectorTimer = [NSTimer scheduledTimerWithTimeInterval:0.025 target:self 
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
	
	if ((data = [dataController dataOfType:@"eyeXData"]) != nil) {
		[dataDoc putEvent:@"eyeXData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
		currentEyeUnits.x = *(short *)([data bytes] + [data length] - sizeof(short));
	}
	if ((data = [dataController dataOfType:@"eyeYData"]) != nil) {
		[dataDoc putEvent:@"eyeYData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
		currentEyeUnits.y = *(short *)([data bytes] + [data length] - sizeof(short));
		currentEyeDeg = [eyeCalibrator degPointFromUnitPoint:currentEyeUnits];
	}
	if ((data = [dataController dataOfType:@"VBLData"]) != nil) {
		[dataDoc putEvent:@"VBLData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
	}
	if ((data = [dataController dataOfType:@"spikeData"]) != nil) {
		[dataDoc putEvent:@"spikeData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
	}
}
	
// Stop data collection and shut down the plug in

- (void)deactivate:(id)sender;
{
	if (!active) {
		return;
	}
    [dataController setDataEnabled:[NSNumber numberWithBool:NO]];
    [stateSystem stop];
	[collectorTimer invalidate];
    [dataDoc removeObserver:stateSystem];
    [dataDoc removeObserver:behaviorController];
    [dataDoc removeObserver:spikeController];
    [dataDoc removeObserver:eyeXYController];
    [dataDoc removeObserver:summaryController];
    [dataDoc removeObserver:xtController];
	[dataDoc clearEventDefinitions];

// Remove Actions and Settings menus from menu bar
	 
	[[NSApp mainMenu] removeItem:settingsMenuItem];
	[[NSApp mainMenu] removeItem:actionsMenuItem];

// Release all the display windows

    [behaviorController close];
    [behaviorController release];
    [spikeController close];
    [spikeController release];
    [eyeXYController deactivate];			// requires a special call
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
	long index;
 
	while ([stateSystem running]) {};		// wait for state system to stop, then release it
	
	for (index = 0; keyPaths[index] != nil; index++) {
		[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:keyPaths[index]];
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self]; 

    [[task dataDoc] removeObserver:stateSystem];
    [stateSystem release];
	
	[actionsMenuItem release];
	[settingsMenuItem release];
	[scheduler release];
	[stimuli release];
	[controlPanel release];
	[taskStatus dealloc];
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

- (IBAction)doCueSettings:(id)sender;
{
	[stimuli doCueSettings];
}

- (IBAction)doFixSettings:(id)sender;
{
	[stimuli doFixSettings];
}

- (IBAction)doGaborSettings:(id)sender;
{
	[stimuli doGaborSettings];
}

- (IBAction)doJuice:(id)sender;
{
	long juiceMS;
	NSSound *juiceSound;
	
	if ([sender respondsToSelector:@selector(juiceMS)]) {
		juiceMS = (long)[sender performSelector:@selector(juiceMS)];
	}
	else {
		juiceMS = [[task defaults] integerForKey:MTCRewardMSKey];
	}
	[[task dataController] digitalOutputBitsOff:kRewardBit];
	[scheduler schedule:@selector(doJuiceOff) toTarget:self withObject:nil delayMS:juiceMS];
	if ([[task defaults] boolForKey:MTCDoSoundsKey]) {
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
    requestReset();
}

- (IBAction)doRFMap:(id)sender;
{
	[host performSelector:@selector(switchToTaskWithName:) withObject:@"RFMap"];
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
// defaults, stimWindow, eyeCalibrator, etc.  Only aMSer those are initialized, the
// following method will be called.  We therefore defer most of our initialization here

- (void)initializationDidFinish;
{
	long index;
	
	task = self;
	
// Register our default settings. This should be done first thing, before the
// nib is loaded, because items in the nib are linked to defaults

	[LLSystemUtil registerDefaultsFromFilePath:
			[[NSBundle bundleForClass:[self class]] pathForResource:@"UserDefaults" ofType:@"plist"] defaults:defaults];
	[NSValueTransformer 
			setValueTransformer:[[[LLFactorToOctaveStepTransformer alloc] init] autorelease]
			forName:@"FactorToOctaveStepTransformer"];

// Set up to respond to changes to the values

	for (index = 0; keyPaths[index] != nil; index++) {
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:keyPaths[index]
				options:NSKeyValueObservingOptionNew context:nil];
	}
		
// Set up the task mode object.  We need to do this before loading the nib,
// because some items in the nib are bound to the task mode. We also need
// to set the mode, because the value in defaults will be the last entry made
// which is typically kTaskEnding.

	taskStatus = [[LLTaskStatus alloc] init];
	stimuli = [[MTCStimuli alloc] init];

// Load the items in the nib

	[NSBundle loadNibNamed:@"MTContrast" owner:self];
	
// Initialize other task objects

	scheduler = [[LLScheduleController alloc] init];
	stateSystem = [[MTCStateSystem alloc] init];

// Set up control panel and observer for control panel

	controlPanel = [[LLControlPanel alloc] init];
	[controlPanel setWindowFrameAutosaveName:@"MTCControlPanel"];
	[[controlPanel window] setFrameUsingName:@"MTCControlPanel"];
	[[controlPanel window] setTitle:@"MTContrast"];
	[[NSNotificationCenter defaultCenter] addObserver:self 
		selector:@selector(doControls:) name:nil object:controlPanel];
}

- (long)mode;
{
	return [taskStatus mode];
}

- (NSString *)name;
{
	return @"MTContrast";
}

// The release notes for 10.3 say that the options for addObserver are ignore
// (http://developer.apple.com/releasenotes/Cocoa/AppKit.html).   This means that the change dictionary
// will not contain the new values of the change.  For now it must be read directly from the model

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
	static BOOL tested = NO;
	NSString *key;
	id newValue;
	long longValue;

	if (!tested) {
		newValue = [change objectForKey:NSKeyValueChangeNewKey];
		if (![[newValue className] isEqualTo:@"NSNull"]) {
			NSLog(@"NSKeyValueChangeNewKey is not NSNull, JHRM needs to change how values are accessed");
		}
		tested = YES;
	}
	key = [keyPath pathExtension];
	if ([key isEqualTo:MTCTriesKey]) {
		longValue = [defaults integerForKey:MTCTriesKey];
		[dataDoc putEvent:@"tries" withData:&longValue];
	}
	else if ([key isEqualTo:MTCRespTimeMSKey]) {
		longValue = [defaults integerForKey:MTCRespTimeMSKey];
		[dataDoc putEvent:@"responseTimeMS" withData:&longValue];
	}
	else if ([key isEqualTo:MTCStimDurationMSKey]) {
		longValue = [defaults integerForKey:MTCStimDurationMSKey];
		[dataDoc putEvent:@"stimDurationMS" withData:&longValue];
		requestReset();
	}
	else if ([key isEqualTo:MTCInterstimMSKey]) {
		longValue = [defaults integerForKey:MTCInterstimMSKey];
		[dataDoc putEvent:@"interstimMS" withData:&longValue];
		requestReset();
	}
	else if ([key isEqualTo:MTCContrastsKey] || [key isEqualTo:MTCContrastFactorKey] ||
												[key isEqualTo:MTCMaxContrastKey]) {
		[[task dataDoc] putEvent:@"contrastStimParams" withData:(Ptr)getStimParams()];
		requestReset();
	}
	else if ([key isEqualTo:MTCStimRepsPerBlockKey]) {
		longValue = [defaults integerForKey:MTCContrastsKey];
		[dataDoc putEvent:@"stimRepsPerBlock" withData:&longValue];
	}
}

- (DisplayModeParam)requestedDisplayMode;
{
	displayMode.widthPix = 1024;
	displayMode.heightPix = 768;
	displayMode.pixelBits = 32;
	displayMode.frameRateHz = 75;
	return displayMode;
}

- (void)setMode:(long)newMode;
{
	[taskStatus setMode:newMode];
	[defaults setInteger:[taskStatus status] forKey:MTCTaskStatusKey];
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
		[defaults setInteger:[taskStatus status] forKey:MTCTaskStatusKey];
		if ([taskStatus dataFileOpen]) {
			announceEvents();
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

- (MTCStimuli *)stimuli;
{
	return stimuli;
}
@end
