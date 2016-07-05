//
//  VideoTest.m
//  VideoTest
//
//  Created by John Maunsell on January 21, 2005.
//  Copyright 2005. All rights reserved.
//

#import "VT.h"
#import "VideoTest.h"
#import "VTSummaryController.h"
#import "VTBehaviorController.h"
#import "VTXTController.h"
#import "UtilityFunctions.h"

// Behavioral parameters

NSString *VTAcquireMSKey = @"VTAcquireMS";
NSString *VTBlockLimitKey = @"VTBlockLimit";
NSString *VTBreakPunishMSKey = @"VTBreakPunishMS";
NSString *VTDoSoundsKey = @"VTDoSounds";
NSString *VTFixateKey = @"VTFixate";
NSString *VTFixateMSKey = @"VTFixateMS";
NSString *VTFixGraceMSKey = @"VTFixGraceMS";
NSString *VTFixSpotSizeDegKey = @"VTFixSpotSizeDeg";
NSString *VTFixWindowWidthDegKey = @"VTFixWindowWidthDeg";
NSString *VTIntertrialMSKey = @"VTIntertrialMS";
NSString *VTNontargetContrastPCKey = @"VTNontargetContrastPC";
NSString *VTTaskStatusKey = @"VTTaskStatus";
NSString *VTRespSpotSizeDegKey = @"VTRespSpotSizeDeg";
NSString *VTRespTimeMSKey = @"VTRespTimeMS";
NSString *VTRespWindowWidthDegKey = @"VTRespWindowWidthDeg";
NSString *VTRespWindow0AziKey = @"VTRespWindow0Azi";
NSString *VTRespWindow0EleKey = @"VTRespWindow0Ele";
NSString *VTRespWindow1AziKey = @"VTRespWindow1Azi";
NSString *VTRespWindow1EleKey = @"VTRespWindow1Ele";
NSString *VTRewardMSKey = @"VTRewardMS";
NSString *VTSaccadeTimeMSKey = @"VTSaccadeTimeMS";
NSString *VTTooFastMSKey = @"VTTooFastMS";
NSString *VTTriesKey = @"VTTries";

// Stimulus Parameters

NSString *VTGapMSKey= @"VTGapMS";
NSString *VTIntervalMSKey= @"VTIntervalMS";
NSString *VTPostintervalMSKey= @"VTPostintervalMS";
NSString *VTPreintervalMSKey= @"VTPreintervalMS";
NSString *VTStimTypeKey = @"VTStimType";

// Visual Stimulus Parameters 

NSString *VTContrastFactorKey = @"VTContrastFactor";
NSString *VTContrastsKey = @"VTContrasts";
NSString *VTMaxContrastKey = @"VTMaxContrast";

NSString *VTAzimuthDegKey = @"VTAzimuthDeg";
NSString *VTElevationDegKey = @"VTElevationDeg";
NSString *VTKdlPhiDegKey = @"VTKdlPhiDeg";
NSString *VTKdlThetaDegKey = @"VTKdlThetaDeg";
NSString *VTDirectionDegKey = @"VTDirectionDeg";
NSString *VTRadiusDegKey = @"VTRadiusDeg";
NSString *VTSigmaDegKey = @"VTSigmaDeg";
NSString *VTSpatialFreqCPDKey = @"VTSpatialFreqCPD";
NSString *VTSpatialPhaseDegKey = @"VTSpatialPhaseDeg";
NSString *VTTemporalFreqHzKey = @"VTTemporalFreqHz";

// Electrical Stimulus Parameters

NSString *VTCurrentsKey = @"VTCurrents";
NSString *VTCurrentFactorKey = @"VTCurrentFactor";
NSString *VTDAChannelKey = @"VTDAChannel";
NSString *VTFrequencyHzKey = @"VTFrequencyHz";
NSString *VTGateBitKey = @"VTGateBit";
NSString *VTDoGateKey = @"VTDoGate";
NSString *VTPulseWidthUSKey = @"VTPulseWidthUS";
NSString *VTMarkerPulseBitKey = @"VTMarkerPulseBit";
NSString *VTDoMarkerPulsesKey = @"VTDoMarkerPulses";
NSString *VTMaxCurrentKey = @"VTMaxCurrent";
NSString *VTUAPerVKey = @"VTUAPerV";

NSString *keyPaths[] = {@"values.VTTries", @"values.VTBlockLimit", @"values.VTResponseTimeMS", @"values.VTGapMS",
						@"values.VTIntervalMS", @"values.VTPreintervalMS", @"values.VTPostintervalMS",
						@"values.VTStimType", @"values.VTContrasts", @"values.VTMaxContrast", @"values.VTContrastFactor",
						@"values.VTCurrents", @"values.VTMaxCurrent", @"values.VTCurrentFactor", 
						nil};
