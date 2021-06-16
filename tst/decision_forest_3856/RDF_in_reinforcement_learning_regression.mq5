//+------------------------------------------------------------------+
//|                                                Fuzzy logic + RDF |
//|                                Copyright 2018, Dmitrievskiy Max. |
//|                        https://www.mql5.com/ru/users/dmitrievsky |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Dmitrievskiy Max."
#property link      "https://www.mql5.com/ru/users/dmitrievsky"
#property version   "2.00"
#include <Math\Fuzzy\MamdaniFuzzySystem.mqh>
#include <Math\Stat\Uniform.mqh>
#include <Math\Alglib\dataanalysis.mqh>                         //include Random Decsion Forest library
#include <Trade\AccountInfo.mqh>
#include <MT4Orders.mqh>

//RDF system. Here we create all RF objects.
CDecisionForest      RDF;                                     //Random forest object
CMatrixDouble        RDFpolicyMatrix;                         //Matrix for RF inputs and output
CDFReport            RDF_report;                              //RF return errors in this object, then we can check it
double RFout[1], vector[3];                                   //Arrays for calculate result of RF
int RDFinfo;                                                  //Check if RF learn succesfull

                                                              //FUZZY system. Here we create all Fuzz objects
CMamdaniFuzzySystem *OurFuzzy=new CMamdaniFuzzySystem();

CFuzzyVariable *firstInput=new CFuzzyVariable("rsi1",0.0,1.0);
CFuzzyVariable *secondInput=new CFuzzyVariable("rsi2",0.0,1.0);
CFuzzyVariable *thirdInput=new CFuzzyVariable("rsi3",0.0,1.0);
CFuzzyVariable *fuzzyOut=new CFuzzyVariable("out",0.0,1.0);

CDictionary_Obj_Double *firstTerm=new CDictionary_Obj_Double;
CDictionary_Obj_Double *secondTerm=new CDictionary_Obj_Double;
CDictionary_Obj_Double *thirdTerm=new CDictionary_Obj_Double;
CDictionary_Obj_Double *Output;

CMamdaniFuzzyRule *rule1,*rule2,*rule3,*rule4,*rule5,*rule6,*rule7,*rule8,*rule9,*rule10,*rule11,*rule12;
CNormalMembershipFunction *updateNeutral=new CNormalMembershipFunction(0.5,0.2);
CList *Inputs=new CList;

int hnd1,hnd2,hnd3;
double arr1[],arr2[],arr3[];

sinput string AIsettings;           //AI settings
sinput bool clear_model=false;
sinput int number_of_trees=50;
sinput double regularization=0.63;

input int optimization_iterations=3;

sinput string Lotsettings;          //Trade settings
sinput double   MaximumRisk=0.01;
sinput double   CustomLot=0;
sinput int      OrderMagic=666;

double   lots;
static datetime last_time=0;

