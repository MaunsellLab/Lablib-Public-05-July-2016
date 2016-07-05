//
//  RFSummaryController.m
//  Experiment
//
//  Window with summary information trial events.
//
//  Created by John Maunsell on Fri Apr 11 2003.
//  Copyright (c) 2004. All rights reserved.
//

#define NoGlobals

#import "RFSummaryController.h"
#import "RF.h"
#import "RFMapUtilityFunctions.h"

#define kEOTDisplayTimeS		1.0
#define kLastEOTTypeDisplayed   kEOTIgnored		// Count everything up to kEOTIgnored
#define kPlotBinsDefault		10
#define kTableRows				(kLastEOTTypeDisplayed + 6) // extra for blank rows, total, etc.
#define	kXTickSpacing			100

enum {kBlankRow0 = kLastEOTTypeDisplayed + 1, kComputerRow, kBlankRow1, kRewardsRow, kTotalRow};
enum {kColorColumn = 0, kEOTColumn, kDayColumn, kRecentColumn};

NSString *RFSummaryAutosaveKey = @"RFSummaryWindow";
NSString *RFSummaryWindowBrokeKey = @"RFSummaryWindowBroke";
NSString *RFSummaryWindowComputerKey = @"RFSummaryWindowComputer";
NSString *RFSummaryWindowCorrectKey = @"RFSummaryWindowCorrect";
NSString *RFSummaryWindowDateKey = @"RFSummaryWindowDate";
NSString *RFSummaryWindowFailedKey = @"RFSummaryWindowFailed";
NSString *RFSummaryWindowIgnoredKey = @"RFSummaryWindowIgnored";
NSString *RFSummaryWindowTotalKey = @"RFSummaryWindowTotal";
NSString *RFSummaryWindowWrongKey = @"RFSummaryWindowWrong";
NSString *RFSummaryWindowVisibleKey = @"RFSummaryWindowVisible";
NSString *RFSummaryWindowZoomKey = @"RFSummaryWindowZoom";

@implementation RFSummaryController

- (IBAction)changeZoom:(id)sender;
{
    long zoomValue;
    
    zoomValue = [[sender selectedCell] tag];
    [self setScaleFactor:zoomValue / 100.0];
    [[task defaults] setObject:[NSNumber numberWithInt:zoomValue] 
                forKey:RFSummaryWindowZoomKey];
}

- (void)dealloc;
{
	[[task defaults] setFloat:[NSDate timeIntervalSinceReferenceDate] forKey:RFSummaryWindowDateKey];
	[[task defaults] setInteger:dayEOTs[kEOTBroke] forKey:RFSummaryWindowBrokeKey];
	[[task defaults] setInteger:dayEOTs[kEOTCorrect] forKey:RFSummaryWindowCorrectKey];
	[[task defaults] setInteger:dayEOTs[kEOTFailed] forKey:RFSummaryWindowFailedKey];
	[[task defaults] setInteger:dayEOTs[kEOTIgnored] forKey:RFSummaryWindowIgnoredKey];
	[[task defaults] setInteger:dayEOTs[kEOTWrong] forKey:RFSummaryWindowWrongKey];
	[[task defaults] setInteger:dayEOTTotal forKey:RFSummaryWindowTotalKey];
	[[task defaults] setInteger:dayComputer forKey:RFSummaryWindowComputerKey];
    [fontAttr release];
    [labelFontAttr release];
    [leftFontAttr release];
    [super dealloc];
}
    
