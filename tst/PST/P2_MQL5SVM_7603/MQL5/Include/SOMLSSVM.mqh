//+------------------------------------------------------------------+
//|                                                     SOMLSSVM.mqh |
//|                                    Copyright (c) 2020, Marketeer |
//|                          https://www.mql5.com/en/users/marketeer |
//| SOM-LS-SVM implementation for MQL5                         v.1.0 |
//|                            https://www.mql5.com/ru/articles/7603 |
//+------------------------------------------------------------------+

//                              S Y N O P S I S
//
// Predicted function:
//
// Yt = W1 * F(Xt-1) + W2 * F(Xt-2) + ... Wn * F(Xt-n) + b
// F is a non-linear function, which form is not known analytically
// Y and Xs are prices/differences
//
// Which exactly Xt-i to take into this vector and how big n should be is determined by PACF analysis.
//
// Optimization model for LSSVM is the System of Linear Equations:
//
// Y(|X|) = Sum[i=1..N](alpha_i * K(|X|,|X|i)) + b,
// where |X| is the input vector with predictors, alpha_i and b - optimized (calculated) parameters,
// K - the kernel function:
// K(X1,X2) = exp(-(X1-X2)^2/2*S^2),
// where S is a sigma meta-parameter
//
// On every step current values of Gamma and Sigma exist.
// With this parameters solve the linear system:
//
// |  0               |1|            |   |    b    |   |  0  |
// |                                 | * |         | = |     |
// | |1|  |Omega| + |Identity|/Gamma |   | |Alpha| |   | |Y| |
// where Gamma is a regularization meta-parameter (tradeoff between the fitting error minimization and smoothness),
// Omega is N*N matrix built from Kernels on all pairwise combinations of input vectors |X|.
//
// 0. Calculate Omega
// 1. choose Gamma and Sigma randomly/consequently on a wide grid (probably they can be estimated beforehand)
// 2. solve the linear system to obtain Alpha and Beta
// 3. use Alpha and Beta in the model
//
// N-order differencing
//     bar numbers (NOT time-series ordering)
// D0:  0   1   2   3   4   5  :Y
// D1:    0   1   2   3   4
// D2:      0   1   2   3
// D3:        0   1   2
// Y[1] = Y[0] + D1[0]
// Y[2] = Y[1] + D1[1] = Y[1] + (D1[0] + D2[0]) = Y[1] + (Y[1] - Y[0] + D2'[0]) = 2 * Y[1] - Y[0] + D2'
// Y[3] = Y[2] + D1[2] = Y[2] + (D1[1] + D2[1]) = Y[2] + (D1[1] + D2[0] + D3'[0]) = Y[2] + (D1[1] + D1[1] - D1[0] + D3'[0])
//                       Y[2] + (2 * D1[1] - D1[0] + D3'[0])
//                       Y[2] + 2 * (Y[2] - Y[1]) - (Y[1] - Y[0]) + D3'[0]
//                       3 * Y[2] - 3 * Y[1] + Y[0] + D3'
// ' - denotes prediction


#include <Math/Alglib/dataanalysis.mqh>
#include <CSOM/CSOM.mqh>


//#define DEBUGLOG
#define PRT(T, A) Print(T, " ", #A, " ", (A))

#define XX(N,I) X[(N) * VectorSize + (I)]


class LSSVM
{
  protected:
    double X[];
    double Y[];
    double Alpha[];
    double Omega[];
    double Beta;

    double Sigma;
    double Sigma22; // 2 * Sigma * Sigma;
    double Gamma;
    double Threshold;

    double tempGamma;
    double tempSigma;

    double Mean;
    double StdDev;
    
    int VectorNumber;
    int VectorSize;
    int Offset;
    int DifferencingOrder;

    double Kernels[];  // SOM clusters
    int KernelNumber;
    CSOM KohonenMap;

    double Solution[]; // LS-regression (demo option)
    
    LSSVM *crossvalidator;

    bool autodatafeed;
  
  public:
    struct LSSVM_Error
    { // indices: 0 - training set, 1 - test set
      double RMSE[2]; // RMSE
      double CC[2];   // Correlation Coefficient
      double R2[2];   // R-squared
      double PCT[2];  // %
    };

