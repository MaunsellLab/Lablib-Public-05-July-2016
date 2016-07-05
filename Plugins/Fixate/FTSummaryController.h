//
//  FTSummaryController.h
//  Fixate
//
//  Created by John Maunsell on Fri Apr 11 2003.
//  Copyright (c) 2003. All rights reserved.
//

@interface FTSummaryController:NSWindowController {

@private
    NSSize				baseMaxContentSize;
    long				blockLimit;
    long 				eotCode;
    NSDictionary		*fontAttr;
    NSDictionary		*labelFontAttr;
    NSDictionary		*leftFontAttr;
	long 				lastEOTCode;
    BOOL				newTrial;
	long				recentComputer;			// Count of trials with computer certification errors
	long				recentEOTs[kEOTTypes];
    long				recentEOTTotal;

    IBOutlet			LLEOTView *recentPlot;
    IBOutlet			LLEOTHistoryView *eotHistory;
    IBOutlet			NSTableView *percentTable;
    IBOutlet			NSScrollView *scrollView;
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

@end
