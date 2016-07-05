//
//  KNSummaryController.m
//  Knot
//
//  Window with summary information trial events.
//
//  Created by John Maunsell on Fri Apr 11 2003.
//  Copyright (c) 2003-2007. All rights reserved.
//

#define NoGlobals

#import "KNSummaryController.h"
#import "Knot.h"

#define kEOTDisplayTimeS		1.0
#define kLastEOTTypeDisplayed   kEOTIgnored		// Count everything up to kEOTIgnored
#define kPlotBinsDefault		10
#define kTableRows				(kLastEOTTypeDisplayed + 6) // extra for blank rows, total, etc.
#define	kXTickSpacing			100

enum {kBlankRow0 = kLastEOTTypeDisplayed + 1, kComputerRow, kBlankRow1, kRewardsRow, kTotalRow};
enum {kColorColumn = 0, kEOTColumn, kDayColumn, kRecentColumn};

NSString *KNSummaryAutosaveKey = @"KNSummaryAutosave";
NSString *KNSummaryWindowBrokeKey = @"KNSummaryWindowBroke";
NSString *KNSummaryWindowComputerKey = @"KNSummaryWindowComputer";
NSString *KNSummaryWindowCorrectKey = @"KNSummaryWindowCorrect";
NSString *KNSummaryWindowDateKey = @"KNSummaryWindowDate";
NSString *KNSummaryWindowFailedKey = @"KNSummaryWindowFailed";
NSString *KNSummaryWindowIgnoredKey = @"KNSummaryWindowIgnored";
NSString *KNSummaryWindowTotalKey = @"KNSummaryWindowTotal";
NSString *KNSummaryWindowWrongKey = @"KNSummaryWindowWrong";
NSString *KNSummaryWindowVisibleKey = @"KNSummaryWindowVisible";
NSString *KNSummaryWindowZoomKey = @"KNSummaryWindowZoom";

@implementation KNSummaryController

- (IBAction)changeZoom:(id)sender {

    long zoomValue;
    
    zoomValue = [[sender selectedCell] tag];
    [self setScaleFactor:zoomValue / 100.0];
    [defaults setObject:[NSNumber numberWithInt:zoomValue] forKey:KNSummaryWindowZoomKey];
}

- (void)dealloc;
{
    [fontAttr release];
    [labelFontAttr release];
    [leftFontAttr release];
	[defaults release];
    [super dealloc];
}
    
-(id)initWithDefaults:(LLUserDefaults *)userDefaults;
{
    NSRect maxScrollRect;
	double timeNow, timeStored;
    NSScroller *hScroller, *vScroller;
    
    if ((self = [super initWithWindowNibName:@"KNSummaryController"]) != nil) {
		defaults = userDefaults;
		[defaults retain];
		
        [self setWindowFrameAutosaveName:KNSummaryAutosaveKey];
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
        
        [dayPlot setData:dayEOTs];
    
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
		
		timeStored = [defaults floatForKey:KNSummaryWindowDateKey];
		timeNow = [NSDate timeIntervalSinceReferenceDate];
		if (timeNow - timeStored < 12 * 60 * 60) {			// Less than 12 h old?
			dayEOTs[kEOTBroke] = [defaults integerForKey:KNSummaryWindowBrokeKey];
			dayEOTs[kEOTCorrect] = [defaults integerForKey:KNSummaryWindowCorrectKey];
			dayEOTs[kEOTFailed] = [defaults integerForKey:KNSummaryWindowFailedKey];
			dayEOTs[kEOTIgnored] = [defaults integerForKey:KNSummaryWindowIgnoredKey];
			dayEOTs[kEOTWrong] = [defaults integerForKey:KNSummaryWindowWrongKey];
			dayEOTTotal = [defaults integerForKey:KNSummaryWindowTotalKey];
			dayComputer = [defaults integerForKey:KNSummaryWindowComputerKey];
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

- (int)numberOfRowsInTableView:(NSTableView *)tableView;
{
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
    buttonRect.origin.y += buttonRect.size.height;				// Offset because the clipRect is flipped
    buttonRect.origin = [[[self window] contentView] convertPoint:buttonRect.origin fromView:scrollView];
    [zoomButton setFrame:NSInsetRect(buttonRect, 1.0, 1.0)];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[scrollView horizontalScroller] setNeedsDisplay:YES];
        [zoomButton setNeedsDisplay:YES];
    });
}
	