  protected:
    bool trainSOM(const int kernels, const int epochNumber, const bool showProgress = false, const bool useNormalization = false)
    {
      // normalization is performed by LSSVM class, this is why SOM normalization is off by default
      KohonenMap.Reset();
    
      string titles[];
      ArrayResize(titles, VectorSize);
      for(int i = 0; i < VectorSize; i++)
      {
        titles[i] = (string)(i + 1);
      }
      KohonenMap.AssignFeatureTitles(titles); // this defines size of data vector
      
      double x[];
      for(int i = 0; i < VectorNumber; i++)
      {
        vector(i, x);
        KohonenMap.AddPattern(x, (string)(float)Y[i]);
      }
      
      const int cellsXY = (int)sqrt(kernels);
      const bool hexagonalCell = true;
      
      KohonenMap.Init(cellsXY, cellsXY, hexagonalCell);
    
      if(KohonenMap.Train(epochNumber, useNormalization, showProgress) == 0)
      {
        Print("Kohonen training failed");
        return false;
      }
    
      return true;
    }
    
    bool obtainKernels()
    {
      double weights[];
      const int n = KohonenMap.GetSize();
      if(n != KernelNumber)
      {
        Print("SOM size ", n, " does not match kernel number ", KernelNumber);
        return false;
      }
      for(int i = 0; i < n; i++)
      {
        KohonenMap.GetBestMatchingFeatures(i, weights);
        ArrayCopy(Kernels, weights, i * VectorSize, 0, VectorSize);
      }
      return true;
    }

    void preserveDataState()
    {
      tempGamma = Gamma;
      tempSigma = Sigma;
    }
    
    void restoreDataState()
    {
      Gamma = tempGamma;
      Sigma = tempSigma;
      Sigma22 = 2 * Sigma * Sigma;
    }

  public:
    LSSVM(const int VN, const int VS, const int K, const double G, const double S, const int O)
    {
      Sigma = S;
      Sigma22 = 2 * S * S;
      Gamma = G;
      Beta = 0;
      VectorNumber = VN;
      VectorSize = VS;
      Threshold = 0;
      Offset = O;
      KernelNumber = K;
      crossvalidator = NULL;
      DifferencingOrder = 1;
      autodatafeed = true;
    }

    LSSVM(const int VN, const int VS, const int K, const int O)
    {
      Beta = 0;
      VectorNumber = VN;
      VectorSize = VS;
      Threshold = 0;
      Offset = O;
      KernelNumber = K;
      crossvalidator = NULL;
      DifferencingOrder = 1;
      autodatafeed = true;
    }
    
    void setThreshold(const double T)
    {
      Threshold = T;
    }

    void setGamma(const double G)
    {
      Gamma = G;
    }

    void setSigma(const double S)
    {
      Sigma = S;
      Sigma22 = 2 * S * S;
    }
    
    void setDifferencingOrder(const int d)
    {
      DifferencingOrder = d;
    }
    
    static string shortPeriodName(const ENUM_TIMEFRAMES p)
    {
      // "PERIOD_"
      return StringSubstr(EnumToString(p), 7);
    }
    
    int getVectorNumber() const
    {
      return VectorNumber;
    }
    
    int getVectorSize() const
    {
      return VectorSize;
    }
    
    bool isAutoDataFeeded() const
    {
      return autodatafeed;
    }

    void vector(const int n, double &out[]) const
    {
      ArrayResize(out, VectorSize);
      ArrayCopy(out, X, 0, n * VectorSize, VectorSize);
    }

    double kernel(const int x1, const int x2) const
    {
      double sum = 0;
      for(int i = 0; i < VectorSize; i++)
      {
        double x1i = XX(x1, i);
        double x2i = XX(x2, i);
        sum += (x1i - x2i) * (x1i - x2i);
      }
      return exp(-1 * sum / Sigma22);
    }
    
    double kernel(const double &x1[], const double &x2[]) const
    {
      double sum = 0;
      for(int i = 0; i < VectorSize; i++)
      {
        sum += (x1[i] - x2[i]) * (x1[i] - x2[i]);
      }
      return exp(-1 * sum / Sigma22);
    }

