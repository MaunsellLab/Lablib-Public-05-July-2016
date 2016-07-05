//
//  VIPsychController.m
//  VICAN
//
//  Window with summary information about behavioral performance.
//
//  Copyright (c) 2013. All rights reserved.
//

#define NoGlobals

#import "VI.h"
#import "VIPsychController.h"

#define kMarginPix			10
#define kPlotBinsDefault	10
#define kPlotHeightPix		250
#define kPlots				3
#define kPlotWidthPix		250
#define kViewWidthPix		(kPlots * (kPlotWidthPix) + (kPlots + 1) * kMarginPix)
#define	kXTickSpacing		100

#define kContentWidthPix	(kNumPlots * kPlotWidthPix + (kNumPlots + 1) * kMarginPix)
#define kContentHeightPix	(2 * kPlotHeightPix + 3 * kMarginPix)

@implementation VIPsychController

- (void)changeResponseTimeMS;
{
    long index, base, labelSpacing;
    long factors[] = {1, 2, 5};
 
// Find the appropriate spacing for x axis labels

	index = 0;
	base = 1;
    while ((responseTimeMS / kXTickSpacing) / (base * factors[index]) > 2) {
        index = (index + 1) % (sizeof(factors) / sizeof(long));
        if (index == 0) {
            base *= 10;
        }
    }
    labelSpacing = base * factors[index];

}

- (void)checkParams;
{
	long index, p;
	BlockStatus *pCurrent, *pLast;
	BOOL dirty = NO;
	
	pCurrent = &blockStatus;
	pLast = &lastBlockStatus;
	
	if (pCurrent->numChanges == 0) {								// not initialized yet
		return;
	}
	if (pCurrent->numChanges != pLast->numChanges) {
		dirty = YES;
		pLast->numChanges = pCurrent->numChanges;
	}
	for (index = 0; index < pCurrent->numChanges; index++) {
		if (pCurrent->changes[index] != pLast->changes[index]) {
			dirty = YES;
			pLast->changes[index] = pCurrent->changes[index];
		}
//		if (pCurrent->validReps[index] != pLast->validReps[index]) {
//			dirty = YES;
//			pLast->validReps[index] = pCurrent->validReps[index];
//		}
	}
	if (!dirty) {
		return;
	}
	[self makeLabels];
	for (p = 0; p < kNumPlots; p++) {
		[reactPlot[p] setPoints:pCurrent->numChanges];
		[perfPlot[p] setPoints:pCurrent->numChanges];
	}

// If settings have changed (number of stimulus levels, type of stim, etc.  we reset and redraw

	[self reset:[NSData data] eventTime:[NSNumber numberWithLong:0L]]; 
}

- (void)checkTimeParams;
{
	if (maxTargetTimeMS != lastMaxTargetTimeMS || minTargetTimeMS != lastMinTargetTimeMS) {
		lastMaxTargetTimeMS = maxTargetTimeMS;
		lastMinTargetTimeMS = minTargetTimeMS;

// If settings have changed (number of stimulus levels, type of stim, etc.  we reset and redraw

		[self reset:[NSData data] eventTime:[NSNumber numberWithLong:0L]]; 
	}
}

- (void)dealloc;
{
    [labelArray release];
    [timeLabelArray release];
	[xAxisLabelArray release];
	[super dealloc];
}

- (id) init;
{
    if ((self = [super initWithWindowNibName:@"VIPsychController" defaults:[task defaults]]) != nil) {
		highlightedPointIndex = highlightedPlotIndex = -1;
        [self moreInitialization];
    }
    return self;
}

- (void)makeLabels;		// make X labels for contrast
{
    long index, levels;
	float stimValue;
	NSString *string;

	levels = blockStatus.numChanges;
    [labelArray removeAllObjects];
    [xAxisLabelArray removeAllObjects];
    for (index = 0; index < levels; index++) {
		stimValue = blockStatus.changes[index];
		string = [NSString stringWithFormat:@"%.*f",  
					[LLTextUtil precisionForValue:stimValue significantDigits:2], stimValue];
		[labelArray addObject:string];
		if ((levels >= 6) && ((index % 2) == (levels % 2))) {
			[xAxisLabelArray addObject:@""];
		}
		else {
			[xAxisLabelArray addObject:string];
		}
    }
}

