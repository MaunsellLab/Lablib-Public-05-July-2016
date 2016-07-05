//
//  LLState.h
//  Lablib
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

@interface LLState : NSObject {

	BOOL warned;
}

- (void)stateAction;
- (NSString *)name;
- (LLState *)nextState;

@end
