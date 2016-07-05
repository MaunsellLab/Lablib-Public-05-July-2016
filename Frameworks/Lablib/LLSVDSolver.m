//
//  SVDSolver.m
//
//  Created by Erik Cook on 20/01/06.
//  Copyright 2006. All rights reserved.
//

#import "LLSVDSolver.h"

#define FMAX(a,b) (maxarg1=(a),maxarg2=(b),(maxarg1) > (maxarg2) ?\
				   (maxarg1) : (maxarg2))
#define IMIN(a,b) (iminarg1=(a),iminarg2=(b),(iminarg1) < (iminarg2) ?\
				   (iminarg1) : (iminarg2))
#define SIGN(a,b) ((b) >= 0.0 ? fabs(a) : -fabs(a))
#define SQR(a) ((sqrarg=(a)) == 0.0 ? 0.0 : sqrarg*sqrarg)

@implementation LLSVDSolver

-(double)pythagWitha:(double)aa b:(double)bb;
{	
	double absa, absb;
	
	absa = fabs(aa);
	absb = fabs(bb);
	if (absa > absb) {
		return absa*sqrt(1.0+SQR(absb/absa));
	}
	else {
		return (absb == 0.0 ? 0.0 : absb*sqrt(1.0+SQR(absa/absb)));
	}
}

-(NSAffineTransformStruct)solveCalibration:(long)positions degPoints:(NSPoint *)pD unitPoints:(NSPoint *)pU;
{
	long i;
	NSAffineTransformStruct	calibration;
	
	NSParameterAssert(positions >= 0 && positions < kMaxPoints);

	m = positions; 
	n = kUnknowns;
//	calPositions = positions;
//	for (i = 0; i < m; i++) {
//		pDeg[i + 1] = pD[i];
//		pUnit[i + 1] = pU[i];
//	}

// construct design matrix A

	for (i = 1; i <= m; i++) {
		A[i][1] = pU[i - 1].x;
		A[i][2] = pU[i - 1].y;
		A[i][3] = 1;
	}
	[self svd];						// Perform svd.  sets a u w v
	
// solve for m11 m21 tX

	for (i=1; i <= m; i++) {
		b[i] = pD[i - 1].x;
	}
//	[self printB];
	[self svbksb]; // Uses svd results to solve system.  sets xx
	calibration.m11 = xx[1];
	calibration.m21 = xx[2];
	calibration.tX = xx[3];
	
// solve for m12 m22 tY

	for (i = 1; i<= m; i++) {
		b[i] = pD[i - 1].y;
	}
//	[self printB];
	[self svbksb]; // Uses svd results to solve system.  sets xx
	calibration.m12 = xx[1];
	calibration.m22 = xx[2];
	calibration.tY = xx[3];

	return calibration;	
}
	
-(void) svd {
	
	long i,j;
	double wmax, wmin;
	
	for (i=1; i<=m; i++) 
		for (j=1; j<=n; j++) a[i][j] = A[i][j];

	[self svdcmp];  // sets a w and v
	
	// check for singular values
	wmax = 0.0;
	for (i=1; i<=n; i++) if (w[i] > wmax) wmax = w[i];
	wmin = wmax*1.0e-9;
	for (i=1; i<=n; i++) {
		if (w[i] < wmin) {
			w[i] = 0.0;
			NSLog(@"*** WARNING: singular values detected in ECSVDsolver!");
		}
	}
	
	// assign u
	for (i=1; i<=m; i++) 
		for (j=1; j<=n; j++) u[i][j] = a[i][j];
/*	
	[self printA];
	[self printU];
	[self printW];
	[self printV];
	[self printCheckSVD];  // this is the key check of the svd.  Should produce design matrix.
*/	
}