LLDataDef stimParamsDef[] = {
	{@"long",	@"levels", 1, offsetof(StimParams, levels)},
	{@"float",	@"maxValue", 1, offsetof(StimParams, maxValue)},
	{@"float",	@"factor", 1, offsetof(StimParams, factor)},
	{nil}};
LLDataDef trialDescDef[] = {
	{@"long",	@"stimulusType", 1, offsetof(TrialDesc, stimulusType)},
	{@"long",	@"stimulusIndex", 1, offsetof(TrialDesc, stimulusIndex)},
	{@"float",	@"stimulusValue", 1, offsetof(TrialDesc, stimulusValue)},
	{@"long",	@"stimulusInterval", 1, offsetof(TrialDesc, stimulusInterval)},
	{@"float",	@"respAziDeg", 1, offsetof(TrialDesc, respAziDeg)},
	{@"float",	@"respEleDeg", 1, offsetof(TrialDesc, respEleDeg)},
	{nil}};

LLScheduleController	*scheduler = nil;
VTStimuli				*stimuli = nil;
LLDataDef fixWindowStructDef[] = kLLEyeWindowEventDesc;
LLDataDef gaborStructDef[] = kLLGaborEventDesc;
DataAssignment eyeXDataAssignment = {@"eyeXData",	@"Synthetic", 0, 5.0};	
DataAssignment eyeYDataAssignment = {@"eyeYData",	@"Synthetic", 1, 5.0};	
DataAssignment spikeDataAssignment = {@"spikeData", @"Synthetic", 2, 1};
DataAssignment VBLDataAssignment =   {@"VBLData",	@"Synthetic", 1, 1};		
		

EventDefinition VTEvents[] = {
	{@"stimulusType",		sizeof(long),			{@"long"}},			// recorded at start of file
	{@"contrastStimParams", sizeof(StimParams),		{@"struct", @"contrastStimParams", 1, 0, sizeof(StimParams), stimParamsDef}},
	{@"gabor",				sizeof(Gabor),			{@"struct", @"gabor", 1, 0, sizeof(Gabor), gaborStructDef}},
	{@"currentStimParams", sizeof(StimParams),		{@"struct", @"currentStimParams", 1, 0, sizeof(StimParams), stimParamsDef}},
	{@"frequencyHz",		sizeof(float),			{@"float"}},
	{@"pulseWidthUS",		sizeof(long),			{@"long"}},
	{@"uAPerV",				sizeof(long),			{@"long"}},
	{@"voltageRangeV",		sizeof(float),			{@"float"}},

	{@"preIntervalMS",		sizeof(long),			{@"long"}},			// timing parameters
	{@"intervalMS",			sizeof(long),			{@"long"}},
	{@"gapMS",				sizeof(long),			{@"long"}},
	{@"postStimuliMS",		sizeof(long),			{@"long"}},
	{@"responseTimeMS",		sizeof(long),			{@"long"}},
	{@"tooFastTimeMS",		sizeof(long),			{@"long"}},
	{@"tries",				sizeof(long),			{@"long"}},
	{@"blockLimit",			sizeof(long),			{@"long"}},
	{@"blockTrialsDone",	sizeof(long),			{@"long"}},
	{@"blocksDone",			sizeof(long),			{@"long"}},
	
	{@"trial",				sizeof(TrialDesc),		{@"struct", @"trial", 1, 0, sizeof(TrialDesc), trialDescDef}},
	{@"responseWindow",		sizeof(FixWindowData),	{@"struct", @"fixWindowData", 1, 0, sizeof(FixWindowData), fixWindowStructDef}},
	{@"preStimuli",			0,						{@"no data"}},							
	{@"intervalOne",		sizeof(float),			{@"float"}},
	{@"gap",				0,						{@"no data"}},
	{@"intervalTwo",		sizeof(float),			{@"float"}},
	{@"postStimuli",		0,						{@"no data"}},
	{@"targetsOn",			0,						{@"no data"}},
	{@"saccade",			0,						{@"no data"}},

	{@"taskMode", 			sizeof(long),			{@"long"}},
	{@"reset", 				sizeof(long),			{@"long"}}, 
};

LLTaskPlugIn	*task = nil;