- (void) moreInitialization;
{
    long index, plot;
	LLViewScale	*rtScaling;
    
    [[self window] setFrameAutosaveName:[NSString stringWithFormat:@"VIPsychWindow"]];
	documentView = [scrollView documentView];
    labelArray = [[NSMutableArray alloc] init];
    timeLabelArray = [[NSMutableArray alloc] init];
    xAxisLabelArray = [[NSMutableArray alloc] init];
    [self makeLabels];
    highlightColor = [NSColor colorWithDeviceRed:0.85 green:0.85 blue:0.85 alpha:1.0];

// Initialize the reaction time plot

    rtScaling = [[[LLViewScale alloc] init] autorelease];
	for (plot = 0; plot < kNumPlots; plot++) {
		reactTimes[plot] = [[[NSMutableArray alloc] init] autorelease];
		reactTimesInvalidNear[plot] = [[[NSMutableArray alloc] init] autorelease];
		reactTimesInvalidFar[plot] = [[[NSMutableArray alloc] init] autorelease];
		for (index = 0; index < kMaxChanges; index++) {
			[reactTimes[plot] addObject:[[[LLNormDist alloc] init] autorelease]];
			[reactTimesInvalidNear[plot] addObject:[[[LLNormDist alloc] init] autorelease]];
			[reactTimesInvalidFar[plot] addObject:[[[LLNormDist alloc] init] autorelease]];
		}
		reactPlot[plot] = [[[LLPlotView alloc]
                            initWithFrame:NSMakeRect(kMarginPix + plot * (kPlotWidthPix + kMarginPix), kMarginPix, kPlotWidthPix, kPlotHeightPix)
                            scaling:rtScaling] autorelease];
		[reactPlot[plot] addPlot:reactTimes[plot] plotColor:[NSColor greenColor]];
		[reactPlot[plot] addPlot:reactTimesInvalidNear[plot] plotColor:[NSColor redColor]];
		[reactPlot[plot] addPlot:reactTimesInvalidFar[plot] plotColor:[NSColor blueColor]];
		[reactPlot[plot] setXAxisLabel:@"Alpha Change"];
		[reactPlot[plot] setXAxisTickLabels:xAxisLabelArray];
		[reactPlot[plot] setHighlightXRangeColor:highlightColor];
		[documentView addSubview:reactPlot[plot]];
	}
    [reactPlot[kStimLocs] setTitle:@"Average"];
	
// Initialize the performance (by change value) plot.  We set the color for kEOTFail to clear, because we don't 
// want to see those values.  They are mirror image to the correct data

	for (plot = 0; plot < kNumPlots; plot++) {
		perfValid[plot] = [[[NSMutableArray alloc] init] autorelease];
		perfInvalidNear[plot] = [[[NSMutableArray alloc] init] autorelease];
		perfInvalidFar[plot] = [[[NSMutableArray alloc] init] autorelease];
        for (index = 0; index < kMaxChanges; index++) {
            [perfValid[plot] addObject:[[[LLBinomDist alloc] init] autorelease]];
            [perfInvalidNear[plot] addObject:[[[LLBinomDist alloc] init] autorelease]];
            [perfInvalidFar[plot] addObject:[[[LLBinomDist alloc] init] autorelease]];
        }
 		perfPlot[plot] = [[[LLPlotView alloc]
                           initWithFrame:NSMakeRect(kMarginPix + plot * (kPlotWidthPix + kMarginPix), kPlotHeightPix + 2 * kMarginPix, kPlotWidthPix, kPlotHeightPix)]
                          autorelease];
        [perfPlot[plot] addPlot:perfValid[plot] plotColor:[NSColor greenColor]];
        [perfPlot[plot] addPlot:perfInvalidNear[plot] plotColor:[NSColor redColor]];
        [perfPlot[plot] addPlot:perfInvalidFar[plot] plotColor:[NSColor blueColor]];
		[perfPlot[plot] setXAxisLabel:@"Alpha Change"];
		[perfPlot[plot] setXAxisTickLabels:xAxisLabelArray];
		[[perfPlot[plot] scale] setAutoAdjustYMax:NO];
		[[perfPlot[plot] scale] setHeight:1];
		[perfPlot[plot] setHighlightXRangeColor:highlightColor];
		[documentView addSubview:perfPlot[plot]];
	}
    [perfPlot[kStimLocs] setTitle:@"Average"];

    highlightedPointIndex = -1;

    [[zoomButton cell] setBordered:NO];
    [[zoomButton cell] setBezeled:YES];
    [[zoomButton cell] setFont:[NSFont labelFontOfSize:10.0]];

    [self checkParams];
	[self changeResponseTimeMS];
    [super windowDidLoad];
	[documentView setFrame:NSMakeRect(0, 0, kContentWidthPix, kContentHeightPix)];
	[super setBaseMaxContentSize:NSMakeSize(kContentWidthPix, kContentHeightPix)];
}

