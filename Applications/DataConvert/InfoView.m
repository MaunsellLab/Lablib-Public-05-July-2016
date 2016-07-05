#import "InfoView.h"
#import "DataFile.h"

@implementation InfoView

- (void)drawRect:(NSRect)rect {

    NSAttributedString *string;

    [[NSColor whiteColor] set];					// Erase the rectangle
    [NSBezierPath fillRect:rect];
    [[NSColor blackColor] set];    
    string = [document infoString];				// Get string for this line
    [string drawAtPoint:NSMakePoint(0, 0)];
}

- (BOOL)isFlipped
{
    return YES;
}

@end

