/* EventView */

//#import <Cocoa/Cocoa.h>

@interface EventView : NSView
{
    IBOutlet id hexView;
    IBOutlet id document;
}

- (void)centerViewOnLine:(long)line;
- (void)setDisplayableLines:(long)count;

@end
