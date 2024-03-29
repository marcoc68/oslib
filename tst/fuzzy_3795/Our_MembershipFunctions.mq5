﻿//+------------------------------------------------------------------+ 
//|                                     Our MembershipFunctions.mq5 | 
//|                        Copyright 2016, MetaQuotes Software Corp. | 
//|                                             https://www.mql5.com | 
//+------------------------------------------------------------------+ 
#include <Math\Fuzzy\membershipfunction.mqh> 
#include <Graphics\Graphic.mqh> 
//--- Create membership functions 
//CZ_ShapedMembershipFunction func2(0.0, 0.6);
//CNormalMembershipFunction   func1(0.5, 0.2); 
//CS_ShapedMembershipFunction func3(0.4, 1.0);

 
//+------------------------------------------------------------------+ 
//| Script program start function                                    | 
//+------------------------------------------------------------------+ 
void OnStart() { 
    //verificarVariaveisVelVolume();
    verificarVariaveisAcelVolume();
}
  
//--------------------------- VELOCIDADE DO VOLUME -----------------------------
//--- Create membership functions 
   CZ_ShapedMembershipFunction func1(-1000, 40  );
   CNormalMembershipFunction   func2( 0   , 40  ); 
   CS_ShapedMembershipFunction func3(-40  , 1000);

//--- Create wrappers for membership functions 
   double ZShapedMembershipFunction(double x) { return(func1.GetValue(x)); }
   double NormalMembershipFunction1(double x) { return(func2.GetValue(x)); } 
   double SShapedMembershipFunction(double x) { return(func3.GetValue(x)); }
//--------------------------- VELOCIDADE DO VOLUME -----------------------------
void verificarVariaveisVelVolume() 
  { 
//--- create graphic 
   CGraphic graphic; 
   if(!graphic.Create(0,"VELOC_VOL_LIQ",0,30,30,780,380)){
       graphic.Destroy();
   }

   if(!graphic.Create(0,"VELOC_VOL_LIQ",0,30,30,780,380)) 
     { 
       graphic.Attach(0,"VELOC_VOL_LIQ"); 
     } 
   graphic.HistoryNameWidth(70); 
   graphic.BackgroundMain("VELOC_VOL_LIQ"); 
   graphic.BackgroundMainSize(16);
   //graphic.BackgroundSub("sub legenda");
   //graphic.BackgroundSubSize(16);
   Print("tamanho da fonte do nome da curva  padrao:",graphic.HistoryNameSize()  ); // padrao eh 12
   Print("tamanho do nome da curva em pixels padrao:",graphic.HistoryNameWidth() ); // padrao eh 70
   graphic.HistoryNameSize(20);
   graphic.HistoryNameWidth(200);
   Print("tamanho da fonte do nome da curva  novo:",graphic.HistoryNameSize()  );
   Print("tamanho do nome da curva em pixels novo:",graphic.HistoryNameWidth() );
   
//--- create curve 
 //graphic.CurveAdd(ZShapedMembershipFunction,0.0,1.0,0.01,CURVE_LINES,"[0.0, 0.6]func1CZ"); 
 //graphic.CurveAdd(NormalMembershipFunction1,0.0,1.0,0.01,CURVE_LINES,"[0.5, 0.2]func2Normal"); 
 //graphic.CurveAdd(SShapedMembershipFunction,0.0,1.0,0.01,CURVE_LINES,"[0.4, 1.0]func3CS"); 
   graphic.CurveAdd(ZShapedMembershipFunction,-1000,1000,100,CURVE_LINES,"[-1000,0040]func1CZ-vendendo"); 
   graphic.CurveAdd(NormalMembershipFunction1,-1000,1000,100,CURVE_LINES,"[ 0000,0040]func2Norm-neutro"); 
   graphic.CurveAdd(SShapedMembershipFunction,-1000,1000,100,CURVE_LINES,"[-0040,1000]func3CS-comprando"); 
//--- sets the X-axis properties 
   graphic.XAxis().AutoScale(false); 
 //graphic.XAxis().Min(0.0); 
 //graphic.XAxis().Max(1.0); 
   graphic.XAxis().Min(-1000.0); 
   graphic.XAxis().Max( 1000.0); 
   graphic.XAxis().DefaultStep(100); 
//--- sets the Y-axis properties 
   graphic.YAxis().AutoScale(false); 
   graphic.YAxis().Min(0.0); 
   graphic.YAxis().Max(1.1); 
   graphic.YAxis().DefaultStep(0.1); 
//--- plot 
   graphic.CurvePlotAll(); 
   graphic.Update(); 
  } 


//--------------------------- ACELERACAO DO VOLUME -----------------------------
//--- Create membership functions 
   CZ_ShapedMembershipFunction func1AC(-30, 3 );
   CNormalMembershipFunction   func2AC( 0 , 3 ); 
   CS_ShapedMembershipFunction func3AC(-3 , 30);

//--- Create wrappers for membership functions 
   double ZShapedMembershipFunctionAC(double x) { return(func1AC.GetValue(x)); }
   double NormalMembershipFunction1AC(double x) { return(func2AC.GetValue(x)); } 
   double SShapedMembershipFunctionAC(double x) { return(func3AC.GetValue(x)); }
//--------------------------- VELOCIDADE DO VOLUME -----------------------------
void verificarVariaveisAcelVolume() 
  { 
//--- create graphic 
   CGraphic graphic; 
   if(!graphic.Create(0,"ACELERACAO_VOL",0,30,30,780,380)){
       graphic.Destroy();
   }

   if(!graphic.Create(0,"ACELERACAO_VOL",0,30,30,780,380)) 
     { 
       graphic.Attach(0,"ACELERACAO_VOL"); 
     } 
   graphic.HistoryNameWidth(70); 
   graphic.BackgroundMain("ACELERACAO_VOL"); 
   graphic.BackgroundMainSize(16);
   //graphic.BackgroundSub("sub legenda");
   //graphic.BackgroundSubSize(16);
   graphic.HistoryNameSize(20);
   graphic.HistoryNameWidth(200);
   
//--- create curve 
   graphic.CurveAdd(ZShapedMembershipFunctionAC,-30,30,3,CURVE_LINES,"[-30, 3]func1CZ-freiando"); 
   graphic.CurveAdd(NormalMembershipFunction1AC,-30,30,3,CURVE_LINES,"[ 00, 3]func2Norm-mantendo"); 
   graphic.CurveAdd(SShapedMembershipFunctionAC,-30,30,3,CURVE_LINES,"[-3 ,30]func3CS-acelerando"); 
//--- sets the X-axis properties 
   graphic.XAxis().AutoScale(false); 
 //graphic.XAxis().Min(0.0); 
 //graphic.XAxis().Max(1.0); 
   graphic.XAxis().Min(-30.0); 
   graphic.XAxis().Max( 30.0); 
   graphic.XAxis().DefaultStep(3); 
//--- sets the Y-axis properties 
   graphic.YAxis().AutoScale(false); 
   graphic.YAxis().Min(0.0); 
   graphic.YAxis().Max(1.1); 
   graphic.YAxis().DefaultStep(0.1); 
//--- plot 
   graphic.CurvePlotAll(); 
   graphic.Update(); 
  }    