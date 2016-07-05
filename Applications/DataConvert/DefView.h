/* DefView */

@interface DefView : NSView
{
    NSPoint			currentPoint;
	BOOL			*enabled;
	BOOL			*enabledTemp;
    float			lineDescenderPix;
    long			numEvents;
	BOOL			selectState;
	long			startLine;

    IBOutlet id		document;
}

- (IBAction)disableAllEvents:(id)sender;
- (IBAction)enableAllEvents:(id)sender;
- (void)setNumEvents:(long)count;

@end