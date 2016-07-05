/* EventView */

@interface EventView : NSView
{
	double		lineDescenderPix;
	double		lineHeightPix;
	long		lines;

    IBOutlet id hexView;
    IBOutlet id document;
}

- (void)centerViewOnLine:(long)line;
- (void)setDisplayableLines:(long)count;

@end
