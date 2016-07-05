//
//  LPlotColors.h
//  Lablib
//
//  Created by John Maunsell on Tue May 06 2003.
//  Copyright (c) 2003. All rights reserved.
//

#define kGuns			3

@interface LLPlotColors : NSObject {

@protected
    NSMutableArray	*colors;
    long			nextColorIndex;
}

-(id) initWithAlpha:(float)alpha;
-(void) initColorsWithAlpha:(float)alpha;
-(NSColor *)nextColor;
-(void) setNextColorIndex:(long)index;

@end