bool random_policy=true;
bool checked_for_learn=false;
int numberOfsamples=0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Inputs.FreeMode(false);
   hnd1 = iRSI(_Symbol,0,3,PRICE_CLOSE);
   hnd2 = iRSI(_Symbol,0,9,PRICE_CLOSE);
   hnd3 = iRSI(_Symbol,0,27,PRICE_CLOSE);

   firstInput.Terms().Add(new CFuzzyTerm("buy", new CZ_ShapedMembershipFunction(0.0,0.3)));
   firstInput.Terms().Add(new CFuzzyTerm("neutral", new CNormalMembershipFunction(0.5, 0.3)));
   firstInput.Terms().Add(new CFuzzyTerm("sell", new CS_ShapedMembershipFunction(0.7,1.0)));
   OurFuzzy.Input().Add(firstInput);

   secondInput.Terms().Add(new CFuzzyTerm("buy", new CZ_ShapedMembershipFunction(0.0,0.3)));
   secondInput.Terms().Add(new CFuzzyTerm("neutral", new CNormalMembershipFunction(0.5, 0.3)));
   secondInput.Terms().Add(new CFuzzyTerm("sell", new CS_ShapedMembershipFunction(0.7,1.0)));
   OurFuzzy.Input().Add(secondInput);

   thirdInput.Terms().Add(new CFuzzyTerm("buy", new CZ_ShapedMembershipFunction(0.0,0.3)));
   thirdInput.Terms().Add(new CFuzzyTerm("neutral", new CNormalMembershipFunction(0.5, 0.3)));
   thirdInput.Terms().Add(new CFuzzyTerm("sell", new CS_ShapedMembershipFunction(0.7,1.0)));
   OurFuzzy.Input().Add(thirdInput);

   fuzzyOut.Terms().Add(new CFuzzyTerm("buy", new CZ_ShapedMembershipFunction(0.0,0.3)));
   fuzzyOut.Terms().Add(new CFuzzyTerm("neutral", updateNeutral));
   fuzzyOut.Terms().Add(new CFuzzyTerm("sell", new CS_ShapedMembershipFunction(0.7,1.0)));
   OurFuzzy.Output().Add(fuzzyOut);


   rule1 = OurFuzzy.ParseRule("if (rsi1 is buy) and (rsi2 is buy) and (rsi3 is buy) then (out is buy)");
   rule2 = OurFuzzy.ParseRule("if (rsi1 is sell) and (rsi2 is sell) and (rsi3 is sell) then (out is sell)");
   rule3 = OurFuzzy.ParseRule("if (rsi1 is neutral) and (rsi2 is neutral) and (rsi3 is neutral) then (out is neutral)");

   rule4 = OurFuzzy.ParseRule("if (rsi1 is buy) and (rsi2 is sell) and (rsi3 is buy) then (out is neutral)");
   rule5 = OurFuzzy.ParseRule("if (rsi1 is sell) and (rsi2 is sell) and (rsi3 is buy) then (out is neutral)");
   rule6 = OurFuzzy.ParseRule("if (rsi1 is buy) and (rsi2 is buy) and (rsi3 is sell) then (out is neutral)");

   rule7 = OurFuzzy.ParseRule("if (rsi1 is buy) and (rsi2 is buy) and (rsi3 is neutral) then (out is buy)");
   rule8 = OurFuzzy.ParseRule("if (rsi1 is sell) and (rsi2 is sell) and (rsi3 is neutral) then (out is sell)");
   rule9 = OurFuzzy.ParseRule("if (rsi1 is buy) and (rsi2 is neutral) and (rsi3 is buy) then (out is buy)");
   rule10 = OurFuzzy.ParseRule("if (rsi1 is sell) and (rsi2 is neutral) and (rsi3 is sell) then (out is sell)");
   rule11 = OurFuzzy.ParseRule("if (rsi1 is neutral) and (rsi2 is buy) and (rsi3 is buy) then (out is buy)");
   rule12 = OurFuzzy.ParseRule("if (rsi1 is neutral) and (rsi2 is sell) and (rsi3 is sell) then (out is sell)");


   OurFuzzy.Rules().Add(rule1);
   OurFuzzy.Rules().Add(rule2);
   OurFuzzy.Rules().Add(rule3);
   OurFuzzy.Rules().Add(rule4);
   OurFuzzy.Rules().Add(rule5);
   OurFuzzy.Rules().Add(rule6);
   OurFuzzy.Rules().Add(rule7);
   OurFuzzy.Rules().Add(rule8);
   OurFuzzy.Rules().Add(rule9);
   OurFuzzy.Rules().Add(rule10);
   OurFuzzy.Rules().Add(rule11);
   OurFuzzy.Rules().Add(rule12);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkBeforeLearn()
  {
   if(clear_model)
     {
      FileDelete("RDFBufsize"+_Symbol+(string)_Period+".txt",FILE_COMMON);
      FileDelete("RDFNclasses"+_Symbol+(string)_Period+".txt",FILE_COMMON);
      FileDelete("RDFNvars"+_Symbol+(string)_Period+".txt",FILE_COMMON);
      FileDelete("RDFMtrees"+_Symbol+(string)_Period+".txt",FILE_COMMON);
      
      int clearRDF=FileOpen("RDFNtrees"+_Symbol+(string)_Period+".txt",FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON);
      FileWrite(clearRDF,0);
      FileClose(clearRDF);
      ExpertRemove();
      return;
     }

   int filehnd=FileOpen("RDFNtrees"+ _Symbol + (string)_Period +".txt",FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON);
   int ntrees =  (int)FileReadNumber(filehnd);
   FileClose(filehnd);

   if(ntrees>0)
     {
      random_policy=false;

      int setRDF=FileOpen("RDFBufsize"+_Symbol+(string)_Period+".txt",FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON);
      RDF.m_bufsize=(int)FileReadNumber(setRDF);
      FileClose(setRDF);

      setRDF=FileOpen("RDFNclasses"+_Symbol+(string)_Period+".txt",FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON);
      RDF.m_nclasses=(int)FileReadNumber(setRDF);
      FileClose(setRDF);

      setRDF=FileOpen("RDFNtrees"+_Symbol+(string)_Period+".txt",FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON);
      RDF.m_ntrees=(int)FileReadNumber(setRDF);
      FileClose(setRDF);

      setRDF=FileOpen("RDFNvars"+_Symbol+(string)_Period+".txt",FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON);
      RDF.m_nvars=(int)FileReadNumber(setRDF);
      FileClose(setRDF);

      setRDF=FileOpen("RDFMtrees"+_Symbol+(string)_Period+".txt",FILE_READ|FILE_WRITE|FILE_BIN|FILE_ANSI|FILE_COMMON);
      FileReadArray(setRDF,RDF.m_trees);
      FileClose(setRDF);
     }
   else Print("Starting new learn");

   checked_for_learn=true;
  }
