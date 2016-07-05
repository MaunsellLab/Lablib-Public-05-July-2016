//
//  SCSpikeController.h
//  SpotChange
//
//  Copyright (c) 2006. All rights reserved.
//

#include "SC.h"

//#define kEOTs					(kEOTIgnored + 1)				// Plot EOT types up to ignored
#define kMaxSpikeMS				10000
#define	kLocations				3

@interface SCSpikeController : LLScrollZoomWindow {

	BlockStatus		blockStatus;
	NSView			*documentView;
    LLViewScale		*histScaling;
    NSMutableArray	*histViews;
    NSMutableArray	*attRates;								// an array of LLNormDist
    long			interstimDurMS;
    NSMutableArray	*labelArray;
	BlockStatus		lastBlockStatus;
	StimParams		lastStimParams;
    LLPlotView		*ratePlot;
    NSMutableArray	*rates[kLocations];						// arrays of LLNormDist for plotting
//    NSMutableArray	*rates[3];						// arrays of LLNormDist for plotting
	unsigned		referenceOnTimeMS;				// onset time of reference direction (stimulus right before target)
	double			spikeHists[kLocations][kMaxOriChanges][kMaxSpikeMS];
//	double			spikeHists[2][kMaxOriChanges][kMaxSpikeMS];
    long			stimDurMS;
	long			spikeHistsN[kLocations][kMaxOriChanges];
//	long			spikeHistsN[2][kMaxOriChanges];
	float			spikePeriodMS;
//	NSMutableArray	*stimList;
//	NSMutableArray	*stimTimes;
	unsigned long	targetOnTimeMS;
	TrialDesc		trial;
	unsigned long	trialStartTime;
	NSMutableData	*trialSpikes;
    NSMutableArray	*xAxisLabelArray;

    NSColor 		*highlightColor;
    long			histHighlightIndex;
	
}

- (void)changeHistTimeMS;
- (void)checkParams;
- (LLHistView *)initHist:(LLViewScale *)scale data0:(double *)data0 data1:(double *)data1;
- (void)makeLabels;
- (void)positionPlots;
- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime;

@end

