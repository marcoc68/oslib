//+----------------------------------------------------------------------+
//|                                                    BPNN_MQL_IMPL.mqh |
//|                             Copyright (c) 2009-2019, gpwr, Marketeer |
//|                              https://www.mql5.com/en/users/marketeer |
//|                              https://www.mql5.com/en/users/gpwr      |
//| Based on original idea and source codes of gpwr                      |
//|                                                       rev.18.12.2019 |
//+----------------------------------------------------------------------+

// this let it know to the included BPNN_MQL.mqh that we don't need the import
// because the source is embedded directly (inline)
#ifndef BPNN_LIBRARY
#define BPNN_LIBRARY
#define BPNN_LIBRARY_DESC "\nBPNN MQL library is embedded"
#endif

#include <BPNN_MQL.mqh>


int ValidationPercent = 0;
int TrainValidationMseRatio = 0;
int EpochPercent = 1;


#define min(A,B) MathMin((A),(B))
#define max(A,B) MathMax((A),(B))


// ======================= Multidimensional arrays/matrices =========================

template<typename T>
class ObjectArray
{
  public:
    ObjectArray(){}
    ObjectArray(int n)
    {
      resize(n);
    }
    
    void resize(int n)
    {
      ArrayResize(data, n);
    }
    
  public:
    T data[];
};

template<typename T>
class ObjectArray2D
{
  public:
    ObjectArray2D(){}
    ObjectArray2D(int n)
    {
      resize(n);
    }
    
    void resize(int n)
    {
      ArrayResize(data, n);
      for(int i = 0; i < n; i++)
      {
        data[i] = new ObjectArray<T>();
      }
    }
    
    ObjectArray<T> *operator[](int i) const
    {
      return GetPointer(data[i]);
    }
    
    ~ObjectArray2D()
    {
      for(int i = 0; i < ArraySize(data); i++)
      {
        delete data[i];
      }
    }
    
  private:
    ObjectArray<T> *data[];
};

template<typename T>
class ObjectArray3D
{
  public:
    ObjectArray3D(){}
    ObjectArray3D(int n)
    {
      resize(n);
    }

    void resize(int n)
    {
      ArrayResize(data, n);
      for(int i = 0; i < n; i++)
      {
        data[i] = new ObjectArray2D<T>();
      }
    }
    
    ObjectArray2D<T> *operator[](int i) const
    {
      return GetPointer(data[i]);
    }
    
    ~ObjectArray3D()
    {
      for(int i = 0; i < ArraySize(data); i++)
      {
        delete data[i];
      }
    }
    
    
  private:
    ObjectArray2D<T> *data[];
};


// ================================== NN classes & functions ==================================

class NN
{
  protected:
    //  output of each neuron
    ObjectArray2D<double> out;
  
    //  delta value for each neuron; delta[i][j]*out[i-1][k] = -dE/dw[i][j][k]
    ObjectArray2D<double> delta;
  
    //  weights for each neuron
    ObjectArray3D<double> w;
  
    //  update values
    ObjectArray3D<double> d;
  
    //  gradients in curent epoch
    ObjectArray3D<double> g;
  
    //  gradient signs in previous epoch
    ObjectArray3D<int> gSign;
  
    //  no of layers in net including input, hidden and output layers
    int numl;
  
    //  number of neurons in each layer
    int lsize[];
  
    //  type of neuron activation function
    const int AFT;
  
    //  switch to turn activation function in the output layer on/off
    const int OAF;
  
    //  neuron activation function
    double af(double in);
  
    //  derivative of activation function
    double afDeriv(double t);
  
    //  sign function
    int sign(double val);
  
    //  training parameters
    double d0;
    double dmin;
    double dmax;
    double plus;
    double minus;
    
  public:
  
    ~NN();
  
    //  initialize and allocate memory
    NN(const int nl, const int &sz[], const int aft, const int oaf, const int uew, const double &extWt[]);
  
    //  backpropogate error for one batch of input training sets
    NNStatus xprop(ObjectArray2D<double> &in, ObjectArray2D<double> &tgt, const int ntr, int nep, const double maxMSE);
  
