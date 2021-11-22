//+------------------------------------------------------------------+
//|                                                     IndArray.mqh |
//|                                 Copyright © 2016-2019, Marketeer |
//|                          https://www.mql5.com/en/users/marketeer |
//|                                        Arrayed indicator buffers |
//|                        https://www.mql5.com/en/blogs/post/680572 |
//|                                                  rev. 16.12.2019 |
//+------------------------------------------------------------------+

// helper defines
#define SETTER int
#define GETTER uint


class IndicatorGetter;         // forward declaration, helper class

class Indicator                // main indicator buffer class
{
  private:
    double buffer[];           // indicator buffer
    
    int cursor;                // position in the buffer
    
    IndicatorGetter *instance; // helper object for reading values (optional)
    
  public:
    Indicator(int i, const double empty = EMPTY_VALUE)
    {
      SetIndexBuffer(i, buffer);
      ArraySetAsSeries(buffer, true);
      ArrayInitialize(buffer, empty);
      instance = new IndicatorGetter(this);
    }
    
    virtual ~Indicator()
    {
      delete instance;
    }
    
    void empty(const double empty = EMPTY_VALUE)
    {
      ArrayInitialize(buffer, empty);
    }

    double operator[](GETTER b)
    {
      return buffer[b];
    }
    
    Indicator *operator[](SETTER b)
    {
      cursor = (int)b;
      return &this;
    }
    
    double operator=(double x)
    {
      buffer[cursor] = x;
      return x;
    }
    
    void set(const int b, const double v)
    {
      buffer[b] = v;
    }
    
    void set(const int b, const double &array[])
    {
      for(int i = 0; i < ArraySize(array); i++)
      {
        buffer[b + i] = array[i];
      }
    }
    
    IndicatorGetter *edit() const
    {
      return instance;
    }
    
    double operator+(double x) const
    {
      return buffer[cursor] + x;
    }
    
    double operator-(double x) const
    {
      return buffer[cursor] - x;
    }
    
    double operator*(double x) const
    {
      return buffer[cursor] * x;
    }
    
    double operator/(double x) const
    {
      return buffer[cursor] / x;
    }

    double operator+=(double x)
    {
      buffer[cursor] += x;
      return buffer[cursor];
    }
    
    double operator-=(double x)
    {
      buffer[cursor] -= x;
      return buffer[cursor];
    }
    
    double operator*=(double x)
    {
      buffer[cursor] *= x;
      return buffer[cursor];
    }
    
    double operator/=(double x)
    {
      buffer[cursor] /= x;
      return buffer[cursor];
    }

};

class IndicatorGetter       // helper class to access buffer values directly
{
  private:
    Indicator *owner;
    int cursor;
    
  public:
    IndicatorGetter(Indicator &o)
    {
      owner = &o;
    }
    
    double operator[](int b)
    {
      return owner[(GETTER)b];
    }
};

class IndicatorArray
{
  private:
    Indicator *array[];
    
  public:
    IndicatorArray(int n, const double empty = EMPTY_VALUE)
    {
      ArrayResize(array, n);
      for(int i = 0; i < n; ++i)
      {
        array[i] = new Indicator(i, empty);
      }
    }
    
    virtual ~IndicatorArray()
    {
      int n = ArraySize(array);
      for(int i = 0; i < n; ++i)
      {
        if(CheckPointer(array[i]) == POINTER_DYNAMIC)
        {
          delete array[i];
        }
      }
      ArrayResize(array, 0);
    }
    
    Indicator *operator[](int n) const
    {
      return array[n];
    }
    
    int size() const
    {
      return ArraySize(array);
    }
};

class IndicatorArrayGetter
{
  private:
    IndicatorGetter *array[];
    
  public:
    IndicatorArrayGetter(){};
    
    IndicatorArrayGetter(const IndicatorArray &a)
    {
      bind(a);
    }
    
    void bind(const IndicatorArray &a)
    {
      int n = a.size();
      ArrayResize(array, n);
      for(int i = 0; i < n; ++i)
      {
        array[i] = a[i].edit();
      }
    }
    
    IndicatorGetter *operator[](int n) const
    {
      return array[n];
    }
    
    virtual ~IndicatorArrayGetter()
    {
      ArrayResize(array, 0);
    }
};

