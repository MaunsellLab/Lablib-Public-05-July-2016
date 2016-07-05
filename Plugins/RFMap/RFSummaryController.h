//
//  RFSummaryController.h
//  Experiment
//
//  Created by John Maunsell on Fri Apr 11 2003.
//  Copyright (c) 2004. All rights reserved.
//

#import "RF.h"

@interface RFSummaryController:NSWindowController {

@private
    double				accumulatedRunTimeS;
    NSSize				baseMaxContentSize;
    long				blockLimit;
    long				blocksDone;
	long				dayComputer;			// Count of trials with computer certification errors
	long				dayEOTs[kEOTTypes];
    long				dayEOTTotal;
    long 				eotCode;
    NSDictionary		*fontAttr;
    NSDictionary		*labelFontAttr;
    NSDictionary		*leftFontAttr;
	long 				lastEOTCode;
    double				lastStartTimeS;
    BOOL				newTrial;
	long				recentComputer;			// Count of trials with computer certification errors
    long				recentEOTs[kEOTTypes];
    long				recentEOTTotal;
    NSSize				staticWindowFrame;
	StimParams			stimParams[kStimTypes];
    long 				taskMode;
	TrialDesc			trial;
    long				trialsDoneThisBlock;

    IBOutlet			LLEOTView *dayPlot;
    IBOutlet			NSTableView *percentTable;
    IBOutlet			LLEOTView *recentPlot;
    IBOutlet			NSScrollView *scrollView;
    IBOutlet			NSTableView *trialTable;
    IBOutlet			NSPopUpButton *zoomButton;
}

- (IBAction)changeZoom:(id)sender;
- (NSDictionary *)makeAttributesForFont:(NSFont *)font alignment:(NSTextAlignment)align tailIndex:(float)indent;
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)percentTableColumn:(NSTableColumn *)tableColumn row:(long)row;
- (void)positionZoomButton;
- (void)setScaleFactor:(double)factor;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (id)trialTableColumn:(NSTableColumn *)tableColumn row:(long)row;
- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime;

@end
