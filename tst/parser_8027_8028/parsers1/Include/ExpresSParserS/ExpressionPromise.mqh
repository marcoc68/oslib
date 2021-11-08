//+------------------------------------------------------------------+
//|                                            ExpressionPromise.mqh |
//|                                    Copyright (c) 2020, Marketeer |
//|                          https://www.mql5.com/en/users/marketeer |
//+------------------------------------------------------------------+

#include "ExpressionProcessor.mqh"


// stack imitation
#define push(S,V,N) S[N++] = V
#define pop(S,N) S[--N]
#define top(S,N) S[N-1]


struct ByteCode
{
    uchar code;
    double value;
    int index;

    ByteCode(): code(0), value(0.0), index(-1) {}
    ByteCode(const uchar c): code(c), value(0.0), index(-1) {}
    ByteCode(const double d): code('n'), value(d), index(-1) {}
    ByteCode(const uchar c, const int i): code(c), value(0.0), index(i) {}
    
    string toString() const
    {
      return StringFormat("%s %f %d", CharToString(code), value, index);
    }
};


class Promise
{
  protected:
    uchar code;
    double value;
    string name;
    int index;
    Promise *left;
    Promise *right;
    Promise *last;

    static VariableTable *variableTable; // custom vars
    static FunctionTable *functionTable; // custom funcs
    static IExpressionEnvironment *env;  // overall initial settings

    double _variable()
    {
      double result = 0;
      if(index == -1)
      {
        index = variableTable.index(name);
        if(index == -1)
        {
          env.error("Variable undefined: " + name, __FUNCTION__);
          return nan;
        }
        result = variableTable[index];
      }
      else
      {
        result = variableTable[index];
      }
      
      return result;
    }
    
    double _execute()
    {
      double params[];
      if(left)
      {
        ArrayResize(params, 1);
        params[0] = left.resolve();
        if(right)
        {
          ArrayResize(params, 2);
          params[1] = right.resolve();
          if(last)
          {
            ArrayResize(params, 3);
            params[2] = last.resolve();
          }
        }
      }
      IFunctor *ptr = functionTable[index];
      if(ptr == NULL)
      {
        env.error("Function index out of bound: " + (string)index, __FUNCTION__);
        return nan;
      }
      return ptr.execute(params);
    }
    
    double _calc()
    {
      double first = 0, second = 0, third = 0;
      if(left)
      {
        first = left.resolve();
        if(right)
        {
          second = right.resolve();
          if(last)
          {
            third = last.resolve();
          }
        }
      }
      
      switch(code)
      {
        case '+': return first + second;
        case '-': return first - second;
        case '*': return first * second;
        case '/': return safeDivide(first, second);
        case '%': return fmod(first, second);
        case '!': return !first;
        case '~': return -first;
        case '<': return first < second;
        case '>': return first > second;
        case '{': return first <= second;
        case '}': return first >= second;
        case '&': return first && second;
        case '|': return first || second;
        case '`': return env.getPrecision() < fabs(first - second); // first != second;
        case '=': return env.getPrecision() > fabs(first - second); // first == second;
        case '?': return first ? second : third;
      }
      env.error("Unknown operator: " + CharToString(code), __FUNCTION__);
      print();
      return nan;
    }

  public:
    Promise(const uchar token, Promise *l = NULL, Promise *r = NULL, Promise *v = NULL):
      code(token), left(l), right(r), last(v), value(0), name(NULL), index(-1)
    {
    }
    Promise(const double v): // value (const)
      code('n'), left(NULL), right(NULL), last(NULL), value(v), name(NULL), index(-1)
    {
    }
    Promise(const string n, const int idx = -1): // name of variable
      code('v'), left(NULL), right(NULL), last(NULL), value(0), name(n), index(idx)
    {
    }
    Promise(const int f, Promise *&params[]): // index of function
      code('f'), left(NULL), right(NULL), last(NULL), value(0), name(NULL)
    {
      index = f;
      if(ArraySize(params) > 0) left = params[0];
      if(ArraySize(params) > 1) right = params[1];
      if(ArraySize(params) > 2) last = params[2];
      // more params not supported yet
    }
    ~Promise()
    {
      CLEAR(left);
      CLEAR(right);
      CLEAR(last);
    }

    static double safeDivide(double first, double second)
    {
      if(second == 0)
      {
        env.error("Error : Division by 0!", __FUNCTION__);
        return inf;
      }
      return first / second;
    }
    
