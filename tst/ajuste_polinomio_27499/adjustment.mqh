﻿//+------------------------------------------------------------------+
//|                                                   adjustment.mqh |
//|                                            Rafael Floriani Pinto |
//|                           https://www.mql5.com/pt/users/rafaelfp |
//+------------------------------------------------------------------+
#property copyright "Rafael Floriani Pinto"
#property link      "https://www.mql5.com/pt/users/rafaelfp"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
#ifndef GaussMathRafaelFP
#include "system.mqh"
#endif
//+------------------------------------------------------------------+
//SOMAX
int somax(double &a[],int grau,int k,double &retorno[])
  {
   double aux[];
   ArrayResize(aux,(2*grau)+1);
   ZeroMemory(aux);

   for(int i=0; i<2*grau; i++)
     {
      for(int j=0; j<k; j++)
        {
         aux[i]=aux[i]+MinQuadradosaElevadonaB(a[j],((2*grau)-i));
        }

     }
   aux[(2*grau)]=k;
   if(ArrayCopy(retorno,aux)==((2*grau)+1))
     {

      return 1;
     }
   else
     {
      return -1;
     }

  }

//AJUSTE MATRIZ X
int ajustex(double &recX[],int grau,double &MatX[])
  {
   int size=(grau+1)*(grau+1);
   double XMat[];
   ArrayResize(XMat,size);
   for(int i=0; i<=grau; i++)
     {
      for(int j=0; j<=grau; j++)
        {
         XMat[((grau+1)*i) + j]=recX[(2*grau)-i-j];
        }
     }
   if(ArrayCopy(MatX,XMat)==size)
     {
      return 1;
     }

   return -1;
  }
//AJUSTE MATRIZ Y
int ajustey(double &x[],double &y[],int grau,int k,double &MatY[])
  {
   double YMat[];
   ArrayResize(YMat,grau+1);
   ZeroMemory(YMat);
   for(int i=grau; i>=0; i--)
     {
      for(int j=0; j<k; j++)
        {
         YMat[i]=YMat[i]+(MinQuadradosaElevadonaB(x[j],i)*y[j]);
        }
     }

   if(ArrayCopy(MatY,YMat)==grau+1)
     {
      return 1;
     }

   return -1;
  }



//MINIMOS QUADRADOS

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int minquadrados(double &x[],double &y[],int grau,double &coef[])
  {
   int k=ArraySize(y);
   double auxcoef[];
   double recX[];
   double MatX[],MatY[];
   if(somax(x,grau,k,recX)==1)
     {
      if(ajustex(recX,grau,MatX)==1)
        {


         if(ajustey(x,y,grau,k,MatY)==1)
           {

            if(gaussbasico(MatX,MatY,auxcoef)==1)
              {

               ArrayCopy(coef,auxcoef);
               return 1;
              }
            else
              {

               return -4;

              }


           }
         else
           {

            return -3;

           }
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



   printf("-5");
   return -5;

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MinQuadradosaElevadonaB(double a,int b)
  {
   double aux=1;
   for(int i=0; i<b; i++)
     {
      aux=aux*a;
     }
   return aux;
  }
//+------------------------------------------------------------------+

/* APROXIMACAO POR MIN QUADRADOS

LIBS NECESSARIAS
#include<Math/gauss.mqh>

int minquadrados(double &x[],double &y[],int grau,double &coef[])
x[] valores de xi
y[] valores de yi
grau grau desejado

A0+A1*x+A2*x^2....+Agrau*x^grau

coef[] array que retorna os coeficientes A0,A1...Agrau



*/




//+------------------------------------------------------------------+
