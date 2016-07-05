#import "PrintView.h"

@implementation PrintView

#define kPrintFontSize	6
#define kXLimitPix 	2048
#define kXMarginPix	2

static NSSize			charSize;
static DataFile			*document;
static long			printableLines;
static short			printableLinesPerPage;
static long			lines;
static short			linesPerPage;
static long			pages;
static NSMutableDictionary	*printFontAttributes;
static long			printWidthPix;

- (void)dealloc
{
    [printFontAttributes release];
    [super dealloc];
}

- (void)drawRect:(NSRect)rect
{
    long line, displayLine, topLine, bottomLine, stringXOffset;
    NSString *pageString;
    NSBezierPath *path;
    
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:rect];
    [[NSColor blackColor] set]; 
    topLine = rect.origin.y / charSize.height;
    bottomLine = (rect.origin.y + rect.size.height) / charSize.height;
    if (bottomLine >= lines) {
        bottomLine = lines - 1;
    }
    for (line = topLine; line <= bottomLine; line++) {
        switch (line % linesPerPage) {
        case 0:
            [[[document fileURL] lastPathComponent] drawAtPoint:NSMakePoint(kXMarginPix, line * charSize.height)
                                                        withAttributes:printFontAttributes];
            pageString = [[NSString alloc] initWithFormat:@"Page %ld of %ld", line / linesPerPage + 1, pages];
            stringXOffset = [pageString sizeWithAttributes:printFontAttributes].width;
            [pageString  drawAtPoint:NSMakePoint(printWidthPix - stringXOffset, line * charSize.height)
                withAttributes:printFontAttributes];
            [pageString release];
            
            path = [[NSBezierPath alloc] init];
            [path moveToPoint:NSMakePoint(0, (line + 1) * charSize.height + 5)];
            [path lineToPoint:NSMakePoint(printWidthPix, (line + 1) * charSize.height + 5)];
            [path stroke];
            [path release];
            break;
        case 1:
            break;
        default:
            displayLine = line - 2 * (line / linesPerPage + 1);
            [[document printString:displayLine]
                drawAtPoint:NSMakePoint(kXMarginPix, (float)line * charSize.height)
                withAttributes:printFontAttributes];
            break;
        }
    }
}

- (	PrintView *)initWithInfo:(DataFile *)dataFile printInfo:(NSPrintInfo *)printInfo
{
    NSFont *font = [NSFont userFixedPitchFontOfSize:kPrintFontSize];
    
    document = dataFile;
    printFontAttributes = [[NSMutableDictionary alloc] init];
    [printFontAttributes setObject:font forKey:NSFontAttributeName];
    [printFontAttributes retain];

    charSize = [@"X" sizeWithAttributes:printFontAttributes];
    printWidthPix = [printInfo paperSize].width - [printInfo leftMargin] - [printInfo rightMargin];
    linesPerPage = ([printInfo paperSize].height - [printInfo topMargin] - [printInfo bottomMargin]) / charSize.height;
    printableLinesPerPage = linesPerPage - 2;				// two lines left for the header

    self = [super init];
    return self;
}

- (BOOL)isFlipped
{
    return YES;
}

- (BOOL)knowsPageRange:(NSRange *)pRange
{
    pRange->location = 1;
    pRange->length = pages;
    return YES;
}

- (NSRect)rectForPage:(NSInteger)pageNum
{
    NSRect theRect;
    
    theRect.size.width = printWidthPix;
    theRect.size.height = linesPerPage * charSize.height;
    theRect.origin.x = 0;
    theRect.origin.y = (pageNum - 1) * (float)linesPerPage * charSize.height;
    return theRect;
}

- (void)printableLines:(long)lineCount
{
    printableLines = lineCount;
    pages = printableLines / printableLinesPerPage;
    lines = pages * linesPerPage;
    if ((printableLines % printableLinesPerPage) > 0) {
        pages++;
        lines += 2 + (printableLines % printableLinesPerPage);
    }
    [self setFrame:NSMakeRect(0, 0, printWidthPix, ((float)lines) * charSize.height - 1)];

}

@end
