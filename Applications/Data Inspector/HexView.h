/* HexView */

//#import <Cocoa/Cocoa.h>

@interface HexView : NSView
{
    IBOutlet id document;
}

- (void)centerViewOnLine:(long)line;
- (void)setDisplayableLines:(long)lines;

@end
