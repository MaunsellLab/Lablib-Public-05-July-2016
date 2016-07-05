//
//  LLViewUtilities.h
//  Lablib
//
//  Created by John Maunsell on Sat May 03 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLViewScale.h"

@interface LLViewUtilities : NSObject {

}

+ (void) drawString:(NSString *)string centerAndBottomAtPoint:(NSPoint)point rotation:(float)rotateDeg
            withAttributes:(NSDictionary *)attr;
+ (void) drawString:(NSString *)string rightAndBottomAtPoint:(NSPoint)point rotation:(float)rotateDeg
                withAttributes:(NSDictionary *)attr;
+ (void) drawString:(NSString *)string rightAndCenterAtPoint:(NSPoint)point rotation:(float)rotateDeg
            withAttributes:(NSDictionary *)attr;
+ (void) fillCircleAtScaledX:(float)scaledX scaledY:(float)scaledY withScale:(LLViewScale *)scale 
                radiusPix:(long)radiusPix;

@end
