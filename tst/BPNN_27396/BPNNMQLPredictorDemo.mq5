//+--------------------------------------------------------------------------------------+
//|                                                          BPNN MQL Predictor Demo.mq5 |
//|                                             Copyright (c) 2009-2019, gpwr, Marketeer |
//|                                              https://www.mql5.com/en/users/marketeer |
//|                                              https://www.mql5.com/en/users/gpwr      |
//|                                                                       rev.18.12.2019 |
//+--------------------------------------------------------------------------------------+
#property copyright "Copyright (c) 2009-2019, gpwr, Marketeer"
#property version "2.0"
#property link "https://www.mql5.com/en/users/marketeer"
#property description "This is not a real world indicator, but a simple demo of BPNN library, originally written in C++ and ported to MQL.\n"
#property description "The demo shows training and testing a neural network for timeseries prediction."


#property indicator_chart_window

#property indicator_buffers 3
#property indicator_plots 3
#property indicator_color1 Red
#property indicator_width1 2
#property indicator_color2 Blue
#property indicator_width2 2
#property indicator_color3 Yellow
#property indicator_width3 2


// NB! Do not include both variants below, any but only one makes sense:
// 1] this attaches the library via importing ex5-file
//#include <BPNN_MQL.mqh>

// 2] this embedes the library sources inplace
#include <BPNN_MQL_IMPL.mqh>

// let user know if the program uses built-in or standalone library
#property description BPNN_LIBRARY_DESC

// helper methods for mt4-style indicators
#include <BPNNMQLi45.mqh>


//===================================== INPUTS ===========================================

input int _lastBar = 0;     // Last bar in the past data
input int _futBars = 10;    // # of future bars to predict
input int _smoothPer = 6;   // Smoothing period
input int _numLayers = 3;   // # of layers including input, hidden & output (2..6)
input int _numInputs = 12;  // # of inputs
input int _numNeurons1 = 5; // # of neurons in the first hidden or output layer
input int _numNeurons2 = 1; // # of neurons in the second hidden or output layer
input int _numNeurons3 = 0; // # of neurons in the third hidden or output layer
input int _numNeurons4 = 0; // # of neurons in the fourth hidden or output layer
input int _numNeurons5 = 0; // # of neurons in the fifth hidden or output layer
input int _ntr = 500;       // # of training sets / bars
input int _nep = 1000;      // Max # of epochs
input int _maxMSEpwr = -20; // Error (as power of 10) for training to stop; e < _maxMSE:=10^_maxMSEpwr
input int _AFT = 2;         // Type of activ. function (0:sigm, 1:tanh, 2:x/(1+x))


//======================================= INIT ===========================================
// Indicator buffers
double _pred[], _trainedOut[], _targetOut[];
int _handle;

// Global variables
int _lb, _nf, _nin, _nout, _lSz[], _prevBars, _fdMax;
double _maxMSE;

double _extInitWt[]; // trained weights


int OnInit()
{
    // Create 1D array describing NN -----------------------------------------------------+
    ArrayResize(_lSz, _numLayers);
    _lSz[0] = _numInputs;
    _lSz[1] = _numNeurons1;
    if(_numLayers > 2)
    {
        _lSz[2] = _numNeurons2;
        if(_numLayers > 3)
        {
            _lSz[3] = _numNeurons3;
            if(_numLayers > 4)
            {
                _lSz[4] = _numNeurons4;
                if(_numLayers > 5) _lSz[5] = _numNeurons5;
            }
        }
    }

    // Use shorter names for some external inputs -------------------------------------------+
    _lb = _lastBar;
    _nf = _futBars;
    _nin = _numInputs;
    _nout = _lSz[_numLayers - 1];
    _maxMSE = MathPow(10.0, _maxMSEpwr);
    _prevBars = iBars(_Symbol, _Period) - 1;

    // Find maximum Fibonacci delay ---------------------------------------------------------+
    int fd2 = 0;
    int fd1 = 1;
    for(int j = 0; j < _nin; j++)
    {
        int fd = fd1 + fd2;
        fd2 = fd1;
        fd1 = fd;
    }
    _fdMax = fd1;

    // Set indicator properties -------------------------------------------------------------+
    SetIndexBuffer(0, _pred);
    SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2);
    SetIndexLabel(0, "Prediction");
    SetIndexBuffer(1, _trainedOut);
    SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 2);
    SetIndexLabel(1, "Output");
    SetIndexBuffer(2, _targetOut);
    SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 2);
    SetIndexLabel(2, "Target");
    SetIndexShift(0, _nf - _lb); // future data vector i=0.._nf; _nf corresponds to bar=_lb
    IndicatorShortName("BPNN");
    
    _handle = iMA(NULL, 0, _smoothPer, 0, MODE_EMA, PRICE_MEDIAN);
    return (_handle != INVALID_HANDLE) ? INIT_SUCCEEDED : INIT_FAILED;
}

