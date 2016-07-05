//
//  LLXTEventPlot.h
//  Lablib
//
//  Created by John Maunsell on Thu May 22 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLXTPlot.h"

@interface LLXTEventPlot : NSObject <LLXTPlot> {

@protected
	NSLock			*eventLock;
    NSMutableArray	*eventNames;
    NSMutableArray	*eventTimes;
    float			durationS;
    LLViewScale		*scale;
}

- (void)addEvent:(NSString *)name time:(NSNumber *)time;
- (void)clear;
- (void)draw;

@end
