//
//  LLViewUtilities.m
//  Lablib
//
//  Created by John Maunsell on Sat May 03 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLViewUtilities.h"


@implementation LLViewUtilities

+ (void) drawString:(NSString *)string centerAndBottomAtPoint:(NSPoint)point rotation:(float)rotateDeg
                withAttributes:(NSDictionary *)attr {

    float xOffset;
    NSAffineTransform *transform;
 
    xOffset = -[string sizeWithAttributes:attr].width / 2.0;
    if (rotateDeg == 0) {
        point.x += xOffset; 
        [string drawAtPoint:point withAttributes:attr];
    }
    else {
        transform = [NSAffineTransform transform];
        [transform translateXBy:point.x yBy:point.y];
        [transform rotateByDegrees:rotateDeg];
        [transform concat];
        [string drawAtPoint:NSMakePoint(xOffset, 0) withAttributes:attr];
        [transform invert];
        [transform concat];
    }
}

+ (void) drawString:(NSString *)string rightAndBottomAtPoint:(NSPoint)point rotation:(float)rotateDeg
                withAttributes:(NSDictionary *)attr {

    NSAffineTransform *transform;
    float xOffset, yOffset;
 	NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease];
   
    xOffset = -[string sizeWithAttributes:attr].width; 
    yOffset = -[layoutManager defaultLineHeightForFont:[NSFont userFontOfSize:0]];
    if (rotateDeg == 0.0) {
        point.x += xOffset; 
        point.y += yOffset;
        [string drawAtPoint:point withAttributes:attr];
    }
    else {
        transform = [NSAffineTransform transform];
        [transform translateXBy:point.x  yBy:point.y];
        [transform rotateByDegrees:rotateDeg];
        [transform concat];
        [string drawAtPoint:NSMakePoint(xOffset, yOffset) withAttributes:attr];
        [transform invert];
        [transform concat];
    }
}

+ (void) drawString:(NSString *)string rightAndCenterAtPoint:(NSPoint)point rotation:(float)rotateDeg
                withAttributes:(NSDictionary *)attr {

    NSAffineTransform *transform;
    float xOffset, yOffset;
	NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease];
        
    xOffset = -[string sizeWithAttributes:attr].width; 
    yOffset = -[layoutManager defaultLineHeightForFont:[NSFont userFontOfSize:0]] / 2.0;
    if (rotateDeg == 0.0) {
        point.x += xOffset; 
        point.y += yOffset;
        [string drawAtPoint:point withAttributes:attr];
    }
    else {
        transform = [NSAffineTransform transform];
        [transform translateXBy:point.x  yBy:point.y];
        [transform rotateByDegrees:rotateDeg];
        [transform concat];
        [string drawAtPoint:NSMakePoint(xOffset, yOffset) withAttributes:attr];
        [transform invert];
        [transform concat];
    }
}

+ (void) fillCircleAtScaledX:(float)scaledX scaledY:(float)scaledY withScale:(LLViewScale *)scale 
                radiusPix:(long)radiusPix {

    NSPoint pixPoint;
    
    pixPoint = [scale scaledPoint:NSMakePoint(scaledX, scaledY)];
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(pixPoint.x - radiusPix, pixPoint.y - radiusPix,
                    radiusPix * 2, radiusPix * 2)] fill];
}

@end
