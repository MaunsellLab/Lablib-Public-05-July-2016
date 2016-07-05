/*
q_include.h

header file for Quest library.

HISTORY
10/16/86	AF: Restructured QUEST
11/6/87		FW: use double vars everywhere
12/5/87		DGP: streamlined Q2Condition, and added comments.
			Added #ifndef conditional around whole file.
8/3/89		DGP: added ANSI prototypes of q_* functions
8/21/89		DGP: replaced q_machine.h by the appropriate ANSI C
			include files. Changed round() to return a double,
			as the SANE round() does.
8/30/91	dgp	Tidied up.
12/19/91 dgp Added q_Gaussian()
5/16/92	dgp	Tidied up. Renamed arguments and structure members to have names
			beginning with a lowercase letter.
12/29/93	dgp renamed _Q_INCLUDE_ to __Q_INCLUDE__				
8/15/94	dhb, ccc Added definition for INF	
8/16/94 ccc changed RESPONSES from 5 to 2			
8/31/94	dgp if necessary, define MATLAB as 0
9/1/94	dgp made compatible with the fp.h file which gets included on PowerPC
5/26/95 dgp prefer fp.h over math.h, for compatibility with VideoToolbox
6/13/95 dgp added definitions of GENERATINGPOWERPC,GENERATING68K,GENERATING68881.
3/29/96	dhb	Changed conditional for fp.h so that it works with THINK C 8.
4/1/96 dgp restored defs of GENERATING??? and added #undef round, to enhance portability,
			e.g. should work with or without VideoToolbox.h.
4/1/96	dgp removed "MAC_C" requirement for inclusion of fp.h. Tried to make VideoToolbox.h
		more consistent with q_include.h, so both will work separately or together, in
		either order, but I haven't checked whether I succeeded.
*/
#pragma once						/* prevent multiple inclusion of this file */
#ifndef __Q_INCLUDE__				/* prevent multiple inclusion of this file */
#define __Q_INCLUDE__

#include <stdio.h>					/* for q_print() */

#define UNIVERSAL_HEADERS 2			/* version 2; JHRM -- into the 21st century */
#undef	GENERATING68881
#undef  GENERATING68K
#define	GENERATING68K	0
#undef  GENERATINGPOWERPC
#define	GENERATINGPOWERPC	1

#if !defined(UNIVERSAL_HEADERS)
	#if defined(__MIXEDMODE__)
		#if defined(GENERATINGPOWERPC) || defined(GENERATING68K)
			#define UNIVERSAL_HEADERS 2	/* version 2 */
		#else
			#define UNIVERSAL_HEADERS 1	/* version 1 */
		#endif
	#else
		#define UNIVERSAL_HEADERS 0
	#endif
#endif

/*
Based on Apple's ConditionalMacros.h, so that our sources can use these
new macros without worrying about whether you've actually got the new headers (June '95)
in which they are first introduced. These definitions have no effect if
GENERATINGPOWERPC etc. are already defined. These macros also support early versions of
THINK C, which Apple's new headers don't support.
*/

#if !defined(GENERATINGPOWERPC) || !defined(GENERATING68K)
	#undef GENERATINGPOWERPC
	#undef GENERATING68K
	#if defined(powerc) || defined(__powerc)
		#define GENERATINGPOWERPC 1
		#define GENERATING68K 0
	#else
		#define GENERATINGPOWERPC 0
		#define GENERATING68K 1
	#endif
#endif

#if GENERATING68K && !defined(GENERATING68881)
	#if defined(applec) || defined(__SC__)
		#ifdef mc68881
			#define GENERATING68881 1
		#endif
	#else
		#if defined(THINK_C) && THINK_C==1		/* THINK C 4 */
			#define GENERATING68881 _MC68881_
		#endif
		#if defined(THINK_C) && THINK_C>1		/* THINK C 5,6,7,8 */
			#if __option(mc68881)
				#define GENERATING68881 1
			#endif
		#endif
		#ifdef __MWERKS__
			#if __MC68881__
				#define GENERATING68881 1
			#endif
		#endif
	#endif
#endif
#ifndef GENERATING68881
	#define GENERATING68881 0
