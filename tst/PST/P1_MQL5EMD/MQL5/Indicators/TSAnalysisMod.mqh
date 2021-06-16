//-----------------------------------------------------------------------------------
//                                                                  TSAnalysisMod.mqh
//                                        Copyright (c) 2012-2020, victorg, Marketeer
//                                            https://www.mql5.com/en/users/marketeer
//-----------------------------------------------------------------------------------
#property copyright "Copyright (c) 2012-2020, victorg, Marketeer"
#property link "https://www.mql5.com/en/users/marketeer"
#property version "3.0"

struct TSStatMeasures
{
  double MinTS;      // Minimum time series value
  double MaxTS;      // Maximum time series value
  double Median;     // Median
  double Mean;       // Mean (average)
  double Var;        // Variance
  double uVar;       // Unbiased variance
  double StDev;      // Standard deviation
  double uStDev;     // Unbiaced standard deviation
  double Skew;       // Skewness
  double Kurt;       // Kurtosis
  double ExKurt;     // Excess Kurtosis
  double JBTest;     // Jarque-Bera test
  double JBpVal;     // JB test p-value
  double AJBTest;    // Adjusted Jarque-Bera test
  double AJBpVal;    // AJB test p-values
  double maxOut;     // Sequence Plot. Border of outliers
  double minOut;     // Sequence Plot. Border of outliers
  double UPLim;      // ACF. Upper limit (5% significance level)
  double LOLim;      // ACF. Lower limit (5% significance level)
  int NLags;         // Number of lags for ACF and PACF Plot
  int IP;            // Autoregressive model order
};

#define TS_GEN_ARRAY(NAME,ARRAY) \
    int get##NAME(double &result[]) const \
    { \
      ArrayResize(result, ArraySize(ARRAY)); \
      return ArrayCopy(result, ARRAY); \
    }

#define TS_STATS(NAME) result.NAME = NAME;

#define TS_GEN_SWITCH(ELEMENT) case tsa_##ELEMENT: return get##ELEMENT(result);


enum TSA_TYPE
{
  tsa_TimeSeries,
  tsa_TimeSeriesSorted,
  tsa_TimeSeriesCentered,
  tsa_HistogramX,
  tsa_HistogramY,
  tsa_NormalProbabilityX,
  tsa_ACF,
  tsa_ACFConfidenceBandUpper,
  tsa_ACFConfidenceBandLower,
  tsa_ACFSpectrumY,
  tsa_PACF,
  tsa_ARSpectrumY,
  tsa_Size //  
};        //  ^ non-breaking space (to hide aux element tsa_Size name)
    
//-----------------------------------------------------------------------------------
class TSAnalysis
{
  protected:
    double TS[];       // Time series
    double TSort[];    // Sorted time series
    double TSCenter[]; // Centered time series ( TS[] - mean )
    int NumTS;         // Number of time series data points
    double MinTS;      // Minimum time series value
    double MaxTS;      // Maximum time series value
    double Median;     // Median
    double Mean;       // Mean (average)
    double Var;        // Variance
    double uVar;       // Unbiased variance
    double StDev;      // Standard deviation
    double uStDev;     // Unbiaced standard deviation
    double Skew;       // Skewness
    double Kurt;       // Kurtosis
    double ExKurt;     // Excess Kurtosis
    double JBTest;     // Jarque-Bera test
    double JBpVal;     // JB test p-value
    double AJBTest;    // Adjusted Jarque-Bera test
    double AJBpVal;    // AJB test p-values
    double maxOut;     // Sequence Plot. Border of outliers
    double minOut;     // Sequence Plot. Border of outliers
    double XHist[];    // Histogram. X-axis
    double YHist[];    // Histogram. Y-axis
    double Xnpp[];     // Normal Probability Plot. X-axis
    int NLags;         // Number of lags for ACF and PACF Plot
    double ACF[];      // Autocorrelation function (correlogram)
    double UPLim;      // ACF. Upper limit (5% significance level)
    double LOLim;      // ACF. Lower limit (5% significance level)
    double CBup[];     // ACF. Upper limit (confidence bands)
    double CBlo[];     // ACF. Lower limit (confidence bands)
    double Spect[];    // ACF Spectrum. Y-axis
    double PACF[];     // Partial autocorrelation function
    int IP;            // Autoregressive model order
    double ARSp[];     // AR Spectrum. Y-axis

