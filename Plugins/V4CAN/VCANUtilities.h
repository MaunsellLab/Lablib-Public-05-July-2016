//
//  VCANUtilities.h
//  V4CAN
//
//  Created by John Maunsell on 6/23/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VCANUtilities : NSObject

+ (BOOL)inWindow:(LLEyeWindow *)window;
+ (NSString *)stringForStimDescEntry:(NSArray *)stimList entryIndex:(long)index;

@end
