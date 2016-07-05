/*
VCANStimuli.m
Stimulus generation for V4CAN
December 6, 2009 JHRM
*/

#import "VCAN.h"
#import "VCANStimuli.h"
#import "UtilityFunctions.h"
#import "VCANUtilities.h"

#define kDefaultDisplayIndex	1		// Index of stim display when more than one display
#define kMainDisplayIndex		0		// Index of main stimulus display
#define kPixelDepthBits			32		// Depth of pixels in stimulus window
#define	stimWindowSizePix		250		// Height and width of stim window on main display

#define kTargetBlue				0.0
#define kTargetGreen			1.0
#define kMidGray				0.5
//#define kPI						(atan(1) * 4)
//#define kTargetRed				1.0
//#define kDegPerRad				57.295779513

#define kAdjusted(color, contrast)  (kMidGray + (color - kMidGray) / 100.0 * contrast)

NSString *stimulusMonitorID = @"V4CAN Stimulus";

@implementation VCANStimuli

- (void)assignMonitorInterval;
{
    [monitor setTargetIntervalMS:1000.0 / [[task stimWindow] frameRateHz]];
}

- (void) dealloc;
{
	long g;
	
	[[task monitorController] removeMonitorWithID:stimulusMonitorID];
	[stimList release];
	[cueSpot release];
	[targetSpot release];
	[fixSpot release];
	for (g = 0; g < kStimLocs; g++) {
		[gabors[g] release];
		[targetGabors[g] release];
		gabors[g] = targetGabors[g] = nil;
	}
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
	[gabors[kGabor0] runSettingsDialog];
}

- (void)doTargetSpotSettings;
{
	[targetSpot runSettingsDialog];
}

- (void)dumpStimList;
{
	StimDesc stimDesc;
	long index, validCount;
	BOOL valid;
	BOOL validOnly = NO;
	
	NSLog(@"Stim:   On  Off Att Loc List         Type        Dir0    1    2    3  CC0  1    2    3");
	for (index = validCount = 0; index < (NSInteger)[stimList count]; index++) {
		[[stimList objectAtIndex:index] getValue:&stimDesc];
		valid = (stimDesc.listTypes[0] == kValidStim && stimDesc.listTypes[1] == kValidStim && 
				 stimDesc.listTypes[2] == kValidStim);
		if (valid) {
			validCount++;
		}
		else if (validOnly) {
			continue;
		}
		NSLog(@"%4ld: %4ld %4ld %2ld %2ld  %2d %2d %2d %2d  %2ld %2ld %2ld %2ld  %4.0f %4.0f %4.0f %4.0f  %4.2f %4.2f %4.2f %4.2f",
			index, stimDesc.stimOnFrame, stimDesc.stimOffFrame, stimDesc.attendState, stimDesc.attendLoc,
			  stimDesc.listTypes[kGabor0], stimDesc.listTypes[kGabor1], 
              stimDesc.listTypes[kGaborFar0], stimDesc.listTypes[kGaborFar1],
			  stimDesc.stimTypes[kGabor0], stimDesc.stimTypes[kGabor1], 
              stimDesc.stimTypes[kGaborFar0], stimDesc.stimTypes[kGaborFar1], 
			  stimDesc.directionsDeg[kGabor0], stimDesc.directionsDeg[kGabor1], 
              stimDesc.directionsDeg[kGaborFar0], stimDesc.directionsDeg[kGaborFar1], 
			  stimDesc.centerContrast[kGabor0], stimDesc.centerContrast[kGabor1],
              stimDesc.centerContrast[kGaborFar0], stimDesc.centerContrast[kGaborFar1]);
	}
	NSLog(@"%3ld valid stimuli\n", validCount);
}

- (void)dumpStimSequence;
{
    long index, offFrame;
    StimDesc stimDesc;
    NSString *string0 = @"Sequence:  ";
    NSString *string1 = @"Interstim: ";

    for (index = 0; index < [stimList count]; index++) {
        string0 = [string0 stringByAppendingString:[VCANUtilities stringForStimDescEntry:stimList entryIndex:index]];
        string0 = [string0 stringByAppendingString:@" "];
    }
    NSLog(@"%@", string0);
    for (index = 0; index < [stimList count] - 1; index++) {
        [[stimList objectAtIndex:index] getValue:&stimDesc];
        offFrame = stimDesc.stimOffFrame;
        [[stimList objectAtIndex:index + 1] getValue:&stimDesc];
        string1 = [string1 stringByAppendingString:[NSString stringWithFormat:@"%2ld ",
                                                    stimDesc.stimOnFrame - offFrame]];
    }
    NSLog(@"%@", string1);
}

- (void)erase;
{
	[[task stimWindow] lock];
    glClearColor(kMidGray, kMidGray, kMidGray, 0);
    glClear(GL_COLOR_BUFFER_BIT);
	[[NSOpenGLContext currentContext] flushBuffer];
	[[task stimWindow] unlock];
}

// Take an index for one of the stimuli (out of kStimPerState), and return the index values defining the stimType
// (blank, null, preferred) for each of the three positions.  The index passed in is usually incremented each call;
// we use it to access the stimSequence array, which is scrambled, to return stimulus values that are in a 
// pseudorandom order.

- (short *)expandStimType:(long)stimType;
{
    long convertedStimType = stimSequence[stimType];
	static short indices[kStimLocs];
	
    indices[kGabor0] = indices[kGaborFar0] = convertedStimType / kRFStimTypes;
    indices[kGabor1] = indices[kGaborFar1] = convertedStimType % kRFStimTypes;
//    indices[kGabor0] = convertedStimType / kRFStimTypes;
//    indices[kGabor1] = convertedStimType % kRFStimTypes;
//    indices[kGaborFar0] = (rand() % kRFStimTypes);
//    if (indices[kGaborFar0] > 0) {                                   // Visible far stimuli are intermediate types
//        indices[kGaborFar0] += (kRFStimTypes - 1);
//    }
//    indices[kGaborFar1] = (rand() % kRFStimTypes);
//    if (indices[kGaborFar1] > 0) {                                   // Visible far stimuli are intermediate types
//        indices[kGaborFar1] += (kRFStimTypes - 1);
//    }
	return indices;
}

