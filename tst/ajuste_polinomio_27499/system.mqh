﻿//+------------------------------------------------------------------+
//|                                                       system.mqh |
//|                                            Rafael Floriani Pinto |
//|                           https://www.mql5.com/pt/users/rafaelfp |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
#define GaussMathRafaelFP
#property copyright "Rafael Floriani Pinto"
#property link      "https://www.mql5.com/pt/users/rafaelfp"
#define lamb 0.0000000000000001
//+------------------------------------------------------------------+
//OPERAÇÕES MATRICIAIS SEM PIVOTAÇÃO

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int gausstrocaSP(double &a[], double &b[], int n, double &saidaa[], double &saidab[])
  {
//DECLARAÇÕES
   double coef;
   double auxa[], auxb[];
//OPERAÇÕES
   ArrayResize(auxa, n * n);
   ArrayResize(auxb, n);
   ArrayCopy(auxa, a);
   ArrayCopy(auxb, b);
//LOGICA
   for(int i = 0; i < n - 1; i++)
     {
      for(int j = i; j < n - 1; j++)
        {
         if(MathAbs(auxa[n * i + i]) > lamb)
           {
            coef = auxa[n * (j + 1) + i] / auxa[n * i + i];
            auxa[n * (j + 1) + i] = 0;
            auxb[j + 1] = auxb[j + 1] - (coef * auxb[i]);
           }  // if
         else
           {
            return -1;
           } // else
         for(int k = i + 1; k < n; k++)
           {
            auxa[n * (j + 1) + k] = auxa[n * (j + 1) + k] - (coef * auxa[n * i + k]);
           } // for k
        } // for j
     } // for i
   ArrayCopy(saidaa, auxa);
   ArrayCopy(saidab, auxb);
   return 1;
  }

//OBTENÇÃO DA MATRIZ SOLUÇÃO

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int gausscalculo(double &a[], double &b[], int n, double &retorno[])
  {
   double aux[], soma = 0;
   ArrayResize(aux, n);
   if(MathAbs(a[(n * n) - 1]) > lamb)
     {
      aux[n - 1] = b[n - 1] / a[(n * n) - 1];
     }
   else
     {
      return -1;
     }
   for(int i = 1; i < n; i++)
     {
      for(int j = 0; j < i; j++)
        {
         soma = soma + (aux[n - j - 1] * a[(n * (n - i)) - 1 - j]);
        }
      if(MathAbs(a[(n * (n - i)) - 1 - i]) > lamb)
        {
         aux[n - 1 - i] = (b[n - 1 - i] - soma) / a[(n * (n - i)) - 1 - i];
         soma = 0;
        }
      else
        {
         return -1;
        }
     }
   ArrayCopy(retorno, aux);
   return 1;
  }

//FUNCAO CHAMADA

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int gaussbasico(double &a[], double &b[], double &retorno[])
  {
//declarações
   int n = ArraySize(b);
   double auxa[], auxb[];
//funçoes
   if(gausstrocaSP(a, b, n, auxa, auxb) == 1)
     {
      if(gausscalculo(auxa, auxb, n, retorno) == 1)
        {
         return 1;
        }
      else
        {
         return -2;
        }
     }
   else
     {
      return -1;
     }
   return -3;
  }

//+------------------------------------------------------------------+
/* //RESOLUÇÃO DE SISTEMAS LINEARES POR GAUSS
A*X=B

Chamar funçao
int gaussbasico(double &a[],double &b[],double &retorno[]){}
a[]= array com os coeficientes da matriz A, exemplo:
se:
  |1,2,3|
A=|5,6,9|
  |7,0,3|
o parametro a[] deve ser enviado como
a[]={1,2,3,5,6,9,7,0,3}
b[] array com os coeficientes da matriz B exemplo:
   |5|
B= |3|
   |2|
o parametro b[] deve ser enviado como
b[]={5,3,2}
o parametro retorno[] recebe a matriz solução X.


o array retorno[] deve ser declado como um array double dinamico
double retorno[];
A propria função gausssbasico faz o ajuste do seu tamanho.

A função gauss basico retorna um inteiro:
1 - função executada com sucesso.
-1 -Problema nas operações em A.
-2 -Problema nas operações em B.
-3 -Erro desconhecido



*/
//+------------------------------------------------------------------+
