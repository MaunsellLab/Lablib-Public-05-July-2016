/* PrintView */

#import "DataFile.h"

@interface PrintView : NSView
{
}

- (PrintView *)initWithInfo:(DataFile *)dataFile printInfo:(NSPrintInfo *)printInfo;
- (void)printableLines:(long)lines;

@end