- (LLGabor *)gabor;
{
	return gabors[kGabor0];
}

- (long)indexForStimTypes:(StimDesc)stimDesc;
{
    long index;
    long stimIndex = stimDesc.stimTypes[kGabor0] * kRFStimTypes + stimDesc.stimTypes[kGabor1];

    for (index = 0; index < kStimPerState; index++) {
        if (stimSequence[index] == stimIndex){
            break; 
        }
    }
    return index;
}

- (id)init;
{
	if (!(self = [super init])) {
		return nil;
	}
	monitor = [[[LLIntervalMonitor alloc] initWithID:stimulusMonitorID
                                         description:@"Stimulus frame intervals"] autorelease];
	[self assignMonitorInterval];
	[[task monitorController] addMonitor:monitor];
	stimList = [[NSMutableArray alloc] init];
	
// Create and initialize a gabor stimulus

	[self initGabors];    
	cueSpot = [[LLFixTarget alloc] init];
	[cueSpot bindValuesToKeysWithPrefix:@"VCANCue"];
	targetSpot = [[LLFixTarget alloc] init];
	[targetSpot bindValuesToKeysWithPrefix:@"VCANTarget"];
	fixSpot = [[LLFixTarget alloc] init];
	[fixSpot bindValuesToKeysWithPrefix:@"VCANFix"];

// Register for notifications about changes to the gabor settings

	return self;
}

- (void)initGabors;
{
	long g;
	
	for (g = 0; g < kStimLocs; g++) {
		gabors[g] = [[LLGabor alloc] init];				// Create a gabor stimulus
		[gabors[g] setDisplays:[[task stimWindow] displays] displayIndex:[[task stimWindow] displayIndex]];
		[gabors[g] removeKeysFromBinding:[NSArray arrayWithObjects:LLGaborAzimuthDegKey, LLGaborElevationDegKey, 
								LLGaborDirectionDegKey, LLGaborContrastKey, LLGaborSpatialFreqCPDKey,
								LLGaborSigmaDegKey, LLGaborRadiusDegKey,
								LLGaborSpatialPhaseDegKey, LLGaborTemporalFreqHzKey, nil]];
		[gabors[g] bindValuesToKeysWithPrefix:@"VCAN"];

		targetGabors[g] = [[LLGabor alloc] init];				// Create a target gabor stimulus
		[targetGabors[g] setDisplays:[[task stimWindow] displays] displayIndex:[[task stimWindow] displayIndex]];
		[targetGabors[g] removeKeysFromBinding:[NSArray arrayWithObjects:LLGaborAzimuthDegKey, LLGaborElevationDegKey, 
                                          LLGaborDirectionDegKey, LLGaborContrastKey, LLGaborSpatialFreqCPDKey,
                                          LLGaborSigmaDegKey, LLGaborRadiusDegKey,
                                          LLGaborSpatialPhaseDegKey, LLGaborTemporalFreqHzKey, nil]];
		[targetGabors[g] bindValuesToKeysWithPrefix:@"VCANTarget"];
        [targetGabors[g] setAchromatic:YES];
	}
}

- (void)insertStimSettingsAtIndex:(long)index trial:(TrialDesc *)pTrial listTypes:(short *)listTypes 
																	stimTypes:(short *)types;
{
	long stim;
	StimDesc stimDesc;
    float relativeDistContrast = [[task defaults] floatForKey:VCANRelDistContrastKey];
	
	stimDesc.attendState = pTrial->attendState;
	stimDesc.attendLoc = pTrial->attendLoc;
	for (stim = 0; stim < kStimLocs; stim++) {
		stimDesc.listTypes[stim] = listTypes[stim];
		stimDesc.stimTypes[stim] = types[stim];

		if (stim != stimDesc.attendLoc && relativeDistContrast < 1.0)	{	// distractor being dimmed
			stimDesc.contrasts[stim] = relativeDistContrast;
		}
        else {
            stimDesc.contrasts[stim] = 1.0;
        }
	}
	if (index < 0 || index > (NSInteger)[stimList count]) {
		index = (NSInteger)[stimList count];
	}
	[stimList insertObject:[NSValue valueWithBytes:&stimDesc objCType:@encode(StimDesc)]atIndex:index];
}

- (BOOL)isTargetActiveAtIndex:(long)index;
{
	return activeTargets[index];
}

- (long)jitteredInterstimFrames;
{
    long jitteredFrames;
	float frameRateHz = [[task stimWindow] frameRateHz];
	long interJitterTauMS = [[task defaults] integerForKey:VCANInterstimJitterTauMSKey];
	
    jitteredFrames = MAX(1, [[task defaults] integerForKey:VCANInterstimMSKey] / 1000.0 * frameRateHz);
    if (interJitterTauMS > 0) {                                     // add in any random addition
        jitteredFrames += -interJitterTauMS * log(1.0 - ((rand() % 10000) / 10000.0)) / 1000.0 * frameRateHz;
    }
    jitteredFrames = MIN(jitteredFrames, 0.8 * frameRateHz);           // limit to 0.8 sec
    return jitteredFrames;
}

