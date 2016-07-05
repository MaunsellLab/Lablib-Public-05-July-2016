//
//  SCDigitalOut.h
//  SpotChange
//
//  Created by Marlene Cohen on 12/6/07.
//  Copyright 2007 . All rights reserved.
//

#import "SC.h"
#import "LablibITC18.h" 

@interface SCDigitalOut : NSObject {

	LLITC18DataDevice		*digitalOutDevice;
	NSLock					*lock;

}

- (BOOL)outputEvent:(long)event withData:(long)data;

@end
