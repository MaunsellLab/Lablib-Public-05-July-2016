//
//  TUNPlugin.m
//  Tuning
//
//  Copyright 2006. All rights reserved.
//

#import "TUN.h"
#import "TUNPlugin.h"
#import "TUNSummaryController.h"
#import "TUNSpikeController.h"
#import "TUNXTController.h"
#import "UtilityFunctions.h"

#define		kRewardBit				0x0001

// Behavioral parameters

NSString *TUNAcquireMSKey = @"TUNAcquireMS";
NSString *TUNBlockLimitKey = @"TUNBlockLimit";
NSString *TUNBreakPunishMSKey = @"TUNBreakPunishMS";
NSString *TUNDoSoundsKey = @"TUNDoSounds";
NSString *TUNFixateKey = @"TUNFixate";
NSString *TUNFixateMSKey = @"TUNFixateMS";
NSString *TUNFixGraceMSKey = @"TUNFixGraceMS";
NSString *TUNFixWindowWidthDegKey = @"TUNFixWindowWidthDeg";
NSString *TUNIntertrialMSKey = @"TUNIntertrialMS";
NSString *TUNNumInstructTrialsKey = @"TUNNumInstructTrials";
NSString *TUNPreStimMSKey = @"TUNPreStimMS";
NSString *TUNRespTimeMSKey = @"TUNRespTimeMS";
NSString *TUNRewardMSKey = @"TUNRewardMS";
NSString *TUNSpeedDPSKey = @"TUNSpeedDPS";
NSString *TUNTaskStatusKey = @"TUNTaskStatus";
NSString *TUNTooFastMSKey = @"TUNTooFastMS";

// Stimulus Parameters

NSString *TUNInterstimJitterPCKey = @"TUNInterstimJitterPC";
NSString *TUNInterstimMSKey = @"TUNInterstimMS";
NSString *TUNStimDurationMSKey = @"TUNStimDurationMS";
NSString *TUNStimJitterPCKey = @"TUNStimJitterPC";
NSString *TUNStimPerTrialKey = @"TUNStimPerTrial";

// Visual Stimulus Parameters 

NSString *TUNContrastPCKey = @"TUNContrastPC";
NSString *TUNEccentricityDegKey = @"TUNEccentricityDeg";
NSString *TUNPolarAngleDegKey = @"TUNPolarAngleDeg";
NSString *TUNKdlPhiDegKey = @"TUNKdlPhiDeg";
NSString *TUNKdlThetaDegKey = @"TUNKdlThetaDeg";
NSString *TUNDirectionDegKey = @"TUNDirectionDeg";
NSString *TUNRadiusDegKey = @"TUNRadiusDeg";
NSString *TUNSigmaDegKey = @"TUNSigmaDeg";
NSString *TUNSpatialFreqCPDKey = @"TUNSpatialFreqCPD";
NSString *TUNSpatialPhaseDegKey = @"TUNSpatialPhaseDeg";
NSString *TUNStimTypeIndexKey = @"TUNStimTypeIndex";
NSString *TUNTemporalFreqHzKey = @"TUNTemporalFreqHz";

// Tuning test parameters

NSString *TUNCircularKey = @"TUNCircular";
NSString *TUNStimNameKey = @"TUNStimName";
NSString *TUNStimValuesKey = @"TUNStimValues";
NSString *TUNTestValuesKey = @"TUNTestValues";
NSString *TUNTestNameKey = @"TUNTestName";
NSString *TUNTestSpacingTypeKey = @"TUNTestSpacingType";
NSString *TUNTestStepsKey = @"TUNTestSteps";
NSString *TUNMaxValueKey = @"TUNMaxValue";
NSString *TUNMinValueKey = @"TUNMinValue";

// Local keys

NSString *TUNSelectionIndexKey = @"selectionIndex";