- (void)loadGaborsWithStimDesc:(StimDesc *)pSD;
{
	long g;
	NSPoint aziEle;
	
	for (g = 0; g < kStimLocs; g++) {
        aziEle = azimuthAndElevationForStimLoc(g, trial.attendState);
        [gabors[g] setAzimuthDeg:aziEle.x elevationDeg:aziEle.y];
        [gabors[g] setDirectionDeg:pSD->directionsDeg[g]];
        [gabors[g] setContrast:(pSD->listTypes[g] == kNilStim || pSD->stimTypes[g] == kNoStim) ? 
                            0.0 : pSD->contrasts[g]];
        [targetGabors[g] setAzimuthDeg:aziEle.x elevationDeg:aziEle.y];
        [targetGabors[g] setDirectionDeg:pSD->directionsDeg[g]];
        [targetGabors[g] setContrast:(pSD->listTypes[g] == kNilStim || pSD->stimTypes[g] == kNoStim) ? 
                            0.0 : pSD->centerContrast[g]];
	}	
}

/*
makeStimList()

Make a stimulus list for one trial, with the targets and distractors in the specified targetIndex positions 
(0 based counting).  The list is constructed so that each RF stimulus pairing appears n times before any appears (n+1).  
In the simplest case, we just draw n unused entries from the done table.  If there are fewer than n entries remaining, 
we take them all, clear the table, and then proceed.  We also make a provision for the case where several full table 
worths' will be needed to make the list.
 
Lists are constructed so that every RF pair is always preceded by a specific other RF pair. (Latin square details here).
 
Three types of padding stimuli are used.  Back padding stimuli are inserted in the list after the target, so that the 
stream of stimuli continues through the reaction time.  Front stimuli are also optionally put at the start of the trial.
It is standard to exclude at least the first stimulus presentation from analysis, and this is achieved with padding
stimuli.  This is so the first few stimulus presentations, which might have response transients, are not counted.  
The number of padding stimuli at the end of the trial is determined by stimRateHz and reactTimeMS.  The number of 
padding stimuli at the start of the trial is determined by rate of presentation and stimLeadMS.  Note that it is 
possible to set parameters so that there will never be anything except targets and padding stimuli (e.g., with a short 
maxTargetS and a long stimLeadMS).
 
The final padding stimuli appear between the front and back padding stimuli, interspersed with valid stimuli.  Stimuli
that appear with a target or distractor are considered padding stimuli.  Additionally, after the appearance of a 
distractor stimulus, one addition set of stimuli is inserted into the stimulus stream to ensure that subsequent valid
stimuli are precede by the approriate (padding) RF stimuli, rather than distractors.  

*/

