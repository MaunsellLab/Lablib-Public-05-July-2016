//
//  VTBehaviorView.h
//  VideoTest
//
//  Created by John Maunsell on Fri Apr 11 2003.
//  Copyright (c) 2003. All rights reserved.
//

#include "VT.h"
#include "VTStateSystem.h"

#define kEOTs				(kEOTIgnored + 1)				// Plot EOT types up to ignored
#define kMaxRT				1000

@interface VTBehaviorController:NSWindowController {

@protected
    NSSize			baseMaxContentSize;
	NSView			*documentView;
    LLPlotView		*intervalCorrectPlot;
	NSMutableArray  *intervalOneCorrect;				// an array of LLBinomDist
	NSMutableArray  *intervalOnePC;						// an array of LLBinomDist
	NSMutableArray  *intervalTwoCorrect;				// an array of LLBinomDist
    LLHistView		*hist[kMaxHists];
    LLViewScale		*histScaling;
    NSColor 		*highlightColor;
    long			histHighlightIndex;
    NSMutableArray	*labelArray;
	StimParams		lastStimParams[kStimTypes];
	long			lastStimType;
    NSMutableArray	*performance[kEOTs];				// an array of LLBinomDist
    LLPlotView		*perfPlot;
    LLPlotView		*reactPlot;
    NSMutableArray	*reactTimes;						// an array of LLNormDist
    long			responseTimeMS;
    double			rtDist[kMaxHists][kMaxRT];
    double			scaleFactor;
	StimParams		stimParams[kStimTypes];
	long			stimType;
    double			targetsOnTimeMS;
	TrialDesc		trial;
    NSMutableArray	*xAxisLabelArray;
	
    IBOutlet		NSScrollView *scrollView;
    IBOutlet		NSPopUpButton *zoomButton;
}

- (void)changeResponseTimeMS;
- (IBAction)changeZoom:(id)sender;
- (void)checkParams;
- (LLHistView *)initHist:(LLViewScale *)scale data:(double *)data;
- (void)makeLabels;
- (void)positionPlots;
- (void)positionZoomButton;
- (void)setScaleFactor:(double)factor;
- (void)setWindowMaxSize;
- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime;
- (void)targetsOn:(NSData *)eventData eventTime:(NSNumber *)eventTime;

@end
