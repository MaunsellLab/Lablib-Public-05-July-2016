//
//  TUNSpikeController.h
//  Tuning
//
//  Copyright (c) 2006. All rights reserved.
//

#include "TUN.h"

#define kEOTs				(kEOTIgnored + 1)				// Plot EOT types up to ignored
#define kMaxSpikeMS				10000

@interface TUNSpikeController : LLScrollZoomWindow {

    NSMutableArray	*rates;						// arrays of LLNormDist for plotting
	NSView			*documentView;
    LLViewScale		*histScaling;
    NSMutableArray	*histViews;
    NSMutableArray	*attRates;								// an array of LLNormDist
    long			interstimDurMS;
    NSMutableArray	*labelArray;
	TestParams		lastTestParams;
    LLPlotView		*ratePlot;
    double			spikeHists[kMaxSteps][kMaxSpikeMS];
    long			stimDurMS;
	long			spikeHistsN[kMaxSteps];
	float			spikePeriodMS;
	NSMutableArray	*stimList;
	NSMutableArray	*stimTimes;
	TestParams		testParams;
	TrialDesc		trial;
	long			trialStartTime;
	NSMutableData	*trialSpikes;
    NSMutableArray	*xAxisLabelArray;
}

- (void)changeHistTimeMS;
- (void)checkParams;
- (LLHistView *)initHist:(LLViewScale *)scale data0:(double *)data0;
- (void)makeLabels;
- (void)positionPlots;
- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime;

@end