/*
-(void) printA {
	
	long i;
	
	NSLog(@"A = ");
	for (i=1; i<=m; i++) NSLog(@"	%f  %f  %f", A[i][1], A[i][2], A[i][3]);
}


-(void) printU {
	
	long i;
	
	NSLog(@"U = ");
	for (i=1; i<=m; i++) NSLog(@"	%f  %f  %f", u[i][1], u[i][2], u[i][3]);
}

-(void) printW {
		
	NSLog(@"W = ");
	NSLog(@"	%f  %f  %f", w[1], 0.0, 0.0);
	NSLog(@"	%f  %f  %f", 0.0, w[2], 0.0);
	NSLog(@"	%f  %f  %f", 0.0, 0.0, w[3]);
}	

-(void) printV {
	
	long i;
	
	NSLog(@"V = ");
	for (i=1; i<=n; i++) NSLog(@"	%f  %f  %f", v[i][1], v[i][2], v[i][3]);
}


-(void) printB {
	
	long i;
	
	NSLog(@"B = ");
	for (i=1; i<=m; i++) NSLog(@"	%f", b[i]);
}


-(void) printCheckSVD {
	
	long i, j, k;
	double uw[kMaxPoints+1][kUnknowns+1], wf[kUnknowns+1][kUnknowns+1], vt[kUnknowns+1][kUnknowns+1], uwvt[kMaxPoints+1][kUnknowns+1];
	
	for (i=1; i<=n; i++)
		for (j=1; j<=n; j++)
			wf[i][j] = 0;
	for (i=1; i<=n; i++) wf[i][i] = w[i];		
	
	
	for (i=1; i<=m; i++) {
		for (j=1; j<=n; j++) {
			uw[i][j] = 0;
			for (k=1; k<=n; k++) uw[i][j] += u[i][k] * wf[k][j];
		}
	}
	
	for (i=1; i<=n; i++) 
		for (j=1; j<=n; j++) 
			vt[i][j] = v[j][i];
	
	
	for (i=1; i<=m; i++) {
		for (j=1; j<=n; j++) {
			uwvt[i][j] = 0;
			for (k=1; k<=n; k++) uwvt[i][j] += uw[i][k] * vt[k][j];
		}
	}
	
	NSLog(@"uwvt = ");
	for (i=1; i<=m; i++) NSLog(@"	%f  %f  %f", uwvt[i][1], uwvt[i][2], uwvt[i][3]);
}
*/			
	

