//
//  FTSummaryController.m
//  Knot
//
//  Window with summary information trial events.
//
//  Created by John Maunsell on Fri Apr 11 2003.
//  Copyright (c) 2003. All rights reserved.
//

#define NoGlobals

#import "FTSummaryController.h"
#import "FT.h"

#define kEOTDisplayTimeS		1.0
#define kLastEOTTypeDisplayed   kEOTIgnored		// Count everything up to kEOTIgnored
#define kPlotBinsDefault		10
#define kTableRows				(kLastEOTTypeDisplayed + 6) // extra for blank rows, total, etc.
#define	kXTickSpacing			100

enum {kBlankRow0 = kLastEOTTypeDisplayed + 1, kComputerRow, kBlankRow1, kRewardsRow, kTotalRow};
enum {kColorColumn = 0, kEOTColumn, kDayColumn, kRecentColumn};

NSString *FTSummaryAutosaveKey = @"FTSummaryAutosave";
NSString *FTSummaryWindowBrokeKey = @"FTSummaryWindowBroke";
NSString *FTSummaryWindowComputerKey = @"FTSummaryWindowComputer";
NSString *FTSummaryWindowCorrectKey = @"FTSummaryWindowCorrect";
NSString *FTSummaryWindowDateKey = @"FTSummaryWindowDate";
NSString *FTSummaryWindowFailedKey = @"FTSummaryWindowFailed";
NSString *FTSummaryWindowIgnoredKey = @"FTSummaryWindowIgnored";
NSString *FTSummaryWindowTotalKey = @"FTSummaryWindowTotal";
NSString *FTSummaryWindowWrongKey = @"FTSummaryWindowWrong";
NSString *FTSummaryWindowVisibleKey = @"FTSummaryWindowVisible";
NSString *FTSummaryWindowZoomKey = @"FTSummaryWindowZoom";

@implementation FTSummaryController

- (IBAction)changeZoom:(id)sender {

    long zoomValue;
    
    zoomValue = [[sender selectedCell] tag];
    [self setScaleFactor:zoomValue / 100.0];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:zoomValue] 
                forKey:FTSummaryWindowZoomKey];
}

- (void)dealloc {

	[[task defaults] setFloat:[NSDate timeIntervalSinceReferenceDate] forKey:FTSummaryWindowDateKey];
	[[task defaults] setInteger:recentEOTs[kEOTBroke] forKey:FTSummaryWindowBrokeKey];
	[[task defaults] setInteger:recentEOTs[kEOTCorrect] forKey:FTSummaryWindowCorrectKey];
	[[task defaults] setInteger:recentEOTs[kEOTFailed] forKey:FTSummaryWindowFailedKey];
	[[task defaults] setInteger:recentEOTs[kEOTIgnored] forKey:FTSummaryWindowIgnoredKey];
	[[task defaults] setInteger:recentEOTs[kEOTWrong] forKey:FTSummaryWindowWrongKey];
	[[task defaults] setInteger:recentEOTTotal forKey:FTSummaryWindowTotalKey];
	[[task defaults] setInteger:recentComputer forKey:FTSummaryWindowComputerKey];
    [fontAttr release];
    [labelFontAttr release];
    [leftFontAttr release];
    [super dealloc];
}
    
- (id)init {

    NSRect maxScrollRect;
	double timeNow, timeStored;
    NSScroller *hScroller, *vScroller;
    
    if ((self = [super initWithWindowNibName:@"FTSummaryController"]) != Nil) {
        [self setWindowFrameAutosaveName:FTSummaryAutosaveKey];
 		[self setShouldCascadeWindows:NO];
        [self window];							// Force the window to load now

        fontAttr = [self makeAttributesForFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]
                alignment:NSRightTextAlignment tailIndex:-12];
        [fontAttr retain];
        labelFontAttr = [self makeAttributesForFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]
                alignment:NSRightTextAlignment tailIndex:0];
        [labelFontAttr retain];
        leftFontAttr = [self makeAttributesForFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]
                alignment:NSLeftTextAlignment tailIndex:0];
        [leftFontAttr retain];
        
        [recentPlot setData:recentEOTs];
    
    // Work down from the default window max size to a default content max size, which 
    // we will use as a reference for setting window max size when the view scaling is changed.
    
        maxScrollRect = [NSWindow contentRectForFrameRect:
            NSMakeRect(0, 0, [[self window] maxSize].width, [[self window] maxSize].height)
            styleMask:[[self window] styleMask]];
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
        hScroller = [scrollView horizontalScroller];
        vScroller = [scrollView verticalScroller];
        baseMaxContentSize = [NSScrollView contentSizeForFrameSize:maxScrollRect.size
                horizontalScrollerClass:[hScroller class] verticalScrollerClass:[vScroller class]
                borderType:[scrollView borderType]
                controlSize:[hScroller controlSize] scrollerStyle:[hScroller scrollerStyle]];
