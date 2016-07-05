#import "DefView.h"
#import "DataFile.h"

@implementation DefView

#define kButtonMarginPix	3
#define kXLimitPix 		512

#define buttonOuterWidthPix	([document lineHeightPix] - 2 * kButtonMarginPix)
#define xTextOffsetPix		(buttonOuterWidthPix + 2 * kButtonMarginPix)
#define yLimitPix 		(numEvents * [document lineHeightPix])

EnabledArray	enabled;
EnabledArray	enabledTemp;
BOOL 		selectState;
long		startLine;

- (IBAction)disableAllEvents:(id)sender
{
    long index;
    
    for (index = 0; index < numEvents; index++) {
        enabled[index] = NO;
    }
    [document enabledEvents:enabled];
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect
{
    long line, topLine, bottomLine;
    NSAttributedString *string;
    NSBezierPath *button;
    NSAffineTransform *buttonTranslate = [[NSAffineTransform alloc] init];

    [[NSColor whiteColor] set];					// Erase the rectangle
    [NSBezierPath fillRect:rect];
    [[NSColor blackColor] set];    
    topLine = rect.origin.y / [document lineHeightPix];
    bottomLine = (rect.origin.y + rect.size.height) / [document lineHeightPix];
    button = [NSBezierPath bezierPathWithOvalInRect:
                NSMakeRect(kButtonMarginPix, topLine * [document lineHeightPix] + kButtonMarginPix + kButtonMarginPix / 2, 
                buttonOuterWidthPix, buttonOuterWidthPix)];
    [buttonTranslate translateXBy:0 yBy:[document lineHeightPix]];		// For tranlating button path
     
    for (line = topLine; line <= bottomLine; line++) {		// Draw each line

// Draw the enabled button 

        if (enabled[line]) {					// Make event as enabled or unselected
            [[NSColor lightGrayColor] set];
            [button fill];
            [[NSColor blackColor] set];
        }
        [button stroke];
        button = [buttonTranslate transformBezierPath:button];	// Tranlate path for next line

// Draw the event description text

        string = [document definitionString:line];		// Get string for this line
        [string drawAtPoint:NSMakePoint(xTextOffsetPix, line * [document lineHeightPix])];
        [string release];
    }
}

- (IBAction)enableAllEvents:(id)sender
{
    long index;
    
    for (index = 0; index < numEvents; index++) {
        enabled[index] = YES;
    }
    [document enabledEvents:enabled];
    [self setNeedsDisplay:YES];
}

// Inverted coordinates for text

- (BOOL)isFlipped
{
    return YES;
}

// User  has started to select or deselect event definitions.  The process may entail dragging,
// so it is not finished until the mouse up event

- (void) mouseDown:(NSEvent *)event
{
    long index;
    NSPoint downPoint;
    NSPoint p = [event locationInWindow];
    
    for (index = 0; index < numEvents; index++) {
        enabledTemp[index] = enabled[index];
    }
    downPoint = [self convertPoint:p fromView:nil];
    startLine = (long)(downPoint.y / [document lineHeightPix]);
    selectState = !enabled[startLine];
    enabled[startLine] = enabledTemp[startLine] = selectState;
    [self setNeedsDisplay:YES];
}

// User can drag over events to select or deselect a block of event definitions
- (void) mouseDragged:(NSEvent *)event
{
    long index, selectedLine;
    NSPoint downPoint;

    NSPoint p = [event locationInWindow];
    downPoint = [self convertPoint:p fromView:nil];
    selectedLine = (long)(downPoint.y / [document lineHeightPix]);
    
    for (index = 0; index < numEvents; index++) {
        if ((index > startLine && index <= selectedLine) || (index < startLine && index >= selectedLine)) {
            enabled[index] = selectState;
        }
        else {
            enabled[index] = enabledTemp[index];
        }
    }
    [self setNeedsDisplay:YES];
}

// User has finished selecting or deselecting one or more event definitions

- (void) mouseUp:(NSEvent *)event
{
    [document enabledEvents:enabled];
}

- (void)numEvents:(long)count;
{
    long index;
    
    numEvents = count;
    for (index = 0; index < numEvents; index++) {
        enabled[index] = YES;
    }
    [document enabledEvents:enabled];
    [self setFrame:NSMakeRect(0, 0, kXLimitPix, yLimitPix)];
    [self setNeedsDisplay:YES];
}

@end