//+------------------------------------------------------------------+
//| Expert OnTester function                                         |
//+------------------------------------------------------------------+  
double OnTester()
  {
   if(clear_model) return 0;

   if(MQLInfoInteger(MQL_OPTIMIZATION)==true)
     {
      if(numberOfsamples>0)
        {
         CDForest::DFBuildRandomDecisionForest(RDFpolicyMatrix,numberOfsamples,3,1,number_of_trees,regularization,RDFinfo,RDF,RDF_report);
        }
      
      FileDelete("RDFBufsize"+_Symbol+(string)_Period+".txt",FILE_COMMON);
      FileDelete("RDFNclasses"+_Symbol+(string)_Period+".txt",FILE_COMMON);
      FileDelete("RDFNvars"+_Symbol+(string)_Period+".txt",FILE_COMMON);
      FileDelete("RDFMtrees"+_Symbol+(string)_Period+".txt",FILE_COMMON);
      
      int filehnd=FileOpen("RDFBufsize"+_Symbol+(string)_Period+".txt",FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON);
      FileWrite(filehnd,RDF.m_bufsize);
      FileClose(filehnd);

      filehnd=FileOpen("RDFNclasses"+_Symbol+(string)_Period+".txt",FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON);
      FileWrite(filehnd,RDF.m_nclasses);
      FileClose(filehnd);

      filehnd=FileOpen("RDFNtrees"+_Symbol+(string)_Period+".txt",FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON);
      FileWrite(filehnd,RDF.m_ntrees);
      FileClose(filehnd);

      filehnd=FileOpen("RDFNvars"+_Symbol+(string)_Period+".txt",FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON);
      FileWrite(filehnd,RDF.m_nvars);
      FileClose(filehnd);

      filehnd=FileOpen("RDFMtrees"+_Symbol+(string)_Period+".txt",FILE_READ|FILE_WRITE|FILE_BIN|FILE_ANSI|FILE_COMMON);
      FileWriteArray(filehnd,RDF.m_trees);
      FileClose(filehnd);
     }

   return 0;
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Inputs.FreeMode(true);
   delete Inputs;
   delete OurFuzzy;

   delete firstTerm;
   delete secondTerm;
   delete thirdTerm;

   ChartRedraw();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PlaceOrders(double ts)
  {
   if(CountOrders(0)!=0 || CountOrders(1)!=0)
     {
      for(int b=OrdersTotal()-1; b>=0; b--)
         if(OrderSelect(b,SELECT_BY_POS)==true)
            if(OrderSymbol()==_Symbol && OrderMagicNumber()==OrderMagic)

               switch(OrderType())
                 {
                  case OP_BUY:
                     if(ts>=0.5)
                     if(OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0,Red))
                       {
                        updateReward();
                        if(ts>0.6)
                          {
                           lots=LotsOptimized();
                           if(OrderSend(Symbol(),OP_SELL,lots,SymbolInfoDouble(_Symbol,SYMBOL_BID),0,0,0,NULL,OrderMagic,Red)>0)
                             {
                              updatePolicy(ts);
                             };
                          }
                       }
                     break;

                  case OP_SELL:
                     if(ts<=0.5)
                     if(OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0,Red))
                       {
                        updateReward();
                        if(ts<0.4)
                          {
                           lots=LotsOptimized();
                           if(OrderSend(Symbol(),OP_BUY,lots,SymbolInfoDouble(_Symbol,SYMBOL_ASK),0,0,0,NULL,OrderMagic,Green)>0)
                             {
                              updatePolicy(ts);
                             };
                          }
                       }
                     break;
                 }
      return;
     }

   lots=LotsOptimized();

   if((ts<0.4) && (OrderSend(Symbol(),OP_BUY,lots,SymbolInfoDouble(_Symbol,SYMBOL_ASK),0,0,0,NULL,OrderMagic,INT_MIN) > 0))
      updatePolicy(ts);
   else if((ts>0.6) && (OrderSend(Symbol(),OP_SELL,lots,SymbolInfoDouble(_Symbol,SYMBOL_BID),0,0,0,NULL,OrderMagic,INT_MIN) > 0))
      updatePolicy(ts);
   return;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!checked_for_learn) checkBeforeLearn();
//---
   if(!isNewBar())
     {
      return;
     }

   double ts=CalculateMamdani();
   PlaceOrders(ts);
  }
//+------------------------------------------------------------------+

