/*
TUNStimuli.m
Stimulus generation for Tuning
March 29, 2003 JHRM
*/

#import "TUN.h"
#import "TUNStimuli.h"
#import "UtilityFunctions.h"

#define kDefaultDisplayIndex	1		// Index of stim display when more than one display
#define kMainDisplayIndex		0		// Index of main stimulus display
#define kPixelDepthBits			32		// Depth of pixels in stimulus window
#define	stimWindowSizePix		250		// Height and width of stim window on main display

#define kTargetBlue				0.0
#define kTargetGreen			1.0
#define kMidGray				0.5
#define kPI						(atan(1) * 4)
#define kTargetRed				1.0
#define kDegPerRad				57.295779513

#define kAdjusted(color, contrast)  (kMidGray + (color - kMidGray) / 100.0 * contrast)

NSString *stimulusMonitorID = @"Tuning Stimulus";

@implementation TUNStimuli

- (void) dealloc;
{
	[[task monitorController] removeMonitorWithID:stimulusMonitorID];
	[stimList release];
	[cueSpot release];
	[fixSpot release];
    [gabor release];
    [randomDots release];
    [super dealloc];
}

// Run the cue settings dialog

- (void)doCueSettings;
{
	[cueSpot runSettingsDialog];
}

- (void)doFixSettings;
{
	[fixSpot runSettingsDialog];
}

- (void)doStimSettings:(long)stimTypeIndex;
{
	switch (stimTypeIndex) {
	case kGabor:
		[gabor runSettingsDialog];
		break;
	case kRandomDots:
		[randomDots runSettingsDialog];
		break;
	default:
		break;
	}
}

- (void)dumpStimList;
{
	StimDesc stimDesc;
	long index;
		
	NSLog(@"\type stimIndex value on/off Frames");
	for (index = 0; index < [stimList count]; index++) {
		[[stimList objectAtIndex:index] getValue:&stimDesc];
		NSLog(@"%4d: %4d %4d %.1f %d %d",
			index, stimDesc.stimTypeIndex, stimDesc.stimIndex,
			stimDesc.testValue, stimDesc.stimOnFrame, stimDesc.stimOffFrame);
	}
	NSLog(@"\n");
}

- (void)erase;
{
	[[task stimWindow] lock];
    glClearColor(kMidGray, kMidGray, kMidGray, 0);
    glClear(GL_COLOR_BUFFER_BIT);
	[[NSOpenGLContext currentContext] flushBuffer];
	[[task stimWindow] unlock];
}

- (LLGabor *)gabor;
{
	return gabor;
}

- (id)init;
{
	float frameRateHz = [[task stimWindow] frameRateHz]; 
	
	if (!(self = [super init])) {
		return nil;
	}
	monitor = [[[LLIntervalMonitor alloc] initWithID:stimulusMonitorID 
					description:@"Stimulus frame intervals"] autorelease];
	[[task monitorController] addMonitor:monitor];
	[monitor setTargetIntervalMS:1000.0 / frameRateHz];
	stimList = [[NSMutableArray alloc] init];
	
// Create and initialize a gabor stimulus

	gabor = [[LLGabor alloc] init];				// Create a gabor stimulus
	[gabor setDisplays:[[task stimWindow] displays] displayIndex:[[task stimWindow] displayIndex]];
	[gabor removeKeysFromBinding:[NSArray arrayWithObjects:LLGaborAzimuthDegKey, LLGaborElevationDegKey, 
								LLGaborDirectionDegKey, LLGaborTemporalPhaseDegKey, LLGaborContrastKey,
								LLGaborSpatialPhaseDegKey, LLGaborTemporalFreqHzKey, nil]];
	[gabor bindValuesToKeysWithPrefix:@"TUN"];
	
	randomDots = [[LLRandomDots alloc] init];
	[randomDots setDisplays:[[task stimWindow] displays] displayIndex:[[task stimWindow] displayIndex]];
	[randomDots removeKeysFromBinding:[NSArray arrayWithObjects:LLRandomDotsAzimuthDegKey, 
			LLRandomDotsElevationDegKey, LLRandomDotsDirectionDegKey, LLRandomDotsDotContrastKey,
			LLRandomDotsSpeedDPSKey, nil]];
	[randomDots bindValuesToKeysWithPrefix:@"TUN"];
	
	cueSpot = [[LLFixTarget alloc] init];
	[cueSpot bindValuesToKeysWithPrefix:@"TUNCue"];
	fixSpot = [[LLFixTarget alloc] init];
	[fixSpot bindValuesToKeysWithPrefix:@"TUNFix"];
	return self;
}