- (id)init {

    NSRect maxScrollRect;
	double timeNow, timeStored;
    NSScroller *hScroller, *vScroller;
    
    if ((self = [super initWithWindowNibName:@"RFSummaryController"]) != nil) {
 		[self setShouldCascadeWindows:NO];
		[self setWindowFrameAutosaveName:RFSummaryAutosaveKey];
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
        
        [dayPlot setData:dayEOTs];
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
        lastEOTCode = -1;
		
		timeStored = [[task defaults] floatForKey:RFSummaryWindowDateKey];
		timeNow = [NSDate timeIntervalSinceReferenceDate];
		if (timeNow - timeStored < 12 * 60 * 60) {			// Less than 12 h old?
			dayEOTs[kEOTBroke] = [[task defaults] integerForKey:RFSummaryWindowBrokeKey];
			dayEOTs[kEOTCorrect] = [[task defaults] integerForKey:RFSummaryWindowCorrectKey];
			dayEOTs[kEOTFailed] = [[task defaults] integerForKey:RFSummaryWindowFailedKey];
			dayEOTs[kEOTIgnored] = [[task defaults] integerForKey:RFSummaryWindowIgnoredKey];
			dayEOTs[kEOTWrong] = [[task defaults] integerForKey:RFSummaryWindowWrongKey];
			dayEOTTotal = [[task defaults] integerForKey:RFSummaryWindowTotalKey];
			dayComputer = [[task defaults] integerForKey:RFSummaryWindowComputerKey];
		}

//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:)
//				name:NSApplicationWillTerminateNotification object:nil];
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
                string = [NSString stringWithFormat:@"%ld", dayEOTTotal];
            }
            else if (row == kRewardsRow) {
                string = [NSString stringWithFormat:@"%ld", dayEOTs[kEOTCorrect]];
            }
            else if (dayEOTTotal == 0) {
                string = @" ";
            }
			else if (row == kComputerRow) {		// row reserved for computer failures
               string = [NSString stringWithFormat:@"%ld", dayComputer];
			}
            else {
               string = [NSString stringWithFormat:@"%ld%%", 
							(long)round(dayEOTs[kLastEOTTypeDisplayed - row] * 100.0 / dayEOTTotal)];
            }
            break;
       case kRecentColumn:
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
				if (recentEOTTotal == 0) {
					string = @"";
				}
				else {
					string = [NSString stringWithFormat:@"%ld%%",
							(long)round(recentEOTs[kLastEOTTypeDisplayed - row] * 100.0 / recentEOTTotal)];
				}
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

- (void) setScaleFactor:(double)factor;
{
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
        windowFrameRect = [NSWindow frameRectForContentRect:scrollFrameRect
                styleMask:[[self window] styleMask]];
        [[self window] setMaxSize:windowFrameRect.size];
   }
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {

    if (tableView == percentTable) {
        return [self percentTableColumn:tableColumn row:row];
    }
    else if (tableView == trialTable) {
        return [self trialTableColumn:tableColumn row:row];
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

    long column, remainingTrials, doneTrials;
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
						(trial.stimulusType == kBarStimulus) ? "Bar" : "Gabor"];
			break;
        case 1:
			string = @"??";
//			string = [NSString stringWithFormat:@"%s trial %.f%s", newTrial ? "This" : "Last", 
//					trial.stimulusValue, (trial.stimulusType == kBarStimulus) ? "Bar" : " Gabor"];
            break;
        case 2:
            string = @"";
            break;
        case 3:
            string = [NSString stringWithFormat:@"Trial %ld of %ld", 
                MIN(pStimParam->levels, trialsDoneThisBlock + 1), pStimParam->levels];
            break;
        case 4:
            string = [NSString stringWithFormat:@"Block %ld of %ld", blocksDone + 1, blockLimit];
			break;
        case 5:
            remainingTrials =  MAX(0, (blockLimit - blocksDone) * pStimParam->levels - trialsDoneThisBlock);
            doneTrials = trialsDoneThisBlock + blocksDone * pStimParam->levels;
            if (doneTrials == 0) {
                string = [NSString stringWithFormat:@"Remaining: %ld trials", remainingTrials];
            }
            else {
                timeLeftS = ([LLSystemUtil getTimeS] - lastStartTimeS + accumulatedRunTimeS)
													/ doneTrials * remainingTrials;
                if (timeLeftS < 60.0) {
                    string = [NSString stringWithFormat:@"Remaining: %ld trials (%.1f s)", 
                                remainingTrials, timeLeftS];
                }
                else if (timeLeftS < 3600.0) {
                    string = [NSString stringWithFormat:@"Remaining: %ld trials (%.1f m)", 
                                remainingTrials, timeLeftS / 60.0];
                }
                else {
                    string = [NSString stringWithFormat:@"Remaining: %ld trials (%.1f h)", 
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
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification;
{
	[[task defaults] setBool:YES forKey:RFSummaryWindowVisibleKey];
}

- (void) windowDidLoad {
    
	long index, defaultZoom;

    [[zoomButton cell] setBordered:NO];
    [[zoomButton cell] setBezeled:YES];
    [[zoomButton cell] setFont:[NSFont labelFontOfSize:10.0]];
    defaultZoom = [[task defaults] integerForKey:RFSummaryWindowZoomKey];
    for (index = 0; index < [[zoomButton itemArray] count]; index++) {
        if ([[zoomButton itemAtIndex:index] tag] == defaultZoom) {
            [zoomButton selectItemAtIndex:index];
            [self setScaleFactor:defaultZoom / 100.0];
            break;
        }
    }
	[[self window] setFrameUsingName:RFSummaryAutosaveKey];			// Needed when opened a second time
    if ([[task defaults] boolForKey:RFSummaryWindowVisibleKey]) {
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

- (BOOL) windowShouldClose:(NSNotification *)aNotification;
{
    [[self window] orderOut:self];
    [[task defaults] setBool:NO forKey:RFSummaryWindowVisibleKey];
    [NSApp addWindowsItem:[self window] title:[[self window] title] filename:NO];
    return NO;
}

// Methods related to data events follow:

- (void) blockLimit:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&blockLimit length:sizeof(long)];
}

- (void) blocksDone:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&blocksDone length:sizeof(long)];
}

- (void) blockTrialsDone:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&trialsDoneThisBlock length:sizeof(long)];
}

- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    long index;
    
    recentComputer = recentEOTTotal = 0;
    for (index = 0; index <= kLastEOTTypeDisplayed; index++) {
        recentEOTs[index] = 0;
    }
    trial.stimulusType = -1;							// mark ourselves empty of data
    accumulatedRunTimeS = 0;
    if (taskMode == kTaskRunning) {
        lastStartTimeS = [LLSystemUtil getTimeS];
    }
	[percentTable reloadData];
	[trialTable reloadData];
}
/*- (void) stimulusType:(NSData *)eventData eventTime:(NSNumber *)eventTime {
    
	[eventData getBytes:&stimType];
}
*/
- (void) taskMode:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&taskMode length:sizeof(long)];
    switch (taskMode) {
        case kTaskRunning:
            lastStartTimeS = [LLSystemUtil getTimeS];
            break;
        case kTaskStopping:
            accumulatedRunTimeS += [LLSystemUtil getTimeS] - lastStartTimeS;
            break;
        default:
            break;
    }
}

- (void) trialCertify:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	long certifyCode; 
	
	[eventData getBytes:&certifyCode length:sizeof(long)];
    if (certifyCode != 0L) { // -1 because computer errors stored separately
        recentComputer++;  
        dayComputer++;  
    }
}

- (void) trialEnd:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&eotCode length:sizeof(long)];
    if (eotCode <= kLastEOTTypeDisplayed) {
        recentEOTs[eotCode]++;
        recentEOTTotal++;  
        dayEOTs[eotCode]++;
        dayEOTTotal++;  
    }
    newTrial = NO;
	lastEOTCode = eotCode;
    [percentTable reloadData];
	[trialTable reloadData];
	[dayPlot setNeedsDisplay:YES];
	[recentPlot setNeedsDisplay:YES];
}

- (void) trial:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    [eventData getBytes:&trial length:sizeof(TrialDesc)];
    newTrial = YES;
	[trialTable reloadData];
    [percentTable reloadData];
}

@end