- (void) setScaleFactor:(double)factor {

    NSSize maxContentSize;
    NSRect scrollFrameRect, windowFrameRect;
    NSScroller *hScroller, *vScroller;
    double delta;
    static double scaleFactor = 1.0;
  
    if ((long)(scaleFactor * 1000) != (long)(factor * 1000)) {
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
			if ((lastEOTCode >= 0) && (lastEOTCode == (kLastEOTTypeDisplayed - rowIndex))) {
				[cell setBackgroundColor:[NSColor controlHighlightColor]];
			}
			else {
				[cell setBackgroundColor:[NSColor whiteColor]];
			}
		}
    }
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification;
{
	[defaults setObject:[NSNumber numberWithBool:YES]  forKey:KNSummaryWindowVisibleKey];
}

- (void) windowDidLoad;
{
	long index, defaultZoom;

    [[zoomButton cell] setBordered:NO];
    [[zoomButton cell] setBezeled:YES];
    [[zoomButton cell] setFont:[NSFont labelFontOfSize:10.0]];
    defaultZoom = [defaults integerForKey:KNSummaryWindowZoomKey];
    for (index = 0; index < [[zoomButton itemArray] count]; index++) {
        if ([[zoomButton itemAtIndex:index] tag] == defaultZoom) {
            [zoomButton selectItemAtIndex:index];
            [self setScaleFactor:defaultZoom / 100.0];
            break;
        }
    }
        
	[[self window] setFrameUsingName:KNSummaryAutosaveKey];			// Needed when opened a second time
    if ([defaults boolForKey:KNSummaryWindowVisibleKey]) {
        [[self window] makeKeyAndOrderFront:self];
    }
    else {
        [NSApp addWindowsItem:[self window] title:[[self window] title] filename:NO];
    }
    [self positionZoomButton];							// position zoom must be after visible
    dispatch_async(dispatch_get_main_queue(), ^{
        [percentTable reloadData];
    });
    [super windowDidLoad];
}

// We use a delegate method to detect when the window has resized, and 
// adjust the postion of the zoom button when it does.

- (void) windowDidResize:(NSNotification *)aNotification;
{
	[self positionZoomButton];
}

- (BOOL) windowShouldClose:(NSNotification *)aNotification;
{
    [[self window] orderOut:self];
    [defaults setObject:[NSNumber numberWithBool:NO] forKey:KNSummaryWindowVisibleKey];
    [NSApp addWindowsItem:[self window] title:[[self window] title] filename:NO];
    return NO;
}

- (void)windowWillClose:(NSNotification *)notification;
{
	[defaults setFloat:[NSDate timeIntervalSinceReferenceDate] forKey:KNSummaryWindowDateKey];
	[defaults setInteger:dayEOTs[kEOTBroke] forKey:KNSummaryWindowBrokeKey];
	[defaults setInteger:dayEOTs[kEOTCorrect] forKey:KNSummaryWindowCorrectKey];
	[defaults setInteger:dayEOTs[kEOTFailed] forKey:KNSummaryWindowFailedKey];
	[defaults setInteger:dayEOTs[kEOTIgnored] forKey:KNSummaryWindowIgnoredKey];
	[defaults setInteger:dayEOTs[kEOTWrong] forKey:KNSummaryWindowWrongKey];
	[defaults setInteger:dayEOTTotal forKey:KNSummaryWindowTotalKey];
	[defaults setInteger:dayComputer forKey:KNSummaryWindowComputerKey];
}

//
// Methods related to data events follow:
//

- (void)trialCertify:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	long certifyCode; 
	
    [eventData getBytes:&certifyCode length:sizeof(long)];
    if (certifyCode != 0) { // -1 because computer errors stored separately
        dayComputer++;  
    }
}

- (void)trialEnd:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    [eventData getBytes:&eotCode length:sizeof(long)];
    if (eotCode <= kLastEOTTypeDisplayed) {
        dayEOTs[eotCode]++;
        dayEOTTotal++;  
    }
	lastEOTCode = eotCode;
	[eotHistory addEOT:eotCode];
    dispatch_async(dispatch_get_main_queue(), ^{
        [percentTable reloadData];
        [dayPlot setNeedsDisplay:YES];
    });
}

@end
