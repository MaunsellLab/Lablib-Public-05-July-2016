//
//  V4CAN.m
//  V4CAN
//
//  Copyright 2006. All rights reserved.
//

#import "VCAN.h"
#import "V4CAN.h"
#import "VCANSummaryController.h"
#import "VCANDiagnosticsController.h"
#import "VCANBehaviorController.h"
#import "VCANSpikeController.h"
#import "VCANXTController.h"
#import "UtilityFunctions.h"

#define		kRewardBit				0x0001

// Behavioral parameters

NSString *VCANAcquireMSKey = @"VCANAcquireMS";
NSString *VCANBlockLimitKey = @"VCANBlockLimit";
NSString *VCANBreakPunishMSKey = @"VCANBreakPunishMS";
NSString *VCANCatchTrialPCKey = @"VCANCatchTrialPC";
NSString *VCANCueMSKey = @"VCANCueMS";
NSString *VCANDoSoundsKey = @"VCANDoSounds";
NSString *VCANDoRewardMSKey = @"VCANDoRewardMS";
NSString *VCANDoVarRewardsKey = @"VCANDoVarRewards";
NSString *VCANEyeFilterKey = @"VCANEyeFilter";
NSString *VCANExtraRewardRightFactorKey = @"VCANExtraRewardRightFactor";
NSString *VCANExtraDifficultStimRepsKey = @"VCANExtraDifficultStimReps";
NSString *VCANFixateKey = @"VCANFixate";
NSString *VCANFixateMSKey = @"VCANFixateMS";
NSString *VCANFixGraceMSKey = @"VCANFixGraceMS";
NSString *VCANFixWindowWidthDegKey = @"VCANFixWindowWidthDeg";
NSString *VCANIntertrialMSKey = @"VCANIntertrialMS";
NSString *VCANMaxTargetMSKey = @"VCANMaxTargetMS";
NSString *VCANMeanDistractorMSKey = @"VCANMeanDistractorMS";
NSString *VCANMeanTargetMSKey = @"VCANMeanTargetMS";
NSString *VCANMinContrastChangeKey = @"VCANMinContrastChange";
NSString *VCANNumCorrectStaircaseUpKey = @"VCANNumCorrectStaircaseUp";
NSString *VCANNumExtraInstructTrialsKey = @"VCANNumExtraInstructTrials";
NSString *VCANNumMistakesForExtraInstructionsKey = @"VCANNumMistakesForExtraInstructions";
NSString *VCANNumRepsAfterIncorrectKey = @"VCANNumRepsAfterIncorrect";
NSString *VCANNumInstructTrialsKey = @"VCANNumInstructTrials";
NSString *VCANPrecueMSKey = @"VCANPrecueMS";
NSString *VCANPreStimMSKey = @"VCANPreStimMS";
NSString *VCANRelDistContrastKey = @"VCANRelDistContrast";
NSString *VCANRelDistContrastChangeKey = @"VCANRelDistContrastChange";
NSString *VCANRespTimeMSKey = @"VCANRespTimeMS";
NSString *VCANRespWindowWidthDegKey = @"VCANRespWindowWidthDeg";
NSString *VCANRewardMSKey = @"VCANRewardMS";
NSString *VCANVarRewardMaxMSKey = @"VCANVarRewardMaxMS";
NSString *VCANVarRewardMinMSKey = @"VCANVarRewardMinMS";
NSString *VCANSaccadeTimeMSKey = @"VCANSaccadeTimeMS";
NSString *VCANStartContrastPCKey = @"VCANStartContrastPC";
NSString *VCANStepDownPCKey = @"VCANStepDownPC";
NSString *VCANStimRepsPerBlockKey = @"VCANStimRepsPerBlock";
NSString *VCANTaskStatusKey = @"VCANTaskStatus";
NSString *VCANTooFastMSKey = @"VCANTooFastMS";
NSString *VCANTrainingModeKey = @"VCANTrainingMode";
NSString *VCANVarRewardTCMSKey = @"VCANVarRewardTCMS";
NSString *VCANDoErrorCueKey = @"VCANDoErrorCue";

