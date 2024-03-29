﻿//+------------------------------------------------------------------+
//|                                                   IrisSample.mq5 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Graphics\Graphic.mqh>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//--- Iris Setosa
   double Setosa_x[];
   double Setosa_y[];
//--- Iris Versicolour
   double Versicolour_x[];
   double Versicolour_y[];
//--- Iris Virginica
   double Virginica_x[];
   double Virginica_y[];
   string f_name="iris.txt";
   if(!ReadDataFromFile(f_name,Setosa_x,Setosa_y,
      Versicolour_x,Versicolour_y,Virginica_x,Virginica_y))
      Print("Failed reading data from ",f_name);
   CGraphic graphic;
   graphic.Create(0,"G",0,30,30,780,380);
//--- add Curve for Setosa
   CCurve* Setosa=graphic.CurveAdd(Setosa_x,Setosa_y,CURVE_POINTS,"Setosa");
   Setosa.PointsFill(true);
   Setosa.PointsType(POINT_CIRCLE);
//--- add Curve for Versicolour
   CCurve* Versicolour=graphic.CurveAdd(Versicolour_x,Versicolour_y,CURVE_POINTS,"Versicolour");
   Versicolour.PointsFill(true);
   Versicolour.PointsType(POINT_DIAMOND);
//--- add Curve for Virginica
   CCurve* Virginica=graphic.CurveAdd(Virginica_x,Virginica_y,CURVE_POINTS,"Virginica");
   Virginica.PointsFill(true);
   Virginica.PointsType(POINT_TRIANGLE);
//--- plot all curves
   graphic.CurvePlotAll();
   graphic.Update();
  }
//+------------------------------------------------------------------+
//|  Читает данные из подготовленного файла                          |
//+------------------------------------------------------------------+
bool ReadDataFromFile(string filename,double &x1[],double &y1[],
                      double &x2[],double &y2[],double &x3[],double &y3[],)
  {
   int file_handler=FileOpen(filename,FILE_READ|FILE_TXT|FILE_ANSI);
   if(file_handler==INVALID_HANDLE)
     {
      Print("Failed to open file ",filename,"  error=",GetLastError());
      return (false);
     }
   int counter=0;
   while(!FileIsEnding(file_handler))
     {
      counter++;
      string line=FileReadString(file_handler);
      string words[];
      StringSplit(line,',',words);
      string iris=words[4];
      if(iris=="Iris-setosa")
        {
         ArrayResize(x1,ArraySize(x1)+1,200);
         ArrayResize(y1,ArraySize(y1)+1,200);
         x1[ArraySize(x1)-1] = (double)words[0];
         y1[ArraySize(y1)-1] = (double)words[1];
        }
      else
        {
         if(iris=="Iris-versicolor")
           {
            ArrayResize(x2,ArraySize(x2)+1,200);
            ArrayResize(y2,ArraySize(y2)+1,200);
            x2[ArraySize(x2)-1] = (double)words[0];
            y2[ArraySize(y2)-1] = (double)words[1];
           }
         else
           {
            if(iris=="Iris-virginica")
              {
               ArrayResize(x3,ArraySize(x3)+1,200);
               ArrayResize(y3,ArraySize(y3)+1,200);
               x3[ArraySize(x3)-1] = (double)words[0];
               y3[ArraySize(y3)-1] = (double)words[1];
              }
           }
        }
     }
//---
   return (true);
  }
//+------------------------------------------------------------------+
