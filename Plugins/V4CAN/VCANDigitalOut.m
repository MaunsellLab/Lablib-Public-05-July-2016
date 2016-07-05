//
//  VCANDigitalOut.m
//
//  Copyright 2008. All rights reserved.
//

#import "VCANDigitalOut.h"

#define kMinPeriodS			0.000150
#define kStrobeBit			0x8000
#define kStrobeMask			(~kStrobeBit)

@implementation VCANDigitalOut

-(void)dealloc;
{
	[lock release];
	[super dealloc];
}

-(id) init;
{
	if ((self = [super init])) {
		digitalOutDevice = (LLITC18DataDevice *)[[task dataController] deviceWithName:@"ITC-18 1"];
		if (digitalOutDevice == nil) {
			NSRunAlertPanel(@"OCDigitalOut",  @"Can't find data device named \"%@\", trying ITC-18 instead.",
                            @"OK", nil, nil, @"ITC-18 1");
			digitalOutDevice = (LLITC18DataDevice *)[[task dataController] deviceWithName:@"ITC-18"];
			if (digitalOutDevice == nil) {
				NSRunAlertPanel(@"OrientationChange",  @"Can't find data device named \"%@\" (Quitting)",
                                @"OK", nil, nil, @"ITC-18");
				exit(0);
			}
		}
		lock = [[NSLock alloc] init];
	}
	return self;
}

- (BOOL)outputEvent:(long)event withData:(long)data;
{
	if (digitalOutDevice == nil) {
		return NO;
	}
	[lock lock];
	[digitalOutDevice digitalOutputBits:(event | 0x8000)];
	[digitalOutDevice digitalOutputBits:(data & 0x7fff)];
	[lock unlock];
    //NSLog(@"Digital out %lx %lx", (event | 0x8000), (data & 0x7fff));
	return YES;
}

@end
