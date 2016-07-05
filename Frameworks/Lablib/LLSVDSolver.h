//
//  LLSVDSolver.h
//
//  Created by Erik Cook on 20/01/06.
//  Copyright 2006. All rights reserved.
//
//  Uses svdcmp and svbksb from Numerical Recipes in C
//
//	This solver was checked against Matlab's linear least squares.

#define		kMaxPoints	32			// maximum number of calibration points
#define		kUnknowns	3			// number of unknowns we are solving for

// The codes is taken from Numerical Recipes, where all arrays are 1 based.  Because we are
// zero based, we add one to the length of all array to satisfy the 1 based code.

@interface LLSVDSolver : NSObject {
	
	double					a[kMaxPoints+1][kUnknowns+1];
	double					A[kMaxPoints+1][kUnknowns+1];
	double					u[kMaxPoints+1][kUnknowns+1];
	double					b[kMaxPoints+1];
	double					v[kUnknowns+1][kUnknowns+1];
	double					w[kUnknowns+1];
	double					xx[kUnknowns+1];
	long					m;
	long					n;
	
	long					iminarg1;
	long					iminarg2;
	double					sqrarg;
	double					maxarg1;
	double					maxarg2;
}

-(double)pythagWitha:(double)a b:(double)b;
-(NSAffineTransformStruct)solveCalibration:(long)positions degPoints:(NSPoint *)pD unitPoints:(NSPoint *)pU;
-(void) svd;
-(void) svdcmp;
-(void) svbksb;
/*
-(void) printA;
-(void) printU;
-(void) printW;
-(void) printV;
-(void) printCheckSVD;
-(void) printB;
*/
@end