// Quest

NSString *VCANQuestJitterPCKey = @"VCANQuestJitterPC";
NSString *VCANQuestGuessContrastPCKey = @"VCANQuestGuessContrastPC";
NSString *VCANQuestCriterionKey = @"VCANQuestCriterion";

// Stimulus settings dialog

// Stimulus Parameters

NSString *VCANInterstimJitterTauMSKey = @"VCANInterstimJitterTauMS";
NSString *VCANInterstimMSKey = @"VCANInterstimMS";
NSString *VCANStimDurationMSKey = @"VCANStimDurationMS";
NSString *VCANStimJitterPCKey = @"VCANStimJitterPC";
NSString *VCANStimLeadMSKey = @"VCANStimLeadMS";

// Visual Stimulus Parameters 

NSString *VCANEccentricityDegKey = @"VCANEccentricityDeg";
NSString *VCANAngleRF0DegKey = @"VCANAngleRF0Deg";
NSString *VCANAngleRF1DegKey = @"VCANAngleRF1Deg";
NSString *VCANAngleRFOutDegKey = @"VCANAngleRFOutDeg";
NSString *VCANKdlPhiDegKey = @"VCANKdlPhiDeg";
NSString *VCANKdlThetaDegKey = @"VCANKdlThetaDeg";
NSString *VCANDirectionDegKey = @"VCANDirectionDeg";
NSString *VCANRadiusDegKey = @"VCANRadiusDeg";
NSString *VCANSigmaDegKey = @"VCANSigmaDeg";
NSString *VCANSpatialFreqCPDKey = @"VCANSpatialFreqCPD";
NSString *VCANSpatialPhaseDegKey = @"VCANSpatialPhaseDeg";

NSString *keyPaths[] = { @"values.VCANBlockLimit", @"values.VCANRespTimeMS", @"values.VCANMaxTargetMS",
					@"values.VCANStimDurationMS", @"values.VCANInterstimMS", @"values.VCANStimRepsPerBlock",
					nil};

LLDataDef gaborStructDef[] = kLLGaborEventDesc;
LLDataDef fixWindowStructDef[] = kLLEyeWindowEventDesc;

LLDataDef questResultsDef[] = {
{@"long",	@"trials", 1, offsetof(QuestResults, trials)},
{@"float",	@"threshold", 1, offsetof(QuestResults, threshold)},
{@"float",	@"confidenceInterval", 1, offsetof(QuestResults, confidenceInterval)},
{nil}};

LLDataDef blockStatusDef[] = {
	{@"long",	@"attendState", 1, offsetof(BlockStatus, attendState)},
	{@"long",	@"attendLoc", 1, offsetof(BlockStatus, attendLoc)},
	{@"long",	@"instructsDone", 1, offsetof(BlockStatus, instructsDone)},
	{@"long",	@"presDoneThisState", 1, offsetof(BlockStatus, presDoneThisState)},
	{@"long",	@"presPerState", 1, offsetof(BlockStatus, presPerState)},
	{@"long",	@"stimPerState", 1, offsetof(BlockStatus, stimPerState)},
	{@"long",	@"statesPerBlock", 1, offsetof(BlockStatus, statesPerBlock)},
	{@"long",	@"statesDoneThisBlock", 1, offsetof(BlockStatus, statesDoneThisBlock)},
	{@"long",	@"doneStates", kNumStates, offsetof(BlockStatus, doneStates)},
	{@"long",	@"blockLimit", 1, offsetof(BlockStatus, blockLimit)},
	{@"long",	@"blocksDone", 1, offsetof(BlockStatus, blocksDone)},
	{nil}};
