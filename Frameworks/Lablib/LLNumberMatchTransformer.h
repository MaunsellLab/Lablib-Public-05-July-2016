//
//  LLNumberMatchTransformer.h
//  Lablib
//
//  Created by John Maunsell on 3/11/07.
//  Copyright 2007. All rights reserved.
//

@interface LLNumberMatchTransformer : NSValueTransformer {

	NSMutableArray	*numbers;
}

- (void)addNumber:(NSValue *)newNumber;

@end
