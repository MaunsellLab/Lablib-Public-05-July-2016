//
//  VIBehaviorController.h
//  VICAN
//
//  Copyright (c) 2012. All rights reserved.
//

#include "VI.h"

enum {kNoDistractorPlot, kDistractorPlot, kPlots};

#define kEOTs				(kEOTDistractor + 1)

@interface VIBehaviorController : LLScrollZoomWindow {

	NSColor 		*highlightColor;
    long            interstimMS;
	long			lastMaxTargetTimeMS;
	long			lastMinTargetTimeMS;
	long			maxTargetMS;
    long            maxTargetIndex;
    NSMutableArray	*performanceByTime[kPlots][kEOTs + 1];	// an array of LLBinomDist
    long            perfPlotIndex;
    LLPlotView		*perfTimePlot[kPlots];
	long			points;
    long            stimDurationMS;
	LLPlotView		*thresholdPlot;
	NSMutableArray	*thresholds[kNumStates];
    NSMutableArray	*stimLabelArray;
	TrialDesc		trial;
}

- (void)makeStimLabels;

@end
