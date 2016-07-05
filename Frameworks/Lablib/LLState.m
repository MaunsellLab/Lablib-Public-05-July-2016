//
//  LLState.m
//  Lablib
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLState.h"

@implementation LLState

- (void)stateAction {

}

- (NSString *)name {

    return @"-- unnamed LLState --";
}

- (LLState *)nextState {
    
    if (!warned) {
        NSLog(@"LLState named \"%@\" fails to override its nextState method.", [self name]);
        warned = YES;
    }
	return nil;
}

@end
