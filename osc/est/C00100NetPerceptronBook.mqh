﻿//+------------------------------------------------------------------+
//|                                       C00100NetPerceptronBook.mqh|
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
//#include <oslib\osc\osc-mat.mqh>
#include <oslib\osc\est\C0009NetPerceptron.mqh> 
#include <oslib\osc\est\osc-estatistic3.mqh> 
#include <oslib\osc\data\osc_db.mqh>

class C00100NetPerceptronBook{
private:
    osc_estatistic3*   m_est;
    C0009NetPerceptron m_net;
    CMatrixDouble      m_XY             ; // matriz com npoints linhas e nfeatures colunas
    int                m_pos            ;
    int                m_posant         ; // 
    int                m_npoints        ; // qtd de linhas do conjunto de treinamento
    ulong              m_nvoltas        ; // quantidade de voltas de renovacao de casos de treinamento
    int                m_nfeatures      ; // qtd de features da rede
    double             m_ultPmed        ; // ultimo preco medio registrado
    double             m_FEATURES[]     ; // vetor de features;
    double             m_varPrecoPredict;
    bool               m_treinou_uma_vez;
    osc_db             m_db             ;
    bool               m_registradb     ; // se deve registrar a performance em banco de dados
    ost_acum_feature   m_reg_feature    ; // campos para registrar a performance em banco de dados
    

    void addPosicaoPoint(){
        m_pos   ++; if(m_pos   >=m_npoints)   m_pos   =0;
      //m_posant++; if(m_posant>=m_npoints) { m_posant=0; train(); } // treinando a rede a cada volta pelo conjunto de treinamento
        
        
        m_posant++; 
        if(m_posant>=m_npoints){
            m_nvoltas++;
            m_posant=0;
            if( m_nvoltas>1 && m_nvoltas%2 == 0 ) train(); // treinando a rede a cada 2 voltas pelo conjunto de treinamento
        } 
    }
    
    double m_qtd_acertos    , m_qtd_erros;
    double m_qtd_acertos_dut, m_qtd_erros_dut; // dut: desde o ultimo treinamento
    
protected:
public:
    string toString(){
        string str = "";
        StringConcatenate(str, " m_pos:"            , m_pos,
                               " m_posant:"         , m_posant,
                               " m_npoints:"        , m_npoints,
                               " m_nfeatures:"      , m_nfeatures,
                               " m_ultPmed:"        , m_ultPmed,
                               " m_varPrecoPredict:", DoubleToString(m_varPrecoPredict,3),
                               " rms_error:"        , DoubleToString(get_rms_error()  ,3),
                                                      rel_performance(),
                                                      rel_performance_dut()
                               );
        return str;
    };
    
    double get_rms_error(){ return m_net.get_rms_error(); }

    // configura a rede com:
    // nin        numero de neuronios na camada de entrada
    // nhid1      numero de neuronios na primeira camada escondida (deve ser maior que zero)
    // nhid2      numero de neuronios na segunda  camada escondida (deve ser maior que zero)
    // nout       numero de neuronios na camada de saida
    // npoints    quantidade de casos que a rede usarah nos treinamentos
    // est        objeto estatistica que serah usado para recolher as features
    // registradb se true, registra a performance de cada previsao da rede em banco de dados
    bool configurarRede(int nin, int nhid1, int nhid2, int nout, int npoints, osc_estatistic3 *est, bool registradb=true, string ticker=""){
        
        // inicializando variaveis...
        m_treinou_uma_vez = false;
        m_qtd_acertos_dut = 0;
        m_qtd_acertos     = 0;
        m_qtd_erros_dut   = 0;
        m_qtd_erros       = 0;
        m_registradb      = registradb;
        
        // abrindo banco de dados se necessario...
        if(m_registradb){
            Print(__FUNCTION__, " Configurando banco de dados..." );
            m_db.create_or_open_mydb();
            //m_reg_feature.id   = TimeCurrent(); // inicializa o id da chave primaria
            m_reg_feature.grupo  = TimeCurrent();
            m_reg_feature.config = ticker                        + "-" +
                                   "E" +IntegerToString(nin    ) + "-" +
                                   "H" +IntegerToString(nhid1  ) + "-" +
                                   "H" +IntegerToString(nhid2  ) + "-" +
                                   "S" +IntegerToString(nout   ) + "-" +
                                   "T" +IntegerToString(npoints);
        }
        configurarTreinamento(npoints);
        setEstatistica(est);        
        
        // configurando a rede...
        return m_net.configurar(nin, nhid1, nhid2, nout);
    }