    //  feedforward activations for one set of inputs
    void ffwd(ObjectArray<double> &in);
    
    //  return i'th output of the net
    double Out(int i) const;
  
    //  return weight
    double Wt(int i, int j, int k) const;
};

//  Initialize and allocate memory on heap ---------------------------------------------------+
NN::NN(const int nl, const int &sz[], const int aft, const int oaf,
     const int uew, const double &extWt[]) : AFT(aft), OAF(oaf)
{
  // set training parameters
  d0    = 0.02;  // orig 0.01, opt 0.02
  dmin  = 0.0;
  dmax  = 50.0;  // orig 50.0
  plus  = 1.2;   // orig 1.2
  minus  = 0.8;  // orig 0.5, opt 0.8-0.85

  //  set number of layers and their sizes
  numl = nl;
  ArrayResize(lsize, numl);
  for(int i = 0; i <numl; i++) lsize[i] = sz[i];

  //  allocate memory for output of each neuron
  out.resize(numl);
  for(int i = 0; i < numl; i++) out[i].resize(lsize[i]);

  //  allocate memory for deltas
  delta.resize(numl);
  for(int i = 1; i < numl; i++) delta[i].resize(lsize[i]);

  //  allocate memory for weights 
  //  w[curr lr #][neuron # in curr lr][input # of curr neuron = neuron # in prev lr]
  w.resize(numl);
  for(int i = 1; i < numl; i++) w[i].resize(lsize[i]);
  for(int i = 1; i < numl; i++)          // for each layer except input
    for(int j = 0; j < lsize[i]; j++)    // for each neuron in current layer
      w[i][j].resize(lsize[i - 1] + 1);  // w[][][lsize[]] is bias

  //  allocate memory for update values
  d.resize(numl);
  for(int i = 1; i < numl; i++) d[i].resize(lsize[i]);
  for(int i = 1; i < numl; i++)          // for each layer except input
    for(int j = 0; j < lsize[i]; j++)    // for each neuron in current layer
      d[i][j].resize(lsize[i - 1] + 1);

  //  allocate memory for new gradients
  g.resize(numl);
  for(int i = 1; i < numl; i++) g[i].resize(lsize[i]);
  for(int i = 1; i < numl; i++)          // for each layer except input
    for(int j = 0; j < lsize[i]; j++)    // for each neuron in current layer
      g[i][j].resize(lsize[i - 1] + 1);

  //  allocate memory for old gradient signs
  gSign.resize(numl);
  for(int i = 1; i < numl; i++) gSign[i].resize(lsize[i]);
  for(int i = 1; i < numl; i++)          // for each layer except input
    for(int j = 0;j < lsize[i]; j++)     // for each neuron in current layer
      gSign[i][j].resize(lsize[i - 1] + 1);

  //  seed and assign random weights (uew=0), or set them equal to external weights (uew=1)
  srand((unsigned)(GetTickCount()));
  int iw = 0;
  for(int i = 1; i < numl; i++)          // for each layer except input
    for(int j = 0; j < lsize[i]; j++)      // for each neuron in current layer
      for(int k = 0; k <= lsize[i - 1]; k++) // for each input of curr neuron incl bias
        if(uew == 0) w[i][j].data[k] = (0.6 * (rand()/(double)32767 - 0.5));
        else w[i][j].data[k] = extWt[iw++];

  //  initialize update values to d0 for the first epoch
  for(int i = 1; i < numl; i++)          // for each layer except input
    for(int j = 0; j < lsize[i]; j++)      // for each neuron in current layer
      for(int k = 0; k <= lsize[i-1]; k++)  // for each input of curr neuron incl bias
        d[i][j].data[k] = d0;

  //  initialize signs of previous gradients to 0 for the first epoch
  for(int i = 1; i < numl; i++)          // for each layer except input
    for(int j = 0; j < lsize[i]; j++)      // for each neuron in current layer
      for(int k = 0; k <= lsize[i-1]; k++)  // for each input of curr neuron incl bias
        gSign[i][j].data[k] = 0;

  //  Note that the following variables are not used:
  //
  //  delta[0][][]
  //  w[0][][]
  //  d[0][][]
  //  g[0][][]
  //  gSign[0][][]
  //
  //  to maintain consistancy in layer numbering: for a net having n layers, input layer is 
  //  numbered as 0th layer, first hidden layer as 1st layer, and the output layer as 
  //  (n-1)th layer. First (0th) layer just stores the inputs, hence there is no delta or 
  //  weight values corresponding to it. Its outputs out[0][] are the net inputs.
}