#endif

#if !defined(__MATH__) && (UNIVERSAL_HEADERS>=2) && !THINK_C
	#include <fp.h>
#else
	#if GENERATINGPOWERPC || GENERATING68881
		/* as advised by math.h, we don't enable these if using 8-byte doubles on 68k */
		#undef _NOERRORCHECK_
		#undef _INLINE_FPU_CALLS_
		#define _NOERRORCHECK_ 1		/* encourage use of 8881 intrinsic functions */
		#define _INLINE_FPU_CALLS_ 1	/* encourage use of 8881 intrinsic functions */
	#endif
	#include <math.h>
	#if !defined(__FP__)	/* make sure that math.h hasn't included fp.h */
		#undef round
		#define round(x) floor(0.5+(x))	/* used by many VideoToolbox routines */
	#endif
#endif

/* In the limit as x->0, x log x = 0 */
#define XLogX(x) ( (x)==0.0 ? 0.0 : (x)*log(x) )
#define LN10	2.302585093
#define LN2		0.6931471806
#define exp10(x) exp((x)*LN10)
#ifndef NAN
	#define NAN		(0.0/0.0)	/* function return value on domain & range errors */		
#endif
#if !defined(INF)
	#ifdef INFINITY
		#define INF INFINITY
	#else
		#define INF	(1.0/0.0)		/* Infinity */
	#endif
#endif
#if !defined(MATLAB)
	#define MATLAB 0
#endif

/* These pre-processor macros convert among several different scales.
v 	represents the intensity "value," as received from and returned to the user.
l 	represents the intensity level, an internal integer scale, with
	zero at the user's threshold guess, and scaled by the user's
	specified grain.
i 	represents the index, from 0 to nLevels-1, of any of the 
	single-length tables: p, responses, trials, pInitial.
ii	represents the iindex, from 0 to nnLevels-1, of any of the 
	double-length tables: pResponse.
	
Note that these macros always use the value of nLevels or nnLevels out
of the supplied condition. As a result they work fine with the condB
condition in Q2Condition which typically has a different nLevels.
*/

#define vtol(qc,v) ((int)floor(0.5+((v) - (qc)->guess)/(qc)->grain))
#define ltov(qc,l) (((l) * (qc)->grain) + (qc)->guess)
#define ltoi(qc,l) ((l) + ( (qc->nLevels-1)/2) )
#define itol(qc,i) ((i) - ( (qc->nLevels-1)/2) )
#define vtoi(qc,v) ( ltoi( (qc), vtol( (qc), (v) ) ) )
#define itov(qc,i) ( ltov( (qc), itol( (qc), (i) ) ) )
#define iitol(qc,ii) ((ii) - (qc->nnLevels-1)/2)
#define ltoii(qc,l) ((l) + (qc->nnLevels-1)/2)
#define vtoii(qc,v) ( ltoii( (qc), vtol( (qc), (v) ) ) )
#define iitov(qc,ii) ( ltov( (qc), iitol( (qc), (ii) ) ) )

#define RESPONSES 2					/* number of possible responses */

#if RESPONSES<2
	#error "RESPONSES<2 There must be at least two possible responses"
#endif

typedef struct {
	double pTotal;					/* of p array */
	double entropy;					/* of p array */
	double variance;				/* of p array */
	double summedUpVariance;		/* Used by Brightest.c */
	double summedDownVariance;		/* Used by Brightest.c */
} PStatistics;