  public:
    TSAnalysis();
    TSAnalysis(const double &ts[]);
    void Calc(const double &ts[]); // Main calculation

    void getStatMeasures(TSStatMeasures &result)
    {
      TS_STATS(MinTS);
      TS_STATS(MaxTS);
      TS_STATS(Median);
      TS_STATS(Mean);
      TS_STATS(Var);
      TS_STATS(uVar);
      TS_STATS(StDev);
      TS_STATS(uStDev);
      TS_STATS(Skew);
      TS_STATS(Kurt);
      TS_STATS(ExKurt);
      TS_STATS(JBTest);
      TS_STATS(JBpVal);
      TS_STATS(AJBTest);
      TS_STATS(AJBpVal);
      TS_STATS(maxOut);
      TS_STATS(minOut);
      TS_STATS(UPLim);
      TS_STATS(LOLim);
      TS_STATS(NLags);
      TS_STATS(IP);
    }

    TS_GEN_ARRAY(TimeSeries, TS)
    TS_GEN_ARRAY(TimeSeriesSorted, TSort)
    TS_GEN_ARRAY(TimeSeriesCentered, TSCenter)
    TS_GEN_ARRAY(HistogramX, XHist);
    TS_GEN_ARRAY(HistogramY, YHist);
    TS_GEN_ARRAY(NormalProbabilityX, Xnpp);
    TS_GEN_ARRAY(ACF, ACF);
    TS_GEN_ARRAY(ACFConfidenceBandUpper, CBup);
    TS_GEN_ARRAY(ACFConfidenceBandLower, CBlo);
    TS_GEN_ARRAY(ACFSpectrumY, Spect);
    TS_GEN_ARRAY(PACF, PACF);
    TS_GEN_ARRAY(ARSpectrumY, ARSp);

    int getResult(const TSA_TYPE type, double &result[]) const
    {
      switch(type)
      {
        TS_GEN_SWITCH(TimeSeries);
        TS_GEN_SWITCH(TimeSeriesSorted)
        TS_GEN_SWITCH(TimeSeriesCentered)
        TS_GEN_SWITCH(HistogramX);
        TS_GEN_SWITCH(HistogramY);
        TS_GEN_SWITCH(NormalProbabilityX);
        TS_GEN_SWITCH(ACF);
        TS_GEN_SWITCH(ACFConfidenceBandUpper);
        TS_GEN_SWITCH(ACFConfidenceBandLower);
        TS_GEN_SWITCH(ACFSpectrumY);
        TS_GEN_SWITCH(PACF);
        TS_GEN_SWITCH(ARSpectrumY);
        //case tsa_#ELEMENT: return get##ELEMENT(result);
      }
      return 0;
    }

  protected:
    double ndtri(double y); // Inverse of Normal distribution function
    void LevinsonRecursion(const double &R[], double &A[], double &K[]);
    void fht(double &f[], ulong ldn); // Fast Hartley Transform
};

//-----------------------------------------------------------------------------------
// Constructor
//-----------------------------------------------------------------------------------
void TSAnalysis::TSAnalysis()
{
}

void TSAnalysis::TSAnalysis(const double &ts[])
{
  Calc(ts);
}