    double approximate(const double &x[]) const
    {
      double sum = 0;
      double data[];
    
      if(ArraySize(x) + 1 == ArraySize(Solution))
      {
        for(int i = 0; i < ArraySize(x); i++)
        {
          sum += Solution[i] * x[i];
        }
        sum += Solution[ArraySize(x)];
      }
      else
      {
        if(KernelNumber == 0 || KernelNumber == VectorNumber)
        {
          for(int i = 0; i < VectorNumber; i++)
          {
            vector(i, data);
            sum += Alpha[i] * kernel(x, data);
          }
        }
        else
        {
          for(int i = 0; i < KernelNumber; i++)
          {
            ArrayCopy(data, Kernels, 0, i * VectorSize, VectorSize);
            sum += Alpha[i] * kernel(x, data);
          }
        }
      }
      return sum + Beta;
    }

    void differentiate(const double &open[], const int ij, double &diff[])
    {
      for(int q = 0; q <= DifferencingOrder; q++)
      {
        diff[q] = open[ij + q];
      }
      
      int d = DifferencingOrder;
      while(d > 0)
      {
        for(int q = 0; q < d; q++)
        {
          diff[q] = diff[q + 1] - diff[q];
        }
        d--;
      }
    }
    
    // fills output v with latest known prices for VectorSize bars taking DifferencingOrder into account
    bool buildVector(double &v[])
    {
      double open[];
      const int size = VectorSize + DifferencingOrder;
      const int copied = CopyOpen(_Symbol, _Period, Offset, size, open);
      if(copied != size)
      {
        Print("No data for last vector: ", copied, ", requested: ", size);
        return false;
      }

      ArrayResize(v, VectorSize);

      double diff[];
      ArrayResize(diff, DifferencingOrder + 1);

      for(int j = 0; j < VectorSize; j++)
      {
        differentiate(open, j, diff);
        v[j] = diff[0];
      }
      
      return true;
    }
    
    void reset()
    {
      ArrayResize(X, 0);
      ArrayResize(Y, 0);
      VectorNumber = 0;
    }
    
    // custom data input: NOT TESTED
    bool feedXYVectors(const double &data[])
    {
      const int vectorNumber = ArraySize(data) - VectorSize - DifferencingOrder;

      int k = ArraySize(X);
      int m = ArraySize(Y);
      
      double diff[];
      ArrayResize(diff, DifferencingOrder + 1);
      
      for(int i = 0; i < vectorNumber; i++)
      {
        for(int j = 0; j < VectorSize; j++)
        {
          differentiate(data, i + j, diff);

          ArrayResize(X, k + 1);
          X[k++] = diff[0];
        }

        differentiate(data, i + VectorSize, diff);
        ArrayResize(Y, m + 1);
        Y[m++] = diff[0];
      }
      
      VectorNumber += ArraySize(Y) - m;
      autodatafeed = false;
      
      return true;
    }

    bool buildXYVectors()
    {
      ArrayResize(X, VectorNumber * VectorSize);
      ArrayResize(Y, VectorNumber);
      double open[];
      int k = 0;
      const int size = VectorNumber + VectorSize + DifferencingOrder; // +1 is included for future Y
      const int copied = CopyOpen(_Symbol, _Period, Offset, size, open);
      if(copied != size)
      {
        Print("Not enough data copied: ", copied, ", requested: ", size);
        return false;
      }
      
      // VectorNumber = 10, VectorSize = 5
      // 0 1 2 3 4 5 6 7 8 9  0 1 2 3 4
      // + + + + + *
      //   + + + + + *
      //     + + + + + *
      //       + + + + + *
      //         + + + + + *
      //           + + + + +  *
      //             + + + +  + *
      //               + + +  + + *
      //                 + +  + + + *
      //                   +  + + + + *
      
      double diff[];
      ArrayResize(diff, DifferencingOrder + 1); // order 1 means 2 values, 1 subtraction
      
      for(int i = 0; i < VectorNumber; i++)     // loop through anchor bars
      {
        for(int j = 0; j < VectorSize; j++)     // loop through successive bars
        {
          differentiate(open, i + j, diff);

          X[k++] = diff[0];
        }

        differentiate(open, i + VectorSize, diff);
        Y[i] = diff[0];
      }
      #ifdef DEBUGLOG
      Print(" === X === ");
      ArrayPrint(X);
      Print(" === Y === ");
      ArrayPrint(Y);
      #endif
    
      return true;
    }

