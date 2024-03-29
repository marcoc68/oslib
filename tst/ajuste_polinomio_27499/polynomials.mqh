﻿//+------------------------------------------------------------------+
//|                                                  polynomials.mqh |
//|                                            Rafael Floriani Pinto |
//|                           https://www.mql5.com/pt/users/rafaelfp |
//+------------------------------------------------------------------+
#property copyright "Rafael Floriani Pinto"
#property link      "https://www.mql5.com/pt/users/rafaelfp"
//+------------------------------------------------------------------+
//VALOR POLINOMIO
double valpoli(double &coefpoli[], double x)
  {
   int n = ArraySize(coefpoli);
   double soma = 0;
   for(int i = 0; i < n; i++)
     {
      soma = soma + coefpoli[i] * aElevadonaB(x, i);
     }
   return soma;
  }

//COEFICIENTES DERIVADA
int coefderivada(double &coefpoli[], double &coefderi[])  //coefderi[] array de retorno
  {
   int n = ArraySize(coefpoli);
   double coefaux[];
   if(ArrayResize(coefaux, n - 1))
     {
      for(int i = 0; i < n - 1; i++)
        {
         coefaux[i] = coefpoli[i + 1] * (i + 1);
        }
      if(ArrayCopy(coefderi, coefaux) == (n - 1))
        {
         return 1;
        }
      else
        {
         return -1;
        }
     }
   else
     {
      return -1;
     }
  }

//VALOR DERIVADA
double valderivada(double & coefpoli[], double x)
  {
   double coefderi[];
   coefderivada(coefpoli, coefderi);
   return valpoli(coefderi, x);
  }

//DERIVADA CRESCENTE OU DECRESCENTE
int isderivadapolipositiva(double &coefpolinomio[], double x)
  {
   double k = valderivada(coefpolinomio, x);
   return isDoublePositivo(k);
  }

//DIVISÃO DE POLINOMIOS

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int divpoli(double &coefpoli[], double &coefdiv[], double k)
  {
   int n = ArraySize(coefpoli);
   if(ArrayResize(coefdiv, n - 1))
     {
      coefdiv[n - 2] = coefpoli[n - 1];
      for(int i = n - 2; i > 0; i--)
        {
         coefdiv[i - 1] = coefpoli[i] - (coefdiv[i] * (-k));
        }
     }
   else
     {
      return -1;
     }
   return 1;
  }

//RETORNA RESTO




//RAIO PARA RAIZES

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double raiomax(double &coefpoli[])
  {
   return 1;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double aElevadonaB(double a, int b)
  {
   double aux = 1;
   for(int i = 0; i < b; i++)
     {
      aux = aux * a;
     }
   return aux;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int isDoublePositivo(double a)
  {
   if(a > 0)
     {
      return 1;
     }
   if(a < 0)
     {
      return -1;
     }
   else
     {
      return 0;
     }
  }
//+------------------------------------------------------------------+

/*LIBS NECESSARIAS

SEJA O POLINOMIO
A0+A1*X+A2*X^2.....+An*X^n
Todo array , coefpoli[] deve ser passado com os coeficientes A0,A1...An em ordem
FUNÇÕES PRESENTES

double valpoli(double &coefpoli[],double x)
calculo do valor de y no x
Recebe como argumento os coeficientes do polinomio no arrau coefpoli[], e x

int coefderivada(double &coefpoli[],double &coefderi[])
Recebe como argumento os coeficientes do polinomio no array coefpoli[]
O array coefderi[] onde será retornado os coeficientes da primeira derivada do polinomio

double valderivada(double & coefpoli[],double x)
calculo do valor y da primeira derivada do polino no x
Recebe como argumento os coeficientes do polinomio no array coefpoli[], e x

int isderivadapolipositiva(double &coefpolinomio[],double x)
Recebe como argumento os coeficientes do polinomio no array coefpolinomio[], e x
retorna 1 caso seja positiva nesse ponto -1 caso seja negativa, 0 caso seja zero

int divpoli(double &coefpoli[],double &coefdiv[],double k)
EXECUTA UMA DIVISÃO DO POLINIMIO
A0+A1*X+A2*X^2.....+An*X^n
POR
(X - k)
Recebe como argumento os coeficientes do polinomio no array coefpoli[]
O array coefderi[] onde será retornado os coeficientes resultado da divisao
Essa função não retorna o resto, caso exista.

*/
//+------------------------------------------------------------------+
