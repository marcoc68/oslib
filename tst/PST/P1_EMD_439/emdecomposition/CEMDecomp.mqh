﻿//------------------------------------------------------------------------------------
//                                                                       CEMDecomp.mqh
//                                                                        Version 1.01
//                                                                       2012, victorg
//                                                                 http://www.mql5.com
//------------------------------------------------------------------------------------
#include <Object.mqh>
//------------------------------------------------------------------------------------
// The Empirical Mode Decomposition (EMD).
//------------------------------------------------------------------------------------
class CEMDecomp:public CObject
  {
public:
  int     N;                 // Input and output data size
  double  Mean;              // Mean of input data
  int     nIMF;              // IMF counter
  int     MaxIMF;            // Maximum number of IMF
  int     MaxIter;           // Maximum number of iterations
  int     FixedIter;         // 0-variable number of sifting iterations;
                             // 1-always ten sifting iterations.
  double  IMFResult[];       // Result.
private:
  double  X[];
  double  Imf[];
  double  XMax[];            // x of local maxima
  double  YMax[];            // y of local maxima
  double  XMin[];            // x of local minima
  double  YMin[];            // y of local minima
  double  EnvUpp[];          // Upper envelope
  double  EnvLow[];          // Lower envelope
  double  Eps;               // Accuracy comparison of floating-point numbers
  double  Tol;               // Accuracy of calculation IMF
public:  
  void    CEMDecomp(void);
  int     Decomp(double &y[]);          // Decomposition
  void    GetIMF(double &x[], int nn);  // Get IMF number nn
private:
  int     arrayprepare(void);
  void    extrema(double &y[],int &nmax,double &xmax[],double &ymax[],
                                 int &nmin,double &xmin[],double &ymin[]);
  int     SplineInterp(double &x[],double &y[],int n,double &x2[],
                                                double &y2[],int btype=0);
  };
//------------------------------------------------------------------------------------
// Constructor.
//------------------------------------------------------------------------------------
void CEMDecomp::CEMDecomp(void)
  {
  FixedIter=0;
  MaxIMF=16;                 // The maximum number of IMF
  MaxIter=2000;              // The maximum number of iterations
  Eps=8*DBL_EPSILON;         // Accuracy comparison of floating-point numbers
  Tol=1e-6;                  // Accuracy of calculation IMF
  }