//-----------------------------------------------------------------------------------
// Main calculation
//-----------------------------------------------------------------------------------
void TSAnalysis::Calc(const double &ts[])
{
    int i, k, m, n, p;
    double sum2, sum3, sum4, a, b, c, v, delta;
    double cor[], ar[], tdat[];

    NumTS = ArraySize(ts); // Number of time series data points
    if(NumTS < 8)          // Number of data points is too small
    {
        Print("TSAnalysis: Error. Number of TS data points is too small!");
        return;
    }
    ArrayResize(TS, NumTS);
    ArrayCopy(TS, ts); // Time series
    ArrayResize(TSort, NumTS);
    ArrayCopy(TSort, ts);
    ArraySort(TSort);         // Sorted time series
    MinTS = TSort[0];         // Minimum time series value
    MaxTS = TSort[NumTS - 1]; // Maximum time series value

    i = (NumTS - 1) / 2;
    Median = TSort[i];                                              // Median
    if((NumTS & 0x01) == 0) Median = (Median + TSort[i + 1]) / 2.0; // Median

    Mean = 0;
    sum2 = 0;
    sum3 = 0;
    sum4 = 0;
    for(i = 0; i < NumTS; i++)
    {
        n = i + 1;
        delta = TS[i] - Mean;
        a = delta / n;
        Mean += a;                                                                             // Mean (average)
        sum4 += a * (a * a * delta * i * (n * (n - 3.0) + 3.0) + 6.0 * a * sum2 - 4.0 * sum3); // sum of fourth degree
        b = TS[i] - Mean;
        sum3 += a * (b * delta * (n - 2.0) - 3.0 * sum2); // sum of third degree
        sum2 += delta * b;                                // sum of second degree
    }
    if(sum2 < 1.e-250) // variance is too small
    {
        Print("TSAnalysis: Error. The variance is too small or zero!");
        return;
    }
    ArrayResize(TSCenter, NumTS);
    for(i = 0; i < NumTS; i++)
        TSCenter[i] = TS[i] - Mean;                               // Centered time series
    Var = sum2 / NumTS;                                           // Variance
    uVar = sum2 / (NumTS - 1);                                    // Unbiased variance
    StDev = MathSqrt(Var);                                        // Standard deviation
    uStDev = MathSqrt(uVar);                                      // Unbiased standard deviation
    Skew = MathSqrt(NumTS) * sum3 / sum2 / MathSqrt(sum2);        // Skewness
    Kurt = NumTS * sum4 / sum2 / sum2;                            // Kurtosis
    ExKurt = Kurt - 3;                                            // Excess kurtosis
    JBTest = (NumTS / 6.0) * (Skew * Skew + ExKurt * ExKurt / 4); // Jarque-Bera test
    JBpVal = MathExp(-JBTest / 2.0);                              // JB test p-value
    a = 6 * (NumTS - 2.0) / (NumTS + 1.0) / (NumTS + 3.0);
    b = 3 * (NumTS - 1.0) / (NumTS + 1.0);
    AJBTest = Skew * Skew / a + (Kurt - b) * (Kurt - b) / // Adjusted Jarque-Bera test
                                    (24.0 * NumTS * (NumTS - 2.0) * (NumTS - 3.0) / (NumTS + 1.0) /
                                     (NumTS + 1.0) / (NumTS + 3.0) / (NumTS + 5.0));
    AJBpVal = MathExp(-AJBTest / 2.0); // AJB test p-value

    // Time Series Plot. Y=TS[],line1=maxOut,line2=Mean,line3=minOut
    delta = (1.55 + 0.8 * MathLog10(NumTS / 10.0) * MathSqrt(Kurt - 1)) * StDev;
    maxOut = Mean + delta; // Time Series Plot. Border of outliers
    minOut = Mean - delta; // Time Series Plot. Border of outliers

    // Histogram. X=XHist[],Y=YHist[]
    n = (int)MathRound((Kurt + 1.5) * MathPow(NumTS, 0.4) / 6.0);
    if((n & 0x01) == 0) n--;
    if(n < 5) n = 5; // Number of bins
    ArrayResize(XHist, n);
    ArrayResize(YHist, n);
    ArrayInitialize(YHist, 0.0);
    a = MathAbs(TSort[0] - Mean);
    b = MathAbs(TSort[NumTS - 1] - Mean);
    if(a < b) a = b;
    v = Mean - a;
    delta = 2.0 * a / n;
    for(i = 0; i < n; i++)
        XHist[i] = (v + (i + 0.5) * delta - Mean) / StDev; // Histogram. X-axis
    for(i = 0; i < NumTS; i++)
    {
        k = (int)((TS[i] - v) / delta);
        if(k > (n - 1)) k = n - 1;
        YHist[k]++;
    }
    for(i = 0; i < n; i++)
        YHist[i] = YHist[i] / NumTS / delta * StDev; // Histogram. Y-axis

    // Normal Probability Plot. X=Xnpp[],Y=TSort[]
    ArrayResize(Xnpp, NumTS);
    Xnpp[NumTS - 1] = MathPow(0.5, 1.0 / NumTS);
    Xnpp[0] = 1 - Xnpp[NumTS - 1];
    a = NumTS + 0.365;
    for(i = 1; i < (NumTS - 1); i++)
        Xnpp[i] = (i + 0.6825) / a;
    for(i = 0; i < NumTS; i++)
        Xnpp[i] = ndtri(Xnpp[i]); // Normal Probability Plot. X-axis

    // Autocorrelation function (correlogram)
    NLags = (int)MathRound(50 * MathLog(NumTS));
    if(NLags > NumTS / 2) NLags = NumTS / 2;
    if(NLags < 3) NLags = 3; // Number of lags for ACF and PACF Plot

    IP = NLags * 5;
    if(IP > NumTS * 0.7) IP = (int)MathRound(NumTS * 0.7); // Autoregressive model order

    ArrayResize(cor, IP);
    ArrayResize(ar, IP);
    ArrayResize(tdat, IP);
    a = 0;
    for(i = 0; i < NumTS; i++)
        a += TSCenter[i] * TSCenter[i];
    for(i = 1; i <= IP; i++)
    {
        c = 0;
        for(k = i; k < NumTS; k++)
            c += TSCenter[k] * TSCenter[k - i];
        cor[i - 1] = c / a; // Autocorrelation
    }

    LevinsonRecursion(cor, ar, tdat); // Levinson-Durbin recursion

    ArrayResize(ACF, NLags);
    ArrayCopy(ACF, cor, 0, 0, NLags); // ACF
    ArrayResize(PACF, NLags);
    ArrayCopy(PACF, tdat, 0, 0, NLags); // PACF

    UPLim = 1.96 / MathSqrt(NumTS); // Upper limit (5% significance level)
    LOLim = -UPLim;                 // Lower limit (5% significance level)
    ArrayResize(CBup, NLags);
    ArrayResize(CBlo, NLags);
    a = 0;
    for(i = 0; i < NLags; i++)
    {
        a += ACF[i] * ACF[i];
        CBup[i] = 1.96 * MathSqrt((1 + 2 * a) / NumTS); // Upper limit (confidence bands)
        CBlo[i] = -CBup[i];                             // Lower limit (confidence bands)
    }

    // Spectrum Plot
    n = 320; // Number of X-points
    ArrayResize(Spect, n);
    v = M_PI / n;
    for(i = 0; i < n; i++)
    {
        a = i * v;
        b = 0;
        for(k = 0; k < NLags; k++)
            b += ((double)NLags - k) / (NLags + 1.0) * ACF[k] * MathCos(a * (k + 1));
        Spect[i] = 2.0 * (1 + 2 * b); // Spectrum Y-axis
    }

    // AR Spectral Estimates Plot (maximum entropy method)
    p = 12;              // n = 2**p = 4096
    n = ((ulong)1 << p); // Number of X-points
    m = n << 1;
    ArrayResize(ARSp, n); // AR Spectrum. Y-axis
    ArrayResize(tdat, m);
    ArrayInitialize(tdat, 0);
    tdat[0] = 1;
    for(i = 0; i < IP; i++)
        tdat[i + 1] = -ar[i];
    fht(tdat, p + 1); // Fast Hartley transform (FHT)
    for(k = 1, i = m - 1; k < i; ++k, --i)
        tdat[k] = tdat[k] * tdat[k] + tdat[i] * tdat[i];
    tdat[0] = 2 * tdat[0] * tdat[0];
    ArrayCopy(ARSp, tdat, 0, 0, n);
    c = -DBL_MAX;
    for(i = 0; i < n; i++)
    {
        ARSp[i] = 1 / ARSp[i];
        if(c < ARSp[i]) c = ARSp[i]; // c = max(ARSp)
    }
    for(i = 0; i < n; i++) // logarithmic scale
    {
        b = ARSp[i] / c; // normalization
        if(b < 1e-7) b = 1e-7;
        ARSp[i] = 10 * MathLog10(b); // dB
    }
}