    // configura a rede com:
    // nin        numero de neuronios na camada de entrada
    // nhid1      numero de neuronios na primeira camada escondida (deve ser maior que zero)
    // nout       numero de neuronios na camada de saida
    // npoints    quantidade de casos que a rede usarah nos treinamentos
    // est        objeto estatistica que serah usado para recolher as features
    // registradb se true, registra a performance de cada previsao da rede em banco de dados
    bool configurarRede(int nin, int nhid1, int nout, int npoints, osc_estatistic3 *est, bool registradb=true, string ticker=""){
        
        // inicializando variaveis...
        m_treinou_uma_vez = false;
        m_qtd_acertos_dut = 0;
        m_qtd_acertos     = 0;
        m_qtd_erros_dut   = 0;
        m_qtd_erros       = 0;
        m_registradb      = registradb;
        
        // abrindo banco de dados se necessario...
        if(m_registradb){
            Print(__FUNCTION__, " Configurando banco de dados..." );
            m_db.create_or_open_mydb();
            //m_reg_feature.id = TimeCurrent(); // inicializa o id da chave primaria
            m_reg_feature.grupo = TimeCurrent();
            m_reg_feature.config = ticker                        + "-" +
                                   "E" +IntegerToString(nin    ) + "-" +
                                   "H" +IntegerToString(nhid1  ) + "-" +
                                   "S" +IntegerToString(nout   ) + "-" +
                                   "T" +IntegerToString(npoints);
        }
        configurarTreinamento(npoints);
        setEstatistica(est);        

        // configurando a rede...
        return m_net.configurar(nin, nhid1, nout);
    }

    // configura o tamanho do conjunto de treinamento.
    // OBS: o conjunto de treinamento eh mantido pela rede. A cada nova linha de treinamento, a ultima linha
    // eh desprezada.
    void configurarTreinamento( int npoints ){
        m_nfeatures = 9;
        m_npoints   = npoints;
        m_pos       = 1;//0;
        m_posant    = 0;//npoints-1;
        m_varPrecoPredict = 0;
        
        ArrayResize(m_FEATURES,m_nfeatures  );
        m_XY.Resize(m_npoints ,m_nfeatures+1);
    }

    // define o objeto estatistica que serah usado para obter as features do perceptron...
    void setEstatistica(osc_estatistic3 *est){ 
        m_est     = est;
        m_ultPmed = m_est.pmed(); 
    }

    // NAO ESTAH SENDO USADO 
    // acumulando no vetor de features...
    void acumularX(){
        
        int faixas = m_nfeatures;
        int primBid = 0;
        int lenBook = 0;
        MqlBookInfo book[];
        
        //m_est.getBook( const MqlBookInfo& book[] );
        
        // posicionando o book na primeira ordem de compra
        for(int i=0; book[i].type==BOOK_TYPE_SELL; i++){primBid=i;}
        lenBook = primBid*2; // tamanho do book
        
        // gravando as features...
        for(int i=0; i<faixas; i++ ){
            m_XY[m_pos].Set( primBid+i  ,book[primBid+i  ].volume ); // setando os bids
            m_XY[m_pos].Set( primBid-i-1,book[primBid-i-1].volume ); // setando os asks
        }
        
        // obtendo a variacao do preco...
        double varPreco = m_est.pmed()-m_ultPmed;
        
        // gravando a variacao do preco...
        m_XY[m_posant].Set( m_nfeatures+1, varPreco );
        
        // atualizando os ponteiros do conjunto de treinamento...
        addPosicaoPoint();
    }
    
