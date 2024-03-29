﻿//+------------------------------------------------------------------+
//|                                   teste-c0008-net-perceptron.mq5 |
//|                                         Copyright 2020, OS Corp. |
//|                                                http://www.os.org |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, OS Corp."
#property link      "http://www.os.org"
#property version   "1.000"

#include <oslib\osc\est\C0008NetPerceptron.mqh>
#include <oslib\osc\data\osc-csv.mqh>
#include <Math\Alglib\dataanalysis.mqh>

//#property script_show_inputs
//input double  INI   = 0;  
//input double  FATOR = 1;
//input int     QTD   = 40;

//+------------------------------------------------------------------+
//| Calcula progressao aritimetica                                   |
//+------------------------------------------------------------------+

void OnStart(){
    //test_perceptron_train_porta_AND();
    //test_perceptron_train_students_data();
    //test_perceptron_train_porta_XOR_AlgLib();
    test_perceptron_train_porta_AND_AlgLib();
}

void test_perceptron_train_porta_AND(){
   
    C0008NetPerceptron p;

    //double vx[] = {1.0,1.0}; // vx = np.array([1,1])
    //double ny   =  1   ; // ny =  1
    //double vw[] = {2.0,3.0}; // vw = np.array([2,3])
    //double nb   = 4    ; // nb =  4
    //double nl   = 0.01 ; // nl = 0.01
    //p.update_weights(vx, vw, nb, ny, nl); //nvw,nnb = update_weights(vx, ny, vw, nb, nl)
    //ArrayPrint(vw,8);
    //Print(nb);
    //print(nvw)
    //print(nnb)
    //return;

    Print("TESTE TREINAMENTO PERCEPTRON...");
  //double    FEATURES[][2] = {{1,1},{2,2},{3,3},{4,4}};
  //double              Y[] = { 1   , 2   , 3   , 4   };
    double    FEATURES[][2] = {{0,0},{0,1},{1,0},{1,1}};
    double              Y[] = { 0   , 0   , 0   , 1   };
    //double  resul[]         = {0,0,0,0};

    p.train(FEATURES,Y,100,0.1);

    /*
    double X1[]  = { 1, 1};
    double X2[]  = {-1,-1};
    double W []  = {1,1};
    double bias = 0    ;
    
    Print( "Previsao para o ponto X1 ( 1, 1):", p.fnet(X1,W,bias) );
    Print( "Previsao para o ponto X2 (-1,-1):", p.fnet(X2,W,bias) );

    double W []  = {1,1};
    */    
}


