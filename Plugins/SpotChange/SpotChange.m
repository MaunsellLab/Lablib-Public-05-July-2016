//
//  SpotChange.m
//  SpotChange
//
//  Copyright 2013. All rights reserved.
//

/*
 
 This is a mash-up project to collect data on whether a V4 attention axis constructed using responses to one stimulus
 can predict performance using other stimuli at different distances.  Patrick Mayo added this on to his recordings with
 Arturo, but doesn't have a second monkey, so Bram Verhoef is going to record from Fonz.  Fonz, however, is used to 
 flashed stimuli, not continuous stimuli. Modifying either Patrick project (OrientationChange) or Bram's project 
 (VICAN) would be more difficult than modifying Marlene Cohem's old project (OrientationChange MRC), so this project
 is derived from that. We've added support for binocular signals from the EyeLink, and the spot changes that Bram's
 animals use.
 */

#import "SC.h"
#import "SpotChange.h"
#import "SCSummaryController.h"
#import "SCBehaviorController.h"
#import "SCSpikeController.h"
#import "SCXTController.h"
#import "UtilityFunctions.h"

#define		kRewardBit				0x0001

// Behavioral parameters

NSString *SCAcquireMSKey = @"SCAcquireMS";
NSString *SCBlockLimitKey = @"SCBlockLimit";
NSString *SCBreakPunishMSKey = @"SCBreakPunishMS";
NSString *SCChangeScaleKey = @"SCChangeScale";
NSString *SCCatchTrialPCKey = @"SCCatchTrialPC";
NSString *SCCatchTrialMaxPCKey = @"SCCatchTrialMaxPC";
NSString *SCCueMSKey = @"SCCueMS";
NSString *SCDoSoundsKey = @"SCDoSounds";
NSString *SCFixateKey = @"SCFixate";
NSString *SCFixateMSKey = @"SCFixateMS";
NSString *SCFixGraceMSKey = @"SCFixGraceMS";
NSString *SCFixJitterPCKey = @"SCFixJitterPC";
NSString *SCFixWindowWidthDegKey = @"SCFixWindowWidthDeg";
NSString *SCInstructionTrialsKey = @"SCInstructionTrials";
NSString *SCIntertrialMSKey = @"SCIntertrialMS";
NSString *SCInvalidRewardFactorKey = @"SCInvalidRewardFactor";
NSString *SCMinTargetMSKey = @"SCMinTargetMS";
NSString *SCMaxTargetMSKey = @"SCMaxTargetMS";
NSString *SCMeanTargetMSKey = @"SCMeanTargetMS";
NSString *SCNontargetContrastPCKey = @"SCNontargetContrastPC";
NSString *SCNumExtraInstructTrialsKey = @"SCNumExtraInstructTrials";
NSString *SCNumMistakesForExtraInstructionsKey = @"SCNumMistakesForExtraInstructions";
NSString *SCRespSpotSizeDegKey = @"SCRespSpotSizeDeg";
NSString *SCRespTimeMSKey = @"SCRespTimeMS";
NSString *SCRespWindowWidthDegKey = @"SCRespWindowWidthDeg";
NSString *SCRewardMSKey = @"SCRewardMS";
NSString *SCMinRewardMSKey = @"SCMinRewardMS";
NSString *SCRewardScheduleKey = @"SCRewardSchedule";
NSString *SCSaccadeTimeMSKey = @"SCSaccadeTimeMS";
NSString *SCStimRepsPerBlockKey = @"SCStimRepsPerBlock";
NSString *SCStimDistributionKey = @"SCStimDistribution";
NSString *SCTaskStatusKey = @"SCTaskStatus";
NSString *SCTooFastMSKey = @"SCTooFastMS";
NSString *SCValidFATimePunishMSKey = @"SCValidFATimePunishMS";
NSString *SCInvalidFATimePunishMSKey = @"SCInvalidFATimePunishMS";

// Stimulus Parameters

NSString *SCInterstimJitterPCKey = @"SCInterstimJitterPC";
NSString *SCInterstimMSKey = @"SCInterstimMS";
NSString *SCStimDurationMSKey = @"SCStimDurationMS";
NSString *SCStimJitterPCKey = @"SCStimJitterPC";
NSString *SCOrientationChangesKey = @"SCOrientationChanges";
NSString *SCMaxDirChangeDegKey = @"SCMaxDirChangeDeg";
NSString *SCMinDirChangeDegKey = @"SCMinDirChangeDeg";
NSString *SCChangeRemainKey = @"SCChangeRemain";
NSString *SCChangeArrayKey = @"SCChangeArray";
NSString *SCGabor1AlphaFactorKey = @"SCGabor1AlphaFactor";