    void normalizeXYVectors(const bool ns = true)
    {
      // calculate mean and sigma
      double sumx = 0, sumx2 = 0;
      
      const int n = VectorNumber * VectorSize;
      for(int i = 0; i < n; i++)
      {
        sumx += X[i];
        sumx2 += X[i] * X[i];
      }
      const double mean = sumx / n; // near 0 for non-trended differenced time-series
      const double variance = (sumx2 - sumx * sumx / n) / MathMax(n - 1, 1);
      
      if(Sigma == 0)
      {
        Sigma = VectorSize;
        Sigma22 = 2 * Sigma * Sigma;
        PRT("[auto]", Sigma22);
      }

      if(Gamma == 0)
      {
        Gamma = VectorNumber;
        PRT("[auto]", Gamma);
      }
      
      // (X - means) / sigma, (Y - mean) / sigma
      if(ns)
      {
        Mean = mean;
        StdDev = sqrt(variance);

        for(int i = 0; i < n; i++)
        {
          X[i] -= mean;
          X[i] /= StdDev;
        }
        for(int i = 0; i < VectorNumber; i++)
        {
          Y[i] -= mean;
          Y[i] /= StdDev;
        }
      }
      else
      {
        Mean = 0;
        StdDev = 1;
      }
    }

    void normalizeVector(double &x[]) const
    {
      const int n = ArraySize(x);
      for(int i = 0; i < n; i++)
      {
        x[i] -= Mean;
        x[i] /= StdDev;
      }
    }
    
    double denormalize(const double y) const
    {
      return y * StdDev + Mean;
    }
    
    double getMean() const
    {
      return Mean;
    }
    
    double getStdDev() const
    {
      return StdDev;
    }

    void buildOmega()
    {
      KernelNumber = VectorNumber;

      ArrayResize(Omega, VectorNumber * VectorNumber);
    
      for(int i = 0; i < VectorNumber; i++)
      {
        for(int j = i; j < VectorNumber; j++)
        {
          const double k = kernel(i, j);
          Omega[i * VectorNumber + j] = k;
          Omega[j * VectorNumber + i] = k;
          
          if(i == j)
          {
            Omega[i * VectorNumber + j] += 1 / Gamma;
            Omega[j * VectorNumber + i] += 1 / Gamma;
          }
        }
      }
      #ifdef DEBUGLOG
      Print(" === Omega === ");
      ArrayPrint(Omega);
      #endif
    }

    bool buildKernels()
    {
      if(KernelNumber < 4) KernelNumber = 4;

      const int sqs = (int)sqrt(KernelNumber);
      if(sqs * sqs != KernelNumber)
      {
        KernelNumber = sqs * sqs;
        Print("Kernel number must be a squared number, adjusted to ", KernelNumber);
      }
      
      if(!trainSOM(KernelNumber, 200))
      {
        return false;
      }

      ArrayResize(Kernels, VectorSize * KernelNumber);
      obtainKernels();
    
      ArrayResize(Omega, KernelNumber * KernelNumber);
      double x1[], x2[];
      ArrayResize(x1, VectorSize);
      ArrayResize(x2, VectorSize);
    
      for(int i = 0; i < KernelNumber; i++)
      {
        for(int j = i; j < KernelNumber; j++)
        {
          ArrayCopy(x1, Kernels, 0, i * VectorSize, VectorSize);
          ArrayCopy(x2, Kernels, 0, j * VectorSize, VectorSize);
          
          const double xy = kernel(x1, x2);
          
          Omega[i * KernelNumber + j] = xy;
          Omega[j * KernelNumber + i] = xy;
          
          if(i == j)
          {
            Omega[i * KernelNumber + j] += 1 / Gamma;
            Omega[j * KernelNumber + i] += 1 / Gamma;
          }
        }
      }
      #ifdef DEBUGLOG
      Print(" === Kernels' Omega === ");
      ArrayPrint(Omega);
      #endif
      return true;
    }

