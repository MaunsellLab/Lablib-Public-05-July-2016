/*q_bestQuantileOrder() finds the quantile order that will maximize theexpected information, assuming a step psychometric function.HISTORY:1989? dgp	wrote it.8/31/91	dgp	rewrote it to handle an arbitrary number of possible responses.			I only recently worked out the theory for this. The solution is			now an iterative search instead of simple algebra. However, Newton's			method converges in a few iterations, and this will take negligible			time in most applications.8/31/94	dhb & dgp changed fprintf(stderr,...) to printf(...) for compatibility with MATLAB.*/#include <stdlib.h>#include <stdio.h>#include "q_include.h"static void DiDq(QCondition *qc,double q,double *d1,double *d2);#if GENERATING68881 && THINK_C	#define log(x) _log(x)	/* speed! */#endifdouble q_bestQuantileOrder(QCondition *qc){	double pE,pL,pH,d1,d2,dq,q;	int j;		if(0 && qc->nResponses==2){		/* Old code assumes only two possible responses. */		pL=qc->pResponse[1][0];		pH=qc->pResponse[1][qc->nnLevels-1];		pE=XLogX(pH)-XLogX(pL)+XLogX(1.0-pH)-XLogX(1.0-pL);		pE=1.0/(1.0+exp(pE/(pL-pH)));		q=(pE-pL)/(pH-pL);		return q;	}else{		/* New code allows for an arbitrary number of possible responses */		/* Use Newton's method to find zero of first derivative */		q=0.5;							/* initial guess */		for(j=0; j<20; j++) {			DiDq(qc,q,&d1,&d2);			dq=d1/d2;			q-=dq;			if (q<0.0||q>1.0) {				printf("q_bestQuantileOrder jumped out of legal range: %g\007\n",q);				return NAN;			}			if (fabs(dq)<1e-8) return q;		}		printf("q_bestQuantileOrder: too many iterations: q is %g\007\n",q);		return NAN;	}}/* first & second derivative of information w.r.t. quantileOrder q *//* Note that information is computed with log base e */static void DiDq(QCondition *qc,double q,double *d1,double *d2){	double pL,pH,pE;	int r;		*d1=*d2=0.0;	for(r=0; r<qc->nResponses; r++) {		if(qc->pResponse!=NULL){			pL=qc->pResponse[r][0];			pH=qc->pResponse[r][qc->nnLevels-1];		}else{//			pL=(*qc->function)(r,-qc->nLevels*qc->grain,qc->a[0],qc->a[1],qc->a[2],qc->a[3]);//			pH=(*qc->function)(r,qc->nLevels*qc->grain,qc->a[0],qc->a[1],qc->a[2],qc->a[3]);// Alas, that won't work because "function" and a[] are not in the qc struct, so quit.			printf("q_bestQuantileOrder: pResponse arrays missing.\007\n");			*d1=1.0;	// force error return			*d2=0.0;			break;		}		if(pL==pH)continue;		pE=q*pH+(1.0-q)*pL;		*d1+=XLogX(pH)-XLogX(pL)-(pH-pL)*log(pE);		*d2-=(pH-pL)*(pH-pL)/pE;	}}