//void svdcmp(double **a, int m, int n, double w[], double **v)
-(void) svdcmp;
{	
	//double pythag(double a, double b);
	long flag,i,its,j,jj,k,l,nm;
	//double anorm,c,f,g,h,s,scale,x,y,z,*rv1;
	double anorm,c,f,g,h,s,scale,x,y,z,rv1[kUnknowns+1];
	
	//rv1=vector(1,n);
	g=scale=anorm=0.0;
	for (i=1;i<=n;i++) {
		l=i+1;
		rv1[i]=scale*g;
		g=s=scale=0.0;
		if (i <= m) {
			for (k=i;k<=m;k++) scale += fabs(a[k][i]);
			if (scale) {
				for (k=i;k<=m;k++) {
					a[k][i] /= scale;
					s += a[k][i]*a[k][i];
				}
				f=a[i][i];
				g = -SIGN(sqrt(s),f);
				h=f*g-s;
				a[i][i]=f-g;
				for (j=l;j<=n;j++) {
					for (s=0.0,k=i;k<=m;k++) s += a[k][i]*a[k][j];
					f=s/h;
					for (k=i;k<=m;k++) a[k][j] += f*a[k][i];
				}
				for (k=i;k<=m;k++) a[k][i] *= scale;
			}
		}
		w[i]=scale *g;
		g=s=scale=0.0;
		if (i <= m && i != n) {
			for (k=l;k<=n;k++) scale += fabs(a[i][k]);
			if (scale) {
				for (k=l;k<=n;k++) {
					a[i][k] /= scale;
					s += a[i][k]*a[i][k];
				}
				f=a[i][l];
				g = -SIGN(sqrt(s),f);
				h=f*g-s;
				a[i][l]=f-g;
				for (k=l;k<=n;k++) rv1[k]=a[i][k]/h;
				for (j=l;j<=m;j++) {
					for (s=0.0,k=l;k<=n;k++) s += a[j][k]*a[i][k];
					for (k=l;k<=n;k++) a[j][k] += s*rv1[k];
				}
				for (k=l;k<=n;k++) a[i][k] *= scale;
			}
		}
		anorm=FMAX(anorm,(fabs(w[i])+fabs(rv1[i])));
	}
	for (i=n;i>=1;i--) {
		if (i < n) {
			if (g) {
				for (j=l;j<=n;j++)
					v[j][i]=(a[i][j]/a[i][l])/g;
				for (j=l;j<=n;j++) {
					for (s=0.0,k=l;k<=n;k++) s += a[i][k]*v[k][j];
					for (k=l;k<=n;k++) v[k][j] += s*v[k][i];
				}
			}
			for (j=l;j<=n;j++) v[i][j]=v[j][i]=0.0;
		}
		v[i][i]=1.0;
		g=rv1[i];
		l=i;
	}
	for (i=IMIN(m,n);i>=1;i--) {
		l=i+1;
		g=w[i];
		for (j=l;j<=n;j++) a[i][j]=0.0;
		if (g) {
			g=1.0/g;
			for (j=l;j<=n;j++) {
				for (s=0.0,k=l;k<=m;k++) s += a[k][i]*a[k][j];
				f=(s/a[i][i])*g;
				for (k=i;k<=m;k++) a[k][j] += f*a[k][i];
			}
			for (j=i;j<=m;j++) a[j][i] *= g;
		} else for (j=i;j<=m;j++) a[j][i]=0.0;
		++a[i][i];
	}
	for (k=n;k>=1;k--) {
		for (its=1;its<=30;its++) {
			flag=1;
			for (l=k;l>=1;l--) {
				nm=l-1;
				if ((double)(fabs(rv1[l])+anorm) == anorm) {
					flag=0;
					break;
				}
				if ((double)(fabs(w[nm])+anorm) == anorm) break;
			}
			if (flag) {
				c=0.0;
				s=1.0;
				for (i=l;i<=k;i++) {
					f=s*rv1[i];
					rv1[i]=c*rv1[i];
					if ((double)(fabs(f)+anorm) == anorm) break;
					g=w[i];
					h=[self pythagWitha:f b:g];
					w[i]=h;
					h=1.0/h;
					c=g*h;
					s = -f*h;
					for (j=1;j<=m;j++) {
						y=a[j][nm];
						z=a[j][i];
						a[j][nm]=y*c+z*s;
						a[j][i]=z*c-y*s;
					}
				}
			}
			z=w[k];
			if (l == k) {
				if (z < 0.0) {
					w[k] = -z;
					for (j=1;j<=n;j++) v[j][k] = -v[j][k];
				}
				break;
			}
			if (its == 30) NSLog(@"no convergence in 30 svdcmp iterations");
			x=w[l];
			nm=k-1;
			y=w[nm];
			g=rv1[nm];
			h=rv1[k];
			f=((y-z)*(y+z)+(g-h)*(g+h))/(2.0*h*y);
			g=[self pythagWitha:f b:1.0];
			f=((x-z)*(x+z)+h*((y/(f+SIGN(g,f)))-h))/x;
			c=s=1.0;
			for (j=l;j<=nm;j++) {
				i=j+1;
				g=rv1[i];
				y=w[i];
				h=s*g;
				g=c*g;
				z=[self pythagWitha:f b:h];
				rv1[j]=z;
				c=f/z;
				s=h/z;
				f=x*c+g*s;
				g = g*c-x*s;
				h=y*s;
				y *= c;
				for (jj=1;jj<=n;jj++) {
					x=v[jj][j];
					z=v[jj][i];
					v[jj][j]=x*c+z*s;
					v[jj][i]=z*c-x*s;
				}
				z=[self pythagWitha:f b:h];
				w[j]=z;
				if (z) {
					z=1.0/z;
					c=f*z;
					s=h*z;
				}
				f=c*g+s*y;
				x=c*y-s*g;
				for (jj=1;jj<=m;jj++) {
					y=a[jj][j];
					z=a[jj][i];
					a[jj][j]=y*c+z*s;
					a[jj][i]=z*c-y*s;
				}
			}
			rv1[l]=0.0;
			rv1[k]=f;
			w[k]=x;
		}
	}
	//free_vector(rv1,1,n);
}

//void svbksb(double **u, double w[], double **v, long m, long n, double b[], double x[])
-(void) svbksb {
	
	long jj,j,i;
	//double s,*tmp;
	double s,tmp[kUnknowns+1];
	
	//tmp=vector(1,n);
	for (j=1;j<=n;j++) {
		s=0.0;
		if (w[j]) {
			for (i=1;i<=m;i++) s += u[i][j]*b[i];
			s /= w[j];
		}
		tmp[j]=s;
	}
	for (j=1;j<=n;j++) {
		s=0.0;
		for (jj=1;jj<=n;jj++) s += v[j][jj]*tmp[jj];
		xx[j]=s;
	}
}

@end


