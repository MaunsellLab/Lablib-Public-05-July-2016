//
//  VIPsychController.h
//  VICAN
//
//  Copyright (c) 2006. All rights reserved.
//

#include "VI.h"

#define kNumPlots           (kStimLocs + 1)

extern NSString *VIPsychoWindowVisibleKey;

@interface VIPsychController : LLScrollZoomWindow {

	BlockStatus		blockStatus;
	NSView			*documentView;
	NSColor 		*highlightColor;
    long			highlightedPointIndex;
	long			highlightedPlotIndex;
    NSMutableArray	*labelArray;
	BlockStatus		lastBlockStatus;
	long			lastMaxTargetTimeMS;
	long			lastMinTargetTimeMS;
	long			maxTargetTimeMS;
	long			minTargetTimeMS;
    NSMutableArray	*perfValid[kNumPlots];		// an array of LLBinomDist
    NSMutableArray	*perfInvalidNear[kNumPlots];		// an array of LLBinomDist
    NSMutableArray	*perfInvalidFar[kNumPlots];		// an array of LLBinomDist
    LLPlotView		*perfPlot[kNumPlots];
    LLPlotView		*reactPlot[kNumPlots];
    NSMutableArray	*reactTimes[kNumPlots];                        // an array of LLNormDist
    NSMutableArray	*reactTimesInvalidNear[kNumPlots];			// an array of LLNormDist
    NSMutableArray	*reactTimesInvalidFar[kNumPlots];			// an array of LLNormDist
    long			responseTimeMS;
	unsigned long	saccadeStartTimeMS;
	unsigned long   stimStartTimeMS;
	unsigned long   targetOnTimeMS;
    NSMutableArray	*timeLabelArray;
	TrialDesc		trial;
    NSMutableArray	*xAxisLabelArray;
}

- (void)changeResponseTimeMS;
- (void)checkTimeParams;
- (void)checkParams;
- (void)makeLabels;
- (void)moreInitialization;
- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime;

@end