void updatePolicy(double action)
  {
   if(MQLInfoInteger(MQL_OPTIMIZATION)==true)
     {
      numberOfsamples++;
      RDFpolicyMatrix.Resize(numberOfsamples,4);

      RDFpolicyMatrix[numberOfsamples-1].Set(0,arr1[0]);
      RDFpolicyMatrix[numberOfsamples-1].Set(1,arr2[0]);
      RDFpolicyMatrix[numberOfsamples-1].Set(2,arr3[0]);
      RDFpolicyMatrix[numberOfsamples-1].Set(3,action);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void updateReward()
  {
   if(MQLInfoInteger(MQL_OPTIMIZATION)==true)
     {
      int unierr;
      if(getLAstProfit()<0) RDFpolicyMatrix[numberOfsamples-1].Set(3,MathRandomUniform(0,1,unierr));
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateMamdani()
  {
   CopyBuffer(hnd1,0,0,1,arr1);
   NormalizeArrays(arr1);

   CopyBuffer(hnd2,0,0,1,arr2);
   NormalizeArrays(arr2);

   CopyBuffer(hnd3,0,0,1,arr3);
   NormalizeArrays(arr3);

   if(!random_policy)
     {
      vector[0]=arr1[0];
      vector[1]=arr2[0];
      vector[2]=arr3[0];

      CDForest::DFProcess(RDF,vector,RFout);
      updateNeutral.B(RFout[0]);
     }
   else
     {
      int unierr;
      updateNeutral.B(MathRandomUniform(0,1,unierr));
     }
   
   //Print(updateNeutral.B());
   firstTerm.SetAll(firstInput,arr1[0]);
   secondTerm.SetAll(secondInput,arr2[0]);
   thirdTerm.SetAll(thirdInput,arr3[0]);

   Inputs.Clear();
   Inputs.Add(firstTerm);
   Inputs.Add(secondTerm);
   Inputs.Add(thirdTerm);

   CList *FuzzResult=OurFuzzy.Calculate(Inputs);
   Output=FuzzResult.GetNodeAtIndex(0);
   double res=Output.Value();
   delete FuzzResult;

   return(res);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void NormalizeArrays(double &a[])
  {
   a[0]=a[0]/100;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountOrders(int a)
  {
   int result=0;
   for(int k=0; k<OrdersTotal(); k++)
     {
      if(OrderSelect(k,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if(OrderType()==a && OrderMagicNumber()==OrderMagic && OrderSymbol()==_Symbol)
           {result++;}
        }
     }
   return(result);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double LotsOptimized()
  {
   CAccountInfo myaccount; SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);
   double lot;

   lot=NormalizeDouble(myaccount.FreeMargin()*MaximumRisk/1000.0,2);
   if(CustomLot!=0.0) lot=CustomLot;

   double volume_step=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);
   int ratio=(int)MathRound(lot/volume_step);
   if(MathAbs(ratio*volume_step-lot)>0.0000001)
     {
      lot=ratio*volume_step;
     }
   if(lot<SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN)) lot=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   if(lot>SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX)) lot=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
   return(lot);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isNewBar()
  {
   datetime lastbar_time=datetime(SeriesInfoInteger(Symbol(),_Period,SERIES_LASTBAR_DATE));
   if(last_time==0)
     {
      last_time=lastbar_time;
      return(false);
     }
   if(last_time!=lastbar_time)
     {
      last_time=lastbar_time;
      return(true);
     }
   return(false);

  }
//+------------------------------------------------------------------+

bool CheckMoneyForTrade(string symb,double lot,ENUM_ORDER_TYPE type)
  {
//--- Getting the opening price
   MqlTick mqltick;
   SymbolInfoTick(symb,mqltick);
   double price=mqltick.ask;
   if(type==ORDER_TYPE_SELL)
      price=mqltick.bid;
//--- values of the required and free margin
   double margin,free_margin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
//--- call of the checking function
   if(!OrderCalcMargin(type,symb,lots,price,margin))
     {
      //--- something went wrong, report and return false
      Print("Error in ",__FUNCTION__," code=",GetLastError());
      return(false);
     }
//--- if there are insufficient funds to perform the operation
   if(margin>free_margin)
     {
      //--- report the error and return false
      Print("Not enough money for ",EnumToString(type)," ",lots," ",symb," Error code=",GetLastError());
      return(false);
     }
//--- checking successful
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getLAstProfit()
  {
   int result=0;
   long lasttime=0;
   double lasprofit=0;
   for(int k=0; k<OrdersHistoryTotal(); k++)
     {
      if(OrderSelect(k,SELECT_BY_POS,MODE_HISTORY)==true)
        {
         if(OrderOpenTime()>lasttime) lasprofit=OrderProfit();
        }
     }
   return(lasprofit);
  }
//+------------------------------------------------------------------+