NSString *keyPaths[] = {@"values.TUNBlockLimit", @"values.TUNRespTimeMS", 
					@"values.TUNStimDurationMS", @"values.TUNInterstimMS", @"values.TUNStimValues", 
					@"values.TUNStimTypeIndex", @"values.TUNStimPerTrial",
					nil};

LLScheduleController	*scheduler = nil;
TUNStimuli				*stimuli = nil;

LLDataDef gaborStructDef[] = kLLGaborEventDesc;
LLDataDef randomDotsStructDef[] = kLLRandomDotsEventDesc;
LLDataDef fixWindowStructDef[] = kLLEyeWindowEventDesc;
LLDataDef blockStatusDef[] = {
	{@"long",	@"blockLimit", 1, offsetof(BlockStatus, blockLimit)},
	{@"long",	@"blocksDone", 1, offsetof(BlockStatus, blocksDone)},
	{@"long",	@"stimDoneThisBlock", 1, offsetof(BlockStatus, stimDoneThisBlock)},
	{nil}};
LLDataDef testParamsDef[] = {
	{@"char",	@"stimTypeName", kMaxNameChar, offsetof(TestParams, stimTypeName)},
	{@"char",	@"testTypeName", kMaxNameChar, offsetof(TestParams, testTypeName)},
	{@"long",	@"stimTypeIndex", 1, offsetof(TestParams, stimTypeIndex)},
	{@"long",	@"testTypeIndex", 1, offsetof(TestParams, testTypeIndex)},
	{@"long",	@"spacingType", 1, offsetof(TestParams, spacingType)},
	{@"long",	@"steps", 1, offsetof(TestParams, steps)},
	{@"float",	@"maxValue", 1, offsetof(TestParams, maxValue)},
	{@"float",	@"minValue", 1, offsetof(TestParams, minValue)},
	{@"float",	@"values", kMaxSteps, offsetof(TestParams, values)},
	{nil}};
LLDataDef stimDescDef[] = {
	{@"long",	@"stimOnFrame", 1, offsetof(StimDesc, stimOnFrame)},
	{@"long",	@"stimOffFrame", 1, offsetof(StimDesc, stimOffFrame)},
	{@"short",	@"stimTypeIndex", 1, offsetof(StimDesc, stimTypeIndex)},
	{@"long",	@"stimIndex", 1, offsetof(StimDesc, stimIndex)},
	{@"float",	@"eccentricityDeg", 1, offsetof(StimDesc, eccentricityDeg)},
	{@"float",	@"polarAngleDeg", 1, offsetof(StimDesc, polarAngleDeg)},
	{@"float",	@"testValue", 1, offsetof(StimDesc, testValue)},
	{nil}};
LLDataDef trialDescDef[] = {
	{@"long",	@"stimPerTrial", 1, offsetof(TrialDesc, stimPerTrial)},
	{nil}};
	
DataAssignment eyeXDataAssignment = {@"eyeXData",	@"Synthetic", 0, 5.0};	
DataAssignment eyeYDataAssignment = {@"eyeYData",	@"Synthetic", 1, 5.0};	
DataAssignment spikeDataAssignment = {@"spikeData", @"Synthetic", 2, 1};
DataAssignment VBLDataAssignment =   {@"VBLData",	@"Synthetic", 1, 1};	
	
