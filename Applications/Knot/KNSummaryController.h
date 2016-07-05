//
//  KNSummaryController.h
//  Knot
//
//  Created by John Maunsell on Fri Apr 11 2003.
//  Copyright (c) 2003-2007. All rights reserved.
//

@interface KNSummaryController:NSWindowController {

@private
    NSSize				baseMaxContentSize;
	long				dayComputer;			// Count of trials with computer certification errors
	long				dayEOTs[kEOTTypes];
    long				dayEOTTotal;
	LLUserDefaults		*defaults;
    long 				eotCode;
    NSDictionary		*fontAttr;
    NSDictionary		*labelFontAttr; 
    NSDictionary		*leftFontAttr;
	long 				lastEOTCode;

    IBOutlet			LLEOTView *dayPlot;
    IBOutlet			LLEOTHistoryView *eotHistory;
    IBOutlet			NSTableView *percentTable;
    IBOutlet			NSScrollView *scrollView;
    IBOutlet			NSPopUpButton *zoomButton;
}

- (IBAction)changeZoom:(id)sender;
-(id)initWithDefaults:(LLUserDefaults *)userDefaults;
- (NSDictionary *)makeAttributesForFont:(NSFont *)font alignment:(NSTextAlignment)align tailIndex:(float)indent;
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)percentTableColumn:(NSTableColumn *)tableColumn row:(long)row;
- (void)positionZoomButton;
- (void)setScaleFactor:(double)factor;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;

@end