void test_perceptron_train_students_data(){
    osc_csv arq;
    arq.open( "08.36_student_data.csv",',');
    
    string cabec [];
    string fields[];
        
    // imprimindo o cabecalho...
    arq.get_cabec(cabec);
    ArrayPrint(cabec);

    arq.count_lines();
    int qtd_lines       = arq.get_qtd_lines();
    int qtd_lines_test  = qtd_lines/10; // 10% dos dados serao usados pra teste;
    int qtd_lines_train = qtd_lines - qtd_lines_test; // os demais serao usados para treinamento.
    
    Print("Arquivo com ", qtd_lines, " linhas, das quais ", qtd_lines, " serao usadas para treinar a rede e ", qtd_lines_test, " serao usadas para testar");


    // colunas da planilha...
    int ADMIT = 0; // informa se o candidato foi admitido
    int GRE   = 1; // score GRE (test)
    int GPA   = 2; // score GPA ()
    int RANK  = 3; // classificacao
    
    double FEATURES[][3], FEATURES_TRAIN[][3], FEATURES_TEST[][3];
    double TARGETS[]    , TARGETS_TRAIN[]    , TARGETS_TEST[]    ;
    
    ArrayResize(FEATURES      ,qtd_lines      ); ArrayResize(TARGETS      ,qtd_lines      );
    ArrayResize(FEATURES_TRAIN,qtd_lines_train); ArrayResize(TARGETS_TRAIN,qtd_lines_train);
    ArrayResize(FEATURES_TEST ,qtd_lines_test ); ArrayResize(TARGETS_TEST ,qtd_lines_test );
    
    // passando o arquivo para os vetores de features e de resultados...
    for(int i=0; !arq.fim_de_arquivo(); i++ ){
        arq.read_line(fields); // lendo uma linha do arquivo...
        TARGETS [i]         = StringToDouble(fields[ADMIT]);
        FEATURES[i][GRE -1] = StringToDouble(fields[GRE  ]);
        FEATURES[i][GPA -1] = StringToDouble(fields[GPA  ]);
        FEATURES[i][RANK-1] = StringToDouble(fields[RANK ]);
    }
    arq.close();
    
    // padronizando...
    //osc_mat::escalar_colunas_pelo_max(FEATURES); 
    osc_mat::padronizar_colunas(FEATURES,true); 
    
    // passando para os vetores de treinamento...
    for(int i=0; i<qtd_lines_train; i++){
        TARGETS_TRAIN [i]         = TARGETS [i]        ;
        FEATURES_TRAIN[i][GRE -1] = FEATURES[i][GRE -1];
        FEATURES_TRAIN[i][GPA -1] = FEATURES[i][GPA -1];
        FEATURES_TRAIN[i][RANK-1] = FEATURES[i][RANK-1];
    }

    // passando para os vetores de teste...
    for(int i=0; i<qtd_lines_test; i++){
        TARGETS_TEST [i]         = TARGETS [qtd_lines_train+i]        ;
        FEATURES_TEST[i][GRE -1] = FEATURES[qtd_lines_train-i][GRE -1];
        FEATURES_TEST[i][GPA -1] = FEATURES[qtd_lines_train-i][GPA -1];
        FEATURES_TEST[i][RANK-1] = FEATURES[qtd_lines_train-i][RANK-1];
    }
    
    //ArrayPrint(TARGETS_TRAIN ); ArrayPrint(FEATURES_TRAIN,4);
    //ArrayPrint(TARGETS_TEST  ); ArrayPrint(FEATURES_TEST ,4);
    
    arq.close();
    
    //instanciando o perceptron...
    C0008NetPerceptron p;
    
    // treinando...
    double W[];
    p.train_nn(FEATURES_TRAIN,TARGETS_TRAIN,W,1000,0.5);
    ArrayPrint(W,4);
    
}

// Testando uma rede perceptron montada com AlgLib para simular uma porta XOR...
void test_perceptron_train_porta_XOR_AlgLib(){

   CMultilayerPerceptron network;
   CMLPReport            rep;
   int                   info=0;
   
   CMatrixDouble xy;
   xy.Resize(4,3); // a terceira coluna sao os labels (Y)
   xy[0].Set(0,-1); xy[0].Set(1,-1); xy[0].Set(2,-1);
   xy[1].Set(0, 1); xy[1].Set(1,-1); xy[1].Set(2, 1);
   xy[2].Set(0,-1); xy[2].Set(1, 1); xy[2].Set(2, 1);
   xy[3].Set(0, 1); xy[3].Set(1, 1); xy[3].Set(2,-1);
//--- function calls
   // Same as MLPCreate0, but with one hidden layer (NHid neurons) with|
   // non-linear activation function. Output layer is linear.          |
   // 2 neuronios na camada de entrada
   // 2 neuronios na camada escondida
   // 1 neuronio na camada de saida
   CMLPBase::MLPCreate1(2,2,1,network);
   
   // in network : rede neural com a geometria inicializada
   // in xy      : matrix com dados de entrada e labels na ultima coluna
   // in nPoints : quantidade de linhas na matriz que devem ser usados no treinamento
   // in decay   : coeficiente de regularizacao (reducao de peso)
   // in restarts: epocas
   // out network: rede neural treinada
   // out info   : return code. Se 2, entao (ok)
   // out rep    : relatorio do treinamento
   int nPoints = 4;
   CMLPTrain::MLPTrainLM(network,xy,nPoints,0.001,10,info,rep);
   double rms_error = CMLPBase::MLPRMSError(network,xy,nPoints);
   Print("Info:",info," ncholesky:",rep.m_ncholesky," ngrad:",rep.m_ngrad," nhess:",rep.m_nhess," rms_error:",rms_error);
   
   double x[2], y[];
   x[0]= -1; x[1]= -1; CMLPBase::MLPProcess(network,x,y); Print("(",x[0],",",x[1],") --> ",y[0]);
   x[0]=  1; x[1]= -1; CMLPBase::MLPProcess(network,x,y); Print("(",x[0],",",x[1],") --> ",y[0]);
   x[0]= -1; x[1]=  1; CMLPBase::MLPProcess(network,x,y); Print("(",x[0],",",x[1],") --> ",y[0]);
   x[0]=  1; x[1]=  1; CMLPBase::MLPProcess(network,x,y); Print("(",x[0],",",x[1],") --> ",y[0]);
   
//--- search errors
   //trnerrors=trnerrors || CMLPBase::MLPRMSError(network,xy,4)>0.1;
}

