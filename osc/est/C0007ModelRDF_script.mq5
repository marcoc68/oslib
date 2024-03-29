﻿//+------------------------------------------------------------------+
//|                                                 C0007ModelRDF.mqh|
//|                               Copyright 2021,oficina de software.|
//|                                 http://www.metaquotes.net/marcoc.|
//|                                                                  |
//|   Modelo de floresta randomica de arvores de decisao.            |
//|                                                                  |
//|                                                                  |
//|                                                                  |
//| VARIAVEIS DE ENTRADA:                                            |
//| - velLiq [velocidade do volume de compra menos a velocidade do   |
//|           volume de venda. eh a velocidade liquida do mercado]   |
//|   - TERMOS:                                                      |
//|      -comprando de -40 a  1000                                   |
//|      -neutro    de -40 a  40                                     |
//|      -vendendo  de  40 a -1000                                   |
//|                                                                  |
//|        -vendaFreiando   de  2 a -30                              |
//|                                                                  |
//| VARIAVEL DE SAIDA:                                               |
//| - risco  [risco de abrir ou manter a posicao aberta]             |
//|   - TERMOS:                                                      |
//|      -baixo     de 0.0 a 0.3                                     |
//|      -medio     de 0.3 a 0.5                                     |
//|      -alto      de 0.5 a 1.0                                     |
//|                                                                  --------------------------------------------|
//| REGRAS                                                                                                       |
//| - C01 - if mercado estah comprador e compra estah acelerando e volVenda estah freiando   then riscoCompra-01 |
//| - C02 - if mercado estah comprador e compra estah acelerando e volVenda estah acelerando then riscoCompra-02 |
//|                                                                                                              |
//| - V01 - if mercado estah vendedor  e venda estah acelerando e volCompra estah freiando   then riscoVenda-01  |
//| - V02 - if mercado estah vendedor  e venda estah acelerando e volCompra estah acelerando then riscoVenda-02  |
//|                                                                                                              |
//+--------------------------------------------------------------------------------------------------------------+
#property copyright "2020, Oficina de Software."
#property link      "http://www.os.net"

#include <oslib\osc\est\C0007ModelRDF.mqh>


// script para testar a classe...
void OnStart(){
    Print("inicio teste...");
    testar();     
    Print("fim teste...");

}

// script para testar a classe...
void testar(){

    Print("durante teste...");
    C0007ModelRDF rdf     ;
    //CMatrixDouble floresta;
    
    double florestd[ ][4] = {{1,2,3,2},
                             {3,2,1,0},
                             {1,2,2,1},
                             {3,2,2,0},
                             {2,2,2,3},
                             {2,3,4,4},
                             {3,4,5,5},
                             {5,4,3,3},
                             {4,3,2,0},
                             {3,4,5,1},
                             {4,5,6,6},
                             {5,6,7,1},
                             {6,7,8,0},
                             {5,6,6,1},
                             {4,5,5,3},
                             {3,4,4,1},
                             {7,6,5,0},
                             {6,5,4,5},
                             {8,7,6,0} 

                             };
    
    ArrayPrint(florestd);
    Print( ArrayRange(florestd,0) );
    
    //floresta.Resize(5,4); // 5 linhas e 4 colunas...
    
    //matrix2CmatrixD(florestd,floresta);
    
    int           npoints  = ArrayRange(florestd,0); // todas as linhas da matriz serao usadas pra teste.
    int           nvars    = 3  ; // cada linha com 4 colunas, sendo as 3 primeiras, uma arvore.
    int           nclasses = 1  ; // a ultima coluna eh uma variavel com duas classes.
  //int           ntrees   = ArrayRange(florestd,0); ; // quantidade de arvores no modelo
    double        r        = 0.5; // regularizacao
    
    rdf.compile(florestd ,
                npoints  ,
                nvars    ,
                nclasses ,
              //ntrees   ,
                r        );
    
  //double x[] = {1,2,3}; //0,1
  //double x[] = {4,3,2}; //1,0
    double x[] = {2,3,4}; //0,1
  //double x[] = {5,6,6}; //0,1
  //double x[] = {5,6,7}; //0,1
  //double x[] = {6,5,4}; //1,0
    double y[];
    
    rdf.processar(x,y);
    
    ArrayPrint(x);
    ArrayPrint(y);   
}
/*
void matrix2CmatrixD(double &mat[][], CMatrixDouble &matd){
    int qtdLin = ArrayRange(mat,0);
    int qtdCol = ArrayRange(mat,1);
    matd.Resize(qtdLin,qtdCol);
    
    for( int lin=0; lin<qtdLin; lin++){
        for(int col=0; col<qtdCol; col++ ){
            matd[lin].Set(col,mat[lin][col]);
        }
    }
}
*/