//  Free up memory ---------------------------------------------------------------------------+
NN::~NN()
{
}

//  Neuron activation function ---------------------------------------------------------------+
double NN::af(double in)
{
  if(AFT==1)
  {
    //  tanh
    double tmp = 2.0 * in;
    if(tmp >= 0)
    {
      tmp = exp(-tmp);
      return ((1.0 - tmp) / (1.0 + tmp));
    }
    else
    {
      tmp = exp(tmp);
      return ((tmp - 1.0) / (tmp + 1.0));
    }
  }
  else if(AFT == 2)
  {
    //  x/(1+|x|)
    return (in / (1.0 + fabs(in)));
  }
  else
  {
    //  sigmoid
    if(in >= 0) return (1.0 / (1.0 + exp(-in)));
    else
    {
      double tmp = exp(in);
      return (tmp / (tmp + 1.0));
    }
  }
}

//  Derivative of activation function --------------------------------------------------------+
double NN::afDeriv(double t)
{
  if(AFT == 1)
  {
    //  tanh
    return 2 * (1 - t * t);
  }
  else if(AFT == 2)
  {
    //  rational x/(1+|x|)
    return (pow(1.0 - fabs(t), 2));
  }
  else
  {
    //  sigmoid
    return (t * (1.0 - t));
  }
}

//  Sign function ----------------------------------------------------------------------------+
int NN::sign(double val)
{
  if (val < 0.0) return -1;
  else if(val == 0.0) return 0;
  else return 1;
} 

//  Return i'th output of the net ------------------------------------------------------------+
double NN::Out(int j) const
{
  return out[numl - 1].data[j];
}

//  Return weight ----------------------------------------------------------------------------+
double NN::Wt(int i, int j, int k) const
{
  return w[i][j].data[k];
}

//  Feedforward one set of input -------------------------------------------------------------+
void NN::ffwd(ObjectArray<double> &in)
{
  // assign input data to the outputs of the 0th layer (i=0)
  for(int j = 0; j < lsize[0]; j++) out[0].data[j] = in.data[j];

  // compute output of each neuron as a sum of its scaled inputs passed through activation func
  for(int i = 1; i < numl; i++)              // for each layer except input
  {
    for(int j = 0; j < lsize[i]; j++)          // for each neuron in current layer
    {
      double sum = 0.0;
      for(int k = 0; k < lsize[i - 1]; k++)      // for each input of curr neuron excl bias
        sum += out[i - 1].data[k] * w[i][j].data[k]; // apply weights to inputs and add to sum
      sum += w[i][j].data[lsize[i - 1]];             // add bias
      if(i==numl-1 && OAF==0) out[i].data[j] = sum;  // apply activation function to all neurons
      else
      {
        out[i].data[j] = af(sum);          // except in the output layer if OAF=0
      }
    }
  }
}

