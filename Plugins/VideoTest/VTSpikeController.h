//
//  VTSpikeController.h
//  Experiment
//
//  Created by John Maunsell on Fri Apr 11 2003.
//  Copyright (c) 2003. All rights reserved.
//

#include "VT.h"

#define kMaxBins			1000
#define kPlotBinsDefault	20
#define kPoststimMS			250
#define	kXTickSpacing		100

#define	bins				(MIN(kMaxBins, prestimMS + intervalMS + kPoststimMS))

extern 	NSString 	*spikeWindowVisibleKey;
extern 	NSString 	*spikeWindowZoomKey;

@interface SpikeController:NSWindowController {

@private
	NSSize			baseMaxContentSize;
    long			contrasts;
    long 			contrastIndex;
    LLHistView		*hist[kMaxHists];
    LLViewScale		*histScaling;
    NSColor 		*highlightColor;
    long			histHighlightIndex;
    NSMutableArray	*labelArray;
    long			prestimMS;
    unsigned long	prestimOnTimeMS;
    NSMutableArray	*responses;	
    double			spikeCount;
    double			spikeHists[kMaxHists][kMaxBins];
    double			spikeHistsN[kMaxHists];
    long			intervalMS;
    unsigned long	stimOnTimeMS;
	long			stimType;
	StimParams		stimParams[kStimTypes];
    unsigned long	trialStartTimeMS;
    long			trialHist[kMaxBins];
    BOOL			validSpikes;
    
    IBOutlet		LLHistView *histView0;
    IBOutlet		LLHistView *histView1;
    IBOutlet		LLHistView *histView2;
    IBOutlet		LLHistView *histView3;
    IBOutlet		LLHistView *histView4;
    IBOutlet		LLHistView *histView5;
    IBOutlet		LLHistView *histView6;
    IBOutlet		LLHistView *histView7;
    IBOutlet		LLPlotView *responsePlot;
    IBOutlet		NSScrollView *scrollView;
    IBOutlet		NSPopUpButton *zoomButton;
}

- (IBAction) changeZoom:(id)sender;
- (void) makeContrastLabels;
- (void) positionZoomButton;
- (void) setScaleFactor:(double)factor;

@end