EventDefinition TUNEvents[] = {
// recorded at start of file
	{@"gabor",				sizeof(Gabor),			{@"struct", @"gabor", 1, 0, sizeof(Gabor), gaborStructDef}},
	{@"randomDots",			sizeof(RandomDots),		{@"struct", @"randomDots", 1, 0, sizeof(RandomDots), randomDotsStructDef}},
	{@"eccentricityDeg",	sizeof(float),			{@"float"}},
	{@"polarAngleDeg",		sizeof(float),			{@"float"}},
	{@"testParams",			sizeof(TestParams),		{@"struct", @"testParams", 1, 0, sizeof(TestParams), testParamsDef}},
// timing parameters
	{@"preStimMS",			sizeof(long),			{@"long"}},
	{@"stimDurationMS",		sizeof(long),			{@"long"}},
	{@"interstimMS",		sizeof(long),			{@"long"}},
	{@"stimLeadMS",			sizeof(long),			{@"long"}},
	{@"stimRepsPerBlock",	sizeof(long),			{@"long"}},
	{@"blockStatus",		sizeof(BlockStatus),	{@"struct", @"blockStatus", 1, 0, sizeof(BlockStatus), blockStatusDef}},
// declared at start of each trial	
	{@"trial",				sizeof(TrialDesc),		{@"struct", @"trial", 1, 0, sizeof(TrialDesc), trialDescDef}},
// marking the course of each trial
	{@"preStimuli",			0,						{@"no data"}},
	{@"stimulus",			sizeof(StimDesc),		{@"struct", @"stimDesc", 1, 0, sizeof(StimDesc), stimDescDef}},
	{@"stimOn",				0,						{@"no data"}},
	{@"stimOff",			0,						{@"no data"}},

	{@"taskMode", 			sizeof(long),			{@"long"}},
	{@"reset", 				sizeof(long),			{@"long"}}, 
};

BlockStatus		blockStatus;
long			stimDone[kMaxSteps] = {};
TestParams		testParams;
LLTaskPlugIn	*task = nil;

@implementation TUNPlugin

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
  
	spikeController = [[TUNSpikeController alloc] init];
    [dataDoc addObserver:spikeController];

    eyeXYController = [[TUNEyeXYController alloc] init];
    [dataDoc addObserver:eyeXYController];

    summaryController = [[TUNSummaryController alloc] init];
    [dataDoc addObserver:summaryController];
 
	xtController = [[TUNXTController alloc] init];
    [dataDoc addObserver:xtController];