// Visual Stimulus Parameters 

NSString *SCDistContrastPCKey = @"SCDistContrastPC";
NSString *SCSpatialPhaseDegKey = @"SCSpatialPhaseDeg";
NSString *SCTemporalFreqHzKey = @"SCTemporalFreqHz";

// Keys for change array

NSString *SCChangeKey = @"change";
NSString *SCValidRepsKey = @"validReps";
NSString *SCInvalidRepsKey = @"invalidReps";

NSString *keyPaths[] = {@"values.SCBlockLimit", @"values.SCRespTimeMS", 
					@"values.SCStimDurationMS", @"values.SCInterstimMS", @"values.SCOrientationChanges", 
					@"values.SCMinDirChangeDeg", @"values.SCMaxDirChangeDeg", @"values.SCStimRepsPerBlock",
					@"values.SCMinTargetMS", @"values.SCMaxTargetMS", @"values.SCChangeArray",
					@"values.SCChangeScale", @"values.SCMeanTargetMS", @"values.SCFixateMS",
					nil};

LLScheduleController	*scheduler = nil;
SCStimuli				*stimuli = nil;
SCDigitalOut			*digitalOut = nil;

LLDataDef gaborStructDef[] = kLLGaborEventDesc;
LLDataDef fixWindowStructDef[] = kLLEyeWindowEventDesc;

LLDataDef blockStatusDef[] = {
	{@"long",	@"changes", 1, offsetof(BlockStatus, changes)},
	{@"float",	@"orientationChangeDeg", kMaxOriChanges, offsetof(BlockStatus, orientationChangeDeg)},
	{@"long",	@"validReps", kMaxOriChanges, offsetof(BlockStatus, validReps)},
	{@"long",	@"validRepsDone", kMaxOriChanges, offsetof(BlockStatus, validRepsDone)},
	{@"long",	@"invalidReps", kMaxOriChanges, offsetof(BlockStatus, invalidReps)},
	{@"long",	@"invalidRepsDone", kMaxOriChanges, offsetof(BlockStatus, invalidRepsDone)},
	{@"long",	@"instructDone", 1, offsetof(BlockStatus, instructDone)},
	{@"long",	@"instructTrials", 1, offsetof(BlockStatus, instructTrials)},
	{@"long",	@"sidesDone", 1, offsetof(BlockStatus, sidesDone)},
	{@"long",	@"blockLimit", 1, offsetof(BlockStatus, blockLimit)},
	{@"long",	@"blocksDone", 1, offsetof(BlockStatus, blocksDone)},
	{nil}};

LLDataDef stimDescDef[] = {
	{@"long",	@"index", 1, offsetof(StimDesc, index)},
	{@"long",	@"stimOnFrame", 1, offsetof(StimDesc, stimOnFrame)},
	{@"long",	@"stimOffFrame", 1, offsetof(StimDesc, stimOffFrame)},
	{@"short",	@"stim0Type", 1, offsetof(StimDesc, stim0Type)},
	{@"short",	@"stim1Type", 1, offsetof(StimDesc, stim1Type)},
	{@"float",	@"contrast0PC", 1, offsetof(StimDesc, contrast0PC)},
	{@"float",	@"contrast1PC", 1, offsetof(StimDesc, contrast1PC)},
	{@"float",	@"direction0Deg", 1, offsetof(StimDesc, direction0Deg)},
	{@"float",	@"direction1Deg", 1, offsetof(StimDesc, direction1Deg)},
	{@"float",	@"orientationChangeDeg", 1, offsetof(StimDesc, orientationChangeDeg)},
	{nil}};