- (void)blockStatus:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[eventData getBytes:&blockStatus length:sizeof(BlockStatus)];
	[self checkParams];
}


- (void)maxTargetTimeMS:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&maxTargetTimeMS length:sizeof(long)];
	[self checkTimeParams];
}

- (void)minTargetTimeMS:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&minTargetTimeMS length:sizeof(long)];
	[self checkTimeParams];
}

- (void)saccade:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{    
    saccadeStartTimeMS = [eventTime unsignedLongValue];
}

- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    long plot;
    	
	for (plot = 0; plot < kNumPlots; plot++) {
		[reactTimes[plot] makeObjectsPerformSelector:@selector(clear)];
		[reactTimesInvalidNear[plot] makeObjectsPerformSelector:@selector(clear)];
		[reactTimesInvalidFar[plot] makeObjectsPerformSelector:@selector(clear)];
        [perfValid[plot] makeObjectsPerformSelector:@selector(clear)];
        [perfInvalidNear[plot] makeObjectsPerformSelector:@selector(clear)];
        [perfInvalidFar[plot] makeObjectsPerformSelector:@selector(clear)];
		[[reactPlot[plot] scale] setHeight:100];					// Reset scaling as well
	}
    [[[self window] contentView] setNeedsDisplay:YES];
}

- (void)responseTimeMS:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    long newResponseTimeMS;
    
    [eventData getBytes:&newResponseTimeMS length:sizeof(long)];
    if (responseTimeMS != newResponseTimeMS) {
        responseTimeMS = newResponseTimeMS;
        [self changeResponseTimeMS];
    }
}

- (void)stimulus:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	StimDesc stimDesc;
	
//	if (stimStartTimeMS == 0) {
//		stimStartTimeMS = [eventTime unsignedLongValue];
//	}
	[eventData getBytes:&stimDesc length:sizeof(StimDesc)];
//    if (targetOnTimeMS == 0) {
        if (stimDesc.listTypes[trial.targetPos] == kTargetStim) {
            targetOnTimeMS = [eventTime unsignedLongValue];
        }
//    }
}

- (void)taskMode:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    long p, taskMode;
    
	[eventData getBytes:&taskMode length:sizeof(long)];
    if (taskMode == kTaskIdle) {
		for (p = 0; p < kNumPlots; p++) {
			[reactPlot[p] setHighlightXRangeFrom:0 to:0];
			[perfPlot[p] setHighlightXRangeFrom:0 to:0];
		}
    }
}

// Called by the trial event, which occurs at the start of each trial

- (void)trial:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    // Clear any existing highlighting
	
	if (highlightedPlotIndex >= 0) {
		[perfPlot[highlightedPlotIndex] setHighlightXRangeFrom:0 to:0];
		[reactPlot[highlightedPlotIndex] setHighlightXRangeFrom:0 to:0];
		highlightedPlotIndex = -1;
	}
 
    // Decide whether we need to do anything
    
	[eventData getBytes:&trial length:sizeof(TrialDesc)];

    // Clear counter, but don't anything more on instruction trials
	
	saccadeStartTimeMS = stimStartTimeMS = targetOnTimeMS = 0;
	if (trial.instructTrial) {
		return;
	}

    highlightedPlotIndex = trial.targetPos; //(trial.validTrial) ? trial.targetPos : 1 - trial.targetPos;
	
    // Highlight the appropriate histogram and RT and performance plots
    
	if (trial.targetAlphaChangeIndex >= 0) {
		highlightedPointIndex = trial.targetAlphaChangeIndex;
		//[hist[highlightedPointIndex] setHighlightHist:YES];
		[perfPlot[highlightedPlotIndex] setHighlightXRangeFrom:highlightedPointIndex - 0.25 to:highlightedPointIndex + 0.25];
		[reactPlot[highlightedPlotIndex] setHighlightXRangeFrom:highlightedPointIndex - 0.25 to:highlightedPointIndex + 0.25];
	}
    
}