LLDataDef stimDescDef[] = {
	{@"long",	@"attendState", 1, offsetof(StimDesc, attendState)},
	{@"long",	@"attendLoc", 1, offsetof(StimDesc, attendLoc)},
	{@"long",	@"stimOnFrame", 1, offsetof(StimDesc, stimOnFrame)},
	{@"long",	@"stimOffFrame", 1, offsetof(StimDesc, stimOffFrame)},
	{@"short",	@"listTypes", kStimLocs, offsetof(StimDesc, listTypes)},
	{@"long",	@"stimTypes", kStimLocs, offsetof(StimDesc, stimTypes)},
	{@"float",	@"contrasts", kStimLocs, offsetof(StimDesc, contrasts)},
	{@"float",	@"directionsDeg", kStimLocs, offsetof(StimDesc, directionsDeg)},
	{@"float",	@"centerContrast", kStimLocs, offsetof(StimDesc, centerContrast)},
	{nil}};
LLDataDef trialDescDef[] = {
	{@"boolean",@"catchTrial", 1, offsetof(TrialDesc, catchTrial)},
	{@"boolean",@"hasDistractors", 1, offsetof(TrialDesc, hasDistractors)},
	{@"boolean",@"instructTrial", 1, offsetof(TrialDesc, instructTrial)},
	{@"long",	@"repeatCount", 1, offsetof(TrialDesc, repeatCount)},
	{@"long",	@"attendState", 1, offsetof(TrialDesc, attendState)},
	{@"long",	@"attendLoc", 1, offsetof(TrialDesc, attendLoc)},
	{@"long",	@"numStim", 1, offsetof(TrialDesc, numStim)},
	{@"long",	@"rewardMS", 1, offsetof(TrialDesc, rewardMS)},
	{@"long",	@"targetOnTimeMS", 1, offsetof(TrialDesc, targetOnTimeMS)},
	{@"long",	@"targetIndices", kStimLocs, offsetof(TrialDesc, targetIndices)},
	{@"float",	@"targetContrastChangePC", kStimLocs, offsetof(TrialDesc, targetContrastChangePC)},
	{nil}};
	
DataAssignment eyeRXDataAssignment = {@"eyeRXData",     @"Synthetic", 2, 5.0};	
DataAssignment eyeRYDataAssignment = {@"eyeRYData",     @"Synthetic", 3, 5.0};	
DataAssignment eyeRPDataAssignment = {@"eyeRPData",     @"Synthetic", 4, 5.0};	
DataAssignment eyeLXDataAssignment = {@"eyeLXData",     @"Synthetic", 5, 5.0};	
DataAssignment eyeLYDataAssignment = {@"eyeLYData",     @"Synthetic", 6, 5.0};	
DataAssignment eyeLPDataAssignment = {@"eyeLPData",     @"Synthetic", 7, 5.0};	
DataAssignment spikeDataAssignment = {@"spikeData",     @"Synthetic", 2, 1};
DataAssignment VBLDataAssignment =   {@"VBLData",       @"Synthetic", 1, 1};	
	
EventDefinition VCANEvents[] = {
// recorded at start of file
	{@"gabor",				sizeof(Gabor),			{@"struct", @"gabor", 1, 0, sizeof(Gabor), gaborStructDef}},
	{@"eccentricityDeg",	sizeof(float),			{@"float"}},
	{@"polarAngleRF0Deg",	sizeof(float),			{@"float"}},
	{@"polarAngleRF1Deg",	sizeof(float),			{@"float"}},
	{@"polarAngleRFOutDeg",	sizeof(float),			{@"float"}},
	{@"separationDeg",		sizeof(float),			{@"float"}},
// timing parameters
	{@"stimDurationMS",		sizeof(long),			{@"long"}},
	{@"interstimMS",		sizeof(long),			{@"long"}},
	{@"stimLeadMS",			sizeof(long),			{@"long"}},
	{@"responseTimeMS",		sizeof(long),			{@"long"}},
	{@"tooFastTimeMS",		sizeof(long),			{@"long"}},
	{@"tries",				sizeof(long),			{@"long"}},
	{@"stimRepsPerBlock",	sizeof(long),			{@"long"}},
    {@"precueMS",		    sizeof(long),			{@"long"}},
    {@"preStimMS",		    sizeof(long),			{@"long"}},
	{@"blockStatus",		sizeof(BlockStatus),	{@"struct", @"blockStatus", 1, 0, sizeof(BlockStatus), blockStatusDef}},
	{@"maxTargetMS",        sizeof(long),			{@"long"}},
// declared at start of each trial
	{@"trial",				sizeof(TrialDesc),		{@"struct", @"trial", 1, 0, sizeof(TrialDesc), trialDescDef}},
	{@"trialCount",         sizeof(long),			{@"long"}},
	{@"responseWindow",		sizeof(FixWindowData),	{@"struct", @"fixWindowData", 1, 0, sizeof(FixWindowData), fixWindowStructDef}},
	{@"relDistContrast",	sizeof(float),			{@"float"}},
// marking the course of each trial
	{@"cueOn",				0,						{@"no data"}},
	{@"preStimuli",			0,						{@"no data"}},
	{@"stimulus",			sizeof(StimDesc),		{@"struct", @"stimDesc", 1, 0, sizeof(StimDesc), stimDescDef}},
	{@"postStimuli",		0,						{@"no data"}},
	{@"saccade",			0,						{@"no data"}},
	{@"questResults",		sizeof(QuestResults),	{@"struct", @"questResults", 1, 0, sizeof(QuestResults), questResultsDef}},
	{@"staircaseResult", 	sizeof(float),			{@"float"}},
	{@"extendedEOT", 		sizeof(long),			{@"long"}},

	{@"taskMode", 			sizeof(long),			{@"long"}},
	{@"reset", 				sizeof(long),			{@"long"}}, 

	{@"frameCheck",         sizeof(long),			{@"long"}},

};

