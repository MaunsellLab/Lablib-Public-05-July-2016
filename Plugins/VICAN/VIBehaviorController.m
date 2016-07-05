//
//  VIBehaviorController.m
//  VICAN
//
//  Window with summary information about behavioral performance.
//
//  Copyright (c) 2012. All rights reserved.
//

#define NoGlobals

#import "VI.h"
#import "UtilityFunctions.h"
#import "VIBehaviorController.h"

#define kMarginPix			15
#define kMaxStim			12
#define kPlotHeightPix		250
#define kPlotPitchPix       (kPlotWidthPix + kMarginPix)
#define kPlotWidthPix		250

#define contentWidthPix		(kMarginPix + 2 * kPlotPitchPix)
#define contentHeightPix	(2 * kPlotHeightPix + 3 * kMarginPix)

@implementation VIBehaviorController

- (void)checkTimeParams;
{
    if ((long)(maxTargetMS / (stimDurationMS + interstimMS)) != maxTargetIndex) {
        maxTargetIndex = MIN(kMaxStim, maxTargetMS / (stimDurationMS + interstimMS));
        [perfTimePlot[kNoDistractorPlot] setPoints:maxTargetIndex];
        [perfTimePlot[kDistractorPlot] setPoints:maxTargetIndex];
		[self makeStimLabels];
		[self reset:[NSData data] eventTime:[NSNumber numberWithLong:0L]];
	}
}

- (void)dealloc;
{
    [stimLabelArray release];
	[super dealloc];
}

- (id)init;
{
	return [super initWithWindowNibName:@"VIBehaviorController" defaults:[task defaults]];
}

- (void)makeStimLabels;
{
    long index;
    
    [stimLabelArray removeAllObjects];
    for (index = 1; index < maxTargetIndex; index++) {
		if ((index % 2)) {
			[stimLabelArray addObject:@""];
		}
		else {
			[stimLabelArray addObject:[NSString stringWithFormat:@"%ld", index]];
		}
    }
    [stimLabelArray addObject:@"C"];
}

- (void) windowDidLoad;
{
	long state, index, p, plotIndex;
	NSView *documentView = [scrollView documentView];
	
    [super windowDidLoad];
    highlightColor = [NSColor colorWithDeviceRed:0.85 green:0.85 blue:0.85 alpha:1.0];
    stimLabelArray = [[NSMutableArray alloc] init];

	// Initialize the threshold plot.  
	
	thresholdPlot = [[[LLPlotView alloc] initWithFrame:NSMakeRect(kMarginPix, kPlotPitchPix,
                                            2 * kPlotWidthPix + kMarginPix, kPlotHeightPix)] autorelease];
	for (state = 0; state < kNumStates; state++) {
		thresholds[state] = [[[NSMutableArray alloc] init] autorelease];
		[thresholdPlot addPlot:thresholds[state] plotColor:stateColors[state]];
	}
	[thresholdPlot setXAxisLabel:@"Trials"];
	[[thresholdPlot scale] setAutoAdjustYMax:YES];
    [[thresholdPlot scale] setHeight:1];
	[thresholdPlot setPoints:0];
	[thresholdPlot setYAxisLabel:@"Contrast Change"];
	[documentView addSubview:thresholdPlot];

	
    // Initialize the performance-by-time plot.  We set the color for kEOTWrong to clear, because we don't
    // want to see those values.  They are mirror image to the correct data
    
    for (plotIndex = 0; plotIndex < kPlots; plotIndex++) {
        perfTimePlot[plotIndex] = [[[LLPlotView alloc] initWithFrame:NSMakeRect(kMarginPix + plotIndex * kPlotPitchPix,
                                                            0, kPlotWidthPix, kPlotHeightPix)] autorelease];
        for (p = 0; p < kEOTs; p++) {
            performanceByTime[plotIndex][p] = [[[NSMutableArray alloc] init] autorelease]; // addPlot will retain
            for (index = 0; index < kMaxStim + 1; index++) {
                [performanceByTime[plotIndex][p] addObject:[[[LLBinomDist alloc] init] autorelease]];
            }
            [perfTimePlot[plotIndex] addPlot:performanceByTime[plotIndex][p]
                        plotColor:[LLStandardDataEvents eotColor:(p < kEOTTypes) ? p : p - 1]];
        }
        [perfTimePlot[plotIndex] setXAxisLabel:@"Target Index"];
        [[perfTimePlot[plotIndex] scale] setAutoAdjustYMax:NO];
        [[perfTimePlot[plotIndex] scale] setHeight:1];
        [perfTimePlot[plotIndex] setHighlightXRangeColor:highlightColor];
        [perfTimePlot[plotIndex] setXAxisTickLabels:stimLabelArray];
        [perfTimePlot[plotIndex] setPoints:kMaxStim + 1];
        [documentView addSubview:perfTimePlot[plotIndex]];
    }
    [documentView setFrame:NSMakeRect(0, 0, contentWidthPix, contentHeightPix)];
	[super setBaseMaxContentSize:NSMakeSize(contentWidthPix, contentHeightPix)];
}

- (void)interstimMS:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[eventData getBytes:&interstimMS length:sizeof(long)];
	[self checkTimeParams];
}

- (void)maxTargetMS:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[eventData getBytes:&maxTargetMS length:sizeof(long)];
	[self checkTimeParams];
}

- (void)stimDurationMS:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[eventData getBytes:&stimDurationMS length:sizeof(long)];
	[self checkTimeParams];
}