- (void)makeStimList:(TrialDesc *)pTrial;
{
	long targetIndex, instructTrial, attendLoc, stimIndex;
    long distractorIndices[kStimLocs - 1], targetIndices[kStimLocs], distractorSets;
	long s, t, d, e, stim, frontPadStim, nextStimOnFrame, limitStim;
	long stimDurFrames, interDurFrames, stimJitterPC, interJitterTauMS, stimJitterFrames;
	long stimDurBase, remaining, stimListLength, minStimDone;
	short listTypes[kStimLocs];
	float stimRateHz, frameRateHz;
    BOOL frontPaddingDistractor, done;
	StimDesc stimDesc;
	
    trial = *pTrial;                        // save for tallyStimuli
	attendLoc = trial.attendLoc;
	stimListLength = trial.numStim;
	instructTrial = trial.instructTrial;
    
	stimRateHz = 1000.0 / ([[task defaults] integerForKey:VCANStimDurationMSKey] + 
					[[task defaults] integerForKey:VCANInterstimMSKey]);

// To make our list, we will first build it up to targetIndex, and then add back padding
// characters.  However, targetIndex may be beyond stimListLength.  If that happens, 
// set targetIndex to stimListLength so we can use it as a limit in either case.

	for (stim = 0; stim < kStimLocs; stim++) {
		targetIndices[stim] = trial.targetIndices[stim];
		if (stim == attendLoc) {
			targetIndex =  targetIndices[stim];
		}
	}
    if (trial.catchTrial) {
        NSLog(@" Catch Trial: numStim %ld, targetIndex %ld", stimListLength, targetIndex);
        NSLog(@" Target Indices: %ld, %ld %ld %ld", targetIndices[kGabor0], targetIndices[kGabor1], 
              targetIndices[kGaborFar0], targetIndices[kGaborFar1]);
    }
	
// frontPadStim are stimuli at the beginning of the sequence that are not counted
// This serves to eliminate response transients at the start of the sequence.  
// There is always at least one padding stimulus, so that a non-zero contrast
// starting stimulus can be a reference if the target is to come in the second
// position

	frontPadStim = MAX(1, MIN(targetIndex, ceil([[task defaults] integerForKey:VCANStimLeadMSKey] 
                                                / 1000.0 * stimRateHz)));

/*
If distractors are going to appear after the front padding stimuli and before the target stimulus, then they will appear
among valid stimuli.  We have to make sure that the presentation of a distractor is not counted as a valid stimulus.  
The easiest way to do that is to shorten the stimListLength by the number of distractors, and then inserting the (extra)
distractor stimuli after the list has been made.  In this way we make sure that we  don't invalidate one of the stimulus
presentation that should be valid.  For each distractor, we shorten the list by one entry.  Additionally, when a 
distractor will not be followed by another distractor or the target, we need to reduce the list by another count, 
because that distractor will need a padding stimulus put in after it so that the subsequent valid stimuli is not 
preceded by a distractor. A final complication is that two distractors might occur on the same stimulus presentation, 
and we need to make sure that they can do this peacefully.  To do this properly, we record the indices for the 
locations that will have one or more distractors.
*/

    frontPaddingDistractor = NO;
    for (stim = distractorSets = 0; stim < kStimLocs; stim++) {
        if (stim == trial.attendLoc) {              // don't treat target as a distractor
            continue;
        }
        if (targetIndices[stim] >= frontPadStim && targetIndices[stim] < targetIndex && 
                                        targetIndices[stim] < trial.numStim) { // only distractors among valids
            distractorIndices[distractorSets++] = targetIndices[stim];
        }
        frontPaddingDistractor |= (targetIndices[stim] == frontPadStim - 1);
    }
    if (distractorSets > 1) {                                   // multiple distractors among the valid stimuli
 
        done = NO;
        do {
            for (d = 1; d < distractorSets; d++) {                  // put them into order
                if (distractorIndices[d] < distractorIndices[d - 1]) {
                    t = distractorIndices[d];
                    distractorIndices[d] = distractorIndices[d - 1];
                    distractorIndices[d - 1] = t;
                    break;                                          // start over
                }
                done = (d == distractorSets -1);                    // done if we passed through the whole list
            }
        } while (!done);
        
        done = NO;
        do {
            for (d = 0; d < distractorSets - 1; d++) {              // eliminate duplicates
                if (distractorIndices[d] == distractorIndices[d + 1]) {
                    for (e = d + 1; e < distractorSets; e++) {
                        distractorIndices[e - 1] = distractorIndices[e];
                    }
                    done = (--distractorSets == 1);                 // done if only one set remains
                    break;                                          // start over;
                }
                done = (d == distractorSets - 2);                   // done if no duplicates exists
            }
        } while (!done);
    }
    for (s = 0; s < distractorSets; s++) {          // remove one valid stimulus for every distractor among valids,
        stimListLength--;                           //  and a second if the distractor is followed by a valid stimulus.
        targetIndex--;
        if (distractorIndices[s] < trial.numStim - 1 &&
                                        targetIndices[kGabor0] != distractorIndices[s] + 1 && 
                                        targetIndices[kGabor1] != distractorIndices[s] + 1 &&
                                        targetIndices[kGaborFar0] != distractorIndices[s] + 1 &&
                                        targetIndices[kGaborFar1] != distractorIndices[s] + 1) {
            stimListLength--;
            targetIndex--;
        }
        if (distractorIndices[s] == frontPadStim) { // if the first thing after front padding is a distractor, we don't
            frontPaddingDistractor = NO;            // need to do anything about a distractor at the end of the padding.
        }
    }
    if (frontPaddingDistractor) {
        stimListLength--;                           // remove one stim for a distractor at the end of front padding.
        targetIndex--;
    }
    
// Count the number of uncompleted conditions in the done table
	
	for (s = 0, minStimDone = LONG_MAX; s < kStimPerState; s++) {	// copy doneTable, get minimum
        selectTable[s] = stimDone[trial.attendState][s];
        minStimDone = MIN(minStimDone, selectTable[s]);
	}
	for (s = remaining = 0; s < kStimPerState; s++) {				// count number remaining in table
        selectTable[s] -= minStimDone;
        remaining += (selectTable[s] == 0) ? 1 : 0;
	}
		
// The start of the list must begin with the number of requested padding stimuli.  These are 
// simply taken at random from all stimuli.  The very first stimulus in the sequence is always a padding stimulus, 
// and we make sure it is visible.  The final front padding stimulus is handled below, so that it is an appropriate
// stimulus to precede the first valid stimuls

	[stimList removeAllObjects];									// clear the stimList in prep for loading

    for (t = 0; t < kStimLocs; t++) {                               // all stim types are kFrontPadding
        listTypes[t] = kFrontPadding;
    }
	for (stim = 0; stim < frontPadStim - 1; stim++) {
		[self insertStimSettingsAtIndex:-1 trial:pTrial listTypes:listTypes stimTypes:[self randomVisibleIndices]];
	}
    
// Do the final front padding stimulus.  Set it to be the appropriate receptive field stimuli to precede the first valid
// stimulus.
    
    if (++stim == targetIndex) {                                 // no valid stimuli coming, use random
		[self insertStimSettingsAtIndex:-1 trial:pTrial listTypes:listTypes stimTypes:[self randomVisibleIndices]];
	}
    else {                                                      // insert correct preceding stimulus for first valid
        for (s = 0; s < kStimPerState; s++) {
            if (selectTable[s] == 0) {
                break;
            }
        }
        s = (s == 0) ? kStimPerState - 1 : s - 1;
        [self insertStimSettingsAtIndex:-1 trial:pTrial listTypes:listTypes stimTypes:[self expandStimType:s]];
    }
    
// The following entries in the stim list will be valid stimuli, up until the targetIndex (for now).
	
	for (t = 0; t < kStimLocs; t++) {
		listTypes[t] = kValidStim;
	}
	
// If there are fewer than the number of stim we need remaining in the current doneTable,
// pick up all that are there, clearing the table as we go.

    limitStim = MIN(targetIndex, stimListLength);
	if (remaining < limitStim - (NSInteger)[stimList count]) { // need all remaining in block?
		for (s = 0; s < kStimPerState; s++) {
            if (selectTable[s] == 0) {
                [self insertStimSettingsAtIndex:-1 trial:pTrial listTypes:listTypes stimTypes:[self expandStimType:s]];
            }
            else {
                selectTable[s] = 0;                                 // clear out table so it's ready to use
            }
		}
	}	
		
// For long trials, we might need more than a complete doneTable's worth of stimuli.  If that is the case, keep 
// grabbing full image set until we need less than a full table.  We always start from stim 0, because to do this
// snippet we will have always done the previous snippet and cleared out any partial lists. 

	while (limitStim - (NSInteger)[stimList count] > kStimPerState) {
		for (s = 0; s < kStimPerState; s++) {
            [self insertStimSettingsAtIndex:-1 trial:pTrial listTypes:listTypes stimTypes:[self expandStimType:s]];
		}
	}

// At this point there are enough available entries in selectTable to fill the rest of the stimList.  Note that we might
// get here for long lists, that will have done the snippets above, or we might start here if the number needed is 
// smaller than the number remaining in the list.  For that reason, we need to make sure the stimuli have not been done
// yet.
	
    for (s = 0; (NSInteger)[stimList count] < limitStim; s++) {
        if (selectTable[s] == 0) {
            [self insertStimSettingsAtIndex:-1 trial:pTrial listTypes:listTypes stimTypes:[self expandStimType:s]];
            selectTable[s]++;
        }
	}
	
// If this is not a catch trial, load the target stimulus, using a randomly selected base

	if (!trial.catchTrial && targetIndex < stimListLength) {	
		for (stim = 0; stim < kStimLocs; stim++) {
			listTypes[stim] = (stim == attendLoc) ? kTargetStim : kPadding;
		}
		[self insertStimSettingsAtIndex:-1 trial:pTrial listTypes:listTypes stimTypes:[self randomVisibleIndices]];
	}
	
// Load the trailing stimuli.  These are just pulled at random and not tallied or shuffled.

    for (t = 0; t < kStimLocs; t++) {
        if ([[task defaults] boolForKey:VCANTrainingModeKey] && t == attendLoc) {
            listTypes[t] = kTargetStim;
        }
        else {
            listTypes[t] = kBackPadding;
        }
    }
    while ((NSInteger)[stimList count] < stimListLength) {
        [self insertStimSettingsAtIndex:-1 trial:pTrial listTypes:listTypes stimTypes:[self randomStimIndices]];
    }
    
/*
If distractor stimuli are going to appear after the front padding stimuli and before the target stimulus, then they will
appear among valid stimuli.  We have to make sure that the presentation of the distractor is not counted as a valid 
stimulus.  To do this, we shortened the stimListLength by the number of distrators (above).  Now that the list has been
made, we need to insert any (extra) distractors.  In this way we make sure that we don't invalidate one of the stimulus
presentation that should be valid.

If a distractor is among the front padding stimuli, or at or beyond the target, we will simply set the unattended 
location stimulus type to a target.  Things are more complicated if a distractor appears after the front padding
stimuli, but before the target.  In that case, we will have artificially dropped one stimulus from the list before it 
was created (above).  We now insert a distractor stimulus in the correct place, and shove all the remaining stimuli 
back one position, restoring the list to its proper length.
 
A further complication is that we can't have a distractor appear immediately before a valid stimulus, because we need to
make sure that every valid stimulus is preceded by a particular stimulus.  When a distractor would appear immediately
before a valid stimulus, we insert an invalid stimulus of the correct sort.  In anticipation of this, we removed two
stimuli from the list whenever this would occur.
*/
	
    for (t = 0; t < kStimLocs; t++) {                   // load padding stimulus type for now, we'll set kTargets later
        listTypes[t] = kPadding;
    }
    if (frontPaddingDistractor) {
		[[stimList objectAtIndex:frontPadStim] getValue:&stimDesc];  // get the stimulus that follows front padding
//       s = stimDesc.stimTypes[kGabor0] * kRFStimTypes + stimDesc.stimTypes[kGabor1];
        s = [self indexForStimTypes:stimDesc];
        s = (s == 0) ? kStimPerState - 1 : s - 1;
        [self insertStimSettingsAtIndex:frontPadStim trial:pTrial listTypes:listTypes 
                              stimTypes:[self expandStimType:s]];
    }
    for (stim = 0; stim < distractorSets; stim++) {     // insert a distractor stimulus set
        [self insertStimSettingsAtIndex:distractorIndices[stim] trial:pTrial listTypes:listTypes
                              stimTypes:[self randomVisibleIndices]];
        if (distractorIndices[stim] + 1 >= trial.numStim ||             // followed by another distractor or target?   
                        distractorIndices[stim] + 1 == targetIndices[kGabor0] || 
                        distractorIndices[stim] + 1 == targetIndices[kGabor1] ||
                        distractorIndices[stim] + 1 == targetIndices[kGaborFar0] ||
                        distractorIndices[stim] + 1 == targetIndices[kGaborFar1]) {
            continue;                                                   // if so, do no more
        }
        if (distractorIndices[stim] + 1 == [stimList count]) {          // at end of list -- following will be padding
            s = (rand() % kRFStimTypes) * kRFStimTypes;
        }
        else {
            [[stimList objectAtIndex:distractorIndices[stim] + 1] getValue:&stimDesc];  // get the stimulus that follows
//           s = stimDesc.stimTypes[kGabor0] * kRFStimTypes + stimDesc.stimTypes[kGabor1];
            s = [self indexForStimTypes:stimDesc];
            s = (s == 0) ? kStimPerState - 1 : s - 1;
        }
        [self insertStimSettingsAtIndex:(distractorIndices[stim] + 1) trial:pTrial listTypes:listTypes 
                              stimTypes:[self expandStimType:s]];       // load a padding stimulus of correct type
   }
    
// Now that the list is back to its proper length, we can mark distractors in the list (target is already marked)

	for (stim = 0; stim < kStimLocs; stim++) {
        if (stim == trial.attendLoc || targetIndices[stim] >= trial.numStim) {
            continue;
        }
        [[stimList objectAtIndex:targetIndices[stim]] getValue:&stimDesc];  // extract the StimDesc
        stimDesc.listTypes[stim] = kTargetStim;    // flag the target
        [stimList replaceObjectAtIndex:targetIndices[stim] 
                            withObject:[NSValue valueWithBytes:&stimDesc objCType:@encode(StimDesc)]];
    }
		
// Now the list is complete.  We make a pass through the list loading the stimulus presention frames and the stimulus 
// directions.  At the same time, for instruction trials we set all the distractor stimulus types to kNull, so nothing 
// will appear there. 

	frameRateHz = [[task stimWindow] frameRateHz];
	stimDurFrames = [[task defaults] integerForKey:VCANStimDurationMSKey] / 
					1000.0 * frameRateHz;
	stimJitterPC = [[task defaults] integerForKey:VCANStimJitterPCKey];
	stimJitterFrames = stimDurFrames / 100.0 * stimJitterPC;
	stimDurBase = stimDurFrames - stimJitterFrames;
	interDurFrames = [[task defaults] integerForKey:VCANInterstimMSKey] / 1000.0 * frameRateHz;
	interJitterTauMS = [[task defaults] integerForKey:VCANInterstimJitterTauMSKey];
	
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
        for (stimIndex = 0; stimIndex < kStimLocs; stimIndex++) {
            // If there is a target or distractor, the interstim interval is random
            nextStimOnFrame = -1;
            if (stimDesc.listTypes[stimIndex] == kTargetStim) {
                nextStimOnFrame = stimDesc.stimOffFrame + [self jitteredInterstimFrames];
                break;
            }
            // If this is a valid stimulus, then use the fixed interstimulus interval
            if (nextStimOnFrame == -1) {
                nextStimOnFrame = stimDesc.stimOffFrame + interstimFrames[[self indexForStimTypes:stimDesc]];
            }
        }
        
//		if (interJitterTauMS > 0) {
//            interJitterFrames = -interJitterTauMS * log(1.0 - ((rand() % 10000) / 10000.0)) / 1000.0 * frameRateHz;
//			nextStimOnFrame += MIN(frameRateHz , interJitterFrames); // limit to 1 sec
//		}

// Fix instruction trials

		if (instructTrial) {
			for (s = 0; s < kStimLocs; s++) {
				if (s != attendLoc) {
					stimDesc.listTypes[s] = kNilStim;
				}
			}
		}
        
// Set the stimulus directions.  The target directions will be handled when the stimuli are presented
        
        for (s = 0; s < kStimLocs; s++)  {
            switch (stimDesc.stimTypes[s]) {
                case kPrefStim:
                case kNoStim:
                    stimDesc.directionsDeg[s] = [[task defaults] floatForKey:VCANDirectionDegKey];
                    break;
                case kInter0Stim:
                    stimDesc.directionsDeg[s] = [[task defaults] floatForKey:VCANDirectionDegKey] + 45.0;
                   break;
                case kNullStim:
                    stimDesc.directionsDeg[s] = [[task defaults] floatForKey:VCANDirectionDegKey] + 90.0;
                   break;
                case kInter1Stim:
                    stimDesc.directionsDeg[s] = [[task defaults] floatForKey:VCANDirectionDegKey] + 135.0;
                    break;
                default:
                    [NSException raise:@"makeStimList:" format:@"Could find type of stimulus"];
                    break;
            }
            stimDesc.directionsDeg[s] += (stimDesc.directionsDeg[s] > 0.0) ? 0.0 : 360.0;
            stimDesc.directionsDeg[s] -= (stimDesc.directionsDeg[s] < 360.0) ? 0.0 : 360.0;
            if (stimDesc.listTypes[s] == kTargetStim) {
                stimDesc.centerContrast[s] = MAX(0.0, stimDesc.contrasts[s] - trial.targetContrastChangePC[s] / 100);
            }
            else {
                stimDesc.centerContrast[s] = stimDesc.contrasts[s];
            }
        }
		[stimList replaceObjectAtIndex:stim withObject:[NSValue valueWithBytes:&stimDesc objCType:@encode(StimDesc)]];
	}
    //    [self dumpStimList];
}

