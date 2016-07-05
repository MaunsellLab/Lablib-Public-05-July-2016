//
//  LLViewScale.h
//  Lablib
//
//  Created by John Maunsell on Fri May 02 2003.
//  Copyright (c) 2003. All rights reserved.
//

@interface LLViewScale : NSObject {

@protected
    BOOL			autoAdjustYMax;
    BOOL			autoAdjustYMin;
    NSRect			scaleRect;
    NSRect 			viewRect;
    NSMutableArray	*yMaxs;
    NSMutableArray	*yMaxMinViewArray;
    NSMutableArray	*yMins;
}

- (BOOL)autoAdjustYMin:(float)yMin yMax:(float)yMax object:(id)obj;
- (float)height;
- (long)pixYInc:(float)yScaledInc;
- (NSPoint) scaledPoint:(NSPoint)point;
- (long)scaledX:(float)x;
- (long)scaledXInc:(float)xScaledInc;
- (long)scaledY:(float)y;
- (long)scaledYInc:(float)yScaledInc;
- (NSRect)scaleRect;
- (NSRect)scaledRect:(NSRect)userRect;
- (void)setAutoAdjustYMax:(BOOL)state;
- (void)setAutoAdjustYMin:(BOOL)state;
- (void)setScaleRect:(NSRect)rect;
- (void)setHeight:(float)height;
- (void)setWidth:(float)width;
- (void)setXOrigin:(float)xOrigin;
- (void)setXOrigin:(float)xOrigin width:(float)width;
- (void)setYOrigin:(float)yOrigin;
- (void)setYOrigin:(float)xOrigin height:(float)height;
- (void)setViewRectForScale:(NSRect)rectPix;
- (NSRect)viewRect;
- (float)width;
- (float)xMax;
- (float)xMin;
- (float)yMax;
- (float)yMin;
- (float)xOrigin;
- (float)yOrigin;

@end