- (void)staircaseResult:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	float staircaseResult;
	LLPointDist *dist;
	NSString *stateLabels[kNumStates] = { @"In/In Attend In 0", @"In/In Attend In 1", @"In/In Attend Far 0",
        @"In/In Attend Far 1", @"In/Out Attend In 0", @"In/Out Attend Out 1",
        @"In/Out Attend Far 0", @"In/Out Attend Far 1"};
	
	[eventData getBytes:&staircaseResult length:sizeof(float)];
	dist = [[[LLPointDist alloc] init] autorelease];
	[dist addValue:MAX(staircaseResult, 0)];
    [thresholdPlot setTitle:[NSString stringWithFormat:@"%@ Threshold Contrast Change %.1f%%",
                                 stateLabels[trial.attendState], staircaseResult]];
	[thresholds[trial.attendState] addObject:dist];
	points = MAX(points, [thresholds[trial.attendState] count]);
	[thresholdPlot setPoints:points];
	[thresholdPlot setXAxisTickSpacing:MAX(1, points - 1)];
	[thresholdPlot setNeedsDisplay:YES];
}

- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	long state, eot;

	for (state = 0; state < kNumStates; state++) {
		[thresholds[state] removeAllObjects];
	}
	points = 0;
	[thresholdPlot setPoints:points];
	[thresholdPlot setTitle:@"Threshold"];

    for (eot = 0; eot < kEOTs; eot++) {
        [performanceByTime[kNoDistractorPlot][eot] makeObjectsPerformSelector:@selector(clear)];
        [performanceByTime[kDistractorPlot][eot] makeObjectsPerformSelector:@selector(clear)];
    }

    [[[self window] contentView] setNeedsDisplay:YES];
}

- (void)taskMode:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    long taskMode;
    
	[eventData getBytes:&taskMode length:sizeof(long)];
    if (taskMode == kTaskIdle) {
        [perfTimePlot[kNoDistractorPlot] setHighlightXRangeFrom:0 to:0];
        [perfTimePlot[kDistractorPlot] setHighlightXRangeFrom:0 to:0];
    }
}

- (void)trial:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	long targetIndex;
    StimLoc locIndex;

	[eventData getBytes:&trial length:sizeof(TrialDesc)];
    targetIndex = trial.targetIndex;
    for (locIndex = 0, perfPlotIndex = kNoDistractorPlot; locIndex < kStimLocs; locIndex++) {
        if (locIndex == trial.attendLoc) {
            continue;
        }
    }
    [perfTimePlot[kNoDistractorPlot] setHighlightXRangeFrom:0 to:0];
    [perfTimePlot[kDistractorPlot] setHighlightXRangeFrom:0 to:0];
    if (trial.catchTrial) {
		[perfTimePlot[perfPlotIndex] setHighlightXRangeFrom:maxTargetIndex - 1.25 to:maxTargetIndex - 0.75];
        return;
    }
    [perfTimePlot[perfPlotIndex] setHighlightXRangeFrom:targetIndex - 1.25 to:targetIndex - 0.75];
}

- (void)extendedEOT:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    long level, minN, eotCode, targetIndex;
	
    [eventData getBytes:&eotCode length:sizeof(long)];
    
    // Otherwise don't consider any outcomes except Correct, Failed, Early or Distracted
    
    if (eotCode != kEOTCorrect && eotCode != kEOTFailed && eotCode != kEOTEarly && eotCode != kEOTDistractor) {
        return;
    }
    
    if (trial.instructTrial) {
        return;
    }
    
    // For performance as a function of time, we simple record events as they occurred, assigning them
    // each to the time that the change would have occurred.  On invalid trials, we update the probe count on the target
    // side, but we increase the wrongs, ignores and brokes on the cued side.  We do not increment the failed count on
    // invalid trials.
    
    targetIndex = (trial.catchTrial) ? maxTargetIndex - 1 : trial.targetIndex - 1;
    [[performanceByTime[perfPlotIndex][kEOTCorrect] objectAtIndex:targetIndex] addValue:(eotCode == kEOTCorrect)];
    [[performanceByTime[perfPlotIndex][kEOTFailed] objectAtIndex:targetIndex] addValue:(eotCode == kEOTFailed)];
    [[performanceByTime[perfPlotIndex][kEOTEarly] objectAtIndex:targetIndex] addValue:(eotCode == kEOTEarly)];
    [[performanceByTime[perfPlotIndex][kEOTDistractor] objectAtIndex:targetIndex] addValue:(eotCode == kEOTDistractor)];
    
    // Find the least tested time bin, and update the title to show it.  We start with level at perfPlotIndex
    // because there can be no entries on level 0 in the distractor plot (index == 1).
    
    for (level = perfPlotIndex, minN = LONG_MAX; level < maxTargetIndex; level++) {
        minN = MIN(minN, [[performanceByTime[perfPlotIndex][kEOTCorrect] objectAtIndex:level] n] +
                   [[performanceByTime[perfPlotIndex][kEOTFailed] objectAtIndex:level] n]);
    }
    [perfTimePlot[perfPlotIndex] setTitle:[NSString stringWithFormat:@"%@Distractor Outcomes (n >= %ld)",
                                       (perfPlotIndex == 0) ? @"No " : @"", minN]];
    [perfTimePlot[perfPlotIndex] setNeedsDisplay:YES];
}

@end
