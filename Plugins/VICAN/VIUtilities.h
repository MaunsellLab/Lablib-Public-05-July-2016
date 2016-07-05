//
//  VIUtilities.h
//  VICAN
//
//  Created by John Maunsell on 6/23/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import "VI.h"

@interface VIUtilities : NSObject

+ (void)announceEvents;
+ (BOOL)inWindow:(LLEyeWindow *)window;
+ (void)reset;
+ (void)requestReset;
+ (NSString *)stringForStimDescEntry:(NSArray *)stimList entryIndex:(long)index;
+ (void)updateBlockStatus:(BlockStatus *)pBS;

@end
