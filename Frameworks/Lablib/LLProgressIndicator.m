//
//  LLProgressIndicator.m
//  Lablib
//
//  Created by John Maunsell on 3/28/06.
//  Copyright 2006. All rights reserved.
//

#import "LLProgressIndicator.h"
#import "LLSystemUtil.h"

#define kUpdateIntervalMS	100

@implementation LLProgressIndicator

- (IBAction)cancel:(id)sender;
{
	cancelled = YES;
}

- (BOOL)cancelled;
{
	return cancelled;
}

- (void)close;
{
	[[self window] close];
}

- (id)init;
{
    if ((self = [super initWithWindowNibName:@"LLProgressIndicator"]) != nil) {
        [self setWindowFrameAutosaveName:@"LLProgressIndicator"];
		[self window];
	}
    return self;
}

- (BOOL)needsUpdate;
{
	if (nextTime == 0 || [LLSystemUtil timeIsPast:nextTime]) {
		nextTime = [LLSystemUtil timeFromNow:kUpdateIntervalMS];
		return YES;
	}
	else {
		return NO;
	}
}

- (void)setDoubleValue:(double)doubleValue;
{
	[indicator setDoubleValue:doubleValue];
}

- (void)setIndeterminate:(BOOL)flag;
{
	[indicator setIndeterminate:flag];
}

- (void)setMaxValue:(double)newMaxValue;
{
	[indicator setMaxValue:newMaxValue];
}

- (void)setMinValue:(double)newMinValue;
{
	[indicator setMinValue:newMinValue];
}

- (void)setText:(NSString *)string;
{
	[message setStringValue:string];
}

- (void)setTitle:(NSString *)string;
{
	[[self window] setTitle:string];
}

- (void)windowDidLoad;
{
	[indicator setIndeterminate:NO];
}

@end