@implementation VideoTest

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
  
	behaviorController = [[VTBehaviorController alloc] init];
    [dataDoc addObserver:behaviorController];

    eyeXYController = [[VTEyeXYController alloc] init];
    [dataDoc addObserver:eyeXYController];

    summaryController = [[VTSummaryController alloc] init];
    [dataDoc addObserver:summaryController];
 
	xtController = [[VTXTController alloc] init];
    [dataDoc addObserver:xtController];

	[dataDoc defineEvents:[LLStandardDataEvents eventsWithDataDefs] count:[LLStandardDataEvents countOfEventsWithDataDefs]];
	[dataDoc defineEvents:VTEvents count:(sizeof(VTEvents) / sizeof(EventDefinition))];
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
	collectorTimer = [NSTimer scheduledTimerWithTimeInterval:0.010 target:self 
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
	}
	if ((data = [dataController dataOfType:@"eyeYData"]) != nil) {
		[dataDoc putEvent:@"eyeYData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
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
    [dataDoc removeObserver:behaviorController];
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
    [[task dataDoc] removeObserver:stateSystem];
    [stateSystem release];
	
	[actionsMenuItem release];
	[settingsMenuItem release];	
	[scheduler release];
	[stimuli release];
	[controlPanel release];
	[taskStatus release];

	for (index = 0; keyPaths[index] != nil; index++) {
		[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:keyPaths[index]];
	}
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

- (IBAction)doJuice:(id)sender;
{
	long juiceMS;
	NSSound *juiceSound;
	
	if ([sender respondsToSelector:@selector(juiceMS)]) {
		juiceMS = (long)[sender performSelector:@selector(juiceMS)];
	}
	else {
		juiceMS = [[task defaults] integerForKey:VTRewardMSKey];
	}
	[[task dataController] digitalOutputBitsOff:kRewardBit];
	[scheduler schedule:@selector(doJuiceOff) toTarget:self withObject:nil delayMS:juiceMS];
	if ([[task defaults] boolForKey:VTDoSoundsKey]) {
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

// AMSer our -init is called, the host will provide essential pointers such as
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
	stimuli = [[VTStimuli alloc] init];

// Load the items in the nib

	[NSBundle loadNibNamed:@"VideoTest" owner:self];
	
// Initialize other task objects

	scheduler = [[LLScheduleController alloc] init];
	stateSystem = [[VTStateSystem alloc] init];

// Set up control panel and observer for control panel

	controlPanel = [[LLControlPanel alloc] init];
	[controlPanel setWindowFrameAutosaveName:@"VTControlPanel"];
	[[controlPanel window] setFrameUsingName:@"VTControlPanel"];
	[[controlPanel window] setTitle:@"Video Test"];
	[[NSNotificationCenter defaultCenter] addObserver:self 
		selector:@selector(doControls:) name:nil object:controlPanel];
}

- (long)mode;
{
	return [taskStatus mode];
}

- (NSString *)name;
{
	return @"VideoTest";
}

// The release notes for 10.3 say that the options for addObserver are ignore
// (http://developer.apple.com/releasenotes/Cocoa/AppKit.html).   THis means that the change dictionary
// will not contain the new values of the change.  For now it must be read directly from the model

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

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
	if ([key isEqualTo:VTTriesKey]) {
		longValue = [defaults integerForKey:VTTriesKey];
		[dataDoc putEvent:@"tries" withData:&longValue];
	}
	else if ([key isEqualTo:VTBlockLimitKey]) {
		longValue = [defaults integerForKey:VTBlockLimitKey];
		[dataDoc putEvent:@"blockLimit" withData:&longValue];
	}
	else if ([key isEqualTo:VTRespTimeMSKey]) {
		longValue = [defaults integerForKey:VTRespTimeMSKey];
		[dataDoc putEvent:@"responseTimeMS" withData:&longValue];
	}
	else if ([key isEqualTo:VTGapMSKey]) {
		longValue = [defaults integerForKey:VTGapMSKey];
		[dataDoc putEvent:@"gapMS" withData:&longValue];
		requestReset();
	}
	else if ([key isEqualTo:VTIntervalMSKey]) {
		longValue = [defaults integerForKey:VTIntervalMSKey];
		[dataDoc putEvent:@"intervalMS" withData:&longValue];
		requestReset();
	}
	else if ([key isEqualTo:VTPreintervalMSKey]) {
		longValue = [defaults integerForKey:VTPreintervalMSKey];
		[dataDoc putEvent:@"preIntervalMS" withData:&longValue];
		requestReset();
	}
	else if ([key isEqualTo:VTPostintervalMSKey]) {
		longValue = [defaults integerForKey:VTPostintervalMSKey];
		[dataDoc putEvent:@"postStimuliMS" withData:&longValue];
		requestReset();
	}
	else if ([key isEqualTo:VTStimTypeKey]) {
		longValue = [defaults integerForKey:VTStimTypeKey];
		[dataDoc putEvent:@"stimulusType" withData:&longValue];
		requestReset();
	}
	else if ([key isEqualTo:VTContrastFactorKey] || 
				[key isEqualTo:VTMaxContrastKey] ||
				[key isEqualTo:VTContrastsKey]) {
		[dataDoc putEvent:@"contrastStimParams" withData:getStimParams(kVisualStimulus)];
		requestReset();
	}
}

- (void)setMode:(long)newMode;
{
	[taskStatus setMode:newMode];
	[defaults setInteger:[taskStatus status] forKey:VTTaskStatusKey];
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
		[defaults setInteger:[taskStatus status] forKey:VTTaskStatusKey];
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

- (VTStimuli *)stimuli;
{
	return stimuli;
}
@end
