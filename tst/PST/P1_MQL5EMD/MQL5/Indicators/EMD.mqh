//------------------------------------------------------------------------------------
//                                                                      [C]EMD[_2].mqh
//                                                                 2.01, 2012, victorg
// Forecasting modification                Copyright (c) 2012-2020, victorg, Marketeer
//                                             https://www.mql5.com/en/users/marketeer
//------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------
// The Empirical Mode Decomposition (EMD).
//------------------------------------------------------------------------------------
class CEMD
{
  private:
    int N;       // Input and output data size
    int Nf;
    int nIMF;    // IMF (Intrinsic Mode Functions) counter
    double Mean; // Mean of input data

    int MaxIMF;         // Maximum number of IMF
    int MaxIter;        // Maximum number of iterations
    double Eps;         // Accuracy comparison of floating-point numbers
    double Trs;         // Threshold for calculating the zero crossings
    double Retr;        // Number of successful retries
    double IMFResult[]; // Result
    double X[];         // X-coordinate for the TimeSeries. X[]=0,1,2,...,N-1.
    double Imf[];       // Temporary array to calculate the IMF
    double XMax[];      // x of local maxima
    double YMax[];      // y of local maxima
    double XMin[];      // x of local minima
    double YMin[];      // y of local minima
    double EnvUpp[];    // Upper envelope
    double EnvLow[];    // Lower envelope

  public:
    void CEMD(void);
    int decomp(const double &y[], const int extrapolate = 0); // Decomposition and optional extrapolation
    void getIMF(double &x[], const int nn, const bool reverse = false) const; // Returns IMF with the index nn
    int getN(void) const
    {
      return nIMF;
    }
    
    double getMean(void) const
    {
      return Mean;
    }

  private:
    int arrayprepare(void);
    int extrcounter(double &y[]);
    int extrema(double &y[], int &nmax, double &xmax[], double &ymax[], int &nmin,
                double &xmin[], double &ymin[], int &nzer);
    int splineInterp(double &x[], double &y[], int n, double &x2[], double &y2[],
                     int btype = 0);
};

//------------------------------------------------------------------------------------
// Constructor.
//------------------------------------------------------------------------------------
void CEMD::CEMD(void)
{
    MaxIMF = 16;           // The maximum number of IMF
    MaxIter = 1000;        // The maximum number of iterations
    Eps = 8 * DBL_EPSILON; // Accuracy comparison of floating-point numbers
    Trs = 4 * DBL_EPSILON; // Threshold for calculating the zero crossings
    Retr = 7;              // Number of successful retries
}

