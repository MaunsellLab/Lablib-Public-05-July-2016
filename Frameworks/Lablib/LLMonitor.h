/*
 *  LLMonitor.h
 *  Lablib
 *  
 *  Protocol specifying required methods for object that can make reports
 *
 *  Created by John Maunsell on Fri Apr 18 2003.
 *  Copyright (c) 2003. All rights reserved.
 *
 */

extern NSString *LLMonitorUpdated;

@protocol LLMonitor <NSObject>

- (NSString *)IDString;
- (BOOL)isConfigurable;
- (void)configure;
- (NSAttributedString *)report;

@end