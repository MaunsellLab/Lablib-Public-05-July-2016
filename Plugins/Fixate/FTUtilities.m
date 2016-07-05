//
//  FTUtilities.m
//  Fixate
//
//  Created by John Maunsell on 7/2/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import "FTUtilities.h"
#include "FT.h"

NSString *VCANEyeToUseKey = @"FTEyeToUse";

enum {kUseLeftEye = 0, kUseRightEye, kUseBinocular};

@implementation FTUtilities

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

@end
