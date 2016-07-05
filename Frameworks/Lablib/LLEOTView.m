//
//  LLEOTView.m
//  Lablib
//
//  Created by John Maunsell on Wed May 28 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLEOTView.h"
#import "LLStandardDataEvents.h"
#import "LLPlotColors.h"

@implementation LLEOTView

- (id)initWithFrame:(NSRect)frame {

    if ((self = [super initWithFrame:frame]) != nil) {
		eotTypes = kEOTTypes;
    }
    return self;
}

- (void)drawRect:(NSRect)rect;
{
    long index, total, subtotal;
    NSRect r;
    
    r = [self bounds];
    NSEraseRect(r);
    if (pEOTData == NULL) {
        return;
    }
    for (index = total = 0; index < eotTypes; index++) {
        total += pEOTData[index];
    }
    if (total == 0) {
        return;
    }
    for (index = subtotal = 0; index < eotTypes; index++) {
        [[LLStandardDataEvents eotColor:index] set];
        [NSBezierPath fillRect:NSMakeRect(r.origin.x, 
            r.origin.y + r.size.height * subtotal / total,
            r.origin.x + r.size.width, 
            r.origin.y + r.size.height * (subtotal + pEOTData[index]) / total)];
        subtotal += pEOTData[index];
    }
    [[NSColor blackColor] set];
    [NSBezierPath strokeRect:r];
}

// Overwrite isOpaque to improve performance

- (BOOL)isOpaque;
{
	return YES;
}

- (void)setData:(long *)pData;
{
    pEOTData = pData;
}

- (void)setEOTTypes:(long)types;
{
	eotTypes = types;
}

@end
