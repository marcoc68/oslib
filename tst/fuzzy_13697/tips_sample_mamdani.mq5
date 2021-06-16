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
#include <Math\Fuzzy\MamdaniFuzzySystem.mqh>
//--- input parameters
input double   Service;
input double   Food;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//--- Mamdani Fuzzy System  
   CMamdaniFuzzySystem *fsTips=new CMamdaniFuzzySystem();
//--- Create first input variables for the system
   CFuzzyVariable *fvService=new CFuzzyVariable("service",0.0,10.0);
   fvService.Terms().Add(new CFuzzyTerm("poor", new CTriangularMembershipFunction(-5.0, 0.0, 5.0)));
   fvService.Terms().Add(new CFuzzyTerm("good", new CTriangularMembershipFunction(0.0, 5.0, 10.0)));
   fvService.Terms().Add(new CFuzzyTerm("excellent", new CTriangularMembershipFunction(5.0, 10.0, 15.0)));
   fsTips.Input().Add(fvService);
//--- Create second input variables for the system
   CFuzzyVariable *fvFood=new CFuzzyVariable("food",0.0,10.0);
   fvFood.Terms().Add(new CFuzzyTerm("rancid", new CTrapezoidMembershipFunction(0.0, 0.0, 1.0, 3.0)));
   fvFood.Terms().Add(new CFuzzyTerm("delicious", new CTrapezoidMembershipFunction(7.0, 9.0, 10.0, 10.0)));
   fsTips.Input().Add(fvFood);
//--- Create Output
   CFuzzyVariable *fvTips=new CFuzzyVariable("tips",0.0,30.0);
   fvTips.Terms().Add(new CFuzzyTerm("cheap", new CTriangularMembershipFunction(0.0, 5.0, 10.0)));
   fvTips.Terms().Add(new CFuzzyTerm("average", new CTriangularMembershipFunction(10.0, 15.0, 20.0)));
   fvTips.Terms().Add(new CFuzzyTerm("generous", new CTriangularMembershipFunction(20.0, 25.0, 30.0)));
   fsTips.Output().Add(fvTips);
//--- Create three Mamdani fuzzy rule
   CMamdaniFuzzyRule *rule1 = fsTips.ParseRule("if (service is poor )  or (food is rancid) then tips is cheap");
   CMamdaniFuzzyRule *rule2 = fsTips.ParseRule("if ((service is good)) then tips is average");
   CMamdaniFuzzyRule *rule3 = fsTips.ParseRule("if (service is excellent) or (food is delicious) then (tips is generous)");
//--- Add three Mamdani fuzzy rule in system
   fsTips.Rules().Add(rule1);
   fsTips.Rules().Add(rule2);
   fsTips.Rules().Add(rule3);
//--- Set input value
   CList *in=new CList;
   CDictionary_Obj_Double *p_od_Service=new CDictionary_Obj_Double;
   CDictionary_Obj_Double *p_od_Food=new CDictionary_Obj_Double;
   p_od_Service.SetAll(fvService, Service);
   p_od_Food.SetAll(fvFood, Food);
   in.Add(p_od_Service);
   in.Add(p_od_Food);
//--- Get result
   CList *result;
   CDictionary_Obj_Double *p_od_Tips;
   result=fsTips.Calculate(in);
   p_od_Tips=result.GetNodeAtIndex(0);
   Print("Tips, %: ",p_od_Tips.Value());
   delete in;
   delete result;
   delete fsTips;
  }
//+------------------------------------------------------------------+