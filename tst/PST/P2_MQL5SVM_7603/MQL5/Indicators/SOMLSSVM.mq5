//+------------------------------------------------------------------+
//|                                                     SOMLSSVM.mq5 |
//|                                    Copyright (c) 2020, Marketeer |
//|                          https://www.mql5.com/en/users/marketeer |
//|                            https://www.mql5.com/ru/articles/7603 |
//+------------------------------------------------------------------+
#property copyright "2020 (c) Marketeer"
#property link "https://www.mql5.com/en/users/marketeer"
#property version "1.0"
#property description "SOM-LS-SVM test indicator\n"

#define BUF_NUM 4

#property indicator_separate_window
#property indicator_buffers BUF_NUM
#property indicator_plots   BUF_NUM

#property indicator_color1 clrLimeGreen
#property indicator_width1 2
#property indicator_color2 clrDarkTurquoise
#property indicator_width2 2
#property indicator_color3 clrGreen
#property indicator_width3 2
#property indicator_color4 clrBlue
#property indicator_width4 2


input int _VectorNumber = 250; // VectorNumber (training)
input int _VectorNumber2 = 50; // VectorNumber (validating)
input int _VectorSize = 20; // VectorSize
input double _Gamma = 0; // Gamma (0 - auto)
input double _Sigma = 0; // Sigma (0 - auto)
input int _KernelNumber = 0; // KernelNumber (0 - auto)
input int _TrainingOffset = 50; // Offset of training bars
input int _ValidationOffset = 0; // Offset of validation bars
input double Sparsity = 0;
input int DifferencingOrder = 1;
input bool ShowPredictionOnChart = false;


#include <SOMLSSVM.mqh>
#include <IndArray.mqh>


IndicatorArray buffers(BUF_NUM);
IndicatorArrayGetter getter(buffers);

LSSVM *lssvm = NULL;
LSSVM *test = NULL;


const string prefix = "lssvm";
const double _Threshold = 0.0; // Threshold (0 - auto, ALGLIB)
string caption = "LSSVM"; // default

