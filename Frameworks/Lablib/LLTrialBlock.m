//
//  LLTrialBlock.m
//  Lablib
//
//  Created by John Maunsell on Sat Dec 27 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLTrialBlock.h"


@implementation LLTrialBlock

// Return the number of blocks to do

- (long)blocks {

	return blocks;
}

// Return number of blocks done

- (long)blocksDone {
	
	return blocksDone;
}

// Return number of blocks left to do

- (long)blocksRemaining {
	
	return blocks - blocksDone;
}

- (void)countCurrentTrial:(BOOL)correct {

	if (correct  || (--trials[currentTrialIndex] == 0)) {
		trials[currentTrialIndex] = 0;
		trialsRemainingCurrentBlock--;
	}
	if (trialsRemainingCurrentBlock == 0) {
		[self newBlock];
	}
}
	
- (long)currentTrialIndex;
{
	return currentTrialIndex;
}

- (void)dealloc {

	if (trials != nil) {
		free(trials);
	}
	[super dealloc];
}

- (id)initWithTrialCount:(long)trialNum triesCount:(long)repeats blockCount:(long)blockCount {

	if ((self = [super init]) != nil) {
		blocks = blockCount;
		triesCount = repeats;
		[self setTrialCount:trialNum];
	}
	return self;
}

- (long)nextTrialIndex {
	
	long offset;
	
	if ([self blocksRemaining] == 0 || trialsPerBlock < 0) {
		return -1;
	}
	offset = rand() % trialsRemainingCurrentBlock;		// random offset from starting point
	currentTrialIndex = rand() % trialsPerBlock;		// random starting point
	do {
		currentTrialIndex = (currentTrialIndex + 1) % trialsPerBlock;
		while (trials[currentTrialIndex] == 0) {
			currentTrialIndex = (currentTrialIndex + 1) % trialsPerBlock;
		}
	} while (--offset > 0);
	return currentTrialIndex;
}	

// Reset for a new block

- (void)newBlock {

	long index;
	
	for (index = 0; index < trialsPerBlock; index++) {
		trials[index] = triesCount;
	}
	trialsRemainingCurrentBlock = trialsPerBlock;
	blocksDone++;
}

// Reset all counters

- (void)reset {

	[self newBlock];
	blocksDone = 0;
}

// Set the number of block of trials to complete

- (void)setBlocks:(long)count {

	blocks = count;
}


// Set the number of different trial types in the block

- (void)setTrialCount:(long)count {

	if (count != trialsPerBlock) {
		trialsPerBlock = MAX(0, count);
		if (trials != nil) {
			free(trials);
		}
		trials = malloc(trialsPerBlock * sizeof(long));
		[self reset];
	}
}

// Set how often each trial type will be done in one block

- (void)setTriesCount:(long)count {

	triesCount = count;
}

// Return the number of trials done in the current block

- (long)trialsDoneCurrentBlock {

	return trialsPerBlock - trialsRemainingCurrentBlock;
}

// Return the number of trials per block

- (long)trialsPerBlock {

	return trialsPerBlock;
}

// Return the number of trials remaining in all blocks

- (long)trialsRemaining {

	return [self blocksRemaining] * trialsPerBlock + trialsRemainingCurrentBlock;
}
// Return the number of trials remaining in the current block

- (long)trialsRemainingCurrentBlock {

	return trialsRemainingCurrentBlock;
}

@end