typedef struct  {
	/* Sampling grid determined by these:  */
	int nLevels;					/* size of all the tables, except pResponse */
	int nnLevels;					/* size of pResponse table =2*nLevels-1 */
	double grain;
	double guess;
	
	/* Probability/likelihood functions. */
	double *pInitial;				/* dimensioned nLevels */
	double *p;						/* dimensioned nLevels */
	double *pResponse[RESPONSES];	/* dimensioned nnLevels */
	double *H;						/* dimensioned nLevels, used by Brightest.c */
	double *likelihood;				/* dimensioned nLevels, used by Brightest.c */
	double *pSum;					/* dimensioned nLevels, used by Brightest.c */
	double pChosenIsMax;			/* used by Brightest.c */
	
	PStatistics initial,prior,now;	/* initial, prior to current trial, and now */

	short stimulated;				/* Boolean, used by Brightest.c */
	short isDelta;					/* Boolean, used by Brightest.c */
	short iiDelta;					/* used by Brightest.c */			

	/* Data: the observer's responses */
	int nResponses;					/* the number of possible responses */
	int *responses[RESPONSES];		/* response count, dimensioned nLevels */
	int *trials;					/* sum of responses[] over r, dimensioned nLevels */
	int trialsTotal;				/* sum of trials array */
	
	/* Number of trials to use pInitial probability before removing it: */
	int nInitial;
	
	/* The prior prob. of the latest response. */
	double pLatestResponse;
	
	/* For PEST */
	double Pstep;					/* size of the step in intensity */
	double Pintensity;				/* previous testing intensity of this condition */
	int Plast_doubled;				/* flag to indicate whether the step size was
									doubled before the last direction change */
	int Pjust_doubled;				/* flag to indicatie whether the step size has
									been doubled since the last direction change */
	int Preversals;					/* number of steps in the current direction */
	int Pcorrect;					/* number correct since last step */
	int Ptrials;					/* number of trials since last step */
	int Presponse;					/* response of subject at previous intensity */
	
	/* For transformed up-down simulations. */
	double u_run_start;				/* starting intensity of this run of trials */
	double u_psych_slope;			/* 0.5/b, b=slope of psych fcn at convergence */
	double u_step_size;				/* size of step when changing test intensity */
	int u_n_incorrect;				/* number incorrect at this test intensity */
	int u_n_correct;				/* number correct at this test intensity */
	double u_midpt_sum;				/* sum of midpoints of runs */
	double u_place;					/* next trial's test intensity */
	int u_n_size;					/* number of trials at this test intensity */
	int u_nreversals;				/* number of reversals */
	int u_direction;				/* trend of test intensity changes */
} QCondition;

typedef double (*PResponseFunction)(int response,double intensity
	,double beta,double gamma,double delta,double epsilon);


/* ANSI prototypes for the QuestSources */

/* q_brent.c */

double q_brent(double ax,double bx,double cx,double (*f)(),double tol,
	double *xmin);

/* q_copyCond.c */

void q_copyCond(QCondition *qc,QCondition *qcTemp);

/* q_entropy.c */

double q_entropy(QCondition *qc);

/* q_erralloc.c */

char *q_erralloc(const char *s,unsigned long n);

/* q_error.c */

double q_error(QCondition *qc);

/* q_findIntensity.c */

double q_findIntensity(double p,PResponseFunction function
	,int response,double *intensityPtr,double beta,double gamma,double delta
	,double epsilon);
	
/* q_freeCond.c */

void q_freeCond(QCondition **qc);

/* q_get.c */

int q_getResponse(QCondition *qc,double actual,double intensity);
int q_getBinomial(double p);
double q_getSample(QCondition *qc);

/* q_InitialGaussian.c */

void q_InitialGaussian(QCondition *qc,double sd);
void q_Gaussian(QCondition *qc,double sd);

/* q_makeCond.c */

void q_makeCond(QCondition **qcPtr,QCondition *qc0
	,int nResponses,int nLevels,double grain,double guess,int nInitial);

/* q_mean.c */

double q_mean(QCondition *qc);

/* q_minSweatFactor.c */

double q_minSweatFactor(PResponseFunction function
	,double beta,double gamma,double delta,double epsilon);
double q_sweatFactor(PResponseFunction function,double intensity
	,double beta,double gamma,double delta,double epsilon);

/* q_mode.c */

double q_mode(QCondition *qc);

/* q_plot.c */

void q_plot(QCondition *qc,int cond,double intensity,int response
	,int fakeIt,double actualThreshold);

/* q_print.c */

void q_print(FILE *file,int cond,QCondition *qc,double threshold_estimate
	,int fakeIt,double actualThreshold);

/* q_psych.c */

void q_psych(QCondition *qc,PResponseFunction function,double a1,double a2,double a3,
	double a4);

/* q_quantile.c */

