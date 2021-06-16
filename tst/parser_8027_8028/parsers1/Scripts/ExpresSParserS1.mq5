//+------------------------------------------------------------------+
//|                                              ExpresSParserS1.mq5 |
//|                                    Copyright (c) 2020, Marketeer |
//|                          https://www.mql5.com/en/users/marketeer |
//|                           https://www.mql5.com/ru/articles/8027/ |
//+------------------------------------------------------------------+

#include <ExpresSParserS/ExpressionEvaluator.mqh>
#include <ExpresSParserS/ExpressionCompiler.mqh>


#define _NAN DBL_EPSILON
#define _INF DBL_MAX
#define _IND DBL_MIN


template<typename K,typename V>
struct Tuple
{
    K key;
    V value;
};

struct TestCase: public Tuple<string,double>
{
};

template<typename T>
class TestSuite
{
  protected:
    T *e;

  public:
    TestSuite(const string variables = NULL)
    {
      e = new T(variables);
      Print("Expression variables: ", variables);
    }
    ~TestSuite()
    {
      CLEAR(e);
    }
    
    virtual double run(const string &expr) = 0;
    
    void test(TestCase &tests[])
    {
      int count = 0;
      int positive = 0;
      const int n = ArraySize(tests);
      
      Print("Running ", n, " tests on ", typename(e) , " …");

      for(int i = 0; i < n; i++)
      {
        string expr = tests[i].key;
        double result = run(expr);
        
        bool success = e.success();
        positive += success;
        
        // substitutions for special cases of runtime results
        if(tests[i].value == _NAN) tests[i].value = nan;
        else if(tests[i].value == _INF) tests[i].value = inf;
        else if(tests[i].value == _IND) tests[i].value = ind;
        
        bool passed = fabs(result - tests[i].value) < 1.0e-8;
        if(!MathIsValidNumber(result) && !MathIsValidNumber(tests[i].value))
        {
          passed = NaNs[result] == NaNs[tests[i].value];
        }
        count += passed;
        Print((i + 1), " ", (passed ? "passed" : "failed"), ", ", (success ? "ok: " : "er: "), expr, " = ", result, "; expected = ", tests[i].value);
      }
      Print(count, " tests passed of ", n);
      Print(positive, " for correct expressions, ", n - positive, " for invalid expressions");
    }
};

class TestSuiteEvaluator: public TestSuite<ExpressionEvaluator>
{
  public:
    TestSuiteEvaluator(const string variables = NULL): TestSuite(variables) {}

    virtual double run(const string &expr) override
    {
      return e.evaluate(expr);
    }
};

class TestSuiteCompiler: public TestSuite<ExpressionCompiler>
{
  public:
    TestSuiteCompiler(const string variables = NULL): TestSuite(variables) {}

    virtual double run(const string &expr) override
    {
      return e.evaluate(expr).resolve();
    }
};


TestCase testsuite[] =
{
  {"a > b ? b > c ? 1 : 2 : 3", 3},
  {"2 > 3 ? 2 : 3 > 4 ? 3 : 4", 4},
  {"4 > 3 ? 2 > 4 ? 2 : 4 : 3", 4},
  {"(a + b) * sqrt(c)", 8.944271909999159},
  {"(b == c) > (a != 1.5)", 0},
  {"(b == c) >= (a != 1.5)", 1},
  {"(a > b) || sqrt(c)", 1},
  {"(!1 != !(b - c/2))", 1},
  {"-1 * c == -sqrt(-c * -c)", 1},
  {"pow(2, 5) % 5", 2},
  {"min(max(a,b),c)", 2.5},
  {"atan(sin(0.5)/cos(0.5))", 0.5},
  {".2 * .3 + .1", 0.16},
  {"(a == b) + (b == c)", 0},
  {"-(a + b) * !!sqrt(c)", -4},
  {"sin ( max ( 2 * 1.5, 3 ) / 3 * 3.14159265359 )", 0},

  {"1 / _1c", _NAN},         // can't initialize with nan
  {"1 / (2 * b - c)", _INF}, // can't initialize with inf
  {"sqrt(b-c)", _IND},       // can't initialize with ind
};


ulong testEvaluation(const string expr, const int n)
{
  ulong ul, total = 0;
  double r;
  
  ExpressionEvaluator e("a=1.5;b=2.5;c=5");
  for(int i = 0; i < n; i++)
  {
    e.variableTable().update(0, rand());
    e.variableTable().update(1, rand());
    e.variableTable().update(2, rand());
    ul = GetMicrosecondCount();
    r = e.evaluate(expr);
    total += GetMicrosecondCount() - ul;
  }
  return total;
}

ulong testPromise(const string expr, const int n)
{
  ulong ul = 0, total = 0;
  double r;
  
  if(n == 0) ul = GetMicrosecondCount();

  ExpressionCompiler e("a=1.5;b=2.5;c=5");
  Promise * p = e.evaluate(expr);
  
  if(n == 0) total = GetMicrosecondCount() - ul;
  
  VariableTable *vt = e.variableTable();
  
  for(int i = 0; i < n; i++)
  {
    vt.update(0, rand());
    vt.update(1, rand());
    vt.update(2, rand());
    ul = GetMicrosecondCount();
    r = p.resolve();
    total += GetMicrosecondCount() - ul;
  }
  return total;
}


void OnStart()
{
  Print(">>> Functional testing");
  TestSuiteEvaluator evaluator("a=1.5;b=2.5;c=5");
  evaluator.test(testsuite);

  TestSuiteCompiler compiler("a=1.5;b=2.5;c=5");
  compiler.test(testsuite);

  // example of multiple calculations of the same formula with altered variables
  
  Print(">>> Building syntax tree");

  VariableTable vt;               // we could skip this declaration here and move it to point B (below)
  ExpressionCompiler c(vt);       // bind the table with the compiler to preserve indices of the variables' names
                                  // if the table is not specified here, it's created internally
                                  // and accesible via c.variableTable()
  vt.adhocAllocation(true);       // allow register new variable names on the fly during parsing
  
  const string expr = "(a + b) * sqrt(c)";
                                  // names are indexed in the order of appearence, a = 0, b = 1, c = 2
  Promise *p = c.evaluate(expr);  // parse the expression into the tree
  p.print();                      // show the syntax tree

  Print(">>> Calculations via compiled promises");
  
  vt.assign("a=1.5;b=2.5;c=5");
  Print(p.resolve());

  vt.assign("c=1.5;b=2.5;a=5");
  Print(p.resolve());

  Print(">>> Calculation via evaluation (simpliest but slow)");
  ExpressionEvaluator e("a=1.5;b=2.5;c=5");
  Print((e.success() ? "ok: " : "**: "), expr, " = ", e.evaluate(expr)); // NB: arguments of MQL functions are processed from right to left
  
}