    // acumulando no vetor de features...
    // eh acumulada a variacao de preco atual e as features do periodo anterior...
    void acumularFeature(bool verbose=false){
        // adicionando as features recebidas na chamada anterior, ao conjunto de treinamento...
        for(int i=0; i<m_nfeatures; i++){ m_XY[m_posant].Set(i,m_FEATURES[i]); }
        
        // obtendo a variacao do preco desde a ultima acumulacao de feature...
        double varPreco = (m_est.pmed()-m_ultPmed)/5.0;

        // gravando a variacao do preco na ultima coluna da matriz de treinamento...
        m_XY[m_posant].Set( m_nfeatures, varPreco );
        
        // salvando o preco atual para usar na proxima variacao...
        m_ultPmed = m_est.pmed();
        
        // atualizando os ponteiros do conjunto de treinamento...
        addPosicaoPoint();

        // preenchendo o vetor de features (serah usado na proxima acumulacao)...
        m_FEATURES[00] = 1;     // bias
        m_FEATURES[01] = m_est.getDPTrade();           // volatilidade
        m_FEATURES[02] = m_est.getAceVol();
        m_FEATURES[03] = m_est.getAceVolBuy();
        m_FEATURES[04] = m_est.getAceVolSel();
        //m_FEATURES[04] = m_est.getVolTradeTotPorSeg();
        //m_FEATURES[05] = m_est.getVolTradeLiqPorSeg();
        m_FEATURES[05] = m_est.getVolTradeBuyPorSeg();
        m_FEATURES[06] = m_est.getVolTradeSelPorSeg();
        //m_FEATURES[08] = 0;//m_est.getPUP(0); 
        //m_FEATURES[09] = 0;//m_est.getPUP(1); 
        //m_FEATURES[10] = 0;//m_est.getPUP(2); 
        //m_FEATURES[11] = 0;//m_est.getPUP(3);
        //m_FEATURES[12] = 0;//m_est.getPUP(4);
        //m_FEATURES[13] = 0;//m_est.getPUP(5);
        //m_FEATURES[14] = 0;//m_est.getPUP(6);
        //m_FEATURES[15] = 0;//m_est.getPUP(7);
        //m_FEATURES[16] = 0;//m_est.getPUP(8);
        //m_FEATURES[17] = 0;//m_est.getPUP(9);
        //m_FEATURES[18] = 0;//m_est.getInclinacaoBook();      
        m_FEATURES[07] = m_est.getInclinacaoTrade();     
        m_FEATURES[08] = m_est.getKyleLambda();
 //     m_FEATURES[19] = m_est.getKyleLambdaHLTrade();   // apagado
        //ArrayPrint(m_FEATURES,4);
        //Print(osc_mat::toString(m_XY,4) );
        
        if(!m_treinou_uma_vez){
            if(verbose) Print( toString() ); // informando variaveis da rede enquanto nao enche o conjunto de treinamento...
            return;
        }
        
        registraPerformance(varPreco,m_varPrecoPredict);
                       
        // se a previsao anterior tem sinal diferente da variacao de preco atual, treina a rede...
        if ( (m_varPrecoPredict*varPreco) < 0 && fabs(varPreco) > 0 ){
            m_qtd_erros++;
            m_qtd_erros_dut++;
            //registraPerformance(varPreco,m_varPrecoPredict);
            //if(verbose) Print(__FUNCTION__, " Previsao anterior falhou! Treinando a rede...");
            
            if(verbose) Print(__FUNCTION__, " ", rel_performance(varPreco,m_varPrecoPredict), " ",rel_performance_dut());
            
            if( m_qtd_erros_dut > 10 && getPerdaDut() > 0.40 ) train(verbose);
        }else{
            if((m_varPrecoPredict*varPreco) > 0 && fabs(varPreco) > 0 ){
                m_qtd_acertos++;
                m_qtd_acertos_dut++;
                //registraPerformance(varPreco,m_varPrecoPredict);
                //if(verbose) Print(__FUNCTION__," Previsao OK: ",toString());
                if(verbose) Print(__FUNCTION__, " ", rel_performance(varPreco,m_varPrecoPredict), " ",rel_performance_dut());
            }
        }
        
        //fazendo a previsao da variacao do preco e salvando...
        m_varPrecoPredict = predict(verbose);
    }

    string rel_performance(double y, double yhat ){
        string perf= rel_performance();
        StringConcatenate(perf, perf, " y:", DoubleToString(y,2), " yhat:", DoubleToString(yhat,2) );
        return perf;
    }
    string rel_performance(){
        string perf="";
        StringConcatenate(perf,"PERF_GERAL: ACERT:", m_qtd_acertos, " ERR:", m_qtd_erros, " PERD:", DoubleToString(getPerda(),2) );
        return perf;
    }
    
    string rel_performance_dut(){
        string perf="";
        StringConcatenate(perf,"PERF_DUT: ACERT:", m_qtd_acertos_dut, " ERR:", m_qtd_erros_dut, " PERD:",DoubleToString(getPerdaDut(),2) );
        return perf;
    }
    
    double getPerda   (){ return m_qtd_erros    /osc_mat::x_if_zero(m_qtd_erros    +m_qtd_acertos    , 1); }
    double getPerdaDut(){ return m_qtd_erros_dut/osc_mat::x_if_zero(m_qtd_erros_dut+m_qtd_acertos_dut, 1); }

    void registraPerformance(double y, double yhat){
        if(!m_registradb) return;
      //m_reg_feature.id++;
        m_reg_feature.hora       = TimeCurrent();
        m_reg_feature.rms_error  = m_net.get_rms_error();
        m_reg_feature.y          = y;
        m_reg_feature.yhat       = yhat;
        m_reg_feature.resul      = osc_mat::sinal(y*yhat);
        m_reg_feature.loss       = getPerda();
        m_reg_feature.loss_dut   = getPerdaDut();
        m_reg_feature.time_train = m_net.getTimeTrainInMilis();
        
        m_db.insert_table_acum_featute(m_reg_feature);        
    }
    
    // treinando a rede...
    bool train(bool verbose=true){ 
        bool result = m_net.trainLM(m_XY,m_npoints,0.01,10);
        if(verbose) Print( m_net.getStrRelTrain() );
        m_treinou_uma_vez = true;
        m_qtd_erros_dut  =0;
        m_qtd_acertos_dut=0;
        return result;
    }
    
    // calculando a previsao...
  //double predict(bool verbose=false){ return m_net.predict(m_FEATURES, m_XY, verbose); }
    double predict(bool verbose=false){ return m_net.predict(m_FEATURES               ); }
    
    double getPrevisao(){ return m_varPrecoPredict; }
    
};