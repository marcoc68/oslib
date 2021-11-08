//+----------------------------------------------------------------------+
//|                                                         BPNN_MQL.mqh |
//|                             Copyright (c) 2009-2019, gpwr, Marketeer |
//|                              https://www.mql5.com/en/users/marketeer |
//|                              https://www.mql5.com/en/users/gpwr      |
//| Based on original idea and source codes of gpwr                      |
//|                                                       rev.18.12.2019 |
//+----------------------------------------------------------------------+

#ifndef BPNN_LIBRARY_DESC
#define BPNN_LIBRARY_DESC "\nBPNN MQL library is imported from BPNN_MQL.ex5"
#endif


#define NN_STATE_ABORTED  -1
#define NN_STATE_UNDEFINED 0
#define NN_STATE_TRAINED_BY_VALIDATION  1
#define NN_STATE_TRAINED_BY_ACCURACY    2
#define NN_STATE_TRAINED_BY_EPOCH_LIMIT 3


struct NNStatus
{
  int code;
  string message;
  NNStatus(const int n, const string text): code(n), message(text) {}
  NNStatus(const NNStatus &other)
  {
    code = other.code;
    message = other.message;
  }
};


#ifndef BPNN_LIBRARY
//======================================= Ex-DLL =========================================
#import "BPNN_MQL.ex5"
NNStatus Train(
    const double &inpTrain[],  // Input training data (1D array carrying 2D data, old first)
    const double &outTarget[], // Output target data for training (2D data as 1D array, oldest 1st)
    double &outTrain[],        // Output 1D array to hold net outputs from training
    const int ntr,             // # of training sets
    const int UEW,             // Use Ext. Weights for initialization (1=use extInitWt, 0=use rnd)
    const double &extInitWt[], // Input 1D array to hold 3D array of external initial weights
    double &trainedWt[],       // Output 1D array to hold 3D array of trained weights
    const int numLayers,       // # of layers including input, hidden and output
    const int &lSz[],          // # of neurons in layers. lSz[0] is # of net inputs
    const int AFT,             // Type of neuron activation function (0:sigm, 1:tanh, 2:x/(1+x))
    const int OAF,             // 1 enables activation function for output layer; 0 disables
    const int nep,             // Max # of training epochs
    const double maxMSE        // Max MSE; training stops once maxMSE is reached
);

void Test(
    const double &inpTest[],   // Input test data (2D data as 1D array, oldest first)
    double &outTest[],         // Output 1D array to hold net outputs from training (oldest first)
    const int ntt,             // # of test sets
    const double &extInitWt[], // Input 1D array to hold 3D array of external initial weights
    const int numLayers,       // # of layers including input, hidden and output
    const int &lSz[],          // # of neurons in layers. lSz[0] is # of net inputs
    const int AFT,             // Type of neuron activation function (0:sigm, 1:tanh, 2:x/(1+x))
    const int OAF              // 1 enables activation function for output layer; 0 disables
);
#import
#endif
