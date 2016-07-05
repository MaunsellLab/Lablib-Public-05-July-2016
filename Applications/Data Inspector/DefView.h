/* DefView */

#import <Cocoa/Cocoa.h>
//#import "DataInspector.h"

@interface DefView : NSView
{
    NSPoint currentPoint;
    long numEvents;
    float lineDescenderPix;

    IBOutlet id document;
}

- (void)numEvents:(long)count;
- (IBAction)disableAllEvents:(id)sender;
- (IBAction)enableAllEvents:(id)sender;

@end