//------------------------------------------------------------------------------------
// Decomposition.
//------------------------------------------------------------------------------------
int CEMD::decomp(const double &y[], const int extrapolate = 0)
{
    int i, j, iter, nmax, nmin, nzer, pmin, pmax, pzer, count, valid;
    double a;

    N = ArraySize(y);
    if(N < 6)
    {
        Print(__FUNCTION__, ": Error! Insufficient length of the input data.");
        return (-1);
    }
    Nf = N; // preserve actual number of input data points
    N += extrapolate;

    i = arrayprepare();
    if(i < 0)
    {
        Print(__FUNCTION__, ": Error! ArrayResize() error.");
        return (-2);
    }
    for(i = 0; i < N; i++)
        X[i] = i;
    Mean = 0;
    for(i = 0; i < Nf; i++)
        Mean += (y[i] - Mean) / (i + 1.0); // Mean (average) of input data
    for(i = 0; i < N; i++)
    {
        a = y[MathMin(i, Nf - 1)] - Mean;
        Imf[i] = a;       // Input data minus mean
        IMFResult[i] = a; // Input data minus mean
    }
    // The loop of decomposition
    nIMF = 0;
    while(nIMF++ < MaxIMF)
    {
        j = extrcounter(Imf); // Counting of the extrema
        if(j < 2)
            break; // If less than two extremas then the end of decomposition
        // Loop of creation IMF
        iter = 0;
        count = 0;
        pmin = INT_MAX;
        pmax = INT_MAX;
        pzer = INT_MAX;
        while(iter++ < MaxIter)
        {
            // Find local extremas. Result --> XMin[],YMin[],XMax[],YMax[]
            valid = extrema(Imf, nmax, XMax, YMax, nmin, XMin, YMin, nzer);
            // Stopping criterion
            if((nmax == pmax) && (nmin == pmin) && (nzer == pzer) && (valid == 1))
                count++;
            else
            {
                pmax = nmax;
                pmin = nmin;
                pzer = nzer;
                count = 0;
            }
            if(count >= Retr)
                break; // End of loop
            // Upper and Lower envelope
            if(nmax < 2)
                for(i = 0; i < N; i++)
                    EnvUpp[i] = Imf[i];
            else
                splineInterp(XMax, YMax, nmax, X, EnvUpp);
            if(nmin < 2)
                for(i = 0; i < N; i++)
                    EnvLow[i] = Imf[i];
            else
                splineInterp(XMin, YMin, nmin, X, EnvLow);
            // Create current IMF
            for(i = 0; i < N; i++)
            {
                Imf[i] -= EnvUpp[i] +
                          (EnvLow[i] - EnvUpp[i]) * 0.5; // (EnvLow[i]+EnvUpp[i])/2.0
            }
        }
        if(iter >= MaxIter)
            Print(__FUNCTION__, ": Warning! Reached the maximum number of iterations.");
        // Check IMF
        j = extrcounter(Imf); // Counting of the extrema
        if(j < 1)
            break; // If monotonic then the end of decomposition
        // Saving results
        if(ArrayResize(IMFResult, N * (nIMF + 1)) != N * (nIMF + 1)) // Resize for current IMF
        {
            Print(__FUNCTION__, ": Error! ArrayResize() error.");
            return (-2);
        }
        for(i = 0; i < N; i++)
        {
            IMFResult[i + N * nIMF] = Imf[i]; // Save current IMF
            a = IMFResult[i] - Imf[i];
            IMFResult[i] = a; // For the following calculations
            Imf[i] = a;       // For the following calculations
        }
    }
    // Resize the array and save residue
    if(ArrayResize(IMFResult, N * (nIMF + 1)) != N * (nIMF + 1))
    {
        Print(__FUNCTION__ + ": Error! ArrayResize() error.");
        return (-2);
    }
    for(i = 0; i < N; i++)
    {
        IMFResult[i + N * nIMF] = IMFResult[i];      // IMF number nIMF is the residue
        IMFResult[i] = y[MathMin(i, Nf - 1)] - Mean; // IMF number 0 is the input data minus Mean
    }
    if(nIMF >= MaxIMF)
        Print(__FUNCTION__, ": Warning! Reached the maximum number of IMF.");
    return (0);
}

//------------------------------------------------------------------------------------
// Returns the IMF with an index of nn.
// Input:
//   nn  - IMF number:
//     nn=0;      - Input data minus mean;
//     nn=1;      - IMF number 1;
//      . . .
//     nn=nIMF-1; - IMF number nIMF-1;
//     nn=nIMF;   - Residue of decomposition.
// Output:
//   x[] - IMF number nn.
//------------------------------------------------------------------------------------
void CEMD::getIMF(double &x[], const int nn, const bool reverse = false) const
{
    int i, k;

    k = ArraySize(x);
    if(k > N)
        k = N;
    if(nn < 0 || nn > nIMF || nIMF == 0)
        for(i = 0; i < k; i++)
            x[i] = 0.0;
    else
        for(i = 0; i < k; i++)
            x[i] = IMFResult[i + N * nn];
    if(reverse)
        ArrayReverse(x);
}

