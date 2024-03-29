﻿//+------------------------------------------------------------------+
//|                                            C0009NetPerceptron.mqh|
//|                               Copyright 2021,oficina de software.|
//|                                 http://www.metaquotes.net/marcoc.|
//|                                                                  |
//|   Perceptron with statistics                                     |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "2020, Oficina de Software."
#property link      "http://www.os.net"

#include <Math\Alglib\dataanalysis.mqh>
//#include <Math\Stat\Normal.mqh> 
#include <oslib\osc\osc-mat.mqh>

class C0009NetPerceptron{

private:
   CMatrixDouble         m_matrix_train; // matriz usada no treinamento [para que nao altere a matriz original]
   CMultilayerPerceptron m_network  ; // rede;
   CMLPReport            m_rep      ; // relatorio da ultima operacao na rede;
   int                   m_retcode  ; // return code da ultima operacao na rede;
   double                m_rms_error; // erro quadratico medio do ultimo treinamento da rede;
   double                m_Y[]      ; // vetor com a ultima previsao feita pela rede;
   ulong t0,t1,t2,t3;
protected:
public:

    // configura a rede com:
    // nin   numero de neuronios na camada de entrada
    // nhid1 numero de neuronios na primeira camada escondida (deve ser maior que zero)
    // nhid2 numero de neuronios na segunda  camada escondida (deve ser maior que zero)
    // nout  numero de neuronios na camada de saida
    bool configurar(int nin, int nhid1, int nhid2, int nout){
        if(nhid1==0 || nhid2==0) return false;
        CMLPBase::MLPCreate2 (nin,nhid1,nhid2,nout,       m_network);
      //CMLPBase::MLPCreateR2(nin,nhid1,nhid2,nout,-1, 1, m_network);
      //CMLPBase::MLPCreateB2(nin,nhid1,nhid2,nout, 0, 0, m_network);
        return true;
    }
    
    // configura a rede com:
    // nin   numero de neuronios na camada de entrada
    // nhid1 numero de neuronios na primeira camada escondida (deve ser maior que zero)
    // nout  numero de neuronios na camada de saida
    bool configurar(int nin, int nhid1, int nout){
        if(nhid1==0) return false;
        CMLPBase::MLPCreate1(nin,nhid1,nout,m_network);
        return true;
    }
    
    // treinamento da rede
    // in xyd    : matrix com dados de entrada e labels na ultima coluna
    // in npoints: quantidade de linhas na matriz que devem ser usados no treinamento
    // in decay  : coeficiente de regularizacao (reducao de peso)
    // in epochs : epocas
    // out       : true se o treinamento foi OK.
    bool trainLM(CMatrixDouble &XYD, int npoints, double decay=0.01, int epochs=2){
        
        // padronizando os dados de entrada... (ultima coluna nao eh padronizada)...
        t0 = GetTickCount();
      //osc_mat::padronizar_colunas(XYD,m_matrix_train,1);
        
        // treinando a rede...
        t1 = GetTickCount();
        CMLPTrain::MLPTrainLM(m_network,XYD            , npoints, decay, epochs, m_retcode, m_rep);
      //CMLPTrain::MLPTrainLM(m_network, m_matrix_train, npoints, decay, epochs, m_retcode, m_rep);
        
        // salvando o erro quadratico medio atual da rede...
        t2 = GetTickCount();
        m_rms_error = CMLPBase::MLPRMSError(m_network,XYD           ,npoints);
      //m_rms_error = CMLPBase::MLPRMSError(m_network,m_matrix_train,npoints);

        //retornando...
        t3 = GetTickCount();
        return (m_retcode == 2);
    }
    
    long getTimeTrainInMilis(){ return (long)(t3-t0); }
    
    string getStrRelTrain(){
        string rel = "REL_TRAIN:";
        StringConcatenate(rel, rel, " sec:",DoubleToString((t3-t0)/1000.0,4)," RetCode:",m_retcode," ncholesky:",m_rep.m_ncholesky," ngrad:",m_rep.m_ngrad," nhess:",m_rep.m_nhess," rms_error:",DoubleToString(m_rms_error,10));
        return rel;
    }

    // treinamento da rede
    // in xy     : matrix com dados de entrada e labels na ultima coluna
    // in npoints: quantidade de linhas na matriz que devem ser usados no treinamento
    // in decay  : coeficiente de regularizacao (reducao de peso)
    // in epochs : epocas
    // out       : true se o treinamento foi OK.
    bool trainLM(double &XY[][], int npoints, double decay=0.01, int epochs=2){
        
        // convertendo a matriz de entrada para CMatrixDouble...
        CMatrixDouble XYD; osc_mat::matrix2CmatrixD(XY,XYD,npoints);
        
        // treinando a rede...
        return trainLM(XYD,npoints,decay,epochs);        
    }

    // retorna uma previsao feita pela rede...    
    double predict(double &X[]){ CMLPBase::MLPProcess(m_network,X,m_Y); return m_Y[0]; }
    
    // retorna uma previsao feita pela rede...
    // antes da previsao, normaliza X em funcao da matriz XY...    
    double predict(double &X[], CMatrixDouble &XY, bool verbose=false){
        double FEATURES[];
        
        osc_mat::padronizar_linha(XY,X,FEATURES);
        CMLPBase::MLPProcess(m_network,FEATURES,m_Y); 
        
        //if(verbose){
        //    Print("*** ",__FUNCTION__," ***" );
        //    Print("FEATURES:");
        //    ArrayPrint(X,3);
        //    Print("FEATURES PADRONIZADAS:");
        //    ArrayPrint(FEATURES,3);
        //    Print("PREVISAO:",m_Y[0]);
        //    Print("*** ",__FUNCTION__," ***" );
        //}        
        return m_Y[0]; 
    }
    
    // erro quadratico medio do ultimo treinamento...
    double get_rms_error(){ return m_rms_error; }
};