//  Compute new weights and MSE --------------------------------------------------------------+
NNStatus NN::xprop(ObjectArray2D<double> &in, ObjectArray2D<double> &tgt, const int ntr, int nep, const double maxMSE)
{
  double MSE = 0, prevMSE=1.0e9;
  double MSEs, MSEM = 0;
  double MSET = 0, minMSET;
  double MSEsT, MSEMT = 0;
  int ep;
  int minMSETep = 0;
  ulong dwStart = GetTickCount()/1000; // seconds
  int ntr_learn;
  string status;
  
  ntr_learn = ntr * (100 - ValidationPercent) / 100; // for example, 5% - left for validation set
  minMSET = 1000000;
  
  for(ep = 0; ep < nep; ep++)              // for each epoch
  {
    // compute MSE and gradients using backpropagation of error
    MSE = 0.0;
    MSEM = 0.0;

    for(int s = 0; s < ntr_learn; s++)          // for each training set
    {
      // update output values for each neuron
      ffwd(in[s]);

      MSEs = 0.0;
      // find deltas for each neuron in the output layer i=numl-1
      for(int j = 0; j < lsize[numl - 1]; j++)    // for each neuron in output layer
      {
        delta[numl - 1].data[j] = (tgt[s].data[j] - out[numl - 1].data[j]);
        MSEs += pow(delta[numl - 1].data[j], 2);
        if(OAF == 1)
          delta[numl - 1].data[j] *= afDeriv(out[numl - 1].data[j]);
      }
      MSEs = sqrt(MSEs);
      MSE += MSEs;
      if(MSEs > MSEM) MSEM = MSEs;

      // propagate deltas from output layer to hidden layers
      for(int i = numl - 2; i > 0; i--)        // for each layer except input & output
      {
        for(int j = 0; j < lsize[i]; j++)      // for each neuron in current layer
        {
          double sum = 0.0;
          for(int k = 0; k < lsize[i+1]; k++)  // for each neuron in later layer
            sum += delta[i + 1].data[k] * w[i + 1][k].data[j];
          delta[i].data[j] = afDeriv(out[i].data[j]) * sum;
        }
      }

      // compute gradients: dE/dw[i][j][k]=-delta[i][j]*out[i-1][k]
      for(int i = 1; i < numl; i++)          // for each layer except input
      {
        for(int j = 0; j < lsize[i]; j++)      // for each neuron in current layer
        {
          for(int k = 0; k <= lsize[i - 1]; k++)  // for each input of curr neuron incl bias
          {
            //  accumulate gradients for all training sets in each epoch
            if(s == 0) g[i][j].data[k] = 0.0;  // set gradients to 0 at start of each epoch
            if(k == lsize[i - 1])              // acc grad's of bias inputs
              g[i][j].data[k] -= delta[i].data[j];
            else                               // acc gradients of non-bias inputs
              g[i][j].data[k] -= delta[i].data[j] * out[i - 1].data[k];
          }
        }
      }
    }

    MSE /= ntr_learn;

    if(IsStopped())
    {
      NNStatus result(NN_STATE_ABORTED,
        StringFormat("Process aborted at epoch [%u] with max.err. %E, ave.err %E, max.v.err. %E, ave.v. MSE %E",
        ep, MSEM, MSE, MSEMT, MSET));
      return result;
    }

    if(ValidationPercent > 0)
    {
      MSET = 0.0;
      MSEMT = 0.0;
      // count MSE on test part of training set
      for(int s = ntr_learn; s < ntr; s++)
      {
        // update output values for each neuron
        ffwd(in[s]);

        MSEsT = 0.0;
        // find deltas for each neuron in the output layer i=numl-1
        for(int j = 0; j < lsize[numl - 1]; j++)    // for each neuron in output layer
        {
          delta[numl-1].data[j] = tgt[s].data[j] - out[numl-1].data[j];
          MSEsT += pow(delta[numl-1].data[j], 2);
          if(OAF == 1)
          delta[numl - 1].data[j] *= afDeriv(out[numl - 1].data[j]);
        }
        MSEsT = sqrt(MSEsT);
        MSET += MSEsT;
        if(MSEsT > MSEMT) MSEMT = MSEsT;
      }
      MSET /= (ntr - ntr_learn);
    }
    else // use fictious values to keep training
    {
      MSET = MSE;
      MSEMT = MSEM;
    }

    if(MSET < minMSET)
    {
      minMSET = MSET;
      minMSETep = ep;
    }
    else
    {
      if(ep - minMSETep > nep * EpochPercent / 100 && (MSET > TrainValidationMseRatio * minMSET && TrainValidationMseRatio > 0))
      {
        NNStatus result(NN_STATE_TRAINED_BY_VALIDATION,
          StringFormat("Validation stop after epoch [%u]; max.err. %E, ave.err %E, max.v.err. %E, ave.v. MSE %E",
          ep + 1, MSEM, MSE, MSEMT, MSET));
        return result;
      }
    }

    if(MSET < maxMSE)
    {
      NNStatus result(NN_STATE_TRAINED_BY_ACCURACY,
        StringFormat("Network trained in [%u] epochs with max.err. %E, ave. MSE %E",
        ep + 1, MSEMT, MSET));
      return result;
    }

    // compute new weights in batch mode
    for(int i = 1; i < numl; i++)          // for each layer except input
    {
      for(int j = 0; j < lsize[i]; j++)      // for each neuron in current layer
      {
        for(int k = 0; k <= lsize[i-1]; k++)  // for each input of current neuron incl bias
        {
          // batch Rprop
          double prod = g[i][j].data[k] * gSign[i][j].data[k];
          if(prod > 0.0)    // previous weight step reduced error
          {
            d[i][j].data[k] = min(d[i][j].data[k] * plus, dmax);    // increase step
            gSign[i][j].data[k] = sign(g[i][j].data[k]);
            w[i][j].data[k] -= d[i][j].data[k] * gSign[i][j].data[k];
          }
          else if(prod < 0.0)  // previous weight step increased error
          {
            if(MSE > prevMSE)
              w[i][j].data[k] += d[i][j].data[k] * gSign[i][j].data[k];  // backtrack
            d[i][j].data[k] = max(d[i][j].data[k] * minus, dmin);    // reduce step
            gSign[i][j].data[k] = 0;
          }
          else        // typically only happens in the first epoch
          {
            gSign[i][j].data[k] = sign(g[i][j].data[k]);
            w[i][j].data[k] -= d[i][j].data[k] * gSign[i][j].data[k];
          }
        }
      }
    }

    prevMSE = MSE;

    status = StringFormat("Epoch %u, max. %E, ave. %E, max.t. %E, ave.t. %E",
      ep + 1, MSEM, MSE, MSEMT, MSET);
    Comment(status);
  }

  if(ep == nep)
  {
    NNStatus result(NN_STATE_TRAINED_BY_EPOCH_LIMIT,
      StringFormat("Reached the limit of [%u] epochs with max.err. %E, ave.err %E, max.v.err. %E, ave.v. MSE %E",
      nep, MSEM, MSE, MSEMT, MSET));
    return result;
  }

  NNStatus result(NN_STATE_UNDEFINED, status);
  return result;
}