    Promise *operator+(Promise *r)
    {
      return new Promise('+', &this, r);
    }
    Promise *operator-(Promise *r)
    {
      return new Promise('-', &this, r);
    }
    Promise *operator-(void) // unary (used by sign invertion)
    {
      return new Promise('~', &this);
    }
    Promise *operator*(Promise *r)
    {
      return new Promise('*', &this, r);
    }
    Promise *operator/(Promise *r)
    {
      return new Promise('/', &this, r);
    }
    Promise *operator<=(Promise *r)
    {
      return new Promise('{', &this, r); // '{' stands for '<='
    }
    Promise *operator>=(Promise *r)
    {
      return new Promise('}', &this, r); // '}' stands for '>='
    }
    Promise *operator<(Promise *r)
    {
      return new Promise('<', &this, r);
    }
    Promise *operator>(Promise *r)
    {
      return new Promise('>', &this, r);
    }
    Promise *operator&&(Promise *r)
    {
      return new Promise('&', &this, r);
    }
    Promise *operator||(Promise *r)
    {
      return new Promise('|', &this, r);
    }
    
    // assign global settings for multiple calls
    // with possibility to change variables' values or functions in the linked tables
    static void environment(IExpressionEnvironment *e)
    {
      env = e;
      variableTable = e.variableTable();
      functionTable = e.functionTable();
    }

    static Promise *lookUpVariable(const string &name, VariableTable *_variableTable)
    {
      if(CheckPointer(_variableTable) != POINTER_INVALID) // if external table exists
      {
        int index = _variableTable.index(name); // reserve all names for fast access by indices
        if(index == -1)
        {
          if(_variableTable.adhocAllocation())
          {
            env.error("Variable is implicitly allocated: " + name, __FUNCTION__, true);
            index = _variableTable.add(name, nan);
          }
          else
          {
            env.error("Variable is undefined: " + name, __FUNCTION__);
            return new Promise(nan);
          }
        }
        return new Promise(name, index);
      }
      return new Promise(name);
    }

    // find result for the promise with current settings
    double resolve()
    {
      switch(code)
      {
        case 'n': return value;        // number constant
        case 'v': value = _variable(); // variable name
                  return value;
        case 'f': value = _execute();  // function index
                  return value;
        default:  value = _calc();
                  return value;
      }
      return 0;
    };

    void print(const int level = 0)
    {
      string output = "";
      if(level) StringInit(output, level, ' ');
      printf("%s%d %s %s %f %d %s [%d %d]", output, &this, CharToString(code), (name != NULL ? "'" + name + "'" : ""), value, index, (code == 'f' && functionTable != NULL && index != -1) ? "(" + functionTable[index].name() + ")" : "", left, right);
      if(left) left.print(level + 1);
      if(right) right.print(level + 1);
      if(last) last.print(level + 1);
    }
    
    void exportToByteCode(ByteCode &codes[])
    {
      if(left) left.exportToByteCode(codes);
      const int truly = ArraySize(codes);
      
      if(code == '?')
      {
        ArrayResize(codes, truly + 1);
        codes[truly].code = code;
      }
      
      if(right) right.exportToByteCode(codes);
      const int falsy = ArraySize(codes);
      if(last) last.exportToByteCode(codes);
      const int n = ArraySize(codes);
      
      if(code != '?')
      {
        ArrayResize(codes, n + 1);
        codes[n].code = code;
        codes[n].value = value;
        codes[n].index = index;
      }
      else // (code == '?')
      {
        codes[truly].index = falsy; // jump over true branch
        codes[truly].value = n;     // jump over both branches
      }
    }
    
    void prettyPrint(string &output, const uchar parent = 0)
    {
      if(parent != code && parent != 0 && right != NULL && code != 'f') output += "(";
      if(code == '?')
      {
        if(parent != 0) output += "(";
        left.prettyPrint(output, code);
        output += "?";
        right.prettyPrint(output, code);
        output += ":";
        last.prettyPrint(output, code);
        if(parent != 0) output += ")";
      }
      else
      {
        if(left)
        {
          if(right)
          {
            if(code == 'f')
            {
              output += functionTable[index].name() + "(";
              left.prettyPrint(output);
              output += ",";
              right.prettyPrint(output);
              output += ")";
            }
            else
            {
              left.prettyPrint(output, code);
              output += CharToString(code);
              right.prettyPrint(output, code);
            }
          }
          else
          {
            if(code == 'f')
            {
              output += functionTable[index].name() + "(";
              left.prettyPrint(output);
              output += ")";
            }
            else
            {
              if(code == '~') output += "-";
              else output += CharToString(code);
              left.prettyPrint(output, code);
            }
          }
        }
        else
        {
          if(code == 'n')
          {
            output += (string)(float)(value);
          }
          else if(code == 'v')
          {
            output += name;
          }
          else if(code == 'f')
          {
            output += functionTable[index].name() + "()";
          }
        }
      }
      if(parent != code && parent != 0 && right != NULL && code != 'f') output += ")";
    }

