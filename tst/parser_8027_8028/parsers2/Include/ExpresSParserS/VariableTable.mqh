//+------------------------------------------------------------------+
//|                                                VariableTable.mqh |
//|                                    Copyright (c) 2020, Marketeer |
//|                          https://www.mql5.com/en/users/marketeer |
//+------------------------------------------------------------------+

#include "HashMapSimple.mqh"

#define Map HashMapSimple
#define CLEAR(P) if(CheckPointer(P) == POINTER_DYNAMIC) delete P;

template<typename T>
class Table
{
  public:
    virtual T operator[](const int index) const
    {
      return _table[index];
    }
    virtual int index(const string variableName)
    {
      return _table.getIndex(variableName);
    }
    virtual bool exists(const string variableName) const
    {
      return _table.getIndex(variableName) != -1;
    }
    virtual T get(const string variableName) const
    {
      return _table[variableName];
    }
    virtual int add(const string variableName, T value) // blind add
    {
      return _table.add(variableName, value);
    }
    virtual int set(const string variableName, T value) // add or update
    {
      return _table.set(variableName, value);
    }
    virtual void update(const int index, T value)
    {
      _table.replace(index, value);
    }
    
  protected:
    Map<string, T> _table;
};

class VariableTable: public Table<double>
{
  protected:
    bool implicitAllocation;
    
  public:
    VariableTable(const string pairs = NULL): implicitAllocation(false)
    {
      if(pairs != NULL) assign(pairs, true);
    }
    
    void assign(const string pairs, bool init = false)
    {
      if(init) _table.reset();
      else if(_table.getSize() == 0) init = true;
      
      string vararray[];
      const int n = StringSplit(pairs, ';', vararray);
      for(int i = 0; i < n; i++)
      {
        string pair[];
        if(StringSplit(vararray[i], '=', pair) == 2)
        {
          if(init)
          {
            _table.add(pair[0], StringToDouble(pair[1]));
          }
          else
          {
            _table.set(pair[0], StringToDouble(pair[1]));
          }
        }
      }
    }
    void adhocAllocation(const bool b) // set this option to accept and reserve all variable names
    {
      implicitAllocation = b;
    }
    bool adhocAllocation(void)
    {
      return implicitAllocation;
    }
};

interface IFunctor
{
  string name(void) const;
  int arity(void) const;
  double execute(const double &params[]);
};

class FunctionTable: public Table<IFunctor *>
{
  public:
    void add(IFunctor *f)
    {
      Table<IFunctor *>::add(f.name(), f);
    }
    void add(IFunctor *&f[])
    {
      for(int i = 0; i < ArraySize(f); i++)
      {
        add(f[i]);
      }
      // Print("Built-in functions: ", _table.getSize());
    }
    
    #ifdef INDICATOR_FUNCTORS
    virtual int index(const string name) override
    {
      int i = _table.getIndex(name);
      if(i == -1)
      {
        i = _table.getSize();
        IFunctor *f = IndicatorFunc::create(name);
        if(f)
        {
          Table<IFunctor *>::add(name, f);
          return i;
        }
        return -1;
      }
      return i;
    }
    #endif
};