- (LLIntervalMonitor *)monitor {

	return monitor;
}

- (void)presentStimList;
{
    long trialFrame, gaborFrame, stimIndex, g, loc;
    BOOL trainingMode, stimulusVisible;
	StimDesc stimDesc;
    NSPoint aziEleDeg;
    NSAutoreleasePool *threadPool;
    NSColor *targetColor = [[targetSpot foreColor]retain];

    threadPool = [[NSAutoreleasePool alloc] init];		// create a threadPool for this thread
	[LLSystemUtil setThreadPriorityPeriodMS:1.0 computationFraction:0.250 constraintFraction:1.0];
	[monitor reset];
	for (loc = 0; loc < kStimLocs; loc++) {
		activeTargets[loc] = NO;
	}
	
// Set up the stimulus calibration, including the offset then present the stimulus sequence

	[[task stimWindow] lock];
	[[task stimWindow] setScaleOffsetDeg:[[task eyeCalibrator] offsetDeg]];
	[[task stimWindow] scaleDisplay];

// Set up the gabors

	for (g = 0; g < kStimLocs; g++) {
		[gabors[g] setSpatialFreqCPD:[[task defaults] floatForKey:VCANSpatialFreqCPDKey]];
        [gabors[g] setSpatialPhaseDeg:0.0];
		[gabors[g] setTemporalFreqHz:0.0];
        [gabors[g] setTemporalPhaseDeg:0.0];						// same odd phase
		[gabors[g] setRadiusDeg:[[task defaults] floatForKey:VCANRadiusDegKey]];
		[gabors[g] setSigmaDeg:[[task defaults] floatForKey:VCANSigmaDegKey]];
		[targetGabors[g] setSpatialFreqCPD:[[task defaults] floatForKey:VCANSpatialFreqCPDKey]];
        [targetGabors[g] setSpatialPhaseDeg:0.0];
		[targetGabors[g] setTemporalFreqHz:0.0];
        [targetGabors[g] setTemporalPhaseDeg:0.0];						// same odd phase
        
        // Set the radius of the target equal to the sigma of the gabor
        
		[targetGabors[g] setRadiusDeg:[[task defaults] floatForKey:VCANSigmaDegKey]];
		[targetGabors[g] setSigmaDeg:[[task defaults] floatForKey:VCANSigmaDegKey]];
	}
	stimIndex = 0;
	[[stimList objectAtIndex:stimIndex] getValue:&stimDesc];
	[self loadGaborsWithStimDesc:&stimDesc];
    [targetSpot setState:YES];

    trainingMode = [[task defaults] boolForKey:VCANTrainingModeKey];
    for (trialFrame = gaborFrame = 0; !abortStimuli; trialFrame++) {
		glClear(GL_COLOR_BUFFER_BIT);
		if (trialFrame >= stimDesc.stimOnFrame && trialFrame <= stimDesc.stimOffFrame) {
			if (trialFrame < stimDesc.stimOffFrame || [[task defaults] boolForKey:VCANTrainingModeKey]) {
				for (g = 0; g < kStimLocs; g++) {
					[gabors[g] setFrame:[NSNumber numberWithLong:gaborFrame]];	// advance for temporal modulation
					[gabors[g] draw];
                    if (!trainingMode) {
                        if (stimDesc.listTypes[g] == kTargetStim) {
                            [targetGabors[g] setFrame:[NSNumber numberWithLong:gaborFrame]];
                            [targetGabors[g] draw];
                        }
                    }
                    else {
                        
                        if (g == trial.attendLoc && (stimDesc.listTypes[g] == kTargetStim || targetPresented)) {
                            aziEleDeg = azimuthAndElevationForStimLoc(g, trial.attendState);
                            [targetSpot setAzimuthDeg:aziEleDeg.x elevationDeg:aziEleDeg.y];
                            [targetSpot setForeColor:[targetColor colorWithAlphaComponent:1]];
                            [targetSpot draw];
                        }
                        else if (g != trial.attendLoc && (stimDesc.listTypes[g] == kTargetStim)) {
                            aziEleDeg = azimuthAndElevationForStimLoc(g, trial.attendState);
                            [targetSpot setAzimuthDeg:aziEleDeg.x elevationDeg:aziEleDeg.y];
                            [targetSpot setForeColor:[targetColor colorWithAlphaComponent:trial.targetContrastChangePC[trial.attendLoc]/100]];
                            [targetSpot draw];
                        }
                    }
				}
				gaborFrame++;
			}
		}
		[cueSpot draw];
		[fixSpot draw];
		[[NSOpenGLContext currentContext] flushBuffer];
		glFinish();
		[monitor recordEvent];

		if (trialFrame == stimDesc.stimOnFrame) {
			[[task dataDoc] putEvent:@"stimulus" withData:&stimDesc];
			[[task dataDoc] putEvent:@"stimulusOn" withData:&trialFrame];
			[digitalOut outputEvent:kStimulusOnCode withData:stimIndex];
            stimulusVisible = YES;

			if (stimDesc.listTypes[stimDesc.attendLoc] == kTargetStim) {
				targetPresented = YES;
				[digitalOut outputEvent:kTargetOnCode withData:stimIndex];
			}
			for (loc = 0; loc < kStimLocs; loc++) {
				activeTargets[loc] = (stimDesc.listTypes[loc] == kTargetStim);
			}
		}
		else if (trialFrame == stimDesc.stimOffFrame) {
			[[task dataDoc] putEvent:@"stimulusOff" withData:&trialFrame];
			[digitalOut outputEvent:kStimulusOffCode withData:stimIndex];
            stimulusVisible = NO;
			
			if (++stimIndex >= (NSInteger)[stimList count]) {
				break;
			}
			[[stimList objectAtIndex:stimIndex] getValue:&stimDesc];
			[self loadGaborsWithStimDesc:&stimDesc];
			if (![[task defaults] boolForKey:VCANTrainingModeKey]) {
				gaborFrame = 0;
			}
		}
        
        else if (trialFrame > stimDesc.stimOnFrame && trialFrame < stimDesc.stimOffFrame) {
			[[task dataDoc] putEvent:@"frameCheck" withData:&trialFrame];
        }
    }

// Clear the display and leave the back buffer cleared

    glClear(GL_COLOR_BUFFER_BIT);
    [[NSOpenGLContext currentContext] flushBuffer];
	glFinish();
    
    if (stimulusVisible) {
        [[task dataDoc] putEvent:@"stimulusOff" withData:&trialFrame];
        [digitalOut outputEvent:kStimulusOffCode withData:stimIndex];
        stimulusVisible = NO;
    }

	[[task stimWindow] unlock];
	
// The temporal counterphase might have changed some settings.  We restore these here.

    [targetSpot setState:NO];
	stimulusOn = abortStimuli = NO;
	for (loc = 0; loc < kStimLocs; loc++) {
		activeTargets[loc] = NO;
	}
    [targetColor release];
    [threadPool release];
}

