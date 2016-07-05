//
//  MTCBehaviorController.h
//  MTContrast
//
//  Copyright (c) 2006. All rights reserved.
//

#include "MTC.h"

#define kEOTs				(kEOTIgnored + 1)				// Plot EOT types up to ignored
#define kMaxRT				1000

@interface MTCBehaviorController : LLScrollZoomWindow {

	NSView			*documentView;
    LLHistView		*hist[kMaxContrasts];
    LLViewScale		*histScaling;
    NSColor 		*highlightColor;
    long			histHighlightIndex;
    NSMutableArray	*labelArray;
	StimParams		lastStimParams;
    NSMutableArray	*performance[kEOTs];				// an array of LLBinomDist
    LLPlotView		*perfPlot;
    LLPlotView		*reactPlot;
    NSMutableArray	*reactTimes;						// an array of LLNormDist
    long			responseTimeMS;
    double			rtDist[kMaxContrasts][kMaxRT];
	long			saccadeTimeMS;
	StimParams		stimParams;
	double			targetOnTimeMS;
	TrialDesc		trial;
    NSMutableArray	*xAxisLabelArray;
}

- (void)changeResponseTimeMS;
- (void)checkParams;
- (LLHistView *)initHist:(LLViewScale *)scale data:(double *)data;
- (void)makeLabels;
- (void)positionPlots;
- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime;

@end
