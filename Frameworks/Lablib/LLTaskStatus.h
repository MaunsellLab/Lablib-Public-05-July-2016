//
//  LLTaskStatus.h
//
//  Created by John Maunsell on Tue Sep 16 2003.
//  Copyright (c) 2005. All rights reserved.
//

#import "LLStandardDataEvents.h"

@interface LLTaskStatus : NSObject {

	BOOL		dataFileOpen;
	long		mode;
}

- (BOOL)dataFileOpen;
- (BOOL)isEnding;
- (BOOL)isIdle;
- (BOOL)isStopping;
- (long)mode;
- (void)setDataFileOpen:(BOOL)state;
- (void)setMode:(long)newMode;
- (long)status;

@end