//------------------------------------------------------------------------------------
// Decomposition.
// Input:
//  y[] - Input data
// Result:
//  nIMF - Number of IMF plus one;
//  IMFResult[0],...,IMFResult[N-1]                     - Input data minus mean;
//  IMFResult[1*N],...,IMFResult[1*N+N-1]               - IMF number 1;
//                                     . . .
//  IMFResult[(nIMF-1)*N],...,IMFResult[(nIMF-1)*N+N-1] - IMF number nIMF-1;
//  IMFResult[nIMF*N],...,IMFResult[nIMF*N+N-1]         - Residue of decomposition.
// Return:
//   0 - No error.
//  -1 - Insufficient length of the input data.
//  -2 - ArrayResize() error.
//------------------------------------------------------------------------------------
int CEMDecomp::Decomp(double &y[])
  {
  int i,j,iter,nmax,nmin,sstop;
  double a,b,c;
   
  N=ArraySize(y);
  if(N<6)
    {
    Print(__FUNCTION__,": Error! Insufficient length of the input data.");
    return(-1);
    }
  j=arrayprepare();
  if(j<0){Print(__FUNCTION__,": Error! ArrayResize() error."); return(-2);}
  Mean=0;
  for(i=0;i<N;i++)Mean+=(y[i]-Mean)/(i+1.0);   // Mean (average) of input data
  for(i=0;i<N;i++)
    {
    Imf[i]=y[i]-Mean;                          // Input data minus mean
    IMFResult[i]=Imf[i];                       // Input data minus mean
    }
  for(i=0;i<N;i++)X[i]=i;                      // X[] = 0,1,2, . . .,N-1
  if(MaxIMF<1){nIMF=1; return(0);}             // If MaxIMF < 1
// ----- The loop of decomposition
  nIMF=0;
  while(nIMF<MaxIMF)
    {
// ----- Find extremas
    a=Imf[0]; b=Imf[1]; j=0;
    for(i=1;i<N-1;i++)
      {
      c=Imf[i+1];
      if(MathAbs(b-c)>DBL_MIN+Eps*MathMax(MathAbs(b),MathAbs(c))) // b != c
        {
        if(((b>c)&&(b>a))||((b<c)&&(b<a)))j++;
        a=b; b=c;
        }
      }
    if(j<3)break;         // If less than three extremas then the end of decomposition
// ----- Sifting loop
    iter=0;
    while(iter<MaxIter)
      {
// ----- Find local extremas. Result --> XMin[],YMin[],XMax[],YMax[]
      extrema(Imf,nmax,XMax,YMax,nmin,XMin,YMin);
// ----- Upper and Lower envelope
      if(nmax<2)for(i=0;i<N;i++)EnvUpp[i]=Imf[i];
      else SplineInterp(XMax,YMax,nmax,X,EnvUpp);
      if(nmin<2)for(i=0;i<N;i++)EnvLow[i]=Imf[i];
      else SplineInterp(XMin,YMin,nmin,X,EnvLow);
      b=0; c=0;
// ----- Create current IMF
      for(i=0;i<N;i++)
        {
        a=Imf[i]-0.5*(EnvUpp[i]+EnvLow[i]);    // Current IMF
        b+=(Imf[i]-a)*(Imf[i]-a);
        c+=Imf[i]*Imf[i];
        Imf[i]=a;                              // Current IMF
        }
      if(FixedIter==0)
        {
// ----- If sstop==1 then stop sifting
        sstop=1;
        for(i=0;i<nmin;i++)if(YMin[i]>0)sstop=0;
        if(sstop==1)for(i=0;i<nmax;i++)if(YMax[i]<0)sstop=0;
// ----- Checking the accuracy of calculations
        if(sstop==1)
          {
          if(c<DBL_MIN)a=0.0;
          else a=b/c;                            // Relative accuracy
          if(a>Tol)sstop=0;
          }
        if(sstop==1)break;                       // Stop sifting
        }
      else if(iter>8)break;                      // always only ten iterations
      iter++;
      }
    if(iter>=MaxIter)
      Print(__FUNCTION__,": Warning! Reached the maximum number of iterations.");
// ----- Find extremas
    a=Imf[0]; b=Imf[1]; j=0;
    for(i=1;i<N-1;i++)
      {
      c=Imf[i+1];
      if(MathAbs(b-c)>DBL_MIN+Eps*MathMax(MathAbs(b),MathAbs(c))) // b != c
        {
        if(((b>c)&&(b>a))||((b<c)&&(b<a)))j++;
        a=b; b=c;
        }
      }
    if(j<1)break;         // If less than one extremas then the end of decomposition
// ---------- Saving results
    nIMF++;
    if(ArrayResize(IMFResult,N*(nIMF+1))!=N*(nIMF+1)) // Resize for current IMF
      {
      Print(__FUNCTION__,": Error! ArrayResize() error.");
      return(-2);
      }
    for(i=0;i<N;i++)
      {
      IMFResult[i+N*nIMF]=Imf[i];              // Save current IMF
      IMFResult[i]-=Imf[i];
      Imf[i]=IMFResult[i];                     // For the following calculations
      }
    }
// ----- Resize the array and save residue
    nIMF++;
    if(ArrayResize(IMFResult,N*(nIMF+1))!=N*(nIMF+1))
      {
      Print(__FUNCTION__+": Error! ArrayResize() error.");
      return(-2);
      }
   for(i=0;i<N;i++)
      {
      IMFResult[i+N*nIMF]=IMFResult[i];   // IMF number nIMF is the residue
      IMFResult[i]=y[i]-Mean;             // IMF number 0 is the input data minus Mean
      }
  return(0);
  }
//------------------------------------------------------------------------------------
// Setting the size of arrays.
// Return:
//  0 - no error
// -1 - ArrayResize error
//------------------------------------------------------------------------------------
int CEMDecomp::arrayprepare(void)
  {
  
  if(ArrayResize(IMFResult,N)!=N) return(-1);
  if(ArrayResize(X,N)!=N) return(-1);
  if(ArrayResize(Imf,N)!=N) return(-1);
  
  if(ArrayResize(XMax,N+4)!=N+4) return(-1);
  if(ArrayResize(YMax,N+4)!=N+4) return(-1);
  if(ArrayResize(XMin,N+4)!=N+4) return(-1);
  if(ArrayResize(YMin,N+4)!=N+4) return(-1);
  
  if(ArrayResize(EnvUpp,N)!=N) return(-1);
  if(ArrayResize(EnvLow,N)!=N) return(-1);

  return(0);
  }