    static double execute(const ByteCode &codes[], VariableTable *vt = NULL, FunctionTable *ft = NULL)
    {
      if(vt) variableTable = vt;
      if(ft) functionTable = ft;

      double stack[]; int ssize = 0; ArrayResize(stack, STACK_SIZE);
      int jumps[]; int jsize = 0; ArrayResize(jumps, STACK_SIZE / 2);
      const int n = ArraySize(codes);
      for(int i = 0; i < n; i++)
      {
        if(jsize && top(jumps, jsize) == i)
        {
          --jsize; // fast "pop & drop"
          i = pop(jumps, jsize);
          continue;
        }
        switch(codes[i].code)
        {
          case 'n': push(stack, codes[i].value, ssize); break;
          case 'v': push(stack, variableTable[codes[i].index], ssize); break;
          case 'f':
            {
              IFunctor *ptr = functionTable[codes[i].index];
              double params[]; ArrayResize(params, ptr.arity()); int psize = 0;
              for(int j = 0; j < ptr.arity(); j++)
              {
                push(params, pop(stack, ssize), psize);
              }
              ArrayReverse(params);
              push(stack, ptr.execute(params), ssize);
            }
            break;
          case '+': push(stack, pop(stack, ssize) + pop(stack, ssize), ssize); break;
          case '-': push(stack, -pop(stack, ssize) + pop(stack, ssize), ssize); break;
          case '*': push(stack, pop(stack, ssize) * pop(stack, ssize), ssize); break;
          case '/': push(stack, Promise::safeDivide(1, pop(stack, ssize)) * pop(stack, ssize), ssize); break;
          case '%':
            {
              const double second = pop(stack, ssize);
              const double first = pop(stack, ssize);
              push(stack, fmod(first, second), ssize);
            }
            break;
          case '!': push(stack, (double)(!pop(stack, ssize)), ssize); break;
          case '~': push(stack, (double)(-pop(stack, ssize)), ssize); break;
          case '<':
            {
              const double second = pop(stack, ssize);
              const double first = pop(stack, ssize);
              push(stack, (double)(first < second), ssize);
            }
            break;
          case '>':
            {
              const double second = pop(stack, ssize);
              const double first = pop(stack, ssize);
              push(stack, (double)(first > second), ssize);
            }
            break;
          case '{':
            {
              const double second = pop(stack, ssize);
              const double first = pop(stack, ssize);
              push(stack, (double)(first <= second), ssize);
            }
            break;
          case '}':
            {
              const double second = pop(stack, ssize);
              const double first = pop(stack, ssize);
              push(stack, (double)(first >= second), ssize);
            }
            break;
          case '&': push(stack, (double)(pop(stack, ssize) && pop(stack, ssize)), ssize); break;
          case '|':
            {
              const double second = pop(stack, ssize);
              const double first = pop(stack, ssize);
              push(stack, (double)(first || second), ssize); // order is important
            }
            break;
          case '`': push(stack, env.getPrecision() < fabs(pop(stack, ssize) - pop(stack, ssize)), ssize); break;
          case '=': push(stack, env.getPrecision() > fabs(pop(stack, ssize) - pop(stack, ssize)), ssize); break;
          case '?':
            {
              const double first = pop(stack, ssize);
              if(first) // true
              {
                push(jumps, (int)codes[i].value, jsize); // to where the entire if ends
                push(jumps, codes[i].index, jsize);      // we jump from where true ends
              }
              else // false
              {
                i = codes[i].index - 1; // -1 is needed because of forthcoming ++
              }
            }
            break;
          default:
            Print("Unknown byte code ", CharToString(codes[i].code));
        }
      }
      return pop(stack, ssize);
    }
};

static NullEnvironment ne;
static IExpressionEnvironment *Promise::env = &ne;
static VariableTable *Promise::variableTable = ne.variableTable();
static FunctionTable *Promise::functionTable = ne.functionTable();