//-----------------------------------------------------------------------------------
// Inverse of Normal distribution function
// Prototype:
// Cephes Math Library Release 2.8: June, 2000
// Copyright 1984, 1987, 1989, 2000 by Stephen L. Moshier
//-----------------------------------------------------------------------------------
double TSAnalysis::ndtri(double y0)
{
    static double s2pi = 2.50662827463100050242E0; // sqrt(2pi)
    static double P0[5] = {-5.99633501014107895267E1, 9.80010754185999661536E1,
                           -5.66762857469070293439E1, 1.39312609387279679503E1,
                           -1.23916583867381258016E0};
    static double Q0[8] = {1.95448858338141759834E0, 4.67627912898881538453E0,
                           8.63602421390890590575E1, -2.25462687854119370527E2,
                           2.00260212380060660359E2, -8.20372256168333339912E1,
                           1.59056225126211695515E1, -1.18331621121330003142E0};
    static double P1[9] = {4.05544892305962419923E0, 3.15251094599893866154E1,
                           5.71628192246421288162E1, 4.40805073893200834700E1,
                           1.46849561928858024014E1, 2.18663306850790267539E0,
                           -1.40256079171354495875E-1, -3.50424626827848203418E-2,
                           -8.57456785154685413611E-4};
    static double Q1[8] = {1.57799883256466749731E1, 4.53907635128879210584E1,
                           4.13172038254672030440E1, 1.50425385692907503408E1,
                           2.50464946208309415979E0, -1.42182922854787788574E-1,
                           -3.80806407691578277194E-2, -9.33259480895457427372E-4};
    static double P2[9] = {3.23774891776946035970E0, 6.91522889068984211695E0,
                           3.93881025292474443415E0, 1.33303460815807542389E0,
                           2.01485389549179081538E-1, 1.23716634817820021358E-2,
                           3.01581553508235416007E-4, 2.65806974686737550832E-6,
                           6.23974539184983293730E-9};
    static double Q2[8] = {6.02427039364742014255E0, 3.67983563856160859403E0,
                           1.37702099489081330271E0, 2.16236993594496635890E-1,
                           1.34204006088543189037E-2, 3.28014464682127739104E-4,
                           2.89247864745380683936E-6, 6.79019408009981274425E-9};
    double x, y, z, y2, x0, x1, a, b;
    int i, code;

    if(y0 <= 0.0)
    {
        Print("Function ndtri() error!");
        return (-DBL_MAX);
    }
    if(y0 >= 1.0)
    {
        Print("Function ndtri() error!");
        return (DBL_MAX);
    }

    code = 1;
    y = y0;
    if(y > (1.0 - 0.13533528323661269189))
    {
        y = 1.0 - y;
        code = 0;
    }                              // 0.135... = exp(-2)
    if(y > 0.13533528323661269189) // 0.135... = exp(-2)
    {
        y = y - 0.5;
        y2 = y * y;
        a = P0[0];
        for(i = 1; i < 5; i++)
            a = a * y2 + P0[i];
        b = y2 + Q0[0];
        for(i = 1; i < 8; i++)
            b = b * y2 + Q0[i];
        x = y + y * (y2 * a / b);
        x = x * s2pi;
        return (x);
    }
    x = MathSqrt(-2.0 * MathLog(y));
    x0 = x - MathLog(x) / x;
    z = 1.0 / x;
    if(x < 8.0) // y > exp(-32) = 1.2664165549e-14
    {
        a = P1[0];
        for(i = 1; i < 9; i++)
            a = a * z + P1[i];
        b = z + Q1[0];
        for(i = 1; i < 8; i++)
            b = b * z + Q1[i];
        x1 = z * a / b;
    }
    else
    {
        a = P2[0];
        for(i = 1; i < 9; i++)
            a = a * z + P2[i];
        b = z + Q2[0];
        for(i = 1; i < 8; i++)
            b = b * z + Q2[i];
        x1 = z * a / b;
    }
    x = x0 - x1;
    if(code != 0) x = -x;

    return (x);
}