// Set up data events (after setting up windows to receive them)

	[dataDoc defineEvents:[LLStandardDataEvents eventsWithDataDefs] count:[LLStandardDataEvents countOfEventsWithDataDefs]];
	[dataDoc defineEvents:TUNEvents count:(sizeof(TUNEvents) / sizeof(EventDefinition))];
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
	[stimController addObserver:self forKeyPath:TUNSelectionIndexKey 
		options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
	[testController addObserver:self forKeyPath:TUNSelectionIndexKey 
		options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
	[self loadTestParams];
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
    [dataDoc removeObserver:spikeController];
    [dataDoc removeObserver:eyeXYController];
    [dataDoc removeObserver:summaryController];
    [dataDoc removeObserver:xtController];
	[dataDoc clearEventDefinitions];

// Remove Actions and Settings menus from menu bar
	 
	[[NSApp mainMenu] removeItem:settingsMenuItem];
	[[NSApp mainMenu] removeItem:actionsMenuItem];

// Release all the display windows

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
	[stimController removeObserver:self forKeyPath:TUNSelectionIndexKey];
	[testController removeObserver:self forKeyPath:TUNSelectionIndexKey];
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

// Take the number of steps and set the minimum and maximum test values to span a full 
// 360° range.  This is only valid for direction tuning tests

- (IBAction)do360DegTest:(id)sender;
{
	long steps;
	long testTypeIndex;
	NSArray *testArray;
	NSMutableDictionary *testDict;

	testTypeIndex = [testController selectionIndex];
	if (testParams.testTypeIndex == NSNotFound) {
		return;
	}
	testArray = [testController arrangedObjects];					// get the array of test values
	testDict = [NSMutableDictionary dictionaryWithDictionary:[testArray objectAtIndex:testTypeIndex]];							
																	// get the direction test values
	steps =  [[testDict objectForKey:TUNTestStepsKey] intValue];	// get number of steps
	[testDict setValue:[NSNumber numberWithFloat:0.0] forKey:TUNMinValueKey];	// set minimum (zero)
	[testDict setValue:[NSNumber numberWithFloat:(360.0 / steps * (steps - 1))] forKey:TUNMaxValueKey];
	[testDict setValue:[NSNumber numberWithInt:kLinearSpacing] forKey:TUNTestSpacingTypeKey];

	[testController setSelectsInsertedObjects:YES];
	[testController insertObject:testDict atArrangedObjectIndex:testTypeIndex + 1];
	[testController removeObjectAtArrangedObjectIndex:testTypeIndex];
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

- (IBAction)doJuice:(id)sender;
{
	long juiceMS;
	NSSound *juiceSound;
	
	if ([sender respondsToSelector:@selector(juiceMS)]) {
		juiceMS = (long)[sender performSelector:@selector(juiceMS)];
	}
	else {
		juiceMS = [[task defaults] integerForKey:TUNRewardMSKey];
	}
	[[task dataController] digitalOutputBitsOff:kRewardBit];
	[scheduler schedule:@selector(doJuiceOff) toTarget:self withObject:nil delayMS:juiceMS];
	if ([[task defaults] boolForKey:TUNDoSoundsKey]) {
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

- (IBAction)doStimSettings:(id)sender;
{
	[stimuli doStimSettings:[stimController selectionIndex]];
}

// After our -init is called, the host will provide essential pointers such as
// defaults, stimWindow, eyeCalibrator, etc.  Only aMSer those are initialized, the
// following method will be called.  We therefore defer most of our initialization here

- (void)initializationDidFinish;
{
	long index;
	LLNumberNonMatchTransformer *transformer;
	NSString *transformerNames[] = {@"DirectionTestTransformer",
									@"SpeedTestTransformer",
									@"ContrastTestTransformer",
									};
enum {kDirectionTest = 0, kSpeedTest, kContrastTest, kTestTypes};
	
	task = self;
	
// Register our default settings. This should be done first thing, before the
// nib is loaded, because items in the nib are linked to defaults

	[LLSystemUtil registerDefaultsFromFilePath:
			[[NSBundle bundleForClass:[self class]] pathForResource:@"UserDefaults" ofType:@"plist"] defaults:defaults];

// Make the LLTransformers we need to control the dialog fields (via binding)

	for (index = 0; index < kTestTypes; index++) {
		transformer = [[[LLNumberMatchTransformer alloc] init] autorelease];
		[transformer addNumber:[NSNumber numberWithInt:index]];
		[NSValueTransformer setValueTransformer:transformer
					forName:transformerNames[index]];
	}
	transformer = [[[LLNumberNonMatchTransformer alloc] init] autorelease];
	[transformer addNumber:[NSNumber numberWithInt:kDirectionTest]];
	[NSValueTransformer setValueTransformer:transformer
				forName:@"NotDirectionTestTransformer"];

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
	stimuli = [[TUNStimuli alloc] init];

// Load the items in the nib

	[NSBundle loadNibNamed:@"Tuning" owner:self];
	
// Initialize other task objects

	scheduler = [[LLScheduleController alloc] init];
	stateSystem = [[TUNStateSystem alloc] init];

// Set up control panel and observer for control panel

	controlPanel = [[LLControlPanel alloc] init];
	[controlPanel setWindowFrameAutosaveName:@"TUNControlPanel"];
	[[controlPanel window] setFrameUsingName:@"TUNControlPanel"];
	[[controlPanel window] setTitle:@"Tuning"];
	[[NSNotificationCenter defaultCenter] addObserver:self 
		selector:@selector(doControls:) name:nil object:controlPanel];
}

- (void)loadTestParams;
{
	long index;
	double increment;
	NSString *stimTypeName, *testTypeName;
	NSArray *stimArray, *testArray;
	NSDictionary *stimDict, *testDict;

// Get the stimulus type index and name
	
	testParams.stimTypeIndex = [stimController selectionIndex];
	if (testParams.stimTypeIndex == NSNotFound) {
		return;
	}
	stimArray = [[task defaults] arrayForKey:TUNStimValuesKey];
	stimDict = [stimArray objectAtIndex:testParams.stimTypeIndex];
	stimTypeName = [stimDict objectForKey:TUNStimNameKey];
	[stimTypeName getCString:testParams.stimTypeName maxLength:kMaxNameChar encoding:NSUTF8StringEncoding];

// Get the rest of the test parameters

	testParams.testTypeIndex = [testController selectionIndex];
	if (testParams.testTypeIndex == NSNotFound) {
		return;
	}
//	testArray = [[task defaults] arrayForKey:TUNTestValuesKey];
	testArray = [stimDict objectForKey:TUNTestValuesKey];
	testDict = [testArray objectAtIndex:testParams.testTypeIndex];
	testTypeName = [testDict objectForKey:TUNTestNameKey];
	[testTypeName getCString:testParams.testTypeName maxLength:kMaxNameChar encoding:NSUTF8StringEncoding];
	testParams.steps =  [[testDict objectForKey:TUNTestStepsKey] intValue];
	testParams.maxValue =  [[testDict objectForKey:TUNMaxValueKey] floatValue];
	testParams.minValue =  [[testDict objectForKey:TUNMinValueKey] floatValue];
	testParams.spacingType =  [[testDict objectForKey:TUNTestSpacingTypeKey] intValue];
	switch (testParams.spacingType) {
	case kLogSpacing:
		increment = (log(testParams.maxValue) - log(testParams.minValue)) / (testParams.steps - 1);
		break;
	case kLinearSpacing:
	default:
		increment = (testParams.maxValue - testParams.minValue) / (testParams.steps - 1);
		break;
	}
	for (index = 0; index < testParams.steps; index++) {
		switch (testParams.spacingType) {
		case kLogSpacing:
			testParams.values[index] = exp(log(testParams.minValue) + index * increment);
			break;
		case kLinearSpacing:
		default:
			testParams.values[index] = testParams.minValue + index * increment;
			break;
		}
	}
	while (index < kMaxSteps) {
		testParams.values[index++] = 0.0;
	}
	[valuesString setStringValue:[self valuesString]];
}

- (long)mode;
{
	return [taskStatus mode];
}

- (NSString *)name;
{
	return @"Tuning";
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
	if ([key isEqualToString:@""]) {
		key = keyPath;
	}
	if ([key isEqualTo:TUNStimDurationMSKey]) {
		longValue = [defaults integerForKey:TUNStimDurationMSKey];
		[dataDoc putEvent:@"stimDurationMS" withData:&longValue];
		requestReset();
	}
	else if ([key isEqualTo:TUNInterstimMSKey]) {
		longValue = [defaults integerForKey:TUNInterstimMSKey];
		[dataDoc putEvent:@"interstimMS" withData:&longValue];
		requestReset();
	}
	else if ([key isEqualTo:TUNStimPerTrialKey]) {
//		longValue = [defaults integerForKey:TUNTestValuesKey];
//		[dataDoc putEvent:@"stimRepsPerBlock" withData:&longValue];
	}
	else if ([key isEqualTo:TUNStimValuesKey] || [key isEqualTo:TUNSelectionIndexKey]) {
		[self loadTestParams];
		[[task dataDoc] putEvent:@"testParams" withData:&testParams];
		requestReset();
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
	[defaults setInteger:[taskStatus status] forKey:TUNTaskStatusKey];
	NSLog(@"TUN setting status to %d, now %d", newMode, [defaults integerForKey:TUNTaskStatusKey]);
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
		[defaults setInteger:[taskStatus status] forKey:TUNTaskStatusKey];
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

- (TUNStimuli *)stimuli;
{
	return stimuli;
}

// Return a string with all the values that will be tested

- (NSString *)valuesString;
{
	long index;
	NSMutableString *string = [NSMutableString string];
	
	for (index = 0; index < testParams.steps; index++) {
		[string appendString:[NSString stringWithFormat:@"%.*f",  
					[LLTextUtil precisionForValue:testParams.values[index] significantDigits:2], 
					testParams.values[index]]];
		if (index < testParams.steps - 1) {
			[string appendString:@", "];
		}
	}
	return string;
}


@end