BlockStatus				blockStatus;
BOOL					brokeDuringStim;
VCANDigitalOut			*digitalOut = nil;
NSDate                  *lastDataCollectionDate = nil;
long					stimDone[kNumStates][kStimPerState] = {};
LLTaskPlugIn			*task = nil;
LLScheduleController	*scheduler = nil;
VCANStimuli				*stimuli = nil;


long xEventsPosted = 0;
long yEventsPosted = 0;
long xBytesPosted = 0;
long yBytesPosted = 0;
long xEventsReceived = 0;
long yEventsReceived = 0;
long xBytesReceived = 0;
long yBytesReceived = 0;

@implementation V4CAN

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
   
// Make sure that the task status is in the right state
    
    [taskStatus setMode:kTaskIdle];
    [taskStatus setDataFileOpen:NO];
	
// Erase the stimulus display

    [stimuli assignMonitorInterval];                    // frame rate might have changed
	[stimuli erase];
	
// Create on-line display windows

	
	[[controlPanel window] orderFront:self];
  
	behaviorController = [[VCANBehaviorController alloc] init];
    [dataDoc addObserver:behaviorController];

	spikeController = [[VCANSpikeController alloc] init];
    [dataDoc addObserver:spikeController];

    eyeXYController = [[VCANEyeXYController alloc] init];
    [dataDoc addObserver:eyeXYController];

    summaryController = [[VCANSummaryController alloc] init];
    [dataDoc addObserver:summaryController];
 
	xtController = [[VCANXTController alloc] init];
    [dataDoc addObserver:xtController];

    diagnosticsController = [[VCANDiagnosticsController alloc] init];
    [dataDoc addObserver:diagnosticsController];
    

// Set up data events (after setting up windows to receive them)

	[dataDoc defineEvents:[LLStandardDataEvents eventsWithDataDefs] count:[LLStandardDataEvents 
                                                                           countOfEventsWithDataDefs]];
	[dataDoc defineEvents:VCANEvents count:(sizeof(VCANEvents) / sizeof(EventDefinition))];
	

// Set up the data collector to handle our data types

	[dataController assignSampleData:eyeRXDataAssignment];
	[dataController assignSampleData:eyeRYDataAssignment];
	[dataController assignSampleData:eyeRPDataAssignment];
	[dataController assignSampleData:eyeLXDataAssignment];
	[dataController assignSampleData:eyeLYDataAssignment];
	[dataController assignSampleData:eyeLPDataAssignment];
	[dataController assignTimestampData:spikeDataAssignment];
	[dataController assignTimestampData:VBLDataAssignment];
	[dataController assignDigitalInputDevice:@"Synthetic"];
	[dataController assignDigitalOutputDevice:@"Synthetic"];
    
    
	collectorTimer = [NSTimer scheduledTimerWithTimeInterval:0.004 target:self selector:@selector(dataCollect:)
                userInfo:nil repeats:YES];
	[dataDoc addObserver:stateSystem];
    [stateSystem startWithCheckIntervalMS:5];				// Start the experiment state system
	
	active = YES;
	