    // linear regression by least squares
    bool regress(void)
    {
      CMatrixDouble MATRIX(VectorNumber, VectorSize + 1); // +1 stands for b column
      
      for(int i = 0; i < VectorNumber; i++)
      {
        MATRIX[i].Set(VectorSize, Y[i]);
      }

      for(int i = 0; i < VectorSize; i++)
      {
        for(int j = 0; j < VectorNumber; j++)
        {
          MATRIX[j].Set(i, X[j * VectorSize + i]);
        }
      }
      
      CLinearModel LM;
      CLRReport AR;
      int info;
    
      CLinReg::LRBuildZ(MATRIX, VectorNumber, VectorSize, info, LM, AR);
      if(info != 1)
      {
        Alert("Error in regression model!");
        return false;
      }
      
      int _size;
      CLinReg::LRUnpack(LM, Solution, _size);
      
      Print("RMSE=" + (string)AR.m_rmserror);
      ArrayPrint(Solution);
    
      return true;
    }

    bool solveSoLE()
    {
      // |  0              |1|           |   |  Beta   |   |  0  |
      // |                               | * |         | = |     |
      // | |1|  |Omega| + Identity/Gamma |   | |Alpha| |   | |Y| |
    
      CMatrixDouble MATRIX(KernelNumber + 1, KernelNumber + 1);
      
      for(int i = 1; i <= KernelNumber; i++)
      {
        for(int j = 1; j <= KernelNumber; j++)
        {
          MATRIX[j].Set(i, Omega[(i - 1) * KernelNumber + (j - 1)]);
        }
      }
      
      MATRIX[0].Set(0, 0);
      for(int i = 1; i <= KernelNumber; i++)
      {
        MATRIX[i].Set(0, 1);
        MATRIX[0].Set(i, 1);
      }
      
      double B[];
      ArrayResize(B, KernelNumber + 1);
      B[0] = 0;
      for(int j = 1; j <= KernelNumber; j++)
      {
        B[j] = Y[j - 1];
      }

      int info;
      CDenseSolverLSReport rep;
      double x[];
      
      CDenseSolver::RMatrixSolveLS(MATRIX, KernelNumber + 1, KernelNumber + 1, B,
                                   Threshold, info, rep, x);
      if(info != 1)
      {
        Print("Error in matrix!");
        return false;
      }
      #ifdef DEBUGLOG
      ArrayPrint(x);
      #endif
      
      Beta = x[0];
      ArrayResize(Alpha, KernelNumber);
      ArrayCopy(Alpha, x, 0, 1);
      
      return true;
    }
    
    // optional: make Alpha "sparse"
    void sparse(const double fractionToKeep = 0.85)
    {
      double sort[][2];
      const int n = ArraySize(Alpha);
      ArrayResize(sort, n);
      double total = 0.0;
      int i;

      for(i = 0; i < n; i++)
      {
        sort[i][0] = MathAbs(Alpha[i]);
        sort[i][1] = i;
        total += Alpha[i] * Alpha[i];
      }
      
      ArraySort(sort);
      double part = 0.0;
      total *= fractionToKeep;
      for(i = n - 1; i >= 0; i--)
      {
        part += sort[i][0] * sort[i][0];
        if(part >= total)
        {
          break;
        }
      }
      
      for(; i >= 0; i--)
      {
        Alpha[(int)sort[i][1]] = 0;
      }
    }
    
    double check(const int i) const
    {
      double data[];
      vector(i, data);
      const double z = approximate(data);
      #ifdef DEBUGLOG
      ArrayPrint(data);
      Print("Y[", i, "]=", Y[i], " -> ", z);
      #endif
      return z;
    }
    
    // return RMSE and Correlation for normalized target data and estimation
    void checkAll(LSSVM_Error &result)
    {
      result.RMSE[0] = result.RMSE[1] = 0;
      result.CC[0] = result.CC[1] = 0;
      result.R2[0] = result.R2[1] = 0;
      result.PCT[0] = result.PCT[1] = 0;

      double xy = 0;
      double x2 = 0;
      double y2 = 0;
      int correct = 0;

      double out[];
      getResult(out);

      for(int i = 0; i < VectorNumber; i++)
      {
        double given = Y[i];
        double trained = out[i];
        result.RMSE[0] += (given - trained) * (given - trained);
        // mean is 0 after normalization
        xy += (given) * (trained);
        x2 += (given) * (given);
        y2 += (trained) * (trained);
        
        if(given * trained > 0) correct++;
      }

      result.R2[0] = 1 - result.RMSE[0] / x2;
      result.RMSE[0] = sqrt(result.RMSE[0] / VectorNumber);
      result.CC[0] = xy / sqrt(x2 * y2);
      result.PCT[0] = correct * 100.0 / VectorNumber;
      
      crossvalidate(result); // fill metrics for test set (if attached)
    }
    
