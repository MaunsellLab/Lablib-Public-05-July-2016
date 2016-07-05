/*
SCStimuli.m
Stimulus generation for SpotChange
March 29, 2003 JHRM
*/

#import "SC.h"
#import "SCStimuli.h"
#import "UtilityFunctions.h"
#import "SCDigitalOut.h"
#import <unistd.h>

#define kDefaultDisplayIndex	1	 	// Index of stim display when more than one display
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

NSString *stimulusMonitorID = @"SpotChange Stimulus";

@implementation SCStimuli

- (void) dealloc;
{
	[[task monitorController] removeMonitorWithID:stimulusMonitorID];
	[stimList release];
	[fixSpot release];
    [gabor1 release];
    [gabor0 release];
	[targetSpot release];
    [super dealloc];
}

- (void)doFixSettings;
{
	[fixSpot runSettingsDialog];
}

- (void)doGabor0Settings;
{
	[gabor0 runSettingsDialog];
}

- (void)doGabor1Settings;
{
	[gabor1 runSettingsDialog];
}

- (void)doTargetSpotSettings;
{
	[targetSpot runSettingsDialog];
}

- (void)dumpStimList;
{
	StimDesc stimDesc;
	long index;
	
	NSLog(@"cIndex stim0Type stim1Type stimOnFrame stimOffFrame");
	for (index = 0; index < [stimList count]; index++) {
		[[stimList objectAtIndex:index] getValue:&stimDesc];
		NSLog(@"%4ld:\t%4d \t%4d\t %ld %ld", index, stimDesc.stim0Type, stimDesc.stim1Type,
			stimDesc.stimOnFrame, stimDesc.stimOffFrame);
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

- (LLGabor *)gabor0;
{
	return gabor0;
}

- (LLGabor *)gabor1;
{
	return gabor1;
}

- (LLGabor *)gaborWithIndex:(long)index;
{
	switch (index) {
	case 0:
		return gabor0;
		break;
	case 1:
		return gabor1;
		break;
	default:
		return nil;
		break;
	}
	return nil;
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
	
// Create and initialize the visual stimuli

	gabor0 = [self initGaborWithPrefix:@"SC0" achromaticFlag:NO];
	gabor1 = [self initGaborWithPrefix:@"SC1" achromaticFlag:NO];
	targetSpot = [[LLFixTarget alloc] init];
	[targetSpot bindValuesToKeysWithPrefix:@"SCTarget"];
	fixSpot = [[LLFixTarget alloc] init];
	[fixSpot bindValuesToKeysWithPrefix:@"SCFix"];

// Register for notifications about changes to the gabor settings

	return self;
}

- (LLGabor *)initGaborWithPrefix:(NSString *)prefix achromaticFlag:(BOOL)achromatic;
{
	LLGabor *gabor;
	
	gabor = [[LLGabor alloc] init];				// Create a gabor stimulus
	[gabor setDisplays:[[task stimWindow] displays] displayIndex:[[task stimWindow] displayIndex]];
	[gabor removeKeysFromBinding:[NSArray arrayWithObjects:LLGaborDirectionDegKey, 
					LLGaborTemporalPhaseDegKey, LLGaborContrastKey,
					LLGaborSpatialPhaseDegKey, LLGaborTemporalFreqHzKey, nil]];
	[gabor bindValuesToKeysWithPrefix:prefix];
    if (achromatic) {
        [gabor setAchromatic:YES];
    }
	return gabor;
}

/*
makeStimList()

Make a stimulus list for one trial, with the target in the specified targetIndex position 
(0 based counting).  The list is constructed so that each stimulus contrast
appears n times before any appears (n+1).  In the simplest case, we just draw n unused entries 
from the done table.  If there are fewer than n entries remaining, we take them all, clear 
the table, and then proceed.  We also make a provision for the case where several full table 
worth's will be needed to make the list.  Whenever we take all the entries remaining in the table, 
we simply draw them in order and then use shuffleStimList() to randomize their order.  Shuffling 
does not span the borders between successive doneTables, to ensure that each stimulus pairing will 
be presented n times before any appears n + 1 times, even if each appears several times within 
one trial.

Two types of padding stimuli are used.  Padding stimuli are inserted in the list after the target, so
that the stream of stimuli continues through the reaction time.  Padding stimuli are also optionally
put at the start of the trial.  This is so the first few stimulus presentations, which might have 
response transients, are not counted.  The number of padding stimuli at the end of the trial is 
determined by stimRateHz and reactTimeMS.  The number of padding stimuli at the start of the trial
is determined by rate of presentation and stimLeadMS.  Note that it is possible to set parameters 
so that there will never be anything except targets and padding stimuli (e.g., with a short 
maxTargetS and a long stimLeadMS).

*/

- (void)makeStimList:(TrialDesc *)pTrial;
{
	long targetIndex;
	long stim, nextStimOnFrame;
	long stimDurFrames, interDurFrames, stimJitterPC, interJitterPC, stimJitterFrames, interJitterFrames;
	long stimDurBase, interDurBase;
	float stimRateHz, frameRateHz;
	StimDesc stimDesc;
	
	[stimList removeAllObjects];
	stimRateHz = 1000.0 / ([[task defaults] integerForKey:SCStimDurationMSKey] + 
					[[task defaults] integerForKey:SCInterstimMSKey]);
	targetIndex = MIN(pTrial->targetIndex, pTrial->numStim);
    orientationChangeDeg = pTrial->orientationChangeDeg;
	
// Now we make a second pass through the list adding the stimulus times.  We also insert 
// the target stimulus (if this isn't a catch trial) and set the invalid stimuli to kNull
// if this is an instruction trial.

	frameRateHz = [[task stimWindow] frameRateHz];
	stimJitterPC = [[task defaults] integerForKey:SCStimJitterPCKey];
	interJitterPC = [[task defaults] integerForKey:SCInterstimJitterPCKey];
	stimDurFrames = ceil([[task defaults] integerForKey:SCStimDurationMSKey] / 1000.0 * frameRateHz);
	interDurFrames = ceil([[task defaults] integerForKey:SCInterstimMSKey] / 1000.0 * frameRateHz);
	stimJitterFrames = round(stimDurFrames / 100.0 * stimJitterPC);
	interJitterFrames = round(interDurFrames / 100.0 * interJitterPC);
	stimDurBase = stimDurFrames - stimJitterFrames;
	interDurBase = interDurFrames + interJitterFrames;

	pTrial->targetOnTimeMS = 0;
 	for (stim = nextStimOnFrame = 0; stim < pTrial->numStim; stim++) {

// Set the default values
	
		stimDesc.index = stim;
		stimDesc.stim0Type = kValidStim;
		stimDesc.direction0Deg = [gabor0 directionDeg];
		stimDesc.contrast0PC = 100.0;
		stimDesc.stim1Type = kValidStim;
		stimDesc.direction1Deg = [gabor1 directionDeg];
		stimDesc.contrast1PC = 100.0;

// Blank the invalid side for instruction trials

		if (pTrial->instructTrial) {
			if (pTrial->correctLoc == kAttend0) {
				stimDesc.stim1Type = kNullStim;
				stimDesc.contrast1PC = 0.0;
			}
			else {
				stimDesc.stim0Type = kNullStim;
				stimDesc.contrast0PC = 0.0;
			}
		}

// Otherwise set the invalid side to the distractor contrast
		
		else {
			if (pTrial->attendLoc == kAttend0) {
				stimDesc.contrast1PC = [[task defaults] integerForKey:SCDistContrastPCKey];
			}
			else {
				stimDesc.contrast0PC = [[task defaults] integerForKey:SCDistContrastPCKey];
			}
		}
	
// If it's not a catch trial and we're in a target spot, set the target 

		if (!pTrial->catchTrial) {
			if ((stimDesc.index == pTrial->targetIndex) || (stimDesc.index > pTrial->targetIndex &&
							[[task defaults] boolForKey:SCChangeRemainKey])) {
				if (pTrial->correctLoc == kAttend0) {
					stimDesc.stim0Type = kTargetStim;
					stimDesc.direction0Deg += pTrial->orientationChangeDeg;
				}
				else {
					stimDesc.stim1Type = kTargetStim;
					stimDesc.direction1Deg += pTrial->orientationChangeDeg;
				}
			}
		}

// Load the information about the on and off frames
	
		stimDesc.stimOnFrame = nextStimOnFrame;
		if (stimJitterFrames > 0) {
			stimDesc.stimOffFrame = stimDesc.stimOnFrame + 
					MAX(1, stimDurBase + (rand() % (2 * stimJitterFrames + 1)));
		}
		else {
			stimDesc.stimOffFrame = stimDesc.stimOnFrame +  MAX(0, stimDurFrames);
		}
		if (interJitterFrames > 0) {
			nextStimOnFrame = stimDesc.stimOffFrame + 
				MAX(1, interDurBase + (rand() % (2 * interJitterFrames + 1)));
		}
		else {
			nextStimOnFrame = stimDesc.stimOffFrame + MAX(0, interDurFrames);
		}

// Put the stimulus descriptor into the list

		[stimList addObject:[NSValue valueWithBytes:&stimDesc objCType:@encode(StimDesc)]];

// Save the estimated target on time

		if (stimDesc.stim0Type == kTargetStim) {
			pTrial->targetOnTimeMS = stimDesc.stimOnFrame / frameRateHz * 1000.0;	// this is a theoretical value
		}
	}
	[self dumpStimList];
}
	
- (void)loadGaborsWithStimDesc:(StimDesc *)pSD;
{	
	[gabor0 directSetDirectionDeg:pSD->direction0Deg];
	[gabor0 directSetContrast:pSD->contrast0PC / 100.0];
	[gabor1 directSetDirectionDeg:pSD->direction1Deg];
	[gabor1 directSetContrast:pSD->contrast1PC / 100.0];
}

- (LLIntervalMonitor *)monitor;
{
	return monitor;
}

- (void)presentStimSequence;
{
    long trialFrame, gaborFrame, stimIndex, interDurFrames;
	long frameRateHz;
	float originalDirDeg0, originalDirDeg1;
	NSMutableArray *times = [[NSMutableArray alloc] init];
    NSColor *targetColor = [[targetSpot foreColor]retain];
	double lastFinish = -1;
	
	StimDesc stimDesc;
    NSAutoreleasePool *threadPool;
	
    threadPool = [[NSAutoreleasePool alloc] init];		// create a threadPool for this thread
	[LLSystemUtil setThreadPriorityPeriodMS:1.0 computationFraction:0.250 constraintFraction:1.0];
	
// Set up the stimulus calibration, including the offset then present the stimulus sequence

	[[task stimWindow] lock];
	[[task stimWindow] setScaleOffsetDeg:[[task eyeCalibrator] offsetDeg]];
	[[task stimWindow] scaleDisplay];

// Set up the gabors

	originalDirDeg0 = [gabor0 directionDeg];			// Save for restore 
	originalDirDeg1 = [gabor1 directionDeg];
	stimIndex = 0;
	[[stimList objectAtIndex:stimIndex] getValue:&stimDesc];
	[self loadGaborsWithStimDesc:&stimDesc];
	
	frameRateHz = [[task stimWindow] frameRateHz];
	interDurFrames = [[task defaults] integerForKey:SCInterstimMSKey] / 1000.0 * frameRateHz;
	if (interDurFrames == 0) {                          // When stim is continuous, 
		[gabor0 directSetTemporalPhaseDeg:180.0];		// fix the initial phase of the gabor
		[gabor1 directSetTemporalPhaseDeg:180.0];		// fix the initial phase of the gabor
	}

    [targetSpot setState:YES];
    for (trialFrame = gaborFrame = 0; !abortStimuli; trialFrame++) {
		glClear(GL_COLOR_BUFFER_BIT);
		if (trialFrame >= stimDesc.stimOnFrame && trialFrame < stimDesc.stimOffFrame) {
			[gabor0 directSetFrame:[NSNumber numberWithLong:gaborFrame]];	// advance for temporal modulation
			[gabor0 draw];
			[gabor1 directSetFrame:[NSNumber numberWithLong:gaborFrame]];	// advance for temporal modulation
			[gabor1 draw];
			gaborFrame++;
            if (stimDesc.stim0Type == kTargetStim) {
                [targetSpot setAzimuthDeg:[gabor0 azimuthDeg] elevationDeg:[gabor0 elevationDeg]];
                [targetSpot setForeColor:[targetColor colorWithAlphaComponent:orientationChangeDeg]];
                [targetSpot setOuterRadiusDeg:(float) 0.23/0.33 * [gabor0 sigmaDeg]]; // set the target radius proportional to the Gabor size
                [targetSpot draw];
            }
            else if (stimDesc.stim1Type == kTargetStim){
                [targetSpot setAzimuthDeg:[gabor1 azimuthDeg] elevationDeg:[gabor1 elevationDeg]];
                [targetSpot setForeColor:[targetColor colorWithAlphaComponent:orientationChangeDeg]];
                [targetSpot setOuterRadiusDeg:(float) 0.23/0.33 * [gabor1 sigmaDeg]];
                [targetSpot draw];
            }
		}
//		if (!targetPresented) {
			[fixSpot draw];
//		}
		if (lastFinish > 0) {
			if ([LLSystemUtil getTimeS] - lastFinish < 0.002) {
				usleep(2000);
			}
		}
		[[NSOpenGLContext currentContext] flushBuffer];
		glFinish();
		lastFinish = [LLSystemUtil getTimeS];
		if (trialFrame == 0) {
			[monitor reset];
		}
		else {
			[monitor recordEvent];
		}

		if (trialFrame == stimDesc.stimOnFrame) {                // just turned on stimulus
			[[task dataDoc] putEvent:@"stimulusOnTime"]; 
			[[task dataDoc] putEvent:@"stimulus" withData:&stimDesc];
			[[task dataDoc] putEvent:@"stimulusOn" withData:&trialFrame];
			[digitalOut outputEvent:kStimulusOnCode withData:stimIndex];
			if (stimDesc.stim0Type == kTargetStim || stimDesc.stim1Type == kTargetStim) {
				targetPresented = YES;
                [digitalOut outputEvent:kTargetOnCode withData:stimIndex];
			}
		}
		else if ((trialFrame == stimDesc.stimOffFrame - 1) && (interDurFrames == 0)) {
			if (++stimIndex >= [stimList count]) {
				break;
			}
			[[stimList objectAtIndex:stimIndex] getValue:&stimDesc];
			[self loadGaborsWithStimDesc:&stimDesc];
			if (interDurFrames == 0) {                          // When stim is continuous, 
				[gabor0 directSetTemporalPhaseDeg:180.0];				// fix the phase when gabor is continuous
				[gabor1 directSetTemporalPhaseDeg:180.0];				// fix the phase when gabor is continuous
			}
			gaborFrame = trialFrame + 1; 
		}
		
		else if (trialFrame == stimDesc.stimOffFrame) {
			[[task dataDoc] putEvent:@"stimulusOffTime"]; 
			[[task dataDoc] putEvent:@"stimulusOff" withData:&trialFrame];
			[digitalOut outputEvent:kStimulusOffCode withData:stimIndex];
			
			if (++stimIndex >= [stimList count]) {
				break;
			}
			[[stimList objectAtIndex:stimIndex] getValue:&stimDesc];
			[self loadGaborsWithStimDesc:&stimDesc];
			gaborFrame = 0; 
		}
    }

// Clear the display and leave the back buffer cleared

    glClear(GL_COLOR_BUFFER_BIT);
    [[NSOpenGLContext currentContext] flushBuffer];
	glFinish();

	[[task stimWindow] unlock];
    [targetSpot setState:NO];
	
// The temporal counterphase might have changed some settings.  We restore these here.

	[gabor0 setDirectionDeg:originalDirDeg0];					// Restore gabor directions
	[gabor1 setDirectionDeg:originalDirDeg1];
	stimulusOn = abortStimuli = NO;

	[times release];
    [threadPool release];
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
	long rep, reps, stim, index, temp, indices[kMaxOriChanges];
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
		[stimList replaceObjectAtIndex:(start + index) withObject:[block objectAtIndex:index]];
	}
}

- (void)startStimSequence;
{
	if (stimulusOn) {
		return;
	}
	stimulusOn = YES;
	targetPresented = NO;
	[NSThread detachNewThreadSelector:@selector(presentStimSequence) toTarget:self
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


- (BOOL)targetPresented;
{
	return targetPresented;
}

@end
