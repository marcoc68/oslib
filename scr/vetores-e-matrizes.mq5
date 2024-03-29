﻿//+------------------------------------------------------------------+
//|                                           vetores-e-matrizes.mq5 |
//|                                         Copyright 2020, OS Corp. |
//|                                                http://www.os.org |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, OS Corp."
#property link      "http://www.os.org"
#property version   "1.000"

//#property script_show_inputs
//input double  INI   = 0;  
//input double  FATOR = 1;
//input int     QTD   = 40;

#include <Math\Alglib\matrix.mqh>
#include <oslib\osc\osc-mat.mqh>
#include <oslib\osc\est\C0008NetPerceptron.mqh>

//+------------------------------------------------------------------+
//| Teste de comportamento de vetores e matrizes                     |
//+------------------------------------------------------------------+

void OnStart(){
    // definindo a matriz...
    int qtdLin = 3;
    int qtdCol = 2;
    CMatrixDouble m1(qtdLin, qtdCol);
    
    m1[0].Set(0, 0 ); m1[0].Set(1, 1 );
    m1[1].Set(0, 10); m1[1].Set(1, 11);
    m1[2].Set(0, 20); m1[2].Set(1, 21);
    
    // print da matriz...
    Print("TESTE CMatrixDouble...");
    string linha = "|";
    for(int lin=0; lin<qtdLin; lin++){
        for(int col=0; col<qtdCol; col++){
            linha += DoubleToString(m1[lin][col],0) + "|";
        }
        Print(linha); linha = "|";
    }
    
    Print("TESTE MULTIPLICACAO DE 2 VETORES. RESULTADO DEVE SER 60.");
    double v1[] = {1,2,3,4};
    double v2[] = {2,4,6,8};
    double result = 0;
    
    osc_mat::dot(v1,v2,result);
    ArrayPrint(v1);
    ArrayPrint(v2);
    Print("Result m1 x m2: ",result);

    
    Print("TESTE MULTIPLICACAO DE DUAS MATRIZES. RESULTADO DEVE SER [6,12,18,24].");
    double    vv1[][2] = {{1,1},{2,2},{3,3},{4,4}};
    double    vv2[]    = {2,4};
    double  resul[]    = {0,0,0,0};
    
    osc_mat::dot(vv1,vv2,resul);
    ArrayPrint(vv1);
    ArrayPrint(vv2);
    Print("Result m1 x m2:");
    ArrayPrint(resul);
    
    Print("TESTE SIGMOID. RESULTADO DEVE SER: [0.99752738 0.99999386 0.99999998 1.        ]");
    C0008NetPerceptron p;
    double sig[];
    p.sigmoid(resul,sig);
    ArrayPrint(sig,8);
    
    Print("TESTE FNET: RESULTADO DEVE SER [0.99966465 0.99999917 1.         1.        ]");
    double yhat[];
    p.fnet(vv1,vv2,2,yhat);
    ArrayPrint(yhat,10);
    
}

string strLinCol(int lin, int col){return "(" + IntegerToString(lin) + "," + IntegerToString(col) + ")";}
//+------------------------------------------------------------------+