// Testando uma rede perceptron montada com AlgLib para simular uma porta AND...
void test_perceptron_train_porta_AND_AlgLib(){

   CMultilayerPerceptron network;
   CMLPReport            rep;
   int                   info=0;
   
   CMatrixDouble xy;
   xy.Resize(4,3); // a terceira coluna sao os labels (Y)
   xy[0].Set(0,-1); xy[0].Set(1,-1); xy[0].Set(2,-1);
   xy[1].Set(0, 1); xy[1].Set(1,-1); xy[1].Set(2,-1);
   xy[2].Set(0,-1); xy[2].Set(1, 1); xy[2].Set(2,-1);
   xy[3].Set(0, 1); xy[3].Set(1, 1); xy[3].Set(2, 1);
//--- function calls
   // Same as MLPCreate0, but with one hidden layer (NHid neurons) with|
   // non-linear activation function. Output layer is linear.          |
   // 2 neuronios na camada de entrada
   // 1 neuronio na camada escondida
   // 1 neuronio na camada de saida
   CMLPBase::MLPCreate1(2,1,1,network);
   
   // in network : rede neural com a geometria inicializada
   // in xy      : matrix com dados de entrada e labels na ultima coluna
   // in nPoints : quantidade de linhas na matriz que devem ser usados no treinamento
   // in decay   : coeficiente de regularizacao (reducao de peso)
   // in restarts: epocas
   // out network: rede neural treinada
   // out info   : return code. Se 2, entao (ok)
   // out rep    : relatorio do treinamento
   int nPoints = 4;
   CMLPTrain::MLPTrainLM(network,xy,nPoints,0.001,10,info,rep);
   Print("Info:",info," ncholesky:",rep.m_ncholesky," ngrad:",rep.m_ngrad," nhess:",rep.m_nhess," rms_error:",rms_error);
   
   double x[2], y[];
   x[0]= -1; x[1]= -1; CMLPBase::MLPProcess(network,x,y); Print("(",x[0],",",x[1],") --> ",y[0]);
   x[0]=  1; x[1]= -1; CMLPBase::MLPProcess(network,x,y); Print("(",x[0],",",x[1],") --> ",y[0]);
   x[0]= -1; x[1]=  1; CMLPBase::MLPProcess(network,x,y); Print("(",x[0],",",x[1],") --> ",y[0]);
   x[0]=  1; x[1]=  1; CMLPBase::MLPProcess(network,x,y); Print("(",x[0],",",x[1],") --> ",y[0]);
   
//--- search errors
   //trnerrors=trnerrors || CMLPBase::MLPRMSError(network,xy,4)>0.1;
}

//+------------------------------------------------------------------+