double q_quantile(QCondition *qc,double quantileOrder);
double q_bestQuantileOrder(QCondition *qc);

/* q_response.c */

void q_response(QCondition *qc,PResponseFunction function,double a1,double a2,double a3,
	double a4);

/* q_updateCond.c */

int q_updateCond(QCondition *qc,double intensity,int response);
void q_setPrior(QCondition *qc);
void q_removePrior(QCondition *qc);
double q_total(QCondition *qc);

/* q_variance.c */

double q_variance(QCondition *qc);

/* q_Weibull.c */

double q_Weibull(int response,double intensity
	,double beta,double gamma,double delta,double epsilon);
double q_WeibullOld_psych(double intensity,double beta,double gamma,double delta,
	double epsilon);
double q_WeibullOld_response(double intensity,double beta,double gamma);


/* ANSI prototypes for QuestAdvancedSources */

#define		MAXBETAS		8
typedef struct  {
	QCondition qConds[MAXBETAS];	/* one for each beta */
	QCondition condA;				/* marginal pdf, summed across beta */
	QCondition condB;				/* marginal pdf, summed across alpha. Smaller nLevels */
} Q2Condition;						/* a super condition, allowing uncertainty in beta */

/* q2_.c */

void init_superconditions(Q2Condition **q2cPtr,int nConds,double initialsd,
	int nInitial,int nResponses,int nLevels,double grain,double *guess,
	int nLevelsB,double grainB,double guessB);
int q2_makeCond(Q2Condition **q2cPtr,Q2Condition *q2c0,int nInitial
	,int nResponses,int nLevels,double grain,double guess
	,int nLevelsB,double grainB,double guessB);
int q2_getResponse(Q2Condition *q2c,double actualA,double actualB,double intensity);
double q2_minECost(Q2Condition *q2c,Q2Condition *q2cTemp
	,double (*eCost)(Q2Condition *q2c,Q2Condition *q2cTemp,double intensity)
	,double *minECost);
int q2_updateCond(Q2Condition *q2c,double intensity,int response);
double q2_quantileA(Q2Condition *q2c,double quantileOrder);
double q2_ECostA(Q2Condition *q2c,Q2Condition *q2cTemp,double intensity,
	double (*cost)(QCondition *qc));
double q2_EVarianceA(Q2Condition *q2c,Q2Condition *q2cTemp,double intensity);
double q2_EEntropyA(Q2Condition *q2c,Q2Condition *q2cTemp,double intensity);
double q2_EEntropyAB(Q2Condition *q2c,Q2Condition *q2cTemp,double intensity);
double q2_entropyAB(Q2Condition *q2c);
double q2_varianceA(Q2Condition *q2c);
double q2_entropyA(Q2Condition *q2c);
int q2_copyCond(Q2Condition *q2c,Q2Condition *q2cTemp);

/* q_E.c */

double q_ECost(QCondition *qc,QCondition *qcTemp
	,double (*cost)(),double intensity);
double q_EEntropy(QCondition *qc,QCondition *qcTemp,double intensity);
double q_EVariance(QCondition *qc,QCondition *qcTemp,double intensity);

/* q_makeCrick.c */

void q_makeCrick(char *out_fname);

/* q_minECostN.c */

double q_minECostN(QCondition *qc,double (*cost)(QCondition *qc),double *bestintensity,int n);
double q_brentMin(double ax,double bx,double cx
	,double (*f)(QCondition *qc,QCondition *qcTemp,double (*cost)(QCondition *qc),double *xmin,
			int n,double x)
	,double tol,double *xmin
	,QCondition *qc,QCondition *qcTemp,double (*cost)(QCondition *qc),int n);
double q_ECostN(QCondition *qc,QCondition *qcTemp,double (*cost)(QCondition *qc),
	double *bestIntensity,int n,double intensity);

/* q_pest.c */

double q_pest(QCondition *qc,double target,double intensity,int response);

/* q_UDTR.c */

int u_update(QCondition *qc,double intensity,int response);
double u_placeNext(QCondition *qc);
int u_find_slope(QCondition *qc);
double u_thresh(QCondition *qc);

#endif /* __Q_INCLUDE__ */