- (void)trialEnd:(NSData *)eventData eventTime:(NSNumber *)eventTime;
    {
//        long level, eot, loc, minN, reactTimeMS, eotCode, ignoredValue, wrongValue, brokeValue, timeIndex;
    long level, eotCode, ignoredValue, wrongValue, brokeValue, reactTimeMS, minN;
    long levels = blockStatus.numChanges;
        NSMutableArray **times[] = {reactTimes, reactTimesInvalidNear, reactTimesInvalidFar};
        NSMutableArray **t = times[trial.trialType];
        NSMutableArray **perf[] = {perfValid, perfInvalidNear, perfInvalidFar};
        NSMutableArray **p = perf[trial.trialType];

        // No update on instruction trials

	if (trial.instructTrial || trial.catchTrial) {
		return;
	}

    [eventData getBytes:&eotCode length:sizeof(long)];
        
    // Process reaction time on correct trials only

	if ((eotCode == kEOTCorrect) && !trial.catchTrial) {
		reactTimeMS = saccadeStartTimeMS - targetOnTimeMS;
		[[t[trial.targetPos] objectAtIndex:trial.targetAlphaChangeIndex] addValue:reactTimeMS];
		[[t[kStimLocs] objectAtIndex:trial.targetAlphaChangeIndex] addValue:reactTimeMS];
        
        if (trial.trialType == kTargetAttendLoc) { // invalids are usually restricted to a few alpha indices
            for (level = (levels > 1) ? 1 : 0, minN = LONG_MAX; level < levels; level++) {
                minN = MIN(minN, [[t[trial.targetPos] objectAtIndex:level] n]);
            }
            [reactPlot[trial.targetPos] setTitle:[NSString stringWithFormat:@"Reaction Times (n >= %ld)", minN]];
        }
		[reactPlot[trial.targetPos] setNeedsDisplay:YES];
		[reactPlot[kStimLocs] setNeedsDisplay:YES];
	}

    // For behavior as a function of orientation change, we increment the counts of different eots in a customized way.  
    // We want corrects and fails to add to 100%, because these are outcomes of completed trials.  Because they are
    // perfectly complementary, we only display the corrects.  Ignores, breaks and wrongs (early) are
    // computed to be percentages of all trials for orientation changes (but not for times because they occur before the
    // change value is known to the subject.   
	
	ignoredValue = wrongValue = brokeValue = 0;
    
    switch (eotCode) {
	case kEOTCorrect:
    case kEOTFailed:
            [[p[trial.targetPos] objectAtIndex:trial.targetAlphaChangeIndex] addValue:(eotCode == kEOTCorrect) ? 1 : 0];
            [[p[kStimLocs] objectAtIndex:trial.targetAlphaChangeIndex] addValue:(eotCode == kEOTCorrect) ? 1 : 0];
            
            if (trial.trialType == kTargetAttendLoc) { // invalids are usually restricted to a few alpha indices 
                for (level = (levels > 1) ? 1 : 0, minN = LONG_MAX; level < levels; level++) {
                    minN = MIN(minN, [[p[trial.targetPos] objectAtIndex:level] n]);
                }
                [perfPlot[trial.targetPos] setTitle:[NSString stringWithFormat:@"Location %ld (n >= %ld)", trial.targetPos, minN]];
            }
            [perfPlot[trial.targetPos] setNeedsDisplay:YES];
            [perfPlot[kStimLocs] setNeedsDisplay:YES];
		break;
	case kEOTBroke:
	case kEOTWrong:
	case kEOTIgnored:
	default:
		break;
	}
        [perfPlot[trial.targetPos] setNeedsDisplay:YES];
        [perfPlot[kStimLocs] setNeedsDisplay:YES];
}

@end
