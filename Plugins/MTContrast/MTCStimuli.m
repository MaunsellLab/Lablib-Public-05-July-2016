/*
MTCStimuli.m
Stimulus generation for MTContrast
March 29, 2003 JHRM
*/

#import "MTC.h"
#import "MTCStimuli.h"
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

NSString *stimulusMonitorID = @"MTContrast Stimulus";

@implementation MTCStimuli

- (void) dealloc;
{
	[[task monitorController] removeMonitorWithID:stimulusMonitorID];
	[stimList release];
	[cueSpot release];
	[fixSpot release];
    [nGabor release];
    [pGabor release];
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

- (void)doGaborSettings;
{
	[pGabor runSettingsDialog];
}

- (void)dumpStimList;
{
	StimDesc stimDesc;
	long index;
	
	NSLog(@"\ncIndex contrast type0 type0Speed type1 type1Speed stimOnFrame stimOffFrame");
	for (index = 0; index < [stimList count]; index++) {
		[[stimList objectAtIndex:index] getValue:&stimDesc];
		NSLog(@"%4d: %4d %.1f\t%4d %.1f\t%24 %.1f\t %d %d",
			index, stimDesc.contrastIndex, stimDesc.contrastPC,
			stimDesc.type0, stimDesc.speed0DPS, stimDesc.type1, stimDesc.speed1DPS,
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

- (LLGabor *)gabor;
{
	return pGabor;
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

	pGabor = [self initGabor];
	nGabor = [self initGabor];
	cueSpot = [[LLFixTarget alloc] init];
	[cueSpot bindValuesToKeysWithPrefix:@"MTCCue"];
	fixSpot = [[LLFixTarget alloc] init];
	[fixSpot bindValuesToKeysWithPrefix:@"MTCFix"];

// Register for notifications about changes to the gabor settings

	return self;
}

- (LLGabor *)initGabor;
{
	LLGabor *gabor;
	
	gabor = [[LLGabor alloc] init];				// Create a gabor stimulus
	[gabor setDisplays:[[task stimWindow] displays] displayIndex:[[task stimWindow] displayIndex]];
	[gabor removeKeysFromBinding:[NSArray arrayWithObjects:LLGaborAzimuthDegKey, LLGaborElevationDegKey, 
								LLGaborDirectionDegKey, LLGaborTemporalPhaseDegKey, LLGaborContrastKey,
								LLGaborSpatialPhaseDegKey, LLGaborTemporalFreqHzKey, nil]];
	[gabor bindValuesToKeysWithPrefix:@"MTC"];
	return gabor;
}

- (void)insertStimSettingsAtIndex:(long)index trial:(TrialDesc *)pTrial 
				type0:(short)type0 type1:(short)type1 contrastIndex:(short)cIndex;
{
	StimDesc stimDesc;
	
	stimDesc.attendLoc = attendLoc;
	stimDesc.type0 = type0;
	stimDesc.speed0DPS = (type0 == kTargetStim) ? pTrial->targetSpeed : pTrial->stimulusSpeed;
	stimDesc.type1 = type1;
	stimDesc.speed1DPS = (type1 == kTargetStim) ? pTrial->targetSpeed : pTrial->stimulusSpeed;
	stimDesc.direction0Deg = pTrial->direction0Deg;
	stimDesc.direction1Deg = pTrial->direction1Deg;
	stimDesc.contrastIndex = cIndex;
	stimDesc.contrastPC = contrastFromIndex(cIndex);
	if (index < 0 || index > [stimList count]) {
		index = [stimList count];
	}
	[stimList insertObject:[NSValue valueWithBytes:&stimDesc objCType:@encode(StimDesc)]
		atIndex:index];
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
	long targetIndex, distIndex, stimSpeed, targetSpeed, instructTrial;
	long c, contrasts, inStart, cIndex, stim, sectionStart, frontPadStim, nextStimOnFrame;
	long stimDurFrames, interDurFrames, stimJitterPC, interJitterPC, stimJitterFrames, interJitterFrames;
	long stimDurBase, interDurBase, remaining, stimListLength, minStimDone;
	float stimRateHz, frameRateHz;
	StimDesc stimDesc;
	BOOL insertDist;
	
	attendLoc = pTrial->attendLoc;
	targetIndex = pTrial->targetIndex;
	distIndex = pTrial->distIndex;
	stimSpeed = pTrial->stimulusSpeed;
	targetSpeed = pTrial->targetSpeed;
	stimListLength = pTrial->numStim;
	instructTrial = pTrial->instructTrial;
	
	stimRateHz = 1000.0 / ([[task defaults] integerForKey:MTCStimDurationMSKey] + 
					[[task defaults] integerForKey:MTCInterstimMSKey]);

// To make our list, we will first build it up to targetIndex, and then add back padding
// characters.  However, targetIndex may be beyond stimListLength.  If that happens, 
// set targetIndex to stimListLength so we can use it as a limit in either case.

	targetIndex = MIN(targetIndex, stimListLength);
	distIndex = MIN(distIndex, stimListLength);
	
// frontPadStim are stimuli at the beginning of the sequence that are not counted
// This serves to eliminate response transients at the start of the sequence.  
// There is always at least one pad stimulus, so that a non-zero contrast
// starting stimulus can be a reference if the target is to come in the second
// position

	frontPadStim = MAX(1, MIN(targetIndex, 
			ceil([[task defaults] integerForKey:MTCStimLeadMSKey] / 1000.0 * stimRateHz)));

// If distractors are going to appear after the front padding stimuli and before the
// target stimulus, then they will appear among valid stimuli.  We have to make sure that the
// presentation of the distractor is not counted as a valid stimulus.  The easiest way to do
// that is to shorten the stimListLength by the number of distractors, and then inserting the 
// (extra) distractor stimuli after the list has been made.  In this way we make sure that we 
// don't invalidate one of the stimulus presentation that should be valid.

	insertDist = (distIndex >= frontPadStim && distIndex < targetIndex);
	if (insertDist) {
		stimListLength -= 1;
		targetIndex -= 1;
	}

// Count the number of undone conditions in the done table
	
	contrasts = [[task defaults] integerForKey:MTCContrastsKey];
	for (c = 0, minStimDone = LONG_MAX; c < contrasts; c++) {	// copy doneTable, get minimum
		selectTable[c] = stimDone[pTrial->attendLoc][c];
		minStimDone = MIN(minStimDone, selectTable[c]);
	}
	for (c = remaining = 0; c < contrasts; c++) {				// count number remaining in table
		selectTable[c] -= minStimDone;
		remaining += (selectTable[c] == 0) ? 1 : 0;
	}
	[stimList removeAllObjects];
		
// The start of the list must begin with the number of requested padding stimuli.  These are 
// simply taken at random from all stimuli.  We don't scramble this section, because it is random.
// The very first stimulus in the sequence is always a padding stimulus, and we make this highly 
// visible.

	for (stim = 0; stim < frontPadStim; stim++) {
		cIndex = (stim == 0) ? [self randomHighContrastIndex:contrasts] : 
								[self randomVisibleContrastIndex:contrasts];
		[self insertStimSettingsAtIndex:-1 trial:pTrial type0:kFrontPadding 
						type1:kFrontPadding contrastIndex:cIndex];
	}
	
// If there are fewer than the number of stim we need remaining in the current doneTable,
// pick up all that are there, clearing the table as we go.

	sectionStart = [stimList count];				// start of the current section (for scrambling)
	if (remaining < (targetIndex - sectionStart)) {	// need all remaining in block?
		for (c = 0; c < contrasts; c++) {
			if (selectTable[c] == 0) {
				[self insertStimSettingsAtIndex:-1 trial:pTrial type0:kValidStim
							type1:kValidStim contrastIndex:c];
			}
			else {
				selectTable[c] = 0;
			}
		}
		[self shuffleStimListFrom:sectionStart count:remaining];
		
// For long trials, we might need more than a complete doneTable's worth of stimuli.
// If that is the case, keep grabbing full image set until we need less than a full table

		sectionStart = [stimList count];
		while ((targetIndex - sectionStart) > contrasts) {
			for (c = 0; c < contrasts; c++) {
				[self insertStimSettingsAtIndex:-1 trial:pTrial type0:kValidStim
							type1:kValidStim contrastIndex:c];
			}
			[self shuffleStimListFrom:sectionStart count:contrasts];
			sectionStart = [stimList count];
		}
	}

// At this point there are enough available entries in selectTable to fill the rest of the stimList.
	
	while ([stimList count] < targetIndex) {
		c = inStart = (rand() % contrasts);
		while (selectTable[c] != 0) {
			c = (c + 1) % contrasts;
			if (c == inStart) {
				break;
			}
		}
		if (selectTable[c] > 0) {
			NSLog(@"makeStimList: scanned table without finding empty entry");
		}
		selectTable[c]++;
		[self insertStimSettingsAtIndex:-1 trial:pTrial type0:kValidStim
					type1:kValidStim contrastIndex:c];
	}
	
// If this is not a catch trial, load the target stimulus, chosen at random from all non-zero contrasts

	if (targetIndex < stimListLength) {	
		pTrial->targetContrastIndex = [self randomVisibleContrastIndex:contrasts];
		pTrial->targetContrastPC = contrastFromIndex(pTrial->targetContrastIndex);
		if (attendLoc == kAttend0) {
			[self insertStimSettingsAtIndex:-1 trial:pTrial type0:kTargetStim
					type1:kValidStim contrastIndex:pTrial->targetContrastIndex];
		}
		else {
			[self insertStimSettingsAtIndex:-1 trial:pTrial type0:kValidStim
					type1:kTargetStim contrastIndex:pTrial->targetContrastIndex];
		}
	}
	else {
		pTrial->targetContrastIndex = -1;
		pTrial->targetContrastPC = -1;
	}
	
// Load the trailing stimuli.  These are just pulled at random and not tallied or shuffled.

	while ([stimList count] < stimListLength) {
		[self insertStimSettingsAtIndex:-1 trial:pTrial type0:kBackPadding
					type1:kBackPadding contrastIndex:(rand() % contrasts)];
	}

// If distractor stimuli are going to appear after the front padding stimuli and before the
// target stimulus, then they will appear among valid stimuli.  We have to make sure that the
// presentation of the distractor is not counted as a valid stimulus.  To do this, we shortened
// the stimListLength by the number of distrators.  Now that the list has been made, we need
// to insert any (extra) distractors.  In this way we make sure that we don't invalidate
// one of the stimulus presentation that should be valid.

// If a distractor is off the end of the list, we do nothing.  If it is among the front padding 
// stimuli, or at or beyond the target, we simply set the unattended location stimulus type to a 
// target.  Things are more complicated if a distractor appears after the front padding stimuli, 
// but before the target.  In that case, we will have artificially dropped one stimulus from 
// the list before it was created (above, at the start of the function).  We now insert a 
// distractor stimulus in the correct place, and shove all the remaining stimuli back one 
// position, restoring the list to its proper length.
// 021118 Changed the load so that the distractor always has the highest contrast. 

// Do a distractor that is among valid stimuli

	if (insertDist) {
		[self insertStimSettingsAtIndex:distIndex trial:pTrial 
					type0:((attendLoc == kAttend0) ? kValidStim : kTargetStim)
					type1:((attendLoc == kAttend0) ? kTargetStim : kValidStim)
					contrastIndex:[self randomVisibleContrastIndex:contrasts]];
	}
		
// Place distractor in front or back padding stimuli, or with target

	else if (distIndex < [stimList count]) {		// distractor within the stim list
		[[stimList objectAtIndex:distIndex] getValue:&stimDesc];
		if (attendLoc == kAttend0) {
			stimDesc.type1 = kTargetStim;
			stimDesc.speed1DPS = pTrial->targetSpeed;
		}
		else {
			stimDesc.type0 = kTargetStim;
			stimDesc.speed0DPS = pTrial->targetSpeed;
		}
		[stimList replaceObjectAtIndex:distIndex 
			withObject:[NSValue valueWithBytes:&stimDesc objCType:@encode(StimDesc)]];
	}
		
// Now the list is complete.  We make a pass through the list loading the stimulus presention
// frames.  At the same time, for instruction trials we set all the distractor stimulus types
// to kNull, so nothing will appear there

	frameRateHz = [[task stimWindow] frameRateHz];
	stimJitterPC = [[task defaults] integerForKey:MTCStimJitterPCKey];
	interJitterPC = [[task defaults] integerForKey:MTCInterstimJitterPCKey];
	stimDurFrames = [[task defaults] integerForKey:MTCStimDurationMSKey] / 
					1000.0 * frameRateHz;
	interDurFrames = [[task defaults] integerForKey:MTCInterstimMSKey] / 1000.0 * frameRateHz;
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

// Fix instruction trials

		if (instructTrial) {
			if (attendLoc == kAttend0) {
				stimDesc.type1 = kNullStim;
				stimDesc.speed1DPS = stimSpeed;
			}
			else {
				stimDesc.type0 = kNullStim;
				stimDesc.speed0DPS = stimSpeed;
			}
		}
		[stimList replaceObjectAtIndex:stim withObject:
				[NSValue valueWithBytes:&stimDesc objCType:@encode(StimDesc)]];
	}
}
	
- (void)loadGaborsWithStimDesc:(StimDesc *)pSD;
{
	long index;
	NSPoint aziEle;
	LLGabor *gabors[] = {pGabor, nGabor, nil};
	
	for (index = 0; gabors[index] != nil; index++) {
		aziEle = azimuthAndElevationForStimIndex(index);
		[gabors[index] setAzimuthDeg:aziEle.x elevationDeg:aziEle.y];
		[gabors[index] setTemporalPhaseDeg:(180.0 * (rand() % 2))];		// random odd phase
		[gabors[index] setContrast:pSD->contrastPC / 100.0];
		[gabors[index] setDirectionDeg:((index == 0) ? pSD->direction0Deg : pSD->direction1Deg)];
		[gabors[index] setTemporalFreqHz:([gabors[index] spatialFreqCPD] * 
					(index == 0) ? pSD->speed0DPS : pSD->speed1DPS)];
//		[gabors[index] makeDisplayLists];			// use OpenGL display lists to speed things up
	}	

// Blank any null stimuli (which appear on instruction trials

	if (pSD->type0 == kNullStim) {
		[pGabor setContrast:0.0]; 
	}
	if (pSD->type1 == kNullStim) {
		[nGabor setContrast:0.0]; 
	}
}

- (LLIntervalMonitor *)monitor {

	return monitor;
}

- (short)randomHighContrastIndex:(short)contrasts;
{
	switch (contrasts) {
	case 1:
		return(0);
		break;
	case 2:
		return(1);
		break;
	default:
		return((contrasts + 1) / 2 + (rand() % (contrasts / 2)));
		break;
	}
}

- (void)presentStimList;
{
    long trialFrame, gaborFrame, stimIndex;
	StimDesc stimDesc;
    NSAutoreleasePool *threadPool;

    threadPool = [[NSAutoreleasePool alloc] init];		// create a threadPool for this thread
	[LLSystemUtil setThreadPriorityPeriodMS:1.0 computationFraction:0.250 constraintFraction:1.0];
	[monitor reset]; 
	
// Set up the stimulus calibration, including the offset then present the stimulus sequence

	[[task stimWindow] lock];
	[[task stimWindow] setScaleOffsetDeg:[[task eyeCalibrator] offsetDeg]];
	[[task stimWindow] scaleDisplay];

// Set up the gabors

	stimIndex = 0;
	[[stimList objectAtIndex:stimIndex] getValue:&stimDesc];
	[self loadGaborsWithStimDesc:&stimDesc];

    for (trialFrame = gaborFrame = 0; !abortStimuli; trialFrame++) {
		glClear(GL_COLOR_BUFFER_BIT);
		if (trialFrame >= stimDesc.stimOnFrame && trialFrame < stimDesc.stimOffFrame) {
			[pGabor setFrame:[NSNumber numberWithLong:gaborFrame]];	// advance for temporal modulation
			[pGabor draw];
			[nGabor setFrame:[NSNumber numberWithLong:gaborFrame]];	// advance for temporal modulation
			[nGabor draw];
			gaborFrame++;
		}
		[cueSpot draw];
		[fixSpot draw];
		[[NSOpenGLContext currentContext] flushBuffer];
		glFinish();
		[monitor recordEvent];

		if (trialFrame == stimDesc.stimOnFrame) {
			[[task dataDoc] putEvent:@"stimulus" withData:&stimDesc];
			[[task dataDoc] putEvent:@"stimulusOn" withData:&trialFrame];
			if ((attendLoc == 0 && stimDesc.type0 == kTargetStim) ||
					(attendLoc == 1 && stimDesc.type1 == kTargetStim)) {
				targetPresented = YES;
			}
		}
		else if (trialFrame == stimDesc.stimOffFrame) {
			[[task dataDoc] putEvent:@"stimulusOff" withData:&trialFrame];
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
	
// The temporal counterphase might have changed some settings.  We restore these here.

	stimulusOn = abortStimuli = NO;
    [threadPool release];
}

// Return a random contrast index that will not correspond to 0% contrast

- (short)randomVisibleContrastIndex:(short)contrasts;
{
	if (contrasts <= 1) {
		return(0);
	}
	else {
		return((rand() % (contrasts - 1)) + 1);
	}
}

- (void)setCueSpot:(BOOL)state location:(long)loc;
{
	NSPoint aziEle;
	
	[cueSpot setState:state];
	aziEle = azimuthAndElevationForStimIndex(loc);
	[cueSpot setAzimuthDeg:aziEle.x];					// must use key-value compliant calls
	[cueSpot setElevationDeg:aziEle.y];					// must use key-value compliant calls	
	if (!stimulusOn) {
		[[task stimWindow] lock];
		[[task stimWindow] setScaleOffsetDeg:[[task eyeCalibrator] offsetDeg]];
		[[task stimWindow] scaleDisplay];
		glClear(GL_COLOR_BUFFER_BIT);
		[cueSpot draw];
		[fixSpot draw];
		[[NSOpenGLContext currentContext] flushBuffer];
		[[task stimWindow] unlock];
	}
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
	long rep, reps, stim, index, temp, indices[kMaxContrasts];
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
	targetPresented = NO;
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
		if (stimDesc.type0 == kValidStim && stimDesc.type1 == kValidStim) {
			stimDone[stimDesc.attendLoc][stimDesc.contrastIndex]++;
		}
	}
}

- (BOOL)targetPresented;
{
	return targetPresented;
}

@end
