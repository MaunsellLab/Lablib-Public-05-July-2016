//
//  VCANUtilities.m
//  V4CAN
//
//  Created by John Maunsell on 6/23/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import "VCANUtilities.h"
#include "VCAN.h"

enum {kUseLeftEye = 0, kUseRightEye, kUseBinocular};

NSString *VCANEyeToUseKey = @"VCANEyeToUse";

@implementation VCANUtilities

+ (BOOL)inWindow:(LLEyeWindow *)window;
{
    BOOL inWindow = NO;
    
    switch ([[task defaults] integerForKey:VCANEyeToUseKey]) {
        case kUseLeftEye:
        default:
            inWindow = [window inWindowDeg:([task currentEyesDeg])[kLeftEye]];
            break;
        case kUseRightEye:
            inWindow = [window inWindowDeg:([task currentEyesDeg])[kRightEye]];
            break;
        case kUseBinocular:
            inWindow = [window inWindowDeg:([task currentEyesDeg])[kLeftEye]] && 
                                    [window inWindowDeg:([task currentEyesDeg])[kRightEye]];
            break;
    }
    return inWindow;
}

+ (NSString *)stringForStimDescEntry:(NSArray *)stimList entryIndex:(long)index;
{
    long stimIndex;
    NSString *string;
    StimDesc stimDesc;
    
    [[stimList objectAtIndex:index] getValue:&stimDesc];
    string = @"";
    for (stimIndex = 0; stimIndex < kStimLocs; stimIndex++) {
        if (stimDesc.listTypes[stimIndex] == kTargetStim) {
            if (stimIndex == stimDesc.attendLoc) {
                string = [NSString stringWithFormat:@"T%@", string];
            }
            else  {
                string = [NSString stringWithFormat:@"%@D", string];
            }
        }
    }
    if ([string isEqualToString:@""]) {
        stimIndex = stimDesc.stimTypes[kGabor0] * kRFStimTypes + stimDesc.stimTypes[kGabor1];
        string = [NSString stringWithFormat:@"%2ld", stimIndex];       
    }
    return string;
}

@end
