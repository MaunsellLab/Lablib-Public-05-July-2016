//
//  LLEOTView.h
//  Lablib
//
//  Created by John Maunsell on Wed May 28 2003.
//  Copyright (c) 2003. All rights reserved.
//

@interface LLEOTView:NSView {

    long 	*pEOTData;
	long	eotTypes;
}

- (void)setData:(long *)pData;
- (void)setEOTTypes:(long)types;

@end