// Return a random stimulus types that will all be visible

- (short *)randomStimIndices;
{
	static short indices[kStimLocs];
	
    indices[kGabor0] = (rand() % kRFStimTypes);
    indices[kGabor1] = (rand() % kRFStimTypes);
    if (indices[kGabor0] == indices[kGabor1] && indices[kGabor0] != kNoStim) {
        indices[kGabor0] = ((indices[kGabor0] + 1) % kRFStimTypes);
    }
    indices[kGaborFar0] = (rand() % kRFStimTypes);
    if (indices[kGaborFar0] != kNoStim) {
        indices[kGaborFar0] += kInter0Stim - 1;
    }
    indices[kGaborFar1] = (rand() % kRFStimTypes);
    if (indices[kGaborFar1] != kNoStim) {
        indices[kGaborFar1] += kInter0Stim - 1;
    }
	return indices;
}

// Return a random stimulus types that will all be visible

- (short *)randomVisibleIndices;
{
	static short indices[kStimLocs];
	
//    indices[kGabor0] = kNullStim + (rand() % 2);
//    indices[kGabor1] = kNullStim + (rand() % 2);
//    indices[kGaborFar0] = kInter0Stim + (rand() % 2);
//    indices[kGaborFar1] = kInter0Stim + (rand() % 2);
    indices[kGabor0] = indices[kGaborFar0] = kNullStim + (rand() % 2);
    indices[kGabor1] = indices[kGaborFar1] = kNullStim + (rand() % 2);
	return indices;
}