//------------------------------------------------------------------------------------
// Extrema counter.
//------------------------------------------------------------------------------------
int CEMD::extrcounter(double &y[])
{
    int i, j;
    double a, b, c;

    a = y[0];
    b = y[1];
    j = 0;
    for(i = 1; i < N - 1; i++)
    {
        c = y[i + 1];
        if(MathAbs(b - c) > DBL_MIN + Eps * MathMax(MathAbs(b), MathAbs(c))) // b != c
        {
            if(((b > c) && (b > a)) || ((b < c) && (b < a)))
                j++;
            a = b;
            b = c;
        }
    }
    return (j);
}

//------------------------------------------------------------------------------------
// Set the size of arrays.
//------------------------------------------------------------------------------------
int CEMD::arrayprepare(void)
{
    if(ArrayResize(IMFResult, N) != N)
        return (-1);
    if(ArrayResize(X, N) != N)
        return (-1);
    if(ArrayResize(Imf, N) != N)
        return (-1);

    if(ArrayResize(XMax, Nf + 4) != Nf + 4)
        return (-1);
    if(ArrayResize(YMax, Nf + 4) != Nf + 4)
        return (-1);
    if(ArrayResize(XMin, Nf + 4) != Nf + 4)
        return (-1);
    if(ArrayResize(YMin, Nf + 4) != Nf + 4)
        return (-1);

    if(ArrayResize(EnvUpp, N) != N)
        return (-1);
    if(ArrayResize(EnvLow, N) != N)
        return (-1);

    return (0);
}

