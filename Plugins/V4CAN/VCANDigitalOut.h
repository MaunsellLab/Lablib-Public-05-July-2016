//
//  VCANDigitalOut.h
//
//  Created by Marlene Cohen on 12/6/07.
//  Copyright 2007 . All rights reserved.
//

#import "VCAN.h"
#import <LablibITC18/LablibITC18.h>

@interface VCANDigitalOut : NSObject {

	LLITC18DataDevice		*digitalOutDevice;
	double					lastTime;
	NSLock					*lock;
}

- (BOOL)outputEvent:(long)event withData:(long)data;

@end