- (void)setCueSpot:(BOOL)state location:(long)loc;
{
	NSPoint aziEle;
	
	[cueSpot setState:state];
	aziEle = azimuthAndElevationForStimLoc(loc, trial.attendState);
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
		[digitalOut outputEvent:((state) ? kCueOnCode : kCueOffCode) withData:loc];
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

// Pick a new stimulus sequence.  The order is random, except we do not want two successive blank stimuli in either
// location.  Blanks in location 0 are values 0, 1, and 2;  Blanks in location 1 are values 0, 3, and 6.  No two
// elements in either sequence can be successive in the sequence, including wraps.  After scrambling, we simply
// check whether that has happened and try again if it has.

- (void)shuffleStimSequence;
{
    BOOL successiveBlanks;
    long index, selected;
    long orderedSequence[kStimPerState];
    long tryCounter = 0;
    
    do {
        for (index = 0; index < kStimPerState; index++) {   // must reload each pass through the loop
            orderedSequence[index] = index;
        }
        for (index = 0; index < kStimPerState; index++) {   // set stimSequence into a random order
            selected = (rand() % (kStimPerState - index));
            stimSequence[index] = orderedSequence[selected];
            for ( ; selected < kStimPerState - index - 1; selected++) {
                orderedSequence[selected] = orderedSequence[selected + 1];
            }
        }
        successiveBlanks = NO;
        for (index = 0; index < kStimPerState; index++) {
            if (stimSequence[index] / 3 == 0) {            // location 0 is blank
                if (stimSequence[(index + 1) % kStimPerState] / 3 == 0) {
                    successiveBlanks = YES;
                   break;
                }
            }
            if (stimSequence[index] % 3 == 0) {            // location 1 is blank
                if ((stimSequence[(index + 1) % kStimPerState] % 3) == 0) {
                    successiveBlanks = YES;
                   break;
                }
            }
        }
        tryCounter++;
    } while (successiveBlanks);
    NSLog(@"Final Sequence: %ld %ld %ld %ld %ld %ld %ld %ld %ld (%ld tries)",
          stimSequence[0], stimSequence[1], stimSequence[2], stimSequence[3], stimSequence[4],
          stimSequence[5], stimSequence[6], stimSequence[7], stimSequence[8], tryCounter);
    for (index = 0; index < kStimPerState; index++) {
        interstimFrames[index] = [self jitteredInterstimFrames];
        NSLog(@" interstim %ld is %ld", index, interstimFrames[index]);
    }
}

- (void)startStimList;
{
	if (stimulusOn) {
		return;
	}
    [self dumpStimSequence];
	stimulusOn = YES;
	targetPresented = NO;
   [NSThread detachNewThreadSelector:@selector(presentStimList) toTarget:self withObject:nil];
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
		while (stimulusOn) {
            [NSThread sleepForTimeInterval:(NSTimeInterval)0.005];
        };
	}
	else {
		[stimuli setFixSpot:NO];
		[self erase];
	}
}

