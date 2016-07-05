#import "HexView.h"
#import "DataFile.h"

@implementation HexView

#define kXLimitPix 	600
#define kXMarginPix	2

static double 	lineDescenderPix;
static double 	lineHeightPix;
static long	lines = 0; 

- (void)centerViewOnLine:(long)line
{
    float newYOriginPix;
    NSSize scrollSize;
    
    NSRect r;
    r = [self bounds];
    scrollSize = [[self enclosingScrollView] contentSize];
    newYOriginPix = line * lineHeightPix - scrollSize.height / 2;
    if (newYOriginPix < 0) {
        newYOriginPix = 0;
    }
    [self scrollPoint:NSMakePoint(0, newYOriginPix)]; 
}

- (void)drawRect:(NSRect)rect
{
    long line, topLine, bottomLine;

    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:rect];
    [[NSColor blackColor] set];    
    topLine = rect.origin.y / lineHeightPix;
    bottomLine = (rect.origin.y + rect.size.height) / lineHeightPix;
    if (bottomLine >= lines) {
        bottomLine = lines - 1;
    }
    for (line = topLine; line <= bottomLine; line++) {
        [[document hexString:line] drawAtPoint:NSMakePoint(kXMarginPix, line * lineHeightPix + lineDescenderPix)];
    }
}

- (BOOL)isFlipped
{
    return YES;
}

- (void) mouseDown:(NSEvent *)event
{
    NSPoint downPoint;

    downPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    [document hexSelectionChanged:(long)(downPoint.y / [document lineHeightPix]) xPix:downPoint.x
              clickCount:[event clickCount]]; 
}

- (void)setDisplayableLines:(long)displayableLines;
{
    lines = displayableLines;
    lineHeightPix = [document lineHeightPix];
    lineDescenderPix = [document lineDescenderPix];
    [self setFrame:NSMakeRect(0, 0, kXLimitPix, (long)(lines * lineHeightPix - 1))];
    [self setNeedsDisplay:YES];
}

@end