// Put events for start of state system
	
	announceEvents();
	longValue = 0;
	[[task dataDoc] putEvent:@"reset" withData:&longValue];
    
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
    NSPoint newEyeDeg;
    
    float eyeFilter = [[task defaults] floatForKey:@"VCANEyeFilter"];
    
        
	if ((data = [dataController dataOfType:@"eyeLXData"]) != nil) {
		[dataDoc putEvent:@"eyeLXData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
		currentEyesUnits[kLeftEye].x = *(short *)([data bytes] + [data length] - sizeof(short));
	}
    
	if ((data = [dataController dataOfType:@"eyeLYData"]) != nil) {
        [dataDoc putEvent:@"eyeLYData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
		currentEyesUnits[kLeftEye].y = *(short *)([data bytes] + [data length] - sizeof(short));
		newEyeDeg = [[task eyeCalibrator] degPointFromUnitPoint:currentEyesUnits[kLeftEye] forEye:kLeftEye];
        currentEyesDeg[kLeftEye].x = newEyeDeg.x * eyeFilter + currentEyesDeg[kLeftEye].x * (1 - eyeFilter);
        currentEyesDeg[kLeftEye].y = newEyeDeg.y * eyeFilter + currentEyesDeg[kLeftEye].y * (1 - eyeFilter);
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
		newEyeDeg = [[task eyeCalibrator] degPointFromUnitPoint:currentEyesUnits[kRightEye] forEye:kRightEye];
        currentEyesDeg[kRightEye].x = newEyeDeg.x * eyeFilter + currentEyesDeg[kRightEye].x * (1 - eyeFilter);
        currentEyesDeg[kRightEye].y = newEyeDeg.y * eyeFilter + currentEyesDeg[kRightEye].y * (1 - eyeFilter);
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
	
// Stop data collection and shut down the plug in

- (void)deactivate:(id)sender;
{
	long index;
    
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
    [dataDoc removeObserver:diagnosticsController];
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
    [diagnosticsController close];
    [diagnosticsController release];
    [xtController close];
    [xtController release];
    [[controlPanel window] close];
    
    for (index = 0; index < kNumStates; index++) {
        [stateColors[index] release];
        stateColors[index] = nil;
    }

	active = NO;
}

- (void)dealloc;
{
	long index;
 
	while ([stateSystem running]) {
        [NSThread sleepForTimeInterval:(NSTimeInterval)0.005];
    };		// wait for state system to stop, then release it
	
	for (index = 0; keyPaths[index] != nil; index++) {
		[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:keyPaths[index]];
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self]; 

    [[task dataDoc] removeObserver:stateSystem];
    [stateSystem release];
	
	[actionsMenuItem release];
	[settingsMenuItem release];
	[scheduler release];
    [rewardAverage release];
	[digitalOut release];
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
		juiceMS = [[task defaults] integerForKey:VCANRewardMSKey];
	}
	[[task dataController] digitalOutputBitsOff:kRewardBit];
	[scheduler schedule:@selector(doJuiceOff) toTarget:self withObject:nil delayMS:juiceMS];
	if ([[task defaults] boolForKey:VCANDoSoundsKey]) {
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

- (void)doRewardAverage:(NSString *)averageString;
{
    [rewardAverageField setStringValue:averageString];
}

- (void)doRewardTrial:(NSString *)trialString;
{
    [rewardTrialField setStringValue:trialString];
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

- (IBAction)doStaircaseReset:(id)sender;
{
    [stateSystem performSelector:@selector(doStaircaseReset)];
}

- (IBAction)doTargetSpotSettings:(id)sender;
{
	[stimuli doTargetSpotSettings];
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
	stimuli = [[VCANStimuli alloc] init];
	digitalOut = [[VCANDigitalOut alloc] init];

// Load the items in the nib

	[NSBundle loadNibNamed:@"V4CAN" owner:self];
	
// Initialize other task objects

	scheduler = [[LLScheduleController alloc] init];
	stateSystem = [[VCANStateSystem alloc] init];
    rewardAverage = [[LLNormDist alloc] init];

// Set up control panel and observer for control panel

	controlPanel = [[LLControlPanel alloc] init];
	[controlPanel setWindowFrameAutosaveName:@"VCANControlPanel"];
	[[controlPanel window] setFrameUsingName:@"VCANControlPanel"];
	[[controlPanel window] setTitle:@"V4CAN"];
	[[NSNotificationCenter defaultCenter] addObserver:self 
		selector:@selector(doControls:) name:nil object:controlPanel];

// Prepare the state colors

    stateColors[kInInAttIn0] = [NSColor colorWithDeviceRed:0.8 green:0.0 blue:0.0 alpha:1.0];	// red
	stateColors[kInInAttIn1] = [NSColor colorWithDeviceRed:0.0 green:0.6 blue:0.0 alpha:1.0];	// green
	stateColors[kInInAttFar0] = [NSColor colorWithDeviceRed:0.6 green:0.0 blue:0.8 alpha:1.0];	// blue
	stateColors[kInInAttFar1] = [NSColor colorWithDeviceRed:0.6 green:0.0 blue:0.8 alpha:1.0];	// blue

	stateColors[kInOutAttIn0] = [NSColor colorWithDeviceRed:0.6 green:0.0 blue:0.0 alpha:1.0];	// dark red
	stateColors[kInOutAttOut1] = [NSColor colorWithDeviceRed:0.0 green:0.4 blue:0.0 alpha:1.0];	// dark green
	stateColors[kInOutAttFar0] = [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.6 alpha:1.0];	// dark blue
	stateColors[kInOutAttFar1] = [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.6 alpha:1.0];	// dark blue
    for (index = 0; index < kNumStates; index++) {
        [stateColors[index] retain];
    }
}

- (long)mode;
{
	return [taskStatus mode];
}

- (NSString *)name;
{
	return @"V4CAN";
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
	if ([key isEqualTo:VCANRespTimeMSKey]) {
		longValue = [defaults integerForKey:VCANRespTimeMSKey];
		[dataDoc putEvent:@"responseTimeMS" withData:&longValue];
	}
	else if ([key isEqualTo:VCANStimDurationMSKey]) {
		longValue = [defaults integerForKey:VCANStimDurationMSKey];
		[dataDoc putEvent:@"stimDurationMS" withData:&longValue];
		requestReset();
	}
	else if ([key isEqualTo:VCANInterstimMSKey]) {
		longValue = [defaults integerForKey:VCANInterstimMSKey];
		[dataDoc putEvent:@"interstimMS" withData:&longValue];
		requestReset();
	}
	else if ([key isEqualTo:VCANMaxTargetMSKey]) {
		longValue = [defaults integerForKey:VCANMaxTargetMSKey];
		[dataDoc putEvent:@"maxTargetMS" withData:&longValue];
		requestReset();
	}
	else if ([key isEqualTo:VCANStimRepsPerBlockKey]) {
		longValue = [defaults integerForKey:VCANStimRepsPerBlockKey];
		[dataDoc putEvent:@"stimRepsPerBlock" withData:&longValue];
		requestReset();
	}
}

- (DisplayModeParam)requestedDisplayMode;
{
	displayMode.widthPix = 1024;
	displayMode.heightPix = 768;
	displayMode.pixelBits = 32;
	displayMode.frameRateHz = 100;
	return displayMode;
}

- (void)setMode:(long)newMode;
{
	[taskStatus setMode:newMode];
	[defaults setInteger:[taskStatus status] forKey:VCANTaskStatusKey];
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
		[defaults setInteger:[taskStatus status] forKey:VCANTaskStatusKey];
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

- (VCANStimuli *)stimuli;
{
	return stimuli;
}
@end
