//+------------------------------------------------------------------+
//|                                                     fuzzynet.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//| Implementation of FuzzyNet library in MetaQuotes Language 5(MQL5)|
//|                                                                  |
//| The features of the FuzzyNet library include:                    |
//| - Create Mamdani fuzzy model                                     |
//| - Create Sugeno fuzzy model                                      |
//| - Normal membership function                                     |
//| - Triangular membership function                                 |
//| - Trapezoidal membership function                                |
//| - Constant membership function                                   |
//| - Defuzzification method of center of gravity (COG)              |
//| - Defuzzification method of bisector of area (BOA)               |
//| - Defuzzification method of mean of maxima (MeOM)                |
//|                                                                  |
//| If you find any functional differences between FuzzyNet for MQL5 |
//| and the original FuzzyNet project , please contact developers of |
//| MQL5 on the Forum at www.mql5.com.                               |
//|                                                                  |
//| You can report bugs found in the computational algorithms of the |
//| FuzzyNet library by notifying the FuzzyNet project coordinators  |
//+------------------------------------------------------------------+
//|                         SOURCE LICENSE                           |
//|                                                                  |
//| This program is free software; you can redistribute it and/or    |
//| modify it under the terms of the GNU General Public License as   |
//| published by the Free Software Foundation (www.fsf.org); either  |
//| version 2 of the License, or (at your option) any later version. |
//|                                                                  |
//| This program is distributed in the hope that it will be useful,  |
//| but WITHOUT ANY WARRANTY; without even the implied warranty of   |
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the     |
//| GNU General Public License for more details.                     |
//|                                                                  |
//| A copy of the GNU General Public License is available at         |
//| http://www.fsf.org/licensing/licenses                            |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property script_show_inputs
//+------------------------------------------------------------------+
//| Connecting libraries                                             |
//+------------------------------------------------------------------+
#include <Math\Fuzzy\SugenoFuzzySystem.mqh>
//--- input parameters
input double   Speed_Error;
input double   Speed_ErrorDot;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//--- Sugeno Fuzzy System  
   CSugenoFuzzySystem *fsCruiseControl=new CSugenoFuzzySystem();
//--- Create first input variables for the system
   CFuzzyVariable *fvSpeedError=new CFuzzyVariable("SpeedError",-20.0,20.0);
   fvSpeedError.Terms().Add(new CFuzzyTerm("slower",new CTriangularMembershipFunction(-35.0,-20.0,-5.0)));
   fvSpeedError.Terms().Add(new CFuzzyTerm("zero", new CTriangularMembershipFunction(-15.0, -0.0, 15.0)));
   fvSpeedError.Terms().Add(new CFuzzyTerm("faster", new CTriangularMembershipFunction(5.0, 20.0, 35.0)));
   fsCruiseControl.Input().Add(fvSpeedError);
//--- Create second input variables for the system
   CFuzzyVariable *fvSpeedErrorDot=new CFuzzyVariable("SpeedErrorDot",-5.0,5.0);
   fvSpeedErrorDot.Terms().Add(new CFuzzyTerm("slower", new CTriangularMembershipFunction(-9.0, -5.0, -1.0)));
   fvSpeedErrorDot.Terms().Add(new CFuzzyTerm("zero", new CTriangularMembershipFunction(-4.0, -0.0, 4.0)));
   fvSpeedErrorDot.Terms().Add(new CFuzzyTerm("faster", new CTriangularMembershipFunction(1.0, 5.0, 9.0)));
   fsCruiseControl.Input().Add(fvSpeedErrorDot);
//--- Create Output
   CSugenoVariable *svAccelerate=new CSugenoVariable("Accelerate");
   double coeff1[3]={0.0,0.0,0.0};
   svAccelerate.Functions().Add(fsCruiseControl.CreateSugenoFunction("zero",coeff1));
   double coeff2[3]={0.0,0.0,1.0};
   svAccelerate.Functions().Add(fsCruiseControl.CreateSugenoFunction("faster",coeff2));
   double coeff3[3]={0.0,0.0,-1.0};
   svAccelerate.Functions().Add(fsCruiseControl.CreateSugenoFunction("slower",coeff3));
   double coeff4[3]={-0.04,-0.1,0.0};
   svAccelerate.Functions().Add(fsCruiseControl.CreateSugenoFunction("func",coeff4));
   fsCruiseControl.Output().Add(svAccelerate);
//--- Craete Sugeno fuzzy rule
   CSugenoFuzzyRule *rule1 = fsCruiseControl.ParseRule("if (SpeedError is slower) and (SpeedErrorDot is slower) then (Accelerate is faster)");
   CSugenoFuzzyRule *rule2 = fsCruiseControl.ParseRule("if (SpeedError is slower) and (SpeedErrorDot is zero) then (Accelerate is faster)");
   CSugenoFuzzyRule *rule3 = fsCruiseControl.ParseRule("if (SpeedError is slower) and (SpeedErrorDot is faster) then (Accelerate is zero)");
   CSugenoFuzzyRule *rule4 = fsCruiseControl.ParseRule("if (SpeedError is zero) and (SpeedErrorDot is slower) then (Accelerate is faster)");
   CSugenoFuzzyRule *rule5 = fsCruiseControl.ParseRule("if (SpeedError is zero) and (SpeedErrorDot is zero) then (Accelerate is func)");
   CSugenoFuzzyRule *rule6 = fsCruiseControl.ParseRule("if (SpeedError is zero) and (SpeedErrorDot is faster) then (Accelerate is slower)");
   CSugenoFuzzyRule *rule7 = fsCruiseControl.ParseRule("if (SpeedError is faster) and (SpeedErrorDot is slower) then (Accelerate is faster)");
   CSugenoFuzzyRule *rule8 = fsCruiseControl.ParseRule("if (SpeedError is faster) and (SpeedErrorDot is zero) then (Accelerate is slower)");
   CSugenoFuzzyRule *rule9 = fsCruiseControl.ParseRule("if (SpeedError is faster) and (SpeedErrorDot is faster) then (Accelerate is slower)");
//--- Add Sugeno fuzzy rule in system
   fsCruiseControl.Rules().Add(rule1);
   fsCruiseControl.Rules().Add(rule2);
   fsCruiseControl.Rules().Add(rule3);
   fsCruiseControl.Rules().Add(rule4);
   fsCruiseControl.Rules().Add(rule5);
   fsCruiseControl.Rules().Add(rule6);
   fsCruiseControl.Rules().Add(rule7);
   fsCruiseControl.Rules().Add(rule8);
   fsCruiseControl.Rules().Add(rule9);
//--- Set input value and get result
   CList *in=new CList;
   CDictionary_Obj_Double *p_od_Error=new CDictionary_Obj_Double;
   CDictionary_Obj_Double *p_od_ErrorDot=new CDictionary_Obj_Double;
   p_od_Error.SetAll(fvSpeedError,Speed_Error);
   p_od_ErrorDot.SetAll(fvSpeedErrorDot,Speed_ErrorDot);
   in.Add(p_od_Error);
   in.Add(p_od_ErrorDot);
//--- Get result
   CList *result;
   CDictionary_Obj_Double *p_od_Accelerate;
   result=fsCruiseControl.Calculate(in);
   p_od_Accelerate=result.GetNodeAtIndex(0);
   Print("Accelerate, %: ",p_od_Accelerate.Value()*100);
   delete in;
   delete result;
   delete fsCruiseControl;
  }
//+------------------------------------------------------------------+
