//
//  LLUserDefaults.h
//  Lablib
//
//  Created by John Maunsell on 1/4/05.
//  Copyright 2005. All rights reserved.
//

@interface LLUserDefaults : NSUserDefaults {

	NSLock *defaultsLock;
}

@end
