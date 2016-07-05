//
//  LLTrialBlock.h
//  Lablib
//
//  Created by John Maunsell on Sat Dec 27 2003.
//  Copyright (c) 2003. All rights reserved.
//

@interface LLTrialBlock : NSObject {

@protected
	long			blocks;				// number of blocks to do
	long			blocksDone;			// number of blocks completed
	long			currentTrialIndex;
	long			triesCount;
	long			trialsPerBlock;
	long			trialsRemainingCurrentBlock;
	long			*trials;
}

- (long)blocks;
- (long)blocksDone;
- (long)blocksRemaining;
- (void)countCurrentTrial:(BOOL)correct;
- (long)currentTrialIndex;
- (id)initWithTrialCount:(long)trialNum triesCount:(long)repeats blockCount:(long)blockCount;
- (void)newBlock;
- (long)nextTrialIndex;
- (void)reset;
- (void)setBlocks:(long)count;
- (void)setTrialCount:(long)count;
- (void)setTriesCount:(long)count;
- (long)trialsDoneCurrentBlock;
- (long)trialsPerBlock;
- (long)trialsRemaining;
- (long)trialsRemainingCurrentBlock;

@end