- (void)insertStimSettingsAtIndex:(long)index trial:(TrialDesc *)pTrial stimIndex:(long)stimIndex;
{
	StimDesc stimDesc;
	
	stimDesc.stimIndex = stimIndex;
	stimDesc.stimTypeIndex = testParams.stimTypeIndex;
	stimDesc.eccentricityDeg = [[task defaults] floatForKey:TUNEccentricityDegKey];
	stimDesc.polarAngleDeg = [[task defaults] floatForKey:TUNPolarAngleDegKey];
	stimDesc.testValue = testParams.values[stimIndex];
	if (index < 0 || index > [stimList count]) {
		index = [stimList count];
	}
	[stimList insertObject:[NSValue valueWithBytes:&stimDesc objCType:@encode(StimDesc)]
		atIndex:index];
}

/*
makeStimList()

Make a stimulus list for one trial, with the requested number of stimuli presented in a random 
order.  The list is constructed so that each stimulus appears n times before any appears (n+1).  
In the simplest case, we just draw n unused entries from the done table.  If there are fewer than 
n entries remaining, we take them all, clear the table, and then proceed.  We also make a provision 
for the case where several full table worth's will be needed to make the list.  Whenever we take all 
the entries remaining in the table, we simply draw them in order and then use shuffleStimList() to 
randomize their order.  Shuffling does not span the borders between successive doneTables, to ensure 
that each stimulus pairing will be presented n times before any appears n + 1 times, even if each appears 
several times within one trial.

*/

- (void)makeStimList:(TrialDesc *)pTrial;
{
	long s, steps, inStart, stimPerTrial, stim, sectionStart, nextStimOnFrame;
	long stimDurFrames, interDurFrames, stimJitterPC, interJitterPC, stimJitterFrames, interJitterFrames;
	long stimDurBase, interDurBase, remaining, stimListLength, minStimDone;
	float stimRateHz, frameRateHz;
	StimDesc stimDesc;
	
	stimListLength = pTrial->stimPerTrial;
	steps = testParams.steps;
	stimPerTrial = [[task defaults] integerForKey:TUNStimPerTrialKey];
	
	stimRateHz = 1000.0 / ([[task defaults] integerForKey:TUNStimDurationMSKey] + 
					[[task defaults] integerForKey:TUNInterstimMSKey]);
		
	for (s = 0, minStimDone = LONG_MAX; s < steps; s++) {	// copy doneTable, get minimum
		selectTable[s] = stimDone[s];
		minStimDone = MIN(minStimDone, selectTable[s]);
	}
	for (s = remaining = 0; s < steps; s++) {				// count number remaining in table
		selectTable[s] -= minStimDone;
		remaining += (selectTable[s] == 0) ? 1 : 0;
	}
	[stimList removeAllObjects];
	sectionStart = 0;										// start of the current section (for scrambling)
		
// If there are fewer than the number of stim we need remaining in the current doneTable,
// pick up all that are there, clearing the table as we go.

	if (remaining < (stimPerTrial - sectionStart)) {				// need all remaining in block?
		for (s = 0; s < steps; s++) {
			if (selectTable[s] == 0) {
				[self insertStimSettingsAtIndex:-1 trial:pTrial stimIndex:s];
			}
			else {
				selectTable[s] = 0;
			}
		}
		[self shuffleStimListFrom:sectionStart count:remaining];
		
// For long trials, we might need more than a complete doneTable's worth of stimuli.
// If that is the case, keep grabbing full image set until we need less than a full table

		sectionStart = [stimList count];
		while ((stimPerTrial - sectionStart) > steps) {
			for (s = 0; s < steps; s++) {
				[self insertStimSettingsAtIndex:-1 trial:pTrial stimIndex:s];
			}
			[self shuffleStimListFrom:sectionStart count:steps];
			sectionStart = [stimList count];
		}
	}

// At this point there are enough available entries in selectTable to fill the rest of the stimList.
	
	while ([stimList count] < stimPerTrial) {
		s = inStart = (rand() % steps);
		while (selectTable[s] != 0) {
			s = (s + 1) % steps;
			if (s == inStart) {
				break;
			}
		}
		if (selectTable[s] > 0) {
			NSLog(@"makeStimList: scanned table without finding empty entry");
		}
		selectTable[s]++;
		[self insertStimSettingsAtIndex:-1 trial:pTrial stimIndex:s];
	}
			
// Now the list is complete.  We make a pass through the list loading the stimulus presention
// frames.  At the same time, for instruction trials we set all the distractor stimulus types
// to kNull, so nothing will appear there

	frameRateHz = [[task stimWindow] frameRateHz];
	stimJitterPC = [[task defaults] integerForKey:TUNStimJitterPCKey];
	interJitterPC = [[task defaults] integerForKey:TUNInterstimJitterPCKey];
	stimDurFrames = [[task defaults] integerForKey:TUNStimDurationMSKey] / 
					1000.0 * frameRateHz;
	interDurFrames = [[task defaults] integerForKey:TUNInterstimMSKey] / 1000.0 * frameRateHz;
	stimJitterFrames = stimDurFrames / 100.0 * stimJitterPC;
	interJitterFrames = interDurFrames / 100.0 * interJitterPC;
	stimDurBase = stimDurFrames - stimJitterFrames;
	interDurBase = interDurFrames - interJitterFrames;
	
 	for (stim = nextStimOnFrame = 0; stim < [stimList count]; stim++) {
		[[stimList objectAtIndex:stim] getValue:&stimDesc];
		stimDesc.stimOnFrame = nextStimOnFrame;
		if (stimJitterFrames > 0) {
			stimDesc.stimOffFrame = stimDesc.stimOnFrame + 
					MAX(1, stimDurBase + (rand() % (2 * stimJitterFrames + 1)));
		}
		else {
			stimDesc.stimOffFrame = stimDesc.stimOnFrame +  MAX(1, stimDurFrames);
		}
		if (interJitterFrames > 0) {
			nextStimOnFrame = stimDesc.stimOffFrame + 
				MAX(1, interDurBase + (rand() % (2 * interJitterFrames + 1)));
		}
		else {
			nextStimOnFrame = stimDesc.stimOffFrame + MAX(1, interDurFrames);
		}
		[stimList replaceObjectAtIndex:stim withObject:
				[NSValue valueWithBytes:&stimDesc objCType:@encode(StimDesc)]];
	}
}
	