//-----------------------------------------------------------------------------------
// Calculate the Levinson-Durbin recursion for the autocorrelation sequence R[]
// and return the autoregression coefficients A[] and partial autocorrelation
// coefficients K[]
//-----------------------------------------------------------------------------------
void TSAnalysis::LevinsonRecursion(const double &R[], double &A[], double &K[])
{
    int p, i, m;
    double km, Em, Am1[], err;

    p = ArraySize(R);
    ArrayResize(Am1, p);
    ArrayInitialize(Am1, 0);
    ArrayInitialize(A, 0);
    ArrayInitialize(K, 0);
    km = 0;
    Em = 1;
    for(m = 0; m < p; m++)
    {
        err = 0;
        for(i = 0; i < m; i++)
            err += Am1[i] * R[m - i - 1];
        km = (R[m] - err) / Em;
        K[m] = km;
        A[m] = km;
        for(i = 0; i < m; i++)
            A[i] = (Am1[i] - km * Am1[m - i - 1]);
        Em = (1 - km * km) * Em;
        ArrayCopy(Am1, A);
    }
}

//-----------------------------------------------------------------------------------
// Radix-2 decimation in frequency (DIF) fast Hartley transform (FHT).
// Length is N = 2 ** ldn
//-----------------------------------------------------------------------------------
void TSAnalysis::fht(double &f[], ulong ldn)
{
    const ulong n = ((ulong)1 << ldn);
    for(ulong ldm = ldn; ldm >= 1; --ldm)
    {
        const ulong m = ((ulong)1 << ldm);
        const ulong mh = (m >> 1);
        const ulong m4 = (mh >> 1);
        const double phi0 = M_PI / (double)mh;
        for(ulong r = 0; r < n; r += m)
        {
            for(ulong j = 0; j < mh; ++j)
            {
                uint t1 = (uint)(r + j);
                uint t2 = (uint)(t1 + mh);
                double u = f[t1];
                double v = f[t2];
                f[t1] = u + v;
                f[t2] = u - v;
            }
            double ph = 0.0;
            for(ulong j = 1; j < m4; ++j)
            {
                ulong k = mh - j;
                ph += phi0;
                double s = MathSin(ph);
                double c = MathCos(ph);
                uint t1 = (uint)(r + mh + j);
                uint t2 = (uint)(r + mh + k);
                double pj = f[t1];
                double pk = f[t2];
                f[t1] = pj * c + pk * s;
                f[t2] = pj * s - pk * c;
            }
        }
    }
    if(n > 2)
    {
        ulong r = 0;
        for(ulong i = 1; i < n; i++)
        {
            ulong k = n;
            do
            {
                k = k >> 1;
                r = r ^ k;
            } while((r & k) == 0);
            if(r > i)
            {
                double tmp = f[(uint)i];
                f[(uint)i] = f[(uint)r];
                f[(uint)r] = tmp;
            }
        }
    }
}
//-----------------------------------------------------------------------------------
