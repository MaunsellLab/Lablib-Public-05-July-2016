//
//  LLNumberNonMatchTransformer.m
//  Lablib
//
//  Created by John Maunsell on 3/11/07.
//  Copyright 2007. All rights reserved.
//

#import "LLNumberNonMatchTransformer.h"

@implementation LLNumberNonMatchTransformer

- (id)transformedValue:(id)number;
{
	return [NSNumber numberWithBool:([[super transformedValue:number] boolValue] ? NO : YES)];
}

@end