LLDataDef trialDescDef[] = {
	{@"boolean",@"instructTrial", 1, offsetof(TrialDesc, instructTrial)},
	{@"boolean",@"validTrial", 1, offsetof(TrialDesc, validTrial)},
	{@"boolean",@"catchTrial", 1, offsetof(TrialDesc, catchTrial)},
	{@"long",	@"attendLoc", 1, offsetof(TrialDesc, attendLoc)},
	{@"long",	@"correctLoc", 1, offsetof(TrialDesc, correctLoc)},
	{@"long",	@"numStim", 1, offsetof(TrialDesc, numStim)},
	{@"long",	@"targetIndex", 1, offsetof(TrialDesc, targetIndex)},
	{@"long",	@"targetOnTimeMS", 1, offsetof(TrialDesc, targetOnTimeMS)},
	{@"long",	@"orientationChangeIndex", 1, offsetof(TrialDesc, orientationChangeIndex)},
	{@"float",	@"orientationChangeDeg", 1, offsetof(TrialDesc, orientationChangeDeg)},
	{nil}};

LLDataDef behaviorSettingDef[] = {
	{@"long",	@"blocks", 1, offsetof(BehaviorSetting, blocks)},
	{@"long",	@"intertrialMS", 1, offsetof(BehaviorSetting, intertrialMS)},
	{@"long",	@"acquireMS", 1, offsetof(BehaviorSetting, acquireMS)},
	{@"long",	@"fixGraceMS", 1, offsetof(BehaviorSetting, fixGraceMS)},
	{@"long",	@"fixateMS", 1, offsetof(BehaviorSetting, fixateMS)},
	{@"long",	@"fixateJitterPC", 1, offsetof(BehaviorSetting, fixateJitterPC)},
	{@"long",	@"responseTimeMS", 1, offsetof(BehaviorSetting, responseTimeMS)},
	{@"long",	@"tooFastMS", 1, offsetof(BehaviorSetting, tooFastMS)},
	{@"long",	@"minSaccadeDurMS", 1, offsetof(BehaviorSetting, minSaccadeDurMS)},
	{@"long",	@"breakPunishMS", 1, offsetof(BehaviorSetting, breakPunishMS)},
	{@"long",	@"rewardSchedule", 1, offsetof(BehaviorSetting, rewardSchedule)},
	{@"long",	@"rewardMS", 1, offsetof(BehaviorSetting, rewardMS)},
	{@"float",	@"fixWinWidthDeg", 1, offsetof(BehaviorSetting, fixWinWidthDeg)},
	{@"float",	@"respWinWidthDeg", 1, offsetof(BehaviorSetting, respWinWidthDeg)},
	{nil}};

LLDataDef stimSettingDef[] = {
	{@"long",	@"stimDurationMS", 1, offsetof(StimSetting, stimDurationMS)},
	{@"long",	@"stimDurJitterPC", 1, offsetof(StimSetting, stimDurJitterPC)},
	{@"long",	@"interStimMS", 1, offsetof(StimSetting, interStimMS)},
	{@"long",	@"interStimJitterPC", 1, offsetof(StimSetting, interStimJitterPC)},
	{@"long",	@"stimLeadMS", 1, offsetof(StimSetting, stimLeadMS)},
	{@"float",	@"stimSpeedHz", 1, offsetof(StimSetting, stimSpeedHz)},
	{@"long",	@"stimDistribution", 1, offsetof(StimSetting, stimDistribution)},
	{@"long",	@"minTargetOnTimeMS", 1, offsetof(StimSetting, minTargetOnTimeMS)},
	{@"long",	@"meanTargetOnTimeMS", 1, offsetof(StimSetting, meanTargetOnTimeMS)},
	{@"long",	@"maxTargetOnTimeMS", 1, offsetof(StimSetting, maxTargetOnTimeMS)},
	{@"float",	@"eccentricityDeg", 1, offsetof(StimSetting, eccentricityDeg)},
	{@"float",	@"polarAngleDeg", 1, offsetof(StimSetting, polarAngleDeg)},
	{@"float",	@"driftDirectionDeg", 1, offsetof(StimSetting, driftDirectionDeg)},
	{@"float",	@"contrastPC", 1, offsetof(StimSetting, contrastPC)},
	{@"short",	@"numberOfSurrounds", 1, offsetof(StimSetting, numberOfSurrounds)},
	{@"long",	@"changeScale", 1, offsetof(StimSetting, changeScale)},
	{@"long",	@"orientationChanges", 1, offsetof(StimSetting, orientationChanges)},
	{@"float",	@"maxChangeDeg", 1, offsetof(StimSetting, maxChangeDeg)},
	{@"float",	@"minChangeDeg", 1, offsetof(StimSetting, minChangeDeg)},
	{@"long",	@"changeRemains", 1, offsetof(StimSetting, changeRemains)},
	{nil}};

