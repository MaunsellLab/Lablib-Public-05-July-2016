//
//  SCDigitalOut.m
//  SpotChange
//
//  Created by Marlene Cohen on 12/6/07.
//  Copyright 2007. All rights reserved.
//

#import "SCDigitalOut.h" 

@implementation SCDigitalOut

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
			NSRunAlertPanel(@"SCDigitalOut",  @"Can't find data device named \"%@\", trying ITC-18 instead.", 
						@"OK", nil, nil, @"ITC-18 1");
			digitalOutDevice = (LLITC18DataDevice *)[[task dataController] deviceWithName:@"ITC-18"];
			if (digitalOutDevice == nil) {
				NSRunAlertPanel(@"SCDigitalOut",  @"Can't find data device named \"%@\" (Quitting)", 
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
//	NSLog(@"Digital out %lx %lx", (event | 0x8000), (data & 0x7fff));
	return YES;
}

@end
