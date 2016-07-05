//
//  LLMultiplierTransformer.h
//  Lablib
//
//  Created by John Maunsell on 12/18/04.
//  Copyright 2004. All rights reserved.
//

@interface LLMultiplierTransformer:NSValueTransformer {

	float multiplier;
}

- (float)multiplier;
- (void)setMultiplier:(float)newMultiplier;

@end