DataAssignment eyeRXDataAssignment = {@"eyeRXData",     @"Synthetic", 2, 5.0};
DataAssignment eyeRYDataAssignment = {@"eyeRYData",     @"Synthetic", 3, 5.0};
DataAssignment eyeRPDataAssignment = {@"eyeRPData",     @"Synthetic", 4, 5.0};
DataAssignment eyeLXDataAssignment = {@"eyeLXData",     @"Synthetic", 5, 5.0};
DataAssignment eyeLYDataAssignment = {@"eyeLYData",     @"Synthetic", 6, 5.0};
DataAssignment eyeLPDataAssignment = {@"eyeLPData",     @"Synthetic", 7, 5.0};
DataAssignment spikeDataAssignment = {@"spikeData",     @"Synthetic", 2, 1};
DataAssignment VBLDataAssignment =   {@"VBLData",       @"Synthetic", 1, 1};

EventDefinition SCEvents[] = {
// recorded at start of file, these need to be announced using announceEvents() in UtilityFunctions.m
	{@"gabor0",				sizeof(Gabor),			{@"struct", @"gabor0", 1, 0, sizeof(Gabor), gaborStructDef}},
	{@"gabor1",				sizeof(Gabor),			{@"struct", @"gabor1", 1, 0, sizeof(Gabor), gaborStructDef}},
	{@"behaviorSetting",	sizeof(BehaviorSetting),{@"struct", @"behaviorSetting", 1, 0, sizeof(BehaviorSetting), behaviorSettingDef}},
	{@"stimSetting",		sizeof(StimSetting),	{@"struct", @"stimSetting", 1, 0, sizeof(StimSetting), stimSettingDef}},
	{@"eccentricityDeg",	sizeof(float),			{@"float"}},
	{@"polarAngleDeg",		sizeof(float),			{@"float"}},
// timing parameters
	{@"stimDurationMS",		sizeof(long),			{@"long"}},
	{@"interstimMS",		sizeof(long),			{@"long"}},
	{@"stimLeadMS",			sizeof(long),			{@"long"}},
	{@"responseTimeMS",		sizeof(long),			{@"long"}},
	{@"fixateMS",			sizeof(long),			{@"long"}},
	{@"tooFastTimeMS",		sizeof(long),			{@"long"}},
	{@"blockStatus",		sizeof(BlockStatus),	{@"struct", @"blockStatus", 1, 0, sizeof(BlockStatus), blockStatusDef}},
	{@"meanTargetTimeMS",	sizeof(long),			{@"long"}},
	{@"minTargetTimeMS",	sizeof(long),			{@"long"}},
	{@"maxTargetTimeMS",	sizeof(long),			{@"long"}},

// declared at start of each trial	
	{@"trial",				sizeof(TrialDesc),		{@"struct", @"trial", 1, 0, sizeof(TrialDesc), trialDescDef}},
//	{@"responseWindow",		sizeof(FixWindowData),	{@"struct", @"responseWindowData", 1, 0, sizeof(FixWindowData), fixWindowStructDef}},
	{@"responseWindow",		sizeof(FixWindowData),	{@"struct", @"responseWindowData", 1, 0, sizeof(FixWindowData), fixWindowStructDef}},
	{@"wrongWindow",		sizeof(FixWindowData),	{@"struct", @"wrongWindow", 1, 0, sizeof(FixWindowData), fixWindowStructDef}},

// marking the course of each trial
	{@"preStimuli",			0,						{@"no data"}},
	{@"stimulus",			sizeof(StimDesc),		{@"struct", @"stimDesc", 1, 0, sizeof(StimDesc), stimDescDef}},
	{@"stimulusOffTime",	0,						{@"no data"}},
	{@"stimulusOnTime",		0,						{@"no data"}},
	{@"postStimuli",		0,						{@"no data"}},
	{@"saccade",			0,						{@"no data"}},
	{@"tooFast",			0,						{@"no data"}},
	{@"react",				0,						{@"no data"}},
	{@"fixGrace",			0,						{@"no data"}},
	{@"myTrialEnd",			sizeof(long),			{@"long"}},

	{@"taskMode", 			sizeof(long),			{@"long"}},
	{@"reset", 				sizeof(long),			{@"long"}}, 
};

