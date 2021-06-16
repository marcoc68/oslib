//+------------------------------------------------------------------+
//|                                                neuro-example.mq5 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include "osc-padrao.mqh"

class osc_minion_neuro : public osc_padrao {

private:
//--- weight values
double w0; double w1; double w2; double w3; double w4;
double w5; double w6; double w7; double w8; double w9;

double inputs[10];   // array for storing inputs
double weight[10];   // array for storing weights
double out;          // variable for storing the output of the neuron

public:

}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Initialize(){
w0=0.5;w1=0.5;w2=0.5;w3=0.5;w4=0.5;w5=0.5;w6=0.5;w7=0.5;w8=0.5;w9=0.5;

//--- place weights into the array
   weight[0]=w0;   weight[1]=w1;   weight[2]=w2;   weight[3]=w3;   weight[4]=w4;
   weight[5]=w5;   weight[6]=w6;   weight[7]=w7;   weight[8]=w8;   weight[9]=w9;
//--- return 0, initialization complete
   return(0);
  }
//+------------------------------------------------------------------+
//| <TODO: CONTINUAR DAQUI>                                             |
//+------------------------------------------------------------------+
void onTick() {
//--- variable for storing the results of working with the indicator buffer
   int err1=0;
//--- copy data from the indicator array to the iRSI_buf dynamic array for further work with them
   err1=CopyBuffer(iRSI_handle,0,1,10,iRSI_buf);
//--- in case of errors, print the relevant error message into the log file and exit the function
   if(err1<0){ Print("Failed to copy data from the indicator buffer"); return; }
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
