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

#include <Math\Alglib\dataanalysis.mqh>

class C0007ModelRDF{

private:
    //RDF system. Aqui nós criamos todos os objetos RF.
    CDecisionForest      m_RDF      ; //Random forest object
    CMatrixDouble        m_floresta ; //Matrix for RF inputs and output
    CDFReport            m_RDFreport; //RF return errors in this object, then we can check it

    void matrix2CmatrixD(double &mat[][], CMatrixDouble &matd, int nLin);
    void initialize();
protected:
public:
    
    bool compile(      double &floresta[][],
                 const    int npoints ,
                 const    int nvars   ,
                 const    int nclasses,
                 const double r       );

    //+------------------------------------------------------------------+
    //| Procesing                                                        |
    //| INPUT PARAMETERS:                                                |
    //|     X       -   input vector,  array[0..NVars-1].                |
    //| OUTPUT PARAMETERS:                                               |
    //|     Y       -   result. Regression estimate when solving         |
    //|                 regression task, vector of posterior             |
    //|                 probabilities for classification task.           |
    //+------------------------------------------------------------------+
    void processar(double &x[],double &y[]){ CDForest::DFProcess(m_RDF,x,y); }};

//-----------------------------------------------------------------------------
// Compila a RDF.                                            
// 
//-----------------------------------------------------------------------------
// CMatrixDouble &floresta: conjunto de treinamento
// const    int   npoints : quantidade de arvores que devem ser usadas no treinamento
// const    int   nvars   : quantidade de variaveis independentes, NVars>=1
// const    int   nclasses: tipo de tarefa:
//                          * nclasses=1: tarefa de regressao com uma variavel dependente.
//                          * nclasses>1: tarefa de classificacao com qtd de classes 
//                                       igual a nclasses.
// const    int   ntrees  : qtd de arvores na floresta, ntrees>=1.
// const double   r       : porcentagem do conjunto de treinamento usada 
//                          para construir arvores individuais. 0<r<=1.
//-----------------------------------------------------------------------------
bool C0007ModelRDF::compile(      double &floresta[][],
                            const    int  npoints  ,
                            const    int  nvars    ,
                            const    int  nclasses ,
                            const double  r
                            ){
    

    // definindo a quantidade de arvores a usar    
    int ntrees = (int)(npoints*0.1); // inicialmente 10% da quantidade de arvores no conjunto de dados...
    if(ntrees<50) ntrees = 50;   // no minimo 50 arvores...
    if(ntrees>npoints) ntrees = npoints; // a menos que hava poucos dados no conjunto de treinamento

    // passando a matriz double para o formato de matriz da alglib...
    matrix2CmatrixD(floresta,m_floresta, npoints);

    // treinando o modelo...
    int return_code;
    CDForest::DFBuildRandomDecisionForest(m_floresta,
                                          npoints ,
                                          nvars   ,
                                          nclasses,
                                          ntrees  ,
                                          r       ,
                                          return_code,
                                          m_RDF      ,
                                          m_RDFreport);
    // analisando o resultado do treinamento...
    if( return_code >   0 ){
        //Print("m_RDFreport.m_avgce         :",m_RDFreport.m_avgce         ,"\n",
        //      "m_RDFreport.m_avgerror      :",m_RDFreport.m_avgerror      ,"\n",
        //      "m_RDFreport.m_avgrelerror   :",m_RDFreport.m_avgrelerror   ,"\n",
        //      "m_RDFreport.m_oobavgce      :",m_RDFreport.m_oobavgce      ,"\n",
        //      "m_RDFreport.m_oobavgrelerror:",m_RDFreport.m_oobavgrelerror,"\n",
        //      "m_RDFreport.m_oobrelclserror:",m_RDFreport.m_oobrelclserror,"\n",
        //      "m_RDFreport.m_oobrmserror   :",m_RDFreport.m_oobrmserror   ,"\n",
        //      "m_RDFreport.m_relclserror   :",m_RDFreport.m_relclserror   ,"\n",
        //      "m_RDFreport.m_rmserror      :",m_RDFreport.m_rmserror      ,"\n",
        //      "m_RDF.m_ntrees              :",m_RDF.m_ntrees                   ) ;
        return true;
    }
    if( return_code == -1 ){Print(__FUNCTION__," :-( there is a point with class number outside of [0..NClasses-1]"); return false;}
    if( return_code == -2 ){
        Print(__FUNCTION__," :-( incorrect parameters was passed (NPoints<1, NVars<1, NClasses<1, NTrees<1, R<=0 or R>1)"); 
        Print(__FUNCTION__," :-( incorrect parameters was passed (NPoints :", npoints ); 
        Print(__FUNCTION__," :-( incorrect parameters was passed (NClasses:", nclasses); 
        Print(__FUNCTION__," :-( incorrect parameters was passed (NTrees  :", ntrees  ); 
        Print(__FUNCTION__," :-( incorrect parameters was passed (R       :", r       ); 
        return false;}
    Print(__FUNCTION__," :-( ERRO DESCONHECIDO!!!)");
    
    return false;
}
//-----------------------------------------------------------------------------

void C0007ModelRDF::initialize(void){
}

void C0007ModelRDF::matrix2CmatrixD(double &mat[][], CMatrixDouble &matd, int nLin){
  //int nLin = ArrayRange(mat,0);
    int nCol = ArrayRange(mat,1);
    matd.Resize(nLin,nCol);
    
    for( int lin=0; lin<nLin; lin++){
        for(int col=0; col<nCol; col++ ){
            matd[lin].Set(col,mat[lin][col]);
        }
    }
}