- (LLIntervalMonitor *)monitor;
{
	return monitor;
}

- (void)prepareOneStimulus:(StimDesc *)pSD;
{
	long index;
	NSPoint aziEle;

	switch (pSD->stimTypeIndex) {
	case kGabor:
		aziEle = azimuthAndElevationForStimIndex(index);
		[gabor directSetAzimuthDeg:aziEle.x elevationDeg:aziEle.y];
		[gabor directSetSpatialPhaseDeg:0.0];
		[gabor directSetTemporalPhaseDeg:0.0];
		if (strcmp(testParams.testTypeName, "Direction") == 0) {
			[gabor directSetDirectionDeg:pSD->testValue];
//			NSLog(@"%@", [gabor description]);
		}
		else if (strcmp(testParams.testTypeName, "Contrast") == 0) {
			[gabor directSetContrast:pSD->testValue / 100.0];
		}
		else if (strcmp(testParams.testTypeName, "Spatial Frequency") == 0) {
			[gabor directSetSpatialFreqCPD:pSD->testValue];
		}
		else if (strcmp(testParams.testTypeName, "Temporal Frequency") == 0) {
			[gabor directSetTemporalFreqHz:pSD->testValue];
		}
		else {
			NSRunCriticalAlertPanel(@"TUNStimuli", @"Unrecognized test named \"%s\"", 
						@"OK", nil, nil, testParams.testTypeName);
			exit(0);
		}
		break;
	case kRandomDots:
		aziEle = azimuthAndElevationForStimIndex(index);
		[randomDots setAzimuthDeg:aziEle.x elevationDeg:aziEle.y];
//		[randomDots setDirectionDeg:pSD->directionDeg];
//		[randomDots setSpeedDPS:pSD->speedDPS];
//		[randomDots setDotContrast:pSD->contrastPC / 100.0];
		[randomDots makeMovieFrames:pSD->stimOffFrame - pSD->stimOnFrame];
		break;
	default:
		break;
	}
}