#else
        baseMaxContentSize = [NSScrollView contentSizeForFrameSize:maxScrollRect.size
                                             hasHorizontalScroller:YES hasVerticalScroller:YES
                                                        borderType:[scrollView borderType]];
#endif
//        baseMaxContentSize = [NSScrollView contentSizeForFrameSize:maxScrollRect.size
//                hasHorizontalScroller:YES hasVerticalScroller:YES
//                borderType:[scrollView borderType]];
//				
		lastEOTCode = -1;
		
		timeStored = [[NSUserDefaults standardUserDefaults] floatForKey:FTSummaryWindowDateKey];
		timeNow = [NSDate timeIntervalSinceReferenceDate];
		if (timeNow - timeStored < 12 * 60 * 60) {			// Less than 12 h old?
			recentEOTs[kEOTBroke] = [[NSUserDefaults standardUserDefaults] integerForKey:FTSummaryWindowBrokeKey];
			recentEOTs[kEOTCorrect] = [[NSUserDefaults standardUserDefaults] integerForKey:FTSummaryWindowCorrectKey];
			recentEOTs[kEOTFailed] = [[NSUserDefaults standardUserDefaults] integerForKey:FTSummaryWindowFailedKey];
			recentEOTs[kEOTIgnored] = [[NSUserDefaults standardUserDefaults] integerForKey:FTSummaryWindowIgnoredKey];
			recentEOTs[kEOTWrong] = [[NSUserDefaults standardUserDefaults] integerForKey:FTSummaryWindowWrongKey];
			recentEOTTotal = [[NSUserDefaults standardUserDefaults] integerForKey:FTSummaryWindowTotalKey];
			recentComputer = [[NSUserDefaults standardUserDefaults] integerForKey:FTSummaryWindowComputerKey];
		}
    }
    return self;
}