    double calcMSE()
    {
      double error = 0;
      for(int i = 0; i < VectorNumber; i++)
      {
        double e = check(i) - Y[i];
        error += e * e;
      }
      error /= VectorNumber;
      return sqrt(error);
    }

    // return target/required output
    void getY(double &out[], const bool reverse = false) const
    {
      ArrayResize(out, VectorNumber);
      for(int i = 0; i < VectorNumber; i++)
      {
        out[i] = Y[i];
      }
      if(reverse) ArrayReverse(out);
    }
    
    // return actual/estimated output
    void getResult(double &out[], const bool reverse = false) const
    {
      ArrayResize(out, VectorNumber);
      for(int i = 0; i < VectorNumber; i++)
      {
        out[i] = check(i);
      }
      if(reverse) ArrayReverse(out);
    }

    bool process(const bool ns = true, const double sparsity = 0)
    {
      if(!initcrossvalidator()) return false;
      if(autodatafeed)
      {
        if(!buildXYVectors()) return false; // will try on another tick/bar
        normalizeXYVectors(ns);
      }
      
      // least squares linear regression for demo purpose only
      if(KernelNumber == -1 || KernelNumber > VectorNumber)
      {
        return regress();
      }
      
      if(KernelNumber == 0 || KernelNumber == VectorNumber)
      {
        buildOmega();
      }
      else
      {
        if(!buildKernels()) return false;
      }
      if(!solveSoLE()) return false;
      
      if(sparsity > 0) sparse(sparsity);

      LSSVM_Error result;
      checkAll(result);
      ErrorPrint(result);
      // Print("Parameters: ", Gamma, " ", Sigma, "(", Sigma22, ")");

      return true;
    }
    
    // provide the best parameters to outer world
    double getGamma() const
    {
      return Gamma;
    }
    
    double getSigma() const
    {
      return Sigma;
    }
    
    bool bindCrossValidator(LSSVM *tester)
    {
      if(CheckPointer(tester) != POINTER_INVALID)
      {
        if(tester.getVectorSize() == VectorSize)
        {
          crossvalidator = tester;
          return true;
        }
      }
      return false;
    }
    
    bool initcrossvalidator(const bool ns = true)
    {
      if(CheckPointer(crossvalidator) != POINTER_INVALID)
      {
        if(crossvalidator.isAutoDataFeeded())
        {
          if(!crossvalidator.buildXYVectors()) return false;
          crossvalidator.normalizeXYVectors(ns);
        }
      }
      return true;
    }
    
    void crossvalidate(LSSVM_Error &result)
    {
      if(CheckPointer(crossvalidator) == POINTER_INVALID) return;
    
      const int vectorNumber = crossvalidator.getVectorNumber();
      // const double m2 = crossvalidator.getMean();

      double out[];
      double _Y[];
      crossvalidator.getY(_Y); // assumed normalized by validator
      
      double xy = 0;
      double x2 = 0;
      double y2 = 0;
      int correct = 0;
      
      for(int i = 0; i < vectorNumber; i++)
      {
        crossvalidator.vector(i, out);
  
        double z = approximate(out);
        
        result.RMSE[1] += (_Y[i] - z) * (_Y[i] - z);
        xy += (_Y[i]) * (z);
        x2 += (_Y[i]) * (_Y[i]);
        y2 += (z) * (z);
        
        if(_Y[i] * z > 0) correct++;
      }

      result.R2[1] = 1 - result.RMSE[1] / x2;
      result.RMSE[1] = sqrt(result.RMSE[1] / vectorNumber);
      result.CC[1] = xy / sqrt(x2 * y2);
      result.PCT[1] = correct * 100.0 / vectorNumber;
    }

    void ErrorPrint(const LSSVM_Error &error) const
    {
      Print("RMSE: ", (float)error.RMSE[0], " / ", (float)error.RMSE[1],
            "; CC: ", (float)error.CC[0], " / ", (float)error.CC[1],
            "; R2: ", (float)error.R2[0], " / ", (float)error.R2[1]);
    }

};

template<typename T>
void StructPrint(T &_struct)
{
  T array[1];
  array[0] = _struct;
  ArrayPrint(array);
}