// Count the stimuli in the StimList as successfully completed

- (void)tallyStimuli;
{
	long validCount, index;
	StimDesc stimDesc;
	short t;
	BOOL valid;
	
	for (index = validCount = 0; index < (NSInteger)[stimList count]; index++) {
		[[stimList objectAtIndex:index] getValue:&stimDesc];
		for (t = 0, valid = YES; t < kStimLocs; t++) {
			valid = (stimDesc.listTypes[t] == kValidStim) ? valid : NO;
		}
		if (valid) {
			stimDone[stimDesc.attendState][[self indexForStimTypes:stimDesc]]++;
			validCount++;
		}
	}
    [diagnosticsController addStimList:stimList trialDesc:trial];
}

- (LLGabor *)targetGabor;
{
	return targetGabors[kGabor0];
}


- (BOOL)targetPresented;
{
	return targetPresented;
}


// Set high contrast cue at the attended location and low contrast cues at distractor locations if wrong or distracted (see VCANEndTrialState for the exact conditions for invoking this method)

- (void)setCueAfterError;
{
    long loc;
    NSPoint aziEle;
    NSColor *cueColor = [[cueSpot foreColor]retain];
    
    glClear(GL_COLOR_BUFFER_BIT);
    for(loc = 0; loc<kStimLocs; loc++) {
        if (loc != trial.attendLoc) {
            [cueSpot setForeColor:[cueColor colorWithAlphaComponent:0.15]];
        }
        else {
            [cueSpot setForeColor:[cueColor colorWithAlphaComponent:1]];
        }
        [cueSpot setState:YES];
        aziEle = azimuthAndElevationForStimLoc(loc, trial.attendState);
        
        [cueSpot setAzimuthDeg:aziEle.x elevationDeg: aziEle.y];
        				
        if (!stimulusOn) {
            [[task stimWindow] lock];
            [[task stimWindow] setScaleOffsetDeg:[[task eyeCalibrator] offsetDeg]];
            [[task stimWindow] scaleDisplay];
            [cueSpot draw];
            [digitalOut outputEvent:((YES) ? kCueOnCode : kCueOffCode) withData:loc];
            [[task stimWindow] unlock];
        }        
    }
    [[NSOpenGLContext currentContext] flushBuffer];
    [cueColor release];
}


@end