long			attendLoc = 0;
BlockStatus		blockStatus = {};
BOOL			brokeDuringStim = NO;
LLTaskPlugIn	*task = nil;


@implementation SpotChange

+ (NSInteger)version;
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
  
	behaviorController = [[SCBehaviorController alloc] init];
    [dataDoc addObserver:behaviorController];

	spikeController = [[SCSpikeController alloc] init];
    [dataDoc addObserver:spikeController];

    eyeXYController = [[SCEyeXYController alloc] init];
    [dataDoc addObserver:eyeXYController];

    summaryController = [[SCSummaryController alloc] init];
    [dataDoc addObserver:summaryController];
 
	xtController = [[SCXTController alloc] init];
    [dataDoc addObserver:xtController];

// Set up data events (after setting up windows to receive them)

	[dataDoc defineEvents:[LLStandardDataEvents eventsWithDataDefs] count:[LLStandardDataEvents countOfEventsWithDataDefs]];
	[dataDoc defineEvents:SCEvents count:(sizeof(SCEvents) / sizeof(EventDefinition))];
	announceEvents();
	longValue = 0;
	[[task dataDoc] putEvent:@"reset" withData:&longValue];
	

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
    NSPoint newEyeDeg;
    
    float eyeFilter = [[task defaults] floatForKey:@"SCEyeFilter"];
    
    
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
	[digitalOut release];
	[controlPanel release];
	[taskStatus release];
    [topLevelObjects release];
	[super dealloc];
}

//-(SCDigitalOut *)digitalOut;
//{
//	return digitalOut;
//}

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
	[stimuli doFixSettings];
}

- (IBAction)doGabor0Settings:(id)sender;
{
	[stimuli doGabor0Settings];
}

- (IBAction)doGabor1Settings:(id)sender;
{
	[stimuli doGabor1Settings];
}