//------------------------------------------------------------------------------------
// Get IMF number nn.
// Input:
//   nn  - IMF number:
//     nn=0;      - Input data minus mean;
//     nn=1;      - IMF number 1;
//      . . .
//     nn=nIMF-1; - IMF number nIMF-1;
//     nn=nIMF;   - Residue of decomposition.
// Output:
//   x[] - IMF number nn.
//------------------------------------------------------------------------------------
void CEMDecomp::GetIMF(double &x[], int nn)
  {
  int i,k;
  
  k=ArraySize(x);
  if(k>N)k=N;
  if(nn<0||nn>nIMF||nIMF==0)for(i=0;i<k;i++)x[i]=0.0;
  else for(i=0;i<k;i++)x[i]=IMFResult[i+N*nn];
  }
//------------------------------------------------------------------------------------
// Find local extremas and creation of boundary points.
//------------------------------------------------------------------------------------
void CEMDecomp::extrema(double &y[],int &nmax,double &xmax[],double &ymax[],
                                    int &nmin,double &xmin[],double &ymin[])
  {
  int i,nb;
  double a,b,c,e;
  
  nmax=0; nmin=0;
  for(i=1;i<N-1;i++)
    {
    a=y[i-1]; b=y[i]; c=y[i+1];
    e=DBL_MIN+Eps*MathMax(MathAbs(c),MathMax(MathAbs(b),MathAbs(a)));
    if(((a-b)<=e)&&((c-b)<=e)){xmax[2+nmax]=i; ymax[2+nmax++]=y[i];}
    if(((a-b)>=-e)&&((c-b)>=-e)){xmin[2+nmin]=i; ymin[2+nmin++]=y[i];}
    }
//------------ boundary points
  nb=2;
  while(nmin<nb+1&&nmax<nb+1)nb--;
  if(nb<2)
    {
    for(i=0;i<nmin;i++){xmin[i+nb]=xmin[i+2]; ymin[i+nb]=ymin[i+2];}
    for(i=0;i<nmax;i++){xmax[i+nb]=xmax[i+2]; ymax[i+nb]=ymax[i+2];}
    }
  if(nb==0)return;
  if(xmax[nb]<xmin[nb])
    {
    if(y[0]>ymin[nb])
      {
      if(2*xmax[nb]-xmin[2*nb-1]>0)
        {
        for(i=0;i<nb;i++)
          {
          xmax[i]=-xmax[2*nb-1-i];
          ymax[i]=ymax[2*nb-1-i];
          xmin[i]=-xmin[2*nb-1-i];
          ymin[i]=ymin[2*nb-1-i];
          }
        }
      else
        {
        for(i=0;i<nb;i++)
          {
          xmax[i]=2*xmax[nb]-xmax[2*nb-i];
          ymax[i]=ymax[2*nb-i];
          xmin[i]=2*xmax[nb]-xmin[2*nb-1-i];
          ymin[i]=ymin[2*nb-1-i];
          }
        }
      }
    else
      {
      for(i=0;i<nb;i++)
        {
        xmax[i]=-xmax[2*nb-1-i];
        ymax[i]=ymax[2*nb-1-i];
        }
      for(i=0;i<nb-1;i++)
        {
        xmin[i]=-xmin[2*nb-2-i];
        ymin[i]=ymin[2*nb-2-i];
        }
      xmin[nb-1]=0;
      ymin[nb-1]=y[0];
      }
    }
  else
    {
    if(y[0]<ymax[nb])
      {
      if(2*xmin[nb]-xmax[2*nb-1]>0)
        {
        for(i=0;i<nb;i++)
          {
          xmax[i]=-xmax[2*nb-1-i];
          ymax[i]=ymax[2*nb-1-i];
          xmin[i]=-xmin[2*nb-1-i];
          ymin[i]=ymin[2*nb-1-i];
          }
        }
      else
        {
        for(i=0;i<nb;i++)
          {
          xmax[i]=2*xmin[nb]-xmax[2*nb-1-i];
          ymax[i]=ymax[2*nb-1-i];
          xmin[i]=2*xmin[nb]-xmin[2*nb-i];
          ymin[i]=ymin[2*nb-i];
          }
        }
      }
    else
      {
      for(i=0;i<nb;i++)
        {
        xmin[i]=-xmin[2*nb-1-i];
        ymin[i]=ymin[2*nb-1-i];
        }
      for(i=0;i<nb-1;i++)
        {
        xmax[i]=-xmax[2*nb-2-i];
        ymax[i]=ymax[2*nb-2-i];
        }
      xmax[nb-1]=0;
      ymax[nb-1]=y[0];
      }
    }
  nmin+=nb-1;
  nmax+=nb-1;

  if(xmax[nmax]<xmin[nmin])
    {
    if(y[N-1]<ymax[nmax])
      {
      if(2*xmin[nmin]-xmax[nmax-nb+1]<(N-1))
        {
        for(i=0;i<nb;i++)
          {
          xmax[nmax+1+i]=2*(N-1)-xmax[nmax-i];
          ymax[nmax+1+i]=ymax[nmax-i];
          xmin[nmin+1+i]=2*(N-1)-xmin[nmin-i];
          ymin[nmin+1+i]=ymin[nmin-i];
          }
        }
      else
        {
        for(i=0;i<nb;i++)
          {
          xmax[nmax+1+i]=2*xmin[nmin]-xmax[nmax-i];
          ymax[nmax+1+i]=ymax[nmax-i];
          xmin[nmin+1+i]=2*xmin[nmin]-xmin[nmin-1-i];
          ymin[nmin+1+i]=ymin[nmin-1-i];
          }
        }
      }
    else
      {
      for(i=0;i<nb;i++)
        {
        xmin[nmin+1+i]=2*(N-1)-xmin[nmin-i];
        ymin[nmin+1+i]=ymin[nmin-i];
        }
      for(i=0;i<nb-1;i++)
        {
        xmax[nmax+2+i]=2*(N-1)-xmax[nmax-i];
        ymax[nmax+2+i]=ymax[nmax-i];
        }
      xmax[nmax+1]=N-1;
      ymax[nmax+1]=y[N-1];
      }
    }
  else
    {
    if(y[N-1]>ymin[nmin])
      {
      if(2*xmax[nmax]-xmin[nmin-nb+1]<(N-1))
        {
        for(i=0;i<nb;i++)
          {
          xmax[nmax+1+i]=2*(N-1)-xmax[nmax-i];
          ymax[nmax+1+i]=ymax[nmax-i];
          xmin[nmin+1+i]=2*(N-1)-xmin[nmin-i];
          ymin[nmin+1+i]=ymin[nmin-i];
          }
        }
      else
        {
        for(i=0;i<nb;i++)
          {
          xmax[nmax+1+i]=2*xmax[nmax]-xmax[nmax-1-i];
          ymax[nmax+1+i]=ymax[nmax-1-i];
          xmin[nmin+1+i]=2*xmax[nmax]-xmin[nmin-i];
          ymin[nmin+1+i]=ymin[nmin-i];
          }
        }
      }
    else
      {
      for(i=0;i<nb;i++)
        {
        xmax[nmax+1+i]=2*(N-1)-xmax[nmax-i];
        ymax[nmax+1+i]=ymax[nmax-i];
        }
      for(i=0;i<nb-1;i++)
        {
        xmin[nmin+2+i]=2*(N-1)-xmin[nmin-i];
        ymin[nmin+2+i]=ymin[nmin-i];
        }
      xmin[nmin+1]=N-1;
      ymin[nmin+1]=y[N-1];
      }
    }
  nmin=nmin+nb+1;
  nmax=nmax+nb+1;
  }
