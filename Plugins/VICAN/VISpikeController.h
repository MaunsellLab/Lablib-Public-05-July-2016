//
//  VISpikeController.h
//  VICAN
//
//  Copyright (c) 2012. All rights reserved.
//

#include "VI.h"

#define kTaskConditions     2
#define kNumHistStates      (kNumStates - 2)
#define kNumHistPerSet      (kNumHistStates / 2)
#define kMaxSpikeMS			10000

@interface VISpikeController : LLScrollZoomWindow {
	
	NSView			*documentView;
	LLHistView		*histViews[kNumHistStates][kRFStimTypes][kRFStimTypes];
    long			interstimDurMS;
	LLPlotView		*ratePlot[kTaskConditions];						// rate plot 
	NSMutableArray	*rates[kTaskConditions][kAttendTypes];			// arrays of LLNormDist for feature attention plot
    double			spikeHists[kNumHistStates][kRFStimTypes][kRFStimTypes][kMaxSpikeMS];
	long			spikeHistsN[kNumHistStates][kRFStimTypes][kRFStimTypes];
    long			stimDurMS;
	NSMutableArray	*stimList;
	NSMutableArray	*stimTimes;
	TrialDesc		trial;
	long			trialStartTime;
	NSMutableData	*trialSpikes;
    NSMutableArray	*xAxisLabelArray;
	long			xAxisTickSpacing;
    
    IBOutlet NSTextField    *histLabel0;
    IBOutlet NSTextField    *histLabel1;
    IBOutlet NSTextField    *histLabel2;
    IBOutlet NSPopUpButton  *histSelectMenu;
}

- (void)changeHistTimeMS;
- (LLHistView *)myInitHistWithScaling:(LLViewScale *)scaling doXAxisLabel:(BOOL)doLabel; 
- (void)loadHistograms;
- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime;
- (void)tallyResponses;

@end