// =========================================== Train ==========================================

NNStatus Train(
  const double &inpTrain[],  // Input training data (2D data as 1D array, oldest first)
  const double &outTarget[], // Output target data for training (2D data as 1D array, oldest first)
  double       &outTrain[],  // Output 1D array to hold net outputs from training
  const int     ntr,         // # of training sets
  const int     UEW,         // Use External Weights for initialization (1=use extInitWt, 0=use rnd)
  const double &extInitWt[], // Input 1D array to hold 3D array of external initial weights
  double       &trainedWt[], // Output 1D array to hold 3D array of trained weights
  const int     numLayers,   // # of net layers including input, hidden and output
  const int    &lSz[],       // # of neurons in layers. lSz[0] is # of net inputs (nin)
  const int     AFT,         // Type of neuron activation function (0:sigm, 1:tanh, 2:x/(1+x))
  const int     OAF,         // 1 enables activation function for output layer neurons; 0 disables
  const int     nep,         // Max # of training epochs
  const double  maxMSE       // Max MSE; training stops once maxMSE is reached
) export
{
  uint first = GetTickCount();

  // Prepare input data -----------------------------------------------------------------------+
  int nin = lSz[0];
  int nout = lSz[numLayers - 1];

  // Create a 2D array to hold input training data
  ObjectArray2D<double> trainData(ntr);
  
  for(int i = 0; i < ntr; i++) trainData[i].resize(nin);
  
  for(int i = 0; i < ntr; i++)
    for(int j = 0; j < nin; j++) trainData[i].data[j] = inpTrain[i * nin + j];
    
  // Create a 2D array to hold output target data used for training
  ObjectArray2D<double> targetData(ntr);
  
  for(int i = 0; i < ntr; i++) targetData[i].resize(nout);
  for(int i = 0; i < ntr; i++)
    for(int j = 0; j < nout; j++) targetData[i].data[j] = outTarget[i * nout + j];

  // The input data is arranged as follows:
  //
  // trainData[i][j] = inpTrain[i*nin+j]
  //      j= 0...nin-1
  //            |
  // i=0     <inputs>
  // ...     <inputs>
  // i=ntr-1 <inputs>
  //
  // targetData[i][j] = outTarget[i*nout+j]
  //      j= 0...nout-1
  //             |
  // i=0     <targets>
  // ...     <targets>
  // i=ntr-1 <targets>

  //  Create & train NN ------------------------------------------------------------------------+
  NN *bp = new NN(numLayers, lSz, AFT, OAF, UEW, extInitWt);
  NNStatus result = bp.xprop(trainData, targetData, ntr, nep, maxMSE);

  //  Save output data -------------------------------------------------------------------------+
  for(int i = 0; i < ntr; i++)
  {
    bp.ffwd(trainData[i]);
    for(int j = 0; j < nout; j++) outTrain[i * nout + j] = bp.Out(j);
  }
  int iw = 0;
  for(int i = 1; i < numLayers; i++)    // for each layer except input
    for(int j = 0; j < lSz[i]; j++)       // for each neuron in current layer
      for(int k = 0; k <= lSz[i - 1]; k++)  // for each input of current neuron including bias
        trainedWt[iw++] = bp.Wt(i, j, k);

  // The output data is arranged as follows:
  //
  // outTrain[i*nout+j]
  //      j= 0...nout-1
  //             |
  // i=0     <outputs>
  // ...     <outputs>
  // i=ntr-1 <outputs>

  //  Free up memory ---------------------------------------------------------------------------+
  delete bp;
  
  Print("Training finished in " + (string)((GetTickCount() - first) / 1000) + " seconds");

  return result;
}