- (NSDictionary *)makeAttributesForFont:(NSFont *)font alignment:(NSTextAlignment)align tailIndex:(float)indent {

	NSMutableParagraphStyle *para; 
    NSMutableDictionary *attr;
    
        para = [[NSMutableParagraphStyle alloc] init];
        [para setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
        [para setAlignment:align];
        [para setTailIndent:indent];
        
        attr = [[NSMutableDictionary alloc] init];
        [attr setObject:font forKey:NSFontAttributeName];
        [attr setObject:para forKey:NSParagraphStyleAttributeName];
        [attr autorelease];
        [para release];
        return attr;
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
    return kTableRows;
}

// Return an NSAttributedString for a cell in the percent performance table

- (id)percentTableColumn:(NSTableColumn *)tableColumn row:(long)row {

    long column;
    NSString *string;
	NSDictionary *attr = fontAttr;
 
    if (row == kBlankRow0 || row == kBlankRow1) {		// the blank rows
        return @" ";
    }
    column = [[tableColumn identifier] intValue];
    switch (column) {
		case kColorColumn:
            string = @" ";
			break;
        case kEOTColumn:
			attr = labelFontAttr;
            switch (row) {
                case kTotalRow:
                    string = @"Total:";
                    break;
				case kRewardsRow:
					string = @"Rewards:";
					break;
				case kComputerRow:					// row for computer failures
                    string = @"Computer:";
					break;
                default:
                    string = [NSString stringWithFormat:@"%@:", 
								[LLStandardDataEvents trialEndName:kLastEOTTypeDisplayed - row]];
                    break;
            }
            break;
        case kDayColumn:
            if (row == kTotalRow) {
                string = [NSString stringWithFormat:@"%ld", recentEOTTotal];
            }
            else if (row == kRewardsRow) {
                string = [NSString stringWithFormat:@"%ld", recentEOTs[kEOTCorrect]];
            }
            else if (recentEOTTotal == 0) {
                string = @" ";
            }
			else if (row == kComputerRow) {		// row reserved for computer failures
               string = [NSString stringWithFormat:@"%ld", recentComputer];
			}
            else {
               string = [NSString stringWithFormat:@"%ld%%", 
							(long)round(recentEOTs[kLastEOTTypeDisplayed - row] * 100.0 / recentEOTTotal)];
            }
            break;
        default:
            string = @"???";
            break;
    }
	return [[[NSAttributedString alloc] initWithString:string attributes:attr] autorelease];
}

- (void) positionZoomButton {

    NSRect scrollerRect, buttonRect;
   
    scrollerRect = [[scrollView horizontalScroller] frame];
    scrollerRect.size.width = [scrollView frame].size.width - scrollerRect.size.height - 8;
    NSDivideRect(scrollerRect, &buttonRect, &scrollerRect, 60.0, NSMaxXEdge);
    [[scrollView horizontalScroller] setFrame:scrollerRect];
    [[scrollView horizontalScroller] setNeedsDisplay:YES];
    buttonRect.origin.y += buttonRect.size.height;				// Offset because the clipRect is flipped
    buttonRect.origin = [[[self window] contentView] convertPoint:buttonRect.origin fromView:scrollView];
    [zoomButton setFrame:NSInsetRect(buttonRect, 1.0, 1.0)];
    [zoomButton setNeedsDisplay:YES];
}

- (void) setScaleFactor:(double)factor {

    NSSize maxContentSize;
    NSRect scrollFrameRect, windowFrameRect;
    NSScroller *hScroller, *vScroller;
    double delta;
    static double scaleFactor = 1.0;
  
    if (scaleFactor != factor) {
        delta = factor / scaleFactor;
        [[scrollView contentView] scaleUnitSquareToSize:NSMakeSize(delta, delta)];
        scaleFactor = factor;
        [self positionZoomButton];
        [scrollView display];

// Limit the maximum size of the window.  
  
        maxContentSize.width = baseMaxContentSize.width * factor;
        maxContentSize.height = baseMaxContentSize.height * factor;
        scrollFrameRect.origin = NSMakePoint(0, 0);
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
        hScroller = [scrollView horizontalScroller];
        vScroller = [scrollView verticalScroller];
        scrollFrameRect.size = [NSScrollView frameSizeForContentSize:maxContentSize
                horizontalScrollerClass:[hScroller class] verticalScrollerClass:[vScroller class]
                borderType:[scrollView borderType]
                controlSize:[hScroller controlSize] scrollerStyle:[hScroller scrollerStyle]];
#else
        scrollFrameRect.size = [NSScrollView frameSizeForContentSize:maxContentSize
                hasHorizontalScroller:YES hasVerticalScroller:YES borderType:[scrollView borderType]];
#endif	
//        scrollFrameRect.size = [NSScrollView frameSizeForContentSize:maxContentSize
//            hasHorizontalScroller:YES hasVerticalScroller:YES 
//            borderType:[scrollView borderType]];
        windowFrameRect = [NSWindow frameRectForContentRect:scrollFrameRect
                styleMask:[[self window] styleMask]];
        [[self window] setMaxSize:windowFrameRect.size];
   }
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {

    if (tableView == percentTable) {
        return [self percentTableColumn:tableColumn row:row];
    }
    else {
        return @"";
    }
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row {

	return NO;
}

// Display the color patches showing the EOT color coding, and highlight the text for the last EOT type

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn 					row:(int)rowIndex {

	long column;
	
	if (tableView == percentTable) { 
		column = [[tableColumn identifier] intValue];
		if (column == kColorColumn) {
			[cell setDrawsBackground:YES]; 
			if (rowIndex <= kLastEOTTypeDisplayed) {
				[cell setBackgroundColor:[LLStandardDataEvents eotColor:kLastEOTTypeDisplayed - rowIndex]];
			}
			else {
				[cell setBackgroundColor:[NSColor whiteColor]];
			}
		}
		else {
			if (!newTrial && (lastEOTCode >= 0) && (lastEOTCode == (kLastEOTTypeDisplayed - rowIndex))) {
				[cell setBackgroundColor:[NSColor controlHighlightColor]];
			}
			else {
				[cell setBackgroundColor:[NSColor whiteColor]];
			}
		}
    }
}

- (id)trialTableColumn:(NSTableColumn *)tableColumn row:(long)row {

/*    long column, remainingTrials, doneTrials;
    double timeLeftS;
    NSAttributedString *cellContents;
    NSString *string;
	StimParams *pStimParam;

// Do nothing if the data buffers have nothing in them

    if ((column = [[tableColumn identifier] intValue]) != 0 || trial.stimulusType < 0) {
        return @"";
    }
	
	pStimParam = &stimParams[trial.stimulusType];
    switch (row) {
        case 0:
			string = [NSString stringWithFormat:@"%s Stimulation", 
						(trial.stimulusType == kVisualStimulus) ? "Visual" : "Electrical"];
			break;
        case 1:
			string = [NSString stringWithFormat:@"%s trial %.*f%s", newTrial ? "This" : "Last", 
					[LLTextUtil precisionForValue:trial.stimulusValue significantDigits:3], 
					trial.stimulusValue, (trial.stimulusType == kVisualStimulus) ? "% contrast" : " µA"];
            break;
        case 2:
            string = @"";
            break;
        case 3:
            string = [NSString stringWithFormat:@"Trial %d of %d", 
                MIN(pStimParam->levels, trialsDoneThisBlock + 1), pStimParam->levels];
            break;
        case 4:
            string = [NSString stringWithFormat:@"Block %d of %d", blocksDone + 1, blockLimit];
			break;
        case 5:
            remainingTrials =  MAX(0, (blockLimit - blocksDone) * pStimParam->levels - trialsDoneThisBlock);
            doneTrials = trialsDoneThisBlock + blocksDone * pStimParam->levels;
            if (doneTrials == 0) {
                string = [NSString stringWithFormat:@"Remaining: %d trials", remainingTrials];
            }
            else {
                timeLeftS = ([LLSystemUtil getTimeS] - lastStartTimeS + accumulatedRunTimeS)
													/ doneTrials * remainingTrials;
                if (timeLeftS < 60.0) {
                    string = [NSString stringWithFormat:@"Remaining: %d trials (%.1f s)", 
                                remainingTrials, timeLeftS];
                }
                else if (timeLeftS < 3600.0) {
                    string = [NSString stringWithFormat:@"Remaining: %d trials (%.1f m)", 
                                remainingTrials, timeLeftS / 60.0];
                }
                else {
                    string = [NSString stringWithFormat:@"Remaining: %d trials (%.1f h)", 
                                remainingTrials, timeLeftS / 3600.0];
                }
            }
            break;
        default:
            string = @"???";
            break;
    }
    cellContents = [[NSAttributedString alloc] initWithString:string attributes:leftFontAttr];
	[cellContents autorelease];
    return cellContents;
*/
	return nil;
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification {

	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] 
                forKey:FTSummaryWindowVisibleKey];
}

- (void) windowDidLoad {
    
	long index, defaultZoom;

    [[zoomButton cell] setBordered:NO];
    [[zoomButton cell] setBezeled:YES];
    [[zoomButton cell] setFont:[NSFont labelFontOfSize:10.0]];
    defaultZoom = [[NSUserDefaults standardUserDefaults] integerForKey:FTSummaryWindowZoomKey];
    for (index = 0; index < [[zoomButton itemArray] count]; index++) {
        if ([[zoomButton itemAtIndex:index] tag] == defaultZoom) {
            [zoomButton selectItemAtIndex:index];
            [self setScaleFactor:defaultZoom / 100.0];
            break;
        }
    }
	[[self window] setFrameUsingName:FTSummaryAutosaveKey];			// Needed when opened a second time
    if ([[NSUserDefaults standardUserDefaults] boolForKey:FTSummaryWindowVisibleKey]) {
        [[self window] makeKeyAndOrderFront:self];
    }
    else {
        [NSApp addWindowsItem:[self window] title:[[self window] title] filename:NO];
    }
    
    [self positionZoomButton];							// position zoom must be after visible
    [percentTable reloadData];
    [super windowDidLoad];
}

// We use a delegate method to detect when the window has resized, and 
// adjust the postion of the zoom button when it does.

- (void) windowDidResize:(NSNotification *)aNotification {

	[self positionZoomButton];
}

- (BOOL) windowShouldClose:(NSNotification *)aNotification {

    [[self window] orderOut:self];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] 
                forKey:FTSummaryWindowVisibleKey];
    [NSApp addWindowsItem:[self window] title:[[self window] title] filename:NO];
    return NO;
}

//
// Methods related to data events follow:
//

- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    long index;
    
	recentComputer = recentEOTTotal = 0;
    for (index = 0; index <= kLastEOTTypeDisplayed; index++) {
        recentEOTs[index] = 0;
    }
	[eotHistory reset];
	[eotHistory setNeedsDisplay:YES];
	[percentTable reloadData];
	[recentPlot setNeedsDisplay:YES];
}

- (void)trialCertify:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	long certifyCode; 
	
    [eventData getBytes:&certifyCode length:sizeof(long)];
    if (certifyCode != 0) { // -1 because computer errors stored separately
        recentComputer++;  
    }
}

- (void)trialEnd:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    [eventData getBytes:&eotCode length:sizeof(long)];
    if (eotCode <= kLastEOTTypeDisplayed) {
        recentEOTs[eotCode]++;
        recentEOTTotal++;  
    }
    newTrial = NO;
	lastEOTCode = eotCode;
	[eotHistory addEOT:eotCode];
    [percentTable reloadData];
	[recentPlot setNeedsDisplay:YES];
}

@end
