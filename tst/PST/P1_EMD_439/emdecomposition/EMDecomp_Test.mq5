//------------------------------------------------------------------------------------
//                                                                   EMDecomp_Test.mq5
//                                                                       2012, victorg
//                                                                 http://www.mql5.com
//------------------------------------------------------------------------------------
#property copyright "2012, victorg"
#property link      "http://www.mql5.com"

#include "CEMDecomp.mqh"
#include "ChartTools\CLinDraw.mqh"
//------------------------------------------------------------------------------------
// Script program start function
//------------------------------------------------------------------------------------
void OnStart()
  {
  int i,j,k,m,n,ret;
  double xx[],yy[];

  n=320;
  ArrayResize(yy,n);
  ArrayResize(xx,n);
  for(i=0;i<n;i++)xx[i]=i;
  m=1;
  for(i=0;i<n;i++)
    {
    for(j=0;j<20;j++)
      {
      k=20*i+j;
      if(k<n)yy[k]=m;                         // Input sequence
      else break;
      }
    m=-1*m;
    }
  CEMDecomp *emd=new CEMDecomp();
  emd.FixedIter=0;                            // variable number of sifting iterations
  ret=emd.Decomp(yy);                         // Decomposition
  Print("ret=",ret,"   nIMF=",emd.nIMF);
//-------------------------- Visualization
  CLinDraw *ld=new CLinDraw;
  ld.Title("Empirical Mode Decomposition (EMD).");
  ld.SubTitle("Clicking on the name of the line (legend),"+
              " you can enable or disable the display of individual lines.");
  ld.YTitle("y");
  ld.XTitle("x");

  emd.GetIMF(yy,0);
  ld.AddGraph(xx,yy,"line","Data");
  for(i=1;i<emd.nIMF;i++)
    {
    emd.GetIMF(yy,i);
    ld.AddGraph(xx,yy,"line","IMF "+IntegerToString(i));
    }
  emd.GetIMF(yy,emd.nIMF);
  ld.AddGraph(xx,yy,"line","Res");
  ld.LDraw(1);                                // With autostart
//  ld.LDraw(0);                              // Without autostart
  delete(ld);
  delete(emd);
  }
//------------------------------------------------------------------------------------