// =========================================== Test ===========================================

void Test(
  const double &inpTest[],  // Input test data (2D data as 1D array, oldest first)
  double       &outTest[],  // Net outputs from testing
  const int     ntt,        // # of test sets
  const double &extInitWt[],// Input 1D array to hold 3D array of external initial weights
  const int     numLayers,  // # of net layers including input, hidden and output
  const int    &lSz[],      // # of neurons in layers. lSz[0] is # of net inputs (nin)
  const int     AFT,        // Type of neuron activation function (0:sigm, 1:tanh, 2:x/(1+x))
  const int     OAF         // 1 enables activation function for output layer neurons; 0 disables
) export
{
  // Prepare input data -----------------------------------------------------------------------+
  int nin = lSz[0];
  int nout = lSz[numLayers - 1];

  ObjectArray2D<double> testData(ntt);
  
  for(int i = 0; i < ntt; i++) testData[i].resize(nin);
  for(int i = 0; i < ntt; i++)
  {
    for(int j = 0; j < nin; j++)
    {
      testData[i].data[j] = inpTest[i * nin + j];
    }
  }
  // The input data is arranged as follows:
  //
  // testData[i][j] = inpTest[i*nin+j]
  //      j= 0...nin-1
  //            |
  // i=0     <inputs>
  // ...     <inputs>
  // i=ntt-1 <inputs>
  //
  // <inputs> start with the oldest value first

  //  Create & test NN -------------------------------------------------------------------------+
  NN *bp = new NN(numLayers, lSz, AFT, OAF, 1, extInitWt);
  for(int i = 0; i < ntt; i++)
  {
    bp.ffwd(testData[i]);
    for(int j = 0; j < nout; j++)
    {
      outTest[i * nout + j] = bp.Out(j);
    }
  }
  // The output data is arranged as follows:
  //
  // outTest[i*nout+j]
  //      j= 0...nout-1
  //             |
  // i=0     <outputs>
  // ...     <outputs>
  // i=ntt-1 <outputs>

  //  Free up memory ---------------------------------------------------------------------------+
  delete bp;
}

void ValidationSet(int Percent, int MseRatio, int BadEpochCountPercent) export
{
  ValidationPercent = Percent;
  TrainValidationMseRatio = MseRatio;
  EpochPercent = BadEpochCountPercent;
}