//------------------------------------------------------------------------------------
// Cubic spline Interpolation.
// Input:
//    x[] - Abscissa of input data points. The elements of the array x
//          must be strictly monotone increasing.
//    y[] - Ordinate of input data points.
//      n - Number of input data points.
//   x2[] - Abscissa of spline function points. The elements of the array x
//          must be strictly monotone increasing. x2 interval = [x[0],x[n-1]].
//  btype - Boundary points type. 0-natural spline, 1-parabolic.
// Output:
//   y2[] - Spline function.
// Return:
//      0 - No errors.
//     -1 - Arguments has wrong size.
//     -2 - ArrayResize() error.
// Notes:
//   Based on ALGLIB.
//------------------------------------------------------------------------------------
int CEMDecomp::SplineInterp(double &x[],double &y[],int n,double &x2[],
                                                    double &y2[],int btype=0)
  {
  int i,n2,intervalindex,pointindex;
  bool havetoadvance;
  double c0,c1,c2,c3,a,bb,w,w2,w3,fa,fb,da,db;
  double t,a1[],a2[],a3[],b[],d[];
  
  n2=ArraySize(x2);
  if(n>ArraySize(x)||n>ArraySize(y)||n2>ArraySize(y2)||n<2||n2<1)
    {
    Print(__FUNCTION__,": Error! Arguments has wrong size.");
    return(-1);
    }
  ArrayInitialize(y2,0);
  if(ArrayResize(a1,n)!=n)
    {
    Print(__FUNCTION__,": Error! ArrayResize() error.");
    return(-2);
    }
  if(ArrayResize(a2,n)!=n)
    {
    Print(__FUNCTION__,": Error! ArrayResize() error.");
    return(-2);
    }
  if(ArrayResize(a3,n)!=n)
    {
    Print(__FUNCTION__,": Error! ArrayResize() error.");
    return(-2);
    }
  if(ArrayResize(b,n)!=n)
    {
    Print(__FUNCTION__,": Error! ArrayResize() error.");
    return(-2);
    }
  if(ArrayResize(d,n)!=n)
    {
    Print(__FUNCTION__,": Error! ArrayResize() error.");
    return(-2);
    }
  for(i=1;i<=n-2;i++)
    {
    a1[i]=x[i+1]-x[i]; a2[i]=2*(x[i+1]-x[i-1]); a3[i]=x[i]-x[i-1];
    b[i]=3*(y[i]-y[i-1])/(x[i]-x[i-1])*(x[i+1]-x[i])+3*(y[i+1]-y[i])
                                        /(x[i+1]-x[i])*(x[i]-x[i-1]);
    }
  if(btype==1&&n==2)
    {
    d[0]=(y[1]-y[0])/(x[1]-x[0]);
    d[1]=d[0];
    }
  else
    {
    if(btype==1)
      {
      a1[0]=0; a2[0]=1; a3[0]=1;
      b[0]=2*(y[1]-y[0])/(x[1]-x[0]);
      a1[n-1]=1; a2[n-1]=1; a3[n-1]=0;
      b[n-1]=2*(y[n-1]-y[n-2])/(x[n-1]-x[n-2]);
      }
    else
      {
      a1[0]=0; a2[0]=2; a3[0]=1;
      b[0]=3*(y[1]-y[0])/(x[1]-x[0]);
      a1[n-1]=1; a2[n-1]=2; a3[n-1]=0;
      b[n-1]=3*(y[n-1]-y[n-2])/(x[n-1]-x[n-2]);
      }
    for(i=1;i<=n-1;i++)
      {
      t=a1[i]/a2[i-1];
      a2[i]=a2[i]-t*a3[i-1];
      b[i]=b[i]-t*b[i-1];
      }
    d[n-1]=b[n-1]/a2[n-1];
    for(i=n-2;i>=0;i--)d[i]=(b[i]-a3[i]*d[i+1])/a2[i];
    }
  c0=0; c1=0; c2=0; c3=0; a=0; bb=0;
  intervalindex=-1; pointindex=0;
  for(;;)
    {
    if(pointindex>=n2)break;
    t=x2[pointindex];
    havetoadvance=false;
    if(intervalindex==-1)havetoadvance=true;
    else if(intervalindex<n-2)havetoadvance=(t>=bb);
    if(havetoadvance)
      {
      intervalindex=intervalindex+1;
      a=x[intervalindex]; bb=x[intervalindex+1];
      w=bb-a; w2=w*w; w3=w*w2;
      fa=y[intervalindex]; fb=y[intervalindex+1];
      da=d[intervalindex]; db=d[intervalindex+1];
      c0=fa; c1=da;
      c2=(3*(fb-fa)-2*da*w-db*w)/w2;
      c3=(2*(fa-fb)+da*w+db*w)/w3;
      continue;
      }
    t=t-a;
    y2[pointindex]=c0+t*(c1+t*(c2+t*c3));
    pointindex=pointindex+1;
    }
  return(0);
  }
//------------------------------------------------------------------------------------