- (void)presentStimList;
{
    long trialFrame, stimFrame, stimIndex;
	StimDesc stimDesc;
    NSAutoreleasePool *threadPool;

    threadPool = [[NSAutoreleasePool alloc] init];		// create a threadPool for this thread
	[LLSystemUtil setThreadPriorityPeriodMS:1.0 computationFraction:0.250 constraintFraction:1.0];
	[monitor reset]; 
	
// Set up the stimulus calibration, including the offset then present the stimulus sequence

	[[task stimWindow] lock];
	[[task stimWindow] setScaleOffsetDeg:[[task eyeCalibrator] offsetDeg]];
	[[task stimWindow] scaleDisplay];

// Set up the stimuli

	[gabor store];										// save current settings
	stimIndex = 0;
	[[stimList objectAtIndex:stimIndex] getValue:&stimDesc];
	[self prepareOneStimulus:&stimDesc];

    for (trialFrame = stimFrame = 0; !abortStimuli; trialFrame++) {
		glClear(GL_COLOR_BUFFER_BIT);
		if (trialFrame >= stimDesc.stimOnFrame && trialFrame < stimDesc.stimOffFrame) {
			switch (stimDesc.stimTypeIndex) {
			case kGabor:
				[gabor directSetFrame:[NSNumber numberWithLong:stimFrame]];	// advance for temporal modulation
				[gabor draw];
				break;
			case kRandomDots:
				[randomDots drawFrame:stimFrame];
				break;
			}
			stimFrame++;
		}
		[cueSpot draw];
		[fixSpot draw];
		[[NSOpenGLContext currentContext] flushBuffer];
		glFinish();
		[monitor recordEvent];

		if (trialFrame == stimDesc.stimOnFrame) {
			[[task dataDoc] putEvent:@"stimulus" withData:&stimDesc];
			[[task dataDoc] putEvent:@"stimulusOn" withData:&trialFrame];
			[[task dataDoc] putEvent:@"stimOn"];
		}
		else if (trialFrame == stimDesc.stimOffFrame) {
			[[task dataDoc] putEvent:@"stimulusOff" withData:&trialFrame];
			[[task dataDoc] putEvent:@"stimOff"];
			if (++stimIndex >= [stimList count]) {
				break;
			}
			[[stimList objectAtIndex:stimIndex] getValue:&stimDesc];
			[self prepareOneStimulus:&stimDesc];
			stimFrame = 0;
		}
    }

// Clear the display and leave the back buffer cleared

    glClear(GL_COLOR_BUFFER_BIT);
    [[NSOpenGLContext currentContext] flushBuffer];
	glFinish();

	[[task stimWindow] unlock];
	[gabor restore];										// restore gabor settings
	
// The temporal counterphase might have changed some settings.  We restore these here.

	stimulusOn = abortStimuli = NO;
    [threadPool release];
}

- (LLRandomDots *)randomDots;
{
	return randomDots;
}

- (void)setFixSpot:(BOOL)state;
{
	[fixSpot setState:state];
	if (state) {
		if (!stimulusOn) {
			[[task stimWindow] lock];
			[[task stimWindow] setScaleOffsetDeg:[[task eyeCalibrator] offsetDeg]];
			[[task stimWindow] scaleDisplay];
			glClear(GL_COLOR_BUFFER_BIT);
			[fixSpot draw];
			[[NSOpenGLContext currentContext] flushBuffer];
			[[task stimWindow] unlock];
		}
	}
}

// Shuffle the stimulus sequence by repeated passed along the list and paired substitution

- (void)shuffleStimListFrom:(short)start count:(short)count;
{
	long rep, reps, stim, index, temp, indices[kMaxSteps];
	NSArray *block;
	
	reps = 5;	
	for (stim = 0; stim < count; stim++) {			// load the array of indices
		indices[stim] = stim;
	}
	for (rep = 0; rep < reps; rep++) {				// shuffle the array of indices
		for (stim = 0; stim < count; stim++) {
			index = rand() % count;
			temp = indices[index];
			indices[index] = indices[stim];
			indices[stim] = temp;
		}
	}
	block = [stimList subarrayWithRange:NSMakeRange(start, count)];
	for (index = 0; index < count; index++) {
		[stimList replaceObjectAtIndex:(start + index) withObject:[block objectAtIndex:indices[index]]];
	}
}

- (void)startStimList;
{
	if (stimulusOn) {
		return;
	}
	stimulusOn = YES;
   [NSThread detachNewThreadSelector:@selector(presentStimList) toTarget:self
				withObject:nil];
}

- (BOOL)stimulusOn;
{
	return stimulusOn;
}

// Stop on-going stimulation and clear the display

- (void)stopAllStimuli;
{
	if (stimulusOn) {
		abortStimuli = YES;
		while (stimulusOn) {};
	}
	else {
		[stimuli setFixSpot:NO];
		[self erase];
	}
}

// Count the stimuli in the StimList as successfully completed

- (void)tallyStimuli;
{
	StimDesc stimDesc;
	long index;
	
	for (index = 0; index < [stimList count]; index++) {
		[[stimList objectAtIndex:index] getValue:&stimDesc];
		stimDone[stimDesc.stimIndex]++;
	}
}

@end
