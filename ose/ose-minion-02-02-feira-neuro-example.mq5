//+------------------------------------------------------------------+
//|                                                neuro-example.mq5 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>        //include the library for execution of trades
#include <Trade\PositionInfo.mqh> //include the library for obtaining information on positions

//--- weight values
input double w0=0.5;
input double w1=0.5;
input double w2=0.5;
input double w3=0.5;
input double w4=0.5;
input double w5=0.5;
input double w6=0.5;
input double w7=0.5;
input double w8=0.5;
input double w9=0.5;

int               iRSI_handle;  // variable for storing the indicator handle
double            iRSI_buf[];   // dynamic array for storing indicator values

double            inputs[10];   // array for storing inputs
double            weight[10];   // array for storing weights
double            out;          // variable for storing the output of the neuron

string            my_symbol;    // variable for storing the symbol
ENUM_TIMEFRAMES   my_timeframe; // variable for storing the time frame
double            lot_size;     // variable for storing the minimum lot size of the transaction to be performed

CTrade            m_Trade;      // entity for execution of trades
CPositionInfo     m_Position;   // entity for obtaining information on positions
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- save the current chart symbol for further operation of the EA on this very symbol
   my_symbol=Symbol();
//--- save the current time frame of the chart for further operation of the EA on this very time frame
   my_timeframe=PERIOD_CURRENT;
//--- save the minimum lot of the transaction to be performed
   lot_size=SymbolInfoDouble(my_symbol,SYMBOL_VOLUME_MIN);
//--- apply the indicator and get its handle
   iRSI_handle=iRSI(my_symbol,my_timeframe,14,PRICE_CLOSE);
//--- check the availability of the indicator handle
   if(iRSI_handle==INVALID_HANDLE)
     {
      //--- no handle obtained, print the error message into the log file, complete handling the error
      Print("Failed to get the indicator handle");
      return(-1);
     }
//--- add the indicator to the price chart
   ChartIndicatorAdd(ChartID(),0,iRSI_handle);
//--- set the iRSI_buf array indexing as time series
   ArraySetAsSeries(iRSI_buf,true);
//--- place weights into the array
   weight[0]=w0;
   weight[1]=w1;
   weight[2]=w2;
   weight[3]=w3;
   weight[4]=w4;
   weight[5]=w5;
   weight[6]=w6;
   weight[7]=w7;
   weight[8]=w8;
   weight[9]=w9;
//--- return 0, initialization complete
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- delete the indicator handle and deallocate the memory space it occupies
   IndicatorRelease(iRSI_handle);
//--- free the iRSI_buf dynamic array of data
   ArrayFree(iRSI_buf);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- variable for storing the results of working with the indicator buffer
   int err1=0;
//--- copy data from the indicator array to the iRSI_buf dynamic array for further work with them
   err1=CopyBuffer(iRSI_handle,0,1,10,iRSI_buf);
//--- in case of errors, print the relevant error message into the log file and exit the function
   if(err1<0)
     {
      Print("Failed to copy data from the indicator buffer");
      return;
     }
//---
   double d1=0.0;                                 //lower limit of the normalization range
   double d2=1.0;                                 //upper limit of the normalization range
   double x_min=iRSI_buf[ArrayMinimum(iRSI_buf)]; //minimum value over the range
   double x_max=iRSI_buf[ArrayMaximum(iRSI_buf)]; //maximum value over the range

//--- In the loop, fill in the array of inputs with the pre-normalized indicator values
   for(int i=0;i<ArraySize(inputs);i++)
     {
      inputs[i]=(((iRSI_buf[i]-x_min)*(d2-d1))/(x_max-x_min))+d1;
     }
//--- store the neuron calculation result in the out variable
   out=CalculateNeuron(inputs,weight);
//--- if the output value of the neuron is less than 0.5
   if(out<0.5)
     {
      //--- if the position for this symbol already exists
      if(m_Position.Select(my_symbol))
        {
         //--- and this is a Sell position, then close it
         if(m_Position.PositionType()==POSITION_TYPE_SELL) m_Trade.PositionClose(my_symbol);
         //--- or else, if this is a Buy position, then exit
         if(m_Position.PositionType()==POSITION_TYPE_BUY) return;
        }
      //--- if we got here, it means there is no position; then we open it
      m_Trade.Buy(lot_size,my_symbol);
     }
//--- if the output value of the neuron is equal to or greater than 0.5
   if(out>=0.5)
     {
      //--- if the position for this symbol already exists
      if(m_Position.Select(my_symbol))
        {
         //--- and this is a Buy position, then close it
         if(m_Position.PositionType()==POSITION_TYPE_BUY) m_Trade.PositionClose(my_symbol);
         //--- or else, if this is a Sell position, then exit
         if(m_Position.PositionType()==POSITION_TYPE_SELL) return;
        }
      //--- if we got here, it means there is no position; then we open it
      m_Trade.Sell(lot_size,my_symbol);
     }
  }
//+------------------------------------------------------------------+
//|   Neuron calculation function                                    |
//+------------------------------------------------------------------+
double CalculateNeuron(double &x[],double &w[])
  {
//--- variable for storing the weighted sum of inputs
   double NET=0.0;
//--- Using a loop we obtain the weighted sum of inputs based on the number of inputs
   for(int n=0;n<ArraySize(x);n++)
     {
      NET+=x[n]*w[n];
     }
//--- multiply the weighted sum of inputs by the additional coefficient
   NET*=0.4;
//--- send the weighted sum of inputs to the activation function and return its value
   return(ActivateNeuron(NET));
  }
//+------------------------------------------------------------------+
//|   Activation function                                            |
//+------------------------------------------------------------------+
double ActivateNeuron(double x)
  {
//--- variable for storing the activation function results
   double Out;
//--- sigmoid
   Out=1/(1+exp(-x));
//--- return the activation function value
   return(Out);
  }
//+------------------------------------------------------------------+