- (IBAction)doJuice:(id)sender;
{
	long juiceMS, rewardSchedule;
	long minTargetMS, maxTargetMS;
	long minRewardMS, maxRewardMS;
	long targetOnTimeMS;
	float alpha, beta;
	
	NSSound *juiceSound;
	
	if ([sender respondsToSelector:@selector(juiceMS)]) {
		juiceMS = (long)[sender performSelector:@selector(juiceMS)];
	}
	else {
		juiceMS = [[task defaults] integerForKey:SCRewardMSKey];
	}

	rewardSchedule = [[task defaults] integerForKey:SCRewardScheduleKey];

	if (rewardSchedule == kRewardVariable) {
		minTargetMS = [[task defaults] integerForKey:SCMinTargetMSKey];
		maxTargetMS = [[task defaults] integerForKey:SCMaxTargetMSKey];
		
		minRewardMS = [[task defaults] integerForKey:SCMinRewardMSKey];;
		maxRewardMS = juiceMS * 2 - minRewardMS;
		
		beta = (float)(maxRewardMS - minRewardMS) / (float)(maxTargetMS - minTargetMS);
		alpha = minRewardMS - beta * minTargetMS;
		targetOnTimeMS = MIN(MAX(trial.targetOnTimeMS, minTargetMS), maxTargetMS);
		juiceMS = MAX(1, beta * targetOnTimeMS + alpha);
	}

// For invalid trials, apply invalid multiplier

	if (!trial.validTrial) {
		juiceMS *= [[task defaults] floatForKey:SCInvalidRewardFactorKey];
	}
	[[task dataController] digitalOutputBitsOff:kRewardBit];
	[scheduler schedule:@selector(doJuiceOff) toTarget:self withObject:nil delayMS:juiceMS];
	if ([[task defaults] boolForKey:SCDoSoundsKey]) {
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
	NSString *userDefaultsValuesPath;
    NSDictionary *userDefaultsValuesDict;
	
	extern long argRand;
	
	task = self;
	
// Register our default settings. This should be done first thing, before the
// nib is loaded, because items in the nib are linked to defaults

	userDefaultsValuesPath = [[NSBundle bundleForClass:[self class]]
						pathForResource:@"UserDefaults" ofType:@"plist"];
	userDefaultsValuesDict = [NSDictionary dictionaryWithContentsOfFile:userDefaultsValuesPath];
	[[task defaults] registerDefaults:userDefaultsValuesDict];
	[NSValueTransformer 
			setValueTransformer:[[[LLFactorToOctaveStepTransformer alloc] init] autorelease]
			forName:@"FactorToOctaveStepTransformer"];

	[NSValueTransformer 
			setValueTransformer:[[[SCRoundToStimCycle alloc] init] autorelease]
			forName:@"RoundToStimCycle"];


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
	stimuli = [[SCStimuli alloc] init];
	digitalOut = [[SCDigitalOut alloc] init];

// Load the items in the nib

	[[NSBundle bundleForClass:[self class]] loadNibNamed:@"SpotChange" owner:self topLevelObjects:&topLevelObjects];
	[topLevelObjects retain];
	
// Initialize other task objects

	scheduler = [[LLScheduleController alloc] init];
	stateSystem = [[SCStateSystem alloc] init];

// Set up control panel and observer for control panel

	controlPanel = [[LLControlPanel alloc] init];
	[controlPanel setWindowFrameAutosaveName:@"SCControlPanel"];
	[[controlPanel window] setFrameUsingName:@"SCControlPanel"];
	[[controlPanel window] setTitle:@"SpotChange"];
	[[NSNotificationCenter defaultCenter] addObserver:self 
		selector:@selector(doControls:) name:nil object:controlPanel];
	
// initilize arg for randUnitInterval()
	srand(time(nil));
	argRand = -1 * abs(rand());
}

- (long)mode;
{
	return [taskStatus mode];
}

- (NSString *)name;
{
	return @"SpotChange";
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
	if ([key isEqualTo:SCRespTimeMSKey]) {
		longValue = [defaults integerForKey:SCRespTimeMSKey];
		[dataDoc putEvent:@"responseTimeMS" withData:&longValue];
	}
	else if ([key isEqualTo:SCStimDurationMSKey]) {
		longValue = [defaults integerForKey:SCStimDurationMSKey];
		[dataDoc putEvent:@"stimDurationMS" withData:&longValue];
		if ([[task defaults] integerForKey:SCStimDistributionKey] == kExponential) {
			updateCatchTrialPC();
		}
		requestReset();
	}
	else if ([key isEqualTo:SCMeanTargetMSKey]) {
		longValue = [defaults integerForKey:SCMeanTargetMSKey];
		[dataDoc putEvent:@"meanTargetTimeMS" withData:&longValue];
		if ([[task defaults] integerForKey:SCStimDistributionKey] == kExponential) {
			updateCatchTrialPC();
		}
//		requestReset();
	}
	else if ([key isEqualTo:SCMaxTargetMSKey]) {
		longValue = [defaults integerForKey:SCMaxTargetMSKey];
		[dataDoc putEvent:@"maxTargetTimeMS" withData:&longValue];
		if ([[task defaults] integerForKey:SCStimDistributionKey] == kUniform) {
			longValue = [defaults integerForKey:SCMinTargetMSKey] +
						([defaults integerForKey:SCMaxTargetMSKey] - [defaults integerForKey:SCMinTargetMSKey]) / 2.0;
//			[[task defaults] setInteger: longValue forKey: SCMeanTargetMSKey];
		}
		else updateCatchTrialPC();
		requestReset();
	}
	else if ([key isEqualTo:SCMinTargetMSKey]) {
		longValue = [defaults integerForKey:SCMinTargetMSKey];
		[dataDoc putEvent:@"minTargetTimeMS" withData:&longValue];
		if ([[task defaults] integerForKey:SCStimDistributionKey] == kUniform) {
			longValue = [defaults integerForKey:SCMinTargetMSKey] +
						([defaults integerForKey:SCMaxTargetMSKey] - [defaults integerForKey:SCMinTargetMSKey]) / 2.0;
//			[[task defaults] setInteger: longValue forKey: SCMeanTargetMSKey];
		}
		else updateCatchTrialPC();
		requestReset();
	}
	else if ([key isEqualTo:SCInterstimMSKey]) {
		longValue = [defaults integerForKey:SCInterstimMSKey];
		[dataDoc putEvent:@"interstimMS" withData:&longValue];
		if ([[task defaults] integerForKey:SCStimDistributionKey] == kExponential) {
			updateCatchTrialPC();
		}
		requestReset();
	}
	else if ([key isEqualTo:SCOrientationChangesKey] || [key isEqualTo:SCMaxDirChangeDegKey] ||
				[key isEqualTo:SCMinDirChangeDegKey] || [key isEqualTo:SCChangeScaleKey]) {
		[self updateChangeTable];
	}
	else if ([key isEqualTo:SCChangeArrayKey]) {
		updateBlockStatus();
		[[task dataDoc] putEvent:@"blockStatus" withData:&blockStatus];
	}
	else if ([key isEqualTo:SCFixateMSKey]) {
		longValue = [defaults integerForKey:SCFixateMSKey];
		[[task dataDoc] putEvent:@"fixateMS" withData:&longValue];
	}
	else if ([key isEqualTo:SCStimRepsPerBlockKey]) {
		longValue = [defaults integerForKey:SCOrientationChangesKey];
		[dataDoc putEvent:@"stimRepsPerBlock" withData:&longValue];
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
	[defaults setInteger:[taskStatus status] forKey:SCTaskStatusKey];
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
		[defaults setInteger:[taskStatus status] forKey:SCTaskStatusKey];
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

- (SCStimuli *)stimuli;
{
	return stimuli;
}

// The change table (array) contains information about what changes will be tested and
// how often each change will be tested in the valid and invalid mode in each block

- (void)updateChangeTable;
{
	long index, changes, oldChanges;
	long changeScale;
	float minChange, maxChange;
	float logMinChange, logMaxChange;
	float newValue;
	NSMutableArray *changeArray;
	NSMutableDictionary *changeEntry;

	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.SCChangeArray"];
	changeArray = [NSMutableArray arrayWithArray:[defaults arrayForKey:SCChangeArrayKey]];
	oldChanges = [changeArray count];
	changes = [defaults integerForKey:SCOrientationChangesKey];

	if (oldChanges > changes) {
		[changeArray removeObjectsInRange:NSMakeRange(changes, oldChanges - changes)];
	}
	else if (changes > oldChanges) {
		changeEntry = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithFloat:10.0], SCChangeKey,
				[NSNumber numberWithLong:1], SCValidRepsKey,
				[NSNumber numberWithLong:0], SCInvalidRepsKey,
				nil];
		for (index = oldChanges; index < changes; index++) {
			[changeArray addObject:changeEntry];
		}
	}
/*
	changeSign = 0;
	minChange = [defaults floatForKey:SCMinDirChangeDegKey];
	maxChange = [defaults floatForKey:SCMaxDirChangeDegKey];
	
	changeScale = [defaults integerForKey:SCChangeScaleKey];
	
	if ((minChange > 0) & (maxChange > 0)) {
		changeSign = 1;
		logMinChange = log(minChange);
		logMaxChange = log(maxChange);
		logGuessThreshold = log(guessThreshold);
	}
	else if ((minChange < 0) & (maxChange < 0)) {
		changeSign = -1;
		logMinChange = log((-1*minChange));
		logMaxChange = log((-1*maxChange));
		logGuessThreshold = log(-1*guessThreshold);
	} 

	switch (changes) {
		case 1:
			changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:maxChange], SCChangeKey,
					[NSNumber numberWithLong:1], SCValidRepsKey,
					nil];
			[changeArray replaceObjectAtIndex:0 withObject:changeEntry];
			break;

		case 2:
			changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:minChange], SCChangeKey,
					[NSNumber numberWithLong:1], SCValidRepsKey,
					nil];
			[changeArray replaceObjectAtIndex:0 withObject:changeEntry];
		
			changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:maxChange], SCChangeKey,
					[NSNumber numberWithLong:1], SCValidRepsKey,
					nil];
			[changeArray replaceObjectAtIndex:1 withObject:changeEntry];
			break;
		
		case 3:
			changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:minChange], SCChangeKey,
					[NSNumber numberWithLong:1], SCValidRepsKey,
					nil];
			[changeArray replaceObjectAtIndex:0 withObject:changeEntry];
		
			changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:guessThreshold], SCChangeKey,
					[NSNumber numberWithLong:1], SCValidRepsKey,
					nil];
			[changeArray replaceObjectAtIndex:1 withObject:changeEntry];

			changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:maxChange], SCChangeKey,
					[NSNumber numberWithLong:1], SCValidRepsKey,
					nil];
			[changeArray replaceObjectAtIndex:2 withObject:changeEntry];
			break;

		case 4:
			changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:minChange], SCChangeKey,
					[NSNumber numberWithLong:1], SCValidRepsKey,
					nil];
			[changeArray replaceObjectAtIndex:0 withObject:changeEntry];
		
			changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:guessThreshold], SCChangeKey,
					[NSNumber numberWithLong:1], SCValidRepsKey,
					nil];
			[changeArray replaceObjectAtIndex:1 withObject:changeEntry];

			changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:maxChange], SCChangeKey,
					[NSNumber numberWithLong:1], SCValidRepsKey,
					nil];
			[changeArray replaceObjectAtIndex:2 withObject:changeEntry];

			changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:maxChange * 1.5], SCChangeKey,
					[NSNumber numberWithLong:1], SCValidRepsKey,
					nil];
			[changeArray replaceObjectAtIndex:3 withObject:changeEntry];
			break;

		default:
			netChanges = changes -1;
			halfIndex = changes / 2;
			for (index = 0; index < changes/2; index++) {
				if (changeScale == kLinear) {
					newValue = minChange + (index) * (guessThreshold - minChange) / (changes / 2 - 1);
				}
				else if (changeScale == kLogarithmic) {
				newValue = exp(logMinChange + (index) * (logGuessThreshold - logMinChange) / (changes / 2 - 1));
				newValue = changeSign * newValue;
				}
//				newValue = 0.1;
				changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:newValue], SCChangeKey,
					[NSNumber numberWithLong:1], SCValidRepsKey,
					nil];
				[changeArray replaceObjectAtIndex:index withObject:changeEntry];
			}
			halfIndex = index;
			for (index = halfIndex; index < changes - 1; index++) {
				if (changeScale == kLinear) {
					newValue = guessThreshold + (index - halfIndex + 1) * 
								(maxChange - guessThreshold) / ((changes + 1) / 2 - 1);
				}
				else if (changeScale == kLogarithmic) {
				newValue = exp(logGuessThreshold + (index - halfIndex + 1) * 
								(logMaxChange - logGuessThreshold) / ((changes + 1) / 2 - 1));
				newValue = changeSign * newValue;
				}
//				newValue = 0.1;
				changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:newValue], SCChangeKey,
					[NSNumber numberWithLong:1], SCValidRepsKey,
					nil];
				[changeArray replaceObjectAtIndex:index withObject:changeEntry];
			}
			
			changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithFloat:maxChange*1.5], SCChangeKey,
				[NSNumber numberWithLong:1], SCValidRepsKey,
				nil];

			[changeArray replaceObjectAtIndex:changes-1 withObject:changeEntry];
			break;
	}



	changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithFloat:1.0*changeSign], SCChangeKey,
			[NSNumber numberWithLong:1], SCValidRepsKey,
			nil];

	[changeArray replaceObjectAtIndex:0 withObject:changeEntry];
*/
	changeScale = [defaults integerForKey:SCChangeScaleKey];
	minChange = [defaults floatForKey:SCMinDirChangeDegKey];
	maxChange = [defaults floatForKey:SCMaxDirChangeDegKey];
	logMinChange = log(minChange);
	logMaxChange = log(maxChange);
	for (index = 0; index < changes; index++) {
		if (changes <= 1) {
			newValue = minChange;
		}
		else {
			if (changeScale == kLinear) {
				newValue = minChange + index * (maxChange - minChange) / (changes - 1);
			}
			else if (changeScale == kLogarithmic) {
				newValue = exp(logMinChange + index * (logMaxChange - logMinChange) / (changes - 1));
			}
		}
		changeEntry = [NSMutableDictionary dictionaryWithCapacity:1];
		[changeEntry setDictionary:[changeArray objectAtIndex:index]];
		[changeEntry setObject:[NSNumber numberWithFloat:newValue] forKey:SCChangeKey];
		[changeArray replaceObjectAtIndex:index withObject:changeEntry];
	}

	[defaults setObject:changeArray forKey:SCChangeArrayKey];
	updateBlockStatus();
	[[task dataDoc] putEvent:@"blockStatus" withData:&blockStatus];
	requestReset();
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.SCChangeArray"
				options:NSKeyValueObservingOptionNew context:nil];

}

@end