int OnInit()
{
  if(_KernelNumber == -1 || _KernelNumber > _VectorNumber)
  {
    caption = "LS"; // linear regression (low quality but simple, for comparison only)
  }
  else if(_KernelNumber != 0 && _KernelNumber != _VectorNumber)
  {
    caption = "SOMLSSVM"; // SOM-LS-SVM (medium quality, fast)
  }
  // else // LS-SVM (high quality, but computationally intensive, hence slow)
  IndicatorSetString(INDICATOR_SHORTNAME, caption + " (" + (string)_VectorNumber + ")");
  static string titles[BUF_NUM] = {"Training set", "Trained output", "Test input", "Test output"};

  for(int i = 0; i < BUF_NUM; i++)
  {
    PlotIndexSetInteger(i, PLOT_DRAW_TYPE, DRAW_LINE);
    PlotIndexSetString(i, PLOT_LABEL, titles[i]);
  }

  lssvm = new LSSVM(_VectorNumber, _VectorSize, _KernelNumber, _Gamma, _Sigma, _TrainingOffset);
  test = new LSSVM(_VectorNumber2, _VectorSize, _KernelNumber, 1, 1, _ValidationOffset);
  lssvm.setDifferencingOrder(DifferencingOrder);
  test.setDifferencingOrder(DifferencingOrder);
  
  return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& Time[],
                const double& Open[],
                const double& High[],
                const double& Low[],
                const double& Close[],
                const long& Tick_volume[],
                const long& Volume[],
                const int& Spread[])
{
  ArraySetAsSeries(Open, true);
  ArraySetAsSeries(Time, true);

  static bool calculated = false;
  if(calculated) return rates_total;
  calculated = true;
  
  for(int k = 0; k < BUF_NUM; k++)
  {
    buffers[k].empty();
  }
  
  lssvm.bindCrossValidator(test);
  bool processed = lssvm.process(true, Sparsity);
  if(processed)
  {
    const double m1 = lssvm.getMean();
    const double s1 = lssvm.getStdDev();

    const double m2 = test.getMean();
    const double s2 = test.getStdDev();

    double rmse[2] = {0};
    double xy[2] = {0};
    double x2[2] = {0};
    double y2[2] = {0};


    // training

    double out[];
    lssvm.getY(out, true);
    
    for(int i = 0; i < _VectorNumber; i++)
    {
      out[i] = out[i] * s1 + m1;
    }
    
    buffers[0].set(_TrainingOffset, out);
    
    lssvm.getResult(out, true);

    for(int i = 0; i < _VectorNumber; i++)
    {
      out[i] = out[i] * s1 + m1;
    }
    
    buffers[1].set(_TrainingOffset, out);

    int correct = 0;

    for(int i = 0; i < _VectorNumber; i++)
    {
      // RMSE and Correlation on training set
      double given = getter[0][_VectorNumber - i - 1 + _TrainingOffset];
      double trained = getter[1][_VectorNumber - i - 1 + _TrainingOffset];
      rmse[0] += (given - trained) * (given - trained);
      
      if(given * trained > 0) correct++;
      
      xy[0] += (given - m1) * (trained - m1);
      x2[0] += (given - m1) * (given - m1);
      y2[0] += (trained - m1) * (trained - m1);
    }


    // validation

    test.getY(out, true);

    for(int i = 0; i < _VectorNumber2; i++)
    {
      out[i] = out[i] * s2 + m2;
    }

    buffers[2].set(_ValidationOffset, out);
    
    int correct2 = 0;

    for(int i = 0; i < _VectorNumber2; i++)
    {
      test.vector(i, out);

      double z = lssvm.approximate(out);
      z = z * s2 + m2;
      buffers[3][_VectorNumber2 - i - 1 + _ValidationOffset] = z;
      double given = getter[2][_VectorNumber2 - i - 1 + _ValidationOffset];

      // RMSE and Correlation on test set
      rmse[1] += (given - z) * (given - z);
      
      if(given * z > 0) correct2++;
      
      xy[1] += (given - m2) * (z - m1);
      x2[1] += (given - m2) * (given - m2);
      y2[1] += (z - m1) * (z - m1);
      
      if(ShowPredictionOnChart)
      {
        double target = 0;
        if(DifferencingOrder == 0)
        {
          target = z;
        }
        else if(DifferencingOrder == 1)
        {
          target = Open[_VectorNumber2 - i - 1 + _ValidationOffset + 1] + z;
        }
        else if(DifferencingOrder == 2)
        {
          target = 2 * Open[_VectorNumber2 - i - 1 + _ValidationOffset + 1]
                 - Open[_VectorNumber2 - i - 1 + _ValidationOffset + 2] + z;
        }
        else if(DifferencingOrder == 3)
        {
          target = 3 * Open[_VectorNumber2 - i - 1 + _ValidationOffset + 1]
                 - 3 * Open[_VectorNumber2 - i - 1 + _ValidationOffset + 2]
                 + Open[_VectorNumber2 - i - 1 + _ValidationOffset + 3] + z;
        }
        else
        {
          // unsupported yet
        }

        string name = prefix + (string)i;
        ObjectCreate(0, name, OBJ_TEXT, 0, Time[_VectorNumber2 - i - 1 + _ValidationOffset], target);
        ObjectSetString(0, name, OBJPROP_TEXT, "l");
        ObjectSetString(0, name, OBJPROP_FONT, "Wingdings");
        ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_CENTER);
        ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed);
      }
    }

    rmse[0] /= _VectorNumber;
    rmse[1] /= _VectorNumber2;
    IndicatorSetString(INDICATOR_SHORTNAME, caption
      + " RMSE=" + DoubleToString(sqrt(rmse[0]), 3) + " CC=" + DoubleToString(xy[0] / sqrt(x2[0] * y2[0]), 3)
      + " " + DoubleToString(correct * 100.0 / _VectorNumber, 0) + "%"
      + " / RMSE=" + DoubleToString(sqrt(rmse[1]), 3) + " CC=" + DoubleToString(xy[1] / sqrt(x2[1] * y2[1]), 3)
      + " " + DoubleToString(correct2 * 100.0 / _VectorNumber2, 0) + "%"
      );
  }
  else
  {
    Print("Process error");
  }

  return rates_total;
}


void OnDeinit(const int)
{
  ObjectsDeleteAll(0, prefix, 0, OBJ_TEXT);
  delete lssvm;
  delete test;
}