//===================================== DEINIT ===========================================
void OnDeinit(const int)
{
  Comment("");
}

//===================================== START ============================================
int OnCalculate(const int rates_total,
                 const int prev_calculated,
                 const int begin,
                 const double& price[])
{
    int i, j, k;
    int fd, fd1, fd2;

    if(_prevBars < iBars(_Symbol, _Period))
    {
        ArrayInitialize(_pred, EMPTY_VALUE);
        ArrayInitialize(_trainedOut, EMPTY_VALUE);
        ArrayInitialize(_targetOut, EMPTY_VALUE);
        
        _prevBars = iBars(_Symbol, _Period);
        // Check NN and find the total number of weights ----------------------------------------+
        if(_numLayers > 6)
        {
            Print("The maximum number of layers is 6");
            return 0;
        }
        for(i = 0; i < _numLayers; i++)
        {
            if(_lSz[i] <= 0)
            {
                Print("No neurons in layer # " + DoubleToString(i, 0) +
                      ". Either reduce # of layers or add neurons to this layer");
                return 0;
            }
        }
        int nw = 0;                               // total number of weights
        for(i = 1; i < _numLayers; i++)           // for each layer except input
            for(j = 0; j < _lSz[i]; j++)          // for each neuron in current layer
                for(k = 0; k <= _lSz[i - 1]; k++) // for each input of current neuron including bias
                    nw++;

        double x[];
        int n = _ntr + _fdMax + 1;
        ArrayResize(x, n);

        ResetLastError();
        double value[1];

        // First smooth prices
        for(i = 0; i < n; i++)
        {
            if(CopyBuffer(_handle, 0, _lb + i, 1, value) == -1)
            {
                const int err = GetLastError(); // probably ERR_INDICATOR_DATA_NOT_FOUND
                Print("Error: ", err);
                _prevBars = 0;
                // let indicator calculate
                return 0;
            }
            else
            {
                x[i] = value[0];
            }
        }

        // Prepare input data for training ------------------------------------------------------+
        double inpTrain[], outTarget[];
        ArrayResize(inpTrain, _ntr * _nin);
        ArrayResize(outTarget, _ntr * _nout);

        // The input data is arranged as follows:
        //
        // inpTrain[i*_nin+j]
        //------------------
        //      j= 0..._nin-1
        //            |
        // i=0     <inputs>
        // ...     <inputs>
        // i=_ntr-1 <inputs>
        //
        // outTarget[i*_nout+j]
        //--------------------
        //      j= 0..._nout-1
        //             |
        // i=0     <targets>
        // ...     <targets>
        // i=_ntr-1 <targets>
        //
        // <inputs> start with the oldest value first
        
        // Fill in the input arrays with data; in this example _nout=1
        for(i = _ntr - 1; i >= 0; i--)
        {
            outTarget[i] = (x[_ntr - 1 - i] / x[_ntr - i] - 1.0);
            fd2 = 0;
            fd1 = 1;
            for(j = _nin - 1; j >= 0; j--)
            {
                fd = fd1 + fd2; // use Fibonacci delays: 1,2,3,5,8,13,21,34,55,89,144...
                fd2 = fd1;
                fd1 = fd;
                inpTrain[i * _nin + j] = x[_ntr - i] / x[_ntr - i + fd] - 1.0;
            }
        }

        // online we will re-train on every new bar;
        // in the tester we will use previously obtained weights - this is required to pass automatic validation,
        // which does not allow lengthy operations, such as neural network training
        const bool alreadyTrained = ArraySize(_extInitWt) == nw && MQLInfoInteger(MQL_TESTER);
        
        if(!alreadyTrained)
        {

        // Train NN -----------------------------------------------------------------------------+
        double outTrain[], trainedWt[];
        ArrayResize(outTrain, _ntr * _nout);
        ArrayResize(trainedWt, nw);
        ArrayResize(_extInitWt, nw);

        // The output data is arranged as follows:
        //
        // outTrain[i*_nout+j]
        //      j= 0..._nout-1
        //             |
        // i=0     <outputs>
        // ...     <outputs>
        // i=_ntr-1 <outputs>

        NNStatus status = Train(inpTrain, outTarget, outTrain, _ntr, 0, _extInitWt, trainedWt, _numLayers,
                              _lSz, _AFT, 0, _nep, _maxMSE);
        Comment(status.message);

        if(status.code > 0)
        {
            // Store trainedWt[] as _extInitWt[] for next training
            int iw = 0;
            for(i = 1; i < _numLayers; i++)           // for each layer except input
                for(j = 0; j < _lSz[i]; j++)          // for each neuron in current layer
                    for(k = 0; k <= _lSz[i - 1]; k++) // for each input of current neuron including bias
                    {
                        _extInitWt[iw] = trainedWt[iw];
                        iw++;
                    }
        }
        else // if failed, don't save the weights
        {
            ArrayResize(_extInitWt, 0);
        }

        // Show how individual net outputs match targets
        for(i = 0; i < _ntr; i++)
        {
            _targetOut[_lb + i] = x[i];
            _trainedOut[_lb + i] = (1.0 + outTrain[_ntr - 1 - i]) * x[i + 1];
        }
        } // !alreadyTrained

        // Test NN ------------------------------------------------------------------------------+
        double inpTest[], outTest[];
        ArrayResize(inpTest, _nin);
        ArrayResize(outTest, _nout);

        // The input data is arranged as follows:
        //
        // inpTest[i*_nin+j]
        //-----------------
        //      j= 0..._nin-1
        //            |
        // i=0     <inputs>
        // ...     <inputs>
        // i=ntt-1 <inputs>
        //
        // <inputs> start with the oldest value first
        //
        // The output data is arranged as follows:
        //
        // outTest[i*_nout+j]
        //------------------
        //      j= 0..._nout-1
        //             |
        // i=0     <outputs>
        // ...     <outputs>
        // i=ntt-1 <outputs>

        _pred[_nf] = x[0];
        for(i = 0; i < _nf; i++)
        {
            fd2 = 0;
            fd1 = 1;
            for(j = _nin - 1; j >= 0; j--)
            {
                fd = fd1 + fd2; // use Fibonacci delays: 1,2,3,5,8,13,21,34,55,89,144...
                fd2 = fd1;
                fd1 = fd;
                double o, od;
                if(i > 0)
                    o = _pred[_nf - i];
                else
                    o = x[0];
                if(i - fd > 0)
                    od = _pred[_nf - i + fd];
                else
                    od = x[fd - i];
                inpTest[j] = o / od - 1.0;
            }
            
            Test(inpTest, outTest, 1, _extInitWt, _numLayers, _lSz, _AFT, 0);
            _pred[_nf - i - 1] = _pred[_nf - i] * (outTest[0] + 1.0); // predicted next open
        }
    }
    return rates_total;
}
