/*
 *  LLIODevice.h
 *  Lablib
 *  
 *  Protocol specifying required methods for XT plots
 *
 *  Created by John Maunsell on Fri Apr 18 2003.
 *  Copyright (c) 2003. All rights reserved.
 *
 */

#import "LLViewScale.h"

@protocol LLXTPlot <NSObject>

- (void)clear;
- (void)setDurationS:(NSNumber *)durS;
- (void)setScale:(LLViewScale *)scaling;

@end