//------------------------------------------------------------------------------------
// Find local extremas and creation of extra boundary points.
// Return:
//   If IMF is valid then return 1 else return 0.
//------------------------------------------------------------------------------------
int CEMD::extrema(double &y[], int &nmax, double &xmax[], double &ymax[],
                  int &nmin, double &xmin[], double &ymin[], int &nzer)
{
    int i, k, nb, sig, ret;
    double a, b, c, d;

    sig = 0;
    nzer = 0;
    for(i = 0; i < Nf; i++)
    {
        if((y[i] > Trs) && (sig < 1))
        {
            if(sig == -1)
                nzer++;
            sig = 1;
        }
        if((y[i] < -Trs) && (sig > -1))
        {
            if(sig == 1)
                nzer++;
            sig = -1;
        }
    }
    nmax = 0;
    nmin = 0;
    ret = 1;
    a = y[0];
    b = y[1];
    k = 1;
    for(i = 1; i < Nf - 1; i++)
    {
        c = y[i + 1];
        if(MathAbs(b - c) > DBL_MIN + Eps * MathMax(MathAbs(b), MathAbs(c))) // b != c
        {
            if((b > c) && (b > a))
            {
                xmax[nmax + 2] = 0.5 * (k + i);
                d = 0.5 * (y[k] + y[i]);
                ymax[2 + nmax++] = d;
                if(d < 0)
                    ret = 0;
            }
            else if((b < c) && (b < a))
            {
                xmin[nmin + 2] = 0.5 * (k + i);
                d = 0.5 * (y[k] + y[i]);
                ymin[2 + nmin++] = d;
                if(d > 0)
                    ret = 0;
            }
            a = b;
            b = c;
            k = i + 1;
        }
    }
    if(ret == 1)
    {
        k = nzer - nmax - nmin;
        if((k > 1) && (k < -1))
            ret = 0;
    }
    // extra boundary points
    nb = 2;
    while(nmin < (nb + 1) && nmax < (nb + 1))
        nb--;
    if(nb < 2)
    {
        for(i = 0; i < nmin; i++)
        {
            xmin[i + nb] = xmin[i + 2];
            ymin[i + nb] = ymin[i + 2];
        }
        for(i = 0; i < nmax; i++)
        {
            xmax[i + nb] = xmax[i + 2];
            ymax[i + nb] = ymax[i + 2];
        }
    }
    if(nb < 1)
        return (ret);
    if(xmax[nb] < xmin[nb])
    {
        if(y[0] > ymin[nb])
        {
            if(2 * xmax[nb] - xmin[2 * nb - 1] > 0)
            {
                for(i = 0; i < nb; i++)
                {
                    xmax[i] = -xmax[2 * nb - 1 - i];
                    ymax[i] = ymax[2 * nb - 1 - i];
                    xmin[i] = -xmin[2 * nb - 1 - i];
                    ymin[i] = ymin[2 * nb - 1 - i];
                }
            }
            else
            {
                for(i = 0; i < nb; i++)
                {
                    xmax[i] = 2 * xmax[nb] - xmax[2 * nb - i];
                    ymax[i] = ymax[2 * nb - i];
                    xmin[i] = 2 * xmax[nb] - xmin[2 * nb - 1 - i];
                    ymin[i] = ymin[2 * nb - 1 - i];
                }
            }
        }
        else
        {
            for(i = 0; i < nb; i++)
            {
                xmax[i] = -xmax[2 * nb - 1 - i];
                ymax[i] = ymax[2 * nb - 1 - i];
            }
            for(i = 0; i < nb - 1; i++)
            {
                xmin[i] = -xmin[2 * nb - 2 - i];
                ymin[i] = ymin[2 * nb - 2 - i];
            }
            xmin[nb - 1] = 0;
            ymin[nb - 1] = y[0];
        }
    }
    else
    {
        if(y[0] < ymax[nb])
        {
            if(2 * xmin[nb] - xmax[2 * nb - 1] > 0)
            {
                for(i = 0; i < nb; i++)
                {
                    xmax[i] = -xmax[2 * nb - 1 - i];
                    ymax[i] = ymax[2 * nb - 1 - i];
                    xmin[i] = -xmin[2 * nb - 1 - i];
                    ymin[i] = ymin[2 * nb - 1 - i];
                }
            }
            else
            {
                for(i = 0; i < nb; i++)
                {
                    xmax[i] = 2 * xmin[nb] - xmax[2 * nb - 1 - i];
                    ymax[i] = ymax[2 * nb - 1 - i];
                    xmin[i] = 2 * xmin[nb] - xmin[2 * nb - i];
                    ymin[i] = ymin[2 * nb - i];
                }
            }
        }
        else
        {
            for(i = 0; i < nb; i++)
            {
                xmin[i] = -xmin[2 * nb - 1 - i];
                ymin[i] = ymin[2 * nb - 1 - i];
            }
            for(i = 0; i < nb - 1; i++)
            {
                xmax[i] = -xmax[2 * nb - 2 - i];
                ymax[i] = ymax[2 * nb - 2 - i];
            }
            xmax[nb - 1] = 0;
            ymax[nb - 1] = y[0];
        }
    }
    nmin += nb - 1;
    nmax += nb - 1;
    if(xmax[nmax] < xmin[nmin])
    {
        if(y[Nf - 1] < ymax[nmax])
        {
            if(2 * xmin[nmin] - xmax[nmax - nb + 1] < (Nf - 1))
            {
                for(i = 0; i < nb; i++)
                {
                    xmax[nmax + 1 + i] = 2 * (Nf - 1) - xmax[nmax - i];
                    ymax[nmax + 1 + i] = ymax[nmax - i];
                    xmin[nmin + 1 + i] = 2 * (Nf - 1) - xmin[nmin - i];
                    ymin[nmin + 1 + i] = ymin[nmin - i];
                }
            }
            else
            {
                for(i = 0; i < nb; i++)
                {
                    xmax[nmax + 1 + i] = 2 * xmin[nmin] - xmax[nmax - i];
                    ymax[nmax + 1 + i] = ymax[nmax - i];
                    xmin[nmin + 1 + i] = 2 * xmin[nmin] - xmin[nmin - 1 - i];
                    ymin[nmin + 1 + i] = ymin[nmin - 1 - i];
                }
            }
        }
        else
        {
            for(i = 0; i < nb; i++)
            {
                xmin[nmin + 1 + i] = 2 * (Nf - 1) - xmin[nmin - i];
                ymin[nmin + 1 + i] = ymin[nmin - i];
            }
            for(i = 0; i < nb - 1; i++)
            {
                xmax[nmax + 2 + i] = 2 * (Nf - 1) - xmax[nmax - i];
                ymax[nmax + 2 + i] = ymax[nmax - i];
            }
            xmax[nmax + 1] = Nf - 1;
            ymax[nmax + 1] = y[Nf - 1];
        }
    }
    else
    {
        if(y[Nf - 1] > ymin[nmin])
        {
            if(2 * xmax[nmax] - xmin[nmin - nb + 1] < (Nf - 1))
            {
                for(i = 0; i < nb; i++)
                {
                    xmax[nmax + 1 + i] = 2 * (Nf - 1) - xmax[nmax - i];
                    ymax[nmax + 1 + i] = ymax[nmax - i];
                    xmin[nmin + 1 + i] = 2 * (Nf - 1) - xmin[nmin - i];
                    ymin[nmin + 1 + i] = ymin[nmin - i];
                }
            }
            else
            {
                for(i = 0; i < nb; i++)
                {
                    xmax[nmax + 1 + i] = 2 * xmax[nmax] - xmax[nmax - 1 - i];
                    ymax[nmax + 1 + i] = ymax[nmax - 1 - i];
                    xmin[nmin + 1 + i] = 2 * xmax[nmax] - xmin[nmin - i];
                    ymin[nmin + 1 + i] = ymin[nmin - i];
                }
            }
        }
        else
        {
            for(i = 0; i < nb; i++)
            {
                xmax[nmax + 1 + i] = 2 * (Nf - 1) - xmax[nmax - i];
                ymax[nmax + 1 + i] = ymax[nmax - i];
            }
            for(i = 0; i < nb - 1; i++)
            {
                xmin[nmin + 2 + i] = 2 * (Nf - 1) - xmin[nmin - i];
                ymin[nmin + 2 + i] = ymin[nmin - i];
            }
            xmin[nmin + 1] = Nf - 1;
            ymin[nmin + 1] = y[Nf - 1];
        }
    }
    nmin = nmin + nb + 1;
    nmax = nmax + nb + 1;
    return (ret);
}
//------------------------------------------------------------------------------------
// Cubic spline Interpolation.
// Input:
//    x[] - Abscissa of input data points. The elements of the array x
//          must be strictly monotone increasing.
//    y[] - Ordinate of input data points.
//      n - Number of input data points.
//   x2[] - Abscissa of spline function points. The elements of the array x
//          must be strictly monotone increasing. x2 interval = [x[0],x[n-1]].
//  btype - Boundary points type. 0-natural spline, 1-parabolic.
// Output:
//   y2[] - Spline function.
// Return:
//      0 - No errors.
//     -1 - Arguments has wrong size.
//     -2 - ArrayResize() error.
// Notes:
//   Based on ALGLIB.
//------------------------------------------------------------------------------------
int CEMD::splineInterp(double &x[], double &y[], int n, double &x2[],
                       double &y2[], int btype = 0)
{
    int i, n2, intervalindex, pointindex;
    bool havetoadvance;
    double c0, c1, c2, c3, a, bb, w, w2, w3, fa, fb, da, db;
    double t, a1[], a2[], a3[], b[], d[];

    n2 = ArraySize(x2);
    if(n > ArraySize(x) || n > ArraySize(y) || n2 > ArraySize(y2) || n < 2 || n2 < 1)
    {
        Print(__FUNCTION__, ": Error! Arguments has wrong size.");
        return (-1);
    }
    ArrayInitialize(y2, 0);
    if(ArrayResize(a1, n) != n)
    {
        Print(__FUNCTION__, ": Error! ArrayResize() error.");
        return (-2);
    }
    if(ArrayResize(a2, n) != n)
    {
        Print(__FUNCTION__, ": Error! ArrayResize() error.");
        return (-2);
    }
    if(ArrayResize(a3, n) != n)
    {
        Print(__FUNCTION__, ": Error! ArrayResize() error.");
        return (-2);
    }
    if(ArrayResize(b, n) != n)
    {
        Print(__FUNCTION__, ": Error! ArrayResize() error.");
        return (-2);
    }
    if(ArrayResize(d, n) != n)
    {
        Print(__FUNCTION__, ": Error! ArrayResize() error.");
        return (-2);
    }
    for(i = 1; i <= n - 2; i++)
    {
        a1[i] = x[i + 1] - x[i];
        a2[i] = 2 * (x[i + 1] - x[i - 1]);
        a3[i] = x[i] - x[i - 1];
        b[i] = 3 * (y[i] - y[i - 1]) / (x[i] - x[i - 1]) * (x[i + 1] - x[i]) +
               3 * (y[i + 1] - y[i]) / (x[i + 1] - x[i]) * (x[i] - x[i - 1]);
    }
    if(btype == 1 && n == 2)
    {
        d[0] = (y[1] - y[0]) / (x[1] - x[0]);
        d[1] = d[0];
    }
    else
    {
        if(btype == 1)
        {
            a1[0] = 0;
            a2[0] = 1;
            a3[0] = 1;
            b[0] = 2 * (y[1] - y[0]) / (x[1] - x[0]);
            a1[n - 1] = 1;
            a2[n - 1] = 1;
            a3[n - 1] = 0;
            b[n - 1] = 2 * (y[n - 1] - y[n - 2]) / (x[n - 1] - x[n - 2]);
        }
        else
        {
            a1[0] = 0;
            a2[0] = 2;
            a3[0] = 1;
            b[0] = 3 * (y[1] - y[0]) / (x[1] - x[0]);
            a1[n - 1] = 1;
            a2[n - 1] = 2;
            a3[n - 1] = 0;
            b[n - 1] = 3 * (y[n - 1] - y[n - 2]) / (x[n - 1] - x[n - 2]);
        }
        for(i = 1; i <= n - 1; i++)
        {
            t = a1[i] / a2[i - 1];
            a2[i] = a2[i] - t * a3[i - 1];
            b[i] = b[i] - t * b[i - 1];
        }
        d[n - 1] = b[n - 1] / a2[n - 1];
        for(i = n - 2; i >= 0; i--)
            d[i] = (b[i] - a3[i] * d[i + 1]) / a2[i];
    }
    c0 = 0;
    c1 = 0;
    c2 = 0;
    c3 = 0;
    a = 0;
    bb = 0;
    intervalindex = -1;
    pointindex = 0;
    for(;;)
    {
        if(pointindex >= n2)
            break;
        t = x2[pointindex];
        havetoadvance = false;
        if(intervalindex == -1)
            havetoadvance = true;
        else if(intervalindex < n - 2)
            havetoadvance = (t >= bb);
        if(havetoadvance)
        {
            intervalindex = intervalindex + 1;
            a = x[intervalindex];
            bb = x[intervalindex + 1];
            w = bb - a;
            w2 = w * w;
            w3 = w * w2;
            fa = y[intervalindex];
            fb = y[intervalindex + 1];
            da = d[intervalindex];
            db = d[intervalindex + 1];
            c0 = fa;
            c1 = da;
            c2 = (3 * (fb - fa) - 2 * da * w - db * w) / w2;
            c3 = (2 * (fa - fb) + da * w + db * w) / w3;
            continue;
        }
        t = t - a;
        y2[pointindex] = c0 + t * (c1 + t * (c2 + t * c3));
        pointindex = pointindex + 1;
    }
    return (0);
}
//------------------------------------------------------------------------------------
