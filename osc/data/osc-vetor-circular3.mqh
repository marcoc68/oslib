//+------------------------------------------------------------------+
//|                                          osc-vetor-circular2.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"
//+---------------------------------------------------------------------+
//| Vetor circular baseado em filas visando rapido calculo de medias.   |
//+---------------------------------------------------------------------+
#property description "Vetor circular baseado em filas visando rapido calculo de medias."

#include <oslib/osc-padrao.mqh>
#include <oslib/osc/data/osc-vetor-fila-item2.mqh>

#define OSC_VETOR_CIRCULAR2_LEN_PADRAO 420

struct candle{
    double   open ; // abertura   : primeiro valor na fila
    double   close; // fechamento : ultimo   valor na fila
    double   high ; // maximo     : maior    valor na fila
    double   low  ; // minimo     : menor    valor na fila
  //double   inclHL;// inclinacao entre high e low: se positiva -> (candle de alta), se negativa, eh de baixa;
};

class osc_vetor_circular2 : public osc_padrao {
private:
    osc_vetor_fila_item m_vet         ; //vetor com item para o qual serao calculadas as medias;
    string              m_name        ; //identificador da fila
    bool                m_atuMinMax   ; // flag temporaria usada para manter maximo e minimo da fila; 

    //--------- controle do tamanho do vetor
    bool                m_relogio_por_evento; //true: cada tick eh um segundo. false: cada segundo eh um segundo.
    long                m_secondsMax        ; //se m_relogio_por_evento==false -> tamanho maximo do vetor em segundos;
                                              //se m_relogio_por_evento==true  -> tamanho maximo do vetor em qtd de acumulacoes;
    long                m_secondsAtu        ; //tamanho atual  do vetor em segundos;
                                              //eh o tempo desde a acumuacao mais antiga ateh a atual;
    long                m_tamanhoFila       ; // tamanho da fila, atualizado a cada adicao e retirada de tick
    //--------- controle do tamanho do vetor

  //Item                m_item        ;
    Item*               m_itemP       ;
    datetime            m_time        ; //data do ultimo item inserido no vetor. Novas insrcoes com data menor que esta serao descartadas;
    double              m_media       ; //ultima media calculada;
    double              m_somaVal     ; //soma dos valores usados no calculo da media sem os pesos;
    double              m_somaPeso    ; //soma dos pesos   usados no calculo da media;
    double              m_acelVolume  ;
    double              m_somaValxPeso; //soma acumulada dos valores multiplicados pelos pesos;
    double              m_distancia   ;
    double              m_distanciaM  ; // distancia a media do elemento mais velho e mais novo da lista
    double              m_distanciaHL ;
  //double              m_distanciaHLM; // distancia entre valores maximos e minimos medios
    
    candle              m_candle0   ;
    candle              m_candle1   ;
    candle              m_candle2   ;
  //candle              m_candle0M  ; // candles de medias
  //candle              m_candle1M  ; // candles de medias
  //candle              m_candle2M  ; // candles de medias
  //bool                m_tick_size ; // tamanho da alteracao minima
    bool                m_sou_candle; //se verdadeiro, este vetor circular eh um candle. Entao os metodos
                                        //de dados do candle poderao ser executados.
    //int                 m_orderflow   ; // fluxo de ordens executadas
    double              m_orderFlowRet; // retorno de order flow
    double              m_alterVal    ; //contador de frequencia de alteracoes de valor
    double              m_freqVal     ; //contador de frequencia de alteracoes de valor
    double              m_ultVal      ; //ultimo valor acumulado
    double              m_deltaFreqVal; //ultima alteracao de frequencia de novos valores.
    double              m_freqValIni  ; //frequencia inicial (estah aqui soh pra teste).
    
    // outras propriedades estatisticas
    double              m_logRet         ; // log retorno
    double              m_logRetSoma     ; // soma dos log retornos no vetor circular;
    double              m_logRetxPesoSoma; // soma dos logRetornos multiplicados pelos respectivos pesos(volumes)
    double              m_logRetMedio    ; // media dos log retornos
    double              m_logRetPeso     ; // volume acumulado ateh chegar ao valor do retorno

    //-- variancia movel (tenho feh que serah significativo e ajudara)
    // o2 serah variavel a cada valor acumulado. Isto difere do conceito normal de variancia no qual
    // seria percorrida toda a serie e acumulados os desvios quadrados em torno da media da serie.
    double m_o2,m_o2LogRet;
    
    //double m_volat;
    //long   m_time_ant;
    //long   m_time_atu;

    int    m_agr  ; // tag para agressor (1:comprador, -1:vendedor, 0:ambos ou sem agressao)
    double m_vvol ; // tag para velocidade do volume em volume
    double m_rvvol; // tag para retorno de velocidade do volume
    double getAgressor (){return m_agr  ;} //-1:vendedor 1:comprador 0:ambos ou nenhum
    double getVelVol   (){return m_vvol ;} // velocidade do volume em volume/segundo
    double getRetVelVol(){return m_rvvol;} // retorno de velocidade do volume
    
    long getComQuemDevoCompararMeuTamanho(long& elapsed, long& tamanhoFila){
        if(m_relogio_por_evento) return tamanhoFila;
                                 return elapsed;
    }

    long getMeuTamanho(){
        if(m_relogio_por_evento) return m_tamanhoFila;
                                 return m_secondsAtu;
    }

    
public:
     osc_vetor_circular2(){ initialize(OSC_VETOR_CIRCULAR2_LEN_PADRAO); }
    ~osc_vetor_circular2(){ m_vet.Clear();}

    void setName   (string name){m_name=name;} //identificador da fila
    
    bool initialize(int seconds             ){return initialize(seconds, getIdStr()      );}
    bool initialize(int seconds, string name){return initialize(seconds, name      ,false);}
    bool initialize(int seconds, string name, bool relogio_por_evento);
    
    bool add1(double val, double peso, datetime time, double logRet=0);
    bool add (double val, double peso, datetime time, double retMin=15);
    bool add (double val, double peso               ){return add(val,peso,TimeCurrent());}
    bool add (double val                            ){return add(val, 1                );}

    string getName        (){return m_name              ;} //identificador da fila
    double getMedia       (){return m_media             ;} //Media dos elementos do vetor;
    double getO2          (){return m_o2                ;} //Variancia dos precos;
    double getO2LogRet    (){return m_o2LogRet          ;} //Variancia dos log retornos;
    double getSoma        (){return m_somaVal           ;} //Soma  dos elementos do vetor;
    double getSomaPeso    (){return m_somaPeso          ;} //Soma  dos elementos do vetor;
  //double getSomaValxPeso(){return m_somaValxPeso      ;} //Soma  dos valores do vetor multiplicados pelos respectivos pesos;
    double getMediaPeso   (){return m_somaPeso/oneIfZero(m_vet.Count());}
    double getDistancia   (){return m_distancia         ;} //Diferenca entre o elemento mais novo e o mais antigo da lista.
    double getDistanciaM  (){return m_distanciaM        ;} //Diferenca entre as medias dos elementos mais novo e o mais antigo da lista.
    long   getLenVet      (){return m_tamanhoFila       ;} //Quantidade de elementos no vetor de media.
    long   getLenInSec    (){return m_secondsAtu        ;} //Tamanho do vetor em segundos;
    double getLenInMin    (){return m_secondsAtu/60.0   ;} //Tamanho do vetor em minutos;
    double getLenInHr     (){return m_secondsAtu/3600.0 ;} //Tamanho do vetor em horas  ;

    //double getCoefLinear  (){return m_secondsAtu!=0?     m_distancia   /m_secondsAtu:0;} //velocidade de alteracao do preco. inclinacao da reta de variacao de valores ao longo do tempo;
    //double getCoefLinearHL(){return m_secondsAtu!=0?     m_distanciaHL /m_secondsAtu:0;} //velocidade de alteracao do preco. inclinacao total da reta (high-low)/tempo;
    //double getKyleLambda  (){return m_somaPeso  !=0?fabs(m_distancia  )/m_somaPeso  :0;} //velocidade de alteracao do preco em funcao do volume negociado. inclinacao parcial da reta (close-atu)/volume;
    //double getKyleLambdaHL(){return m_somaPeso  !=0?fabs(m_distanciaHL)/m_somaPeso  :0;} //velocidade de alteracao do preco em funcao do volume negociado. inclinacao total   da reta (high-low )/volume;

    double getCoefLinear  (){return getMeuTamanho()!=0?  m_distancia   /getMeuTamanho():0;} //velocidade de alteracao do preco. inclinacao da reta de variacao de valores ao longo do tempo;
    double getCoefLinearHL(){return getMeuTamanho()!=0?  m_distanciaHL /getMeuTamanho():0;} //velocidade de alteracao do preco. inclinacao total da reta (high-low)/tempo;
    double getKyleLambda  (){return m_somaPeso  !=0?fabs(m_distancia  )/m_somaPeso     :0;} //velocidade de alteracao do preco em funcao do volume negociado. inclinacao parcial da reta (close-atu)/volume;
    double getKyleLambdaHL(){return m_somaPeso  !=0?fabs(m_distanciaHL)/m_somaPeso     :0;} //velocidade de alteracao do preco em funcao do volume negociado. inclinacao total   da reta (high-low )/volume;


    
    //(na geladeira por enquanto por lentidao na execucao)
      double getCoefLinearM  (){return m_secondsAtu!=0?     m_distanciaM   /m_secondsAtu  :0;} //velocidade de alteracao do preco medio. inclinacao da reta de variacao de medias ao longo do tempo;
    //double getCoefLinearHLM(){return m_secondsAtu!=0?     m_distanciaHLM /m_secondsAtu  :0;} //velocidade de alteracao do preco medio. inclinacao total da reta (highM-lowM)/tempo;
      double getKyleLambdaM  (){return m_somaPeso  !=0?fabs(m_distanciaM  )/getMediaPeso():0;} //velocidade de alteracao do preco medio em funcao do volume medio negociado. inclinacao parcial da reta (closeM-atuM)/volume;
    //double getKyleLambdaHLM(){return m_somaPeso  !=0?fabs(m_distanciaHLM)/getMediaPeso():0;} //velocidade de alteracao do preco medio em funcao do volume medio negociado. inclinacao total   da reta (highM-lowM )/volume;
    
    double getVolPorSeg   (){return m_secondsAtu!=0?m_somaPeso /m_secondsAtu:0;}
    double getAcelVol     (){return m_acelVolume;} //aceleracao da velocidade do volume

    int    copyPriceTo (double &price[]                ){return m_vet.copyPriceTo(price    );} // preenche o vetor com os precos armazenados
    int    copyPriceTo (double &price[], double &ind[] ){return m_vet.copyPriceTo(price,ind);} // preenche o vetor com os precos armazenados (y) e outro com os indices correspondentes (x) 

    int    copyMediaTo       (double &media[]){return m_vet.copyMediaTo       (media);} // preenche o vetor com as medias dos precos armazenados
    int    copyOrderFlowRetTo(double &of[]   ){return m_vet.copyOrderFlowRetTo(of   );} // preenche o vetor com as medias dos precos armazenados
    

    void   setSouCandle(bool   souCandle){m_sou_candle = souCandle;}//define se a o vetor representa um candle;
  //void   setTickSize (double tickSize ){m_tick_size  = tickSize ;}//define o tamanho da alteracao minima para executar contagem de alteracao de precos;
    double getOpen     (){return m_candle0.open ;}
    double getClose    (){return m_candle0.close;}
    double getHigh     (){return m_candle0.high ;}
    double getLow      (){return m_candle0.low  ;}
    double getHigh1    (){return m_candle1.high ;}
    double getLow1     (){return m_candle1.low  ;}
    double getHigh2    (){return m_candle2.high ;}
    double getLow2     (){return m_candle2.low  ;}

    //(na geladeira por enquanto por lentidao na execucao)
    //double getOpenM    (){return m_candle0M.open ;}
    //double getCloseM   (){return m_candle0M.close;}
    //double getHighM    (){return m_candle0M.high ;}
    //double getLowM     (){return m_candle0M.low  ;}
    //double getHigh1M   (){return m_candle1M.high ;}
    //double getLow1M    (){return m_candle1M.low  ;}
    //double getHigh2M   (){return m_candle2M.high ;}
    //double getLow2M    (){return m_candle2M.low  ;}
    
    // suportes e resistencias atuais e futuros
    double getResistencia   (){return getHigh1()+getHigh1()-getHigh2();} // ver livro High-Frequency Trading - Irene Aldridge - cap 10 - segunda edicao
    double getSuporte       (){return getLow1 ()+getLow1 ()-getLow2 ();} // ver livro High-Frequency Trading - Irene Aldridge - cap 10 - segunda edicao
    double getResistenciaFut(){return getHigh ()+getHigh ()-getHigh1();} // ver livro High-Frequency Trading - Irene Aldridge - cap 10 - segunda edicao
    double getSuporteFut    (){return getLow  ()+getLow  ()-getLow1 ();} // ver livro High-Frequency Trading - Irene Aldridge - cap 10 - segunda edicao

    // suporte e resistencia medios (na geladeira por enquanto por lentidao na execucao)
    //double getResistenciaM   (){return getHigh1M()+getHigh1M()-getHigh2M();} // ver livro High-Frequency Trading - Irene Aldridge - cap 10 - segunda edicao
    //double getSuporteM       (){return getLow1M ()+getLow1M ()-getLow2M ();} // ver livro High-Frequency Trading - Irene Aldridge - cap 10 - segunda edicao
    //double getResistenciaFutM(){return getHighM ()+getHighM ()-getHigh1M();} // ver livro High-Frequency Trading - Irene Aldridge - cap 10 - segunda edicao
    //double getSuporteFutM    (){return getLowM  ()+getLowM  ()-getLow1M ();} // ver livro High-Frequency Trading - Irene Aldridge - cap 10 - segunda edicao
    
    double getFreqValIni  (){return m_freqValIni  ;}
    double getFreqVal     (){return m_freqVal     ;}
    double getOrderFlowRet(){return m_orderFlowRet;} // retorno de order flow atualizado a cada segundo
    double getDeltaFreqVal(){return m_deltaFreqVal;}
    
    double getLogRet     (){return m_logRet     ;}
    double getLogRetMedio(){return m_logRetMedio;}
    
    //double getVolat      (){return m_volat;} 

 //------------------------------------------------------
};

//+------------------------------------------------------------------------------+
//|Inicializa o vetor de medias definindo a distancia maxima em segundos         |
//|entre o elemento mais antigo e o mais novo.                                   |
//+------------------------------------------------------------------------------+
bool osc_vetor_circular2::initialize(int seconds, string name, bool relogio_por_evento){

    setName( getIdStr()+" "+name);

    // previnindo array com tamanho invalido;
    if(seconds < 2){
        Print(__FUNCTION__, ":-( Tentativa de inicializar vetor circular "+getName()+" com [", seconds,"] falhou para prevenir array com tamanho invalido!");
        return false;
    }
    
    //--- controle do tamanho do vetor
    m_relogio_por_evento = relogio_por_evento; // define se o tamanho do vetor eh em segundos ou em qtd de acumulacoes
    m_tamanhoFila        = 0;
    m_secondsAtu         = 0;
    m_secondsMax         = seconds; 
    m_vet.Clear()                 ; // removendo os itens da fila...
    //--- controle do tamanho do vetor

    m_media        = 0;
    m_o2           = 0;
    m_o2LogRet     = 0;
    m_somaVal      = 0;
    m_somaValxPeso = 0;
    m_acelVolume   = 0;
    m_somaPeso     = 0;
    m_distancia    = 0;
    m_distanciaM   = 0;
    m_distanciaHL  = 0;
  //m_distanciaHLM = 0;
    
    // variaveis para gerenciamento do candle...
    m_sou_candle       = false;
  //m_tick_size        = 0;
    m_candle0.open     = 0;
    m_candle0.close    = 0;
    m_candle0.high     = 0;
    m_candle0.low      = 0;
    m_candle1.open     = 0;
    m_candle1.close    = 0;
    m_candle1.high     = 0;
    m_candle1.low      = 0;
    m_candle2.open     = 0;
    m_candle2.close    = 0;
    m_candle2.high     = 0;
    m_candle2.low      = 0;
  //m_candle0M.open     = 0;
  //m_candle0M.close    = 0;
  //m_candle0M.high     = 0;
  //m_candle0M.low      = 0;
  //m_candle1M.open     = 0;
  //m_candle1M.close    = 0;
  //m_candle1M.high     = 0;
  //m_candle1M.low      = 0;
  //m_candle2M.open     = 0;
  //m_candle2M.close    = 0;
  //m_candle2M.high     = 0;
  //m_candle2M.low      = 0;
  //m_candle0.inclHL   = 0;

   //----------------
    //m_orderflow     = 0;
    m_alterVal      = 0;
    m_freqVal       = 0;
    m_orderFlowRet  = 0;
    m_freqValIni    = 0;
    m_ultVal        = 0;
    m_deltaFreqVal  = 0;
   //----------------
    m_logRet          = 0;
    m_logRetSoma      = 0;
    m_logRetxPesoSoma = 0;
    m_logRetMedio     = 0;
    m_logRetPeso      = 0;
   //----------------
    //m_volat           = 0;
    //m_time_ant        = 0;
    //m_time_atu        = 0;
    m_time            = 0;
    
    Print(__FUNCTION__, ":-) Minion "+getName()+" inicializado corretamente para acumular [",m_secondsMax," sec][", m_secondsMax/60," min]");
    return true             ;
}

//+------------------------------------------------------------------------------+
//|Adiciona ao vetor de medias; se a distancia em tempo, entre o item mais antigo|
//|e valor adicionado for maior que o tamanho em segundos, elimina os itens mais |
//|antigos retirando-os da media.                                                |
//|IMPOTANTE: As adicoes devem ser feitas em ordem crescente de tempo.           |
//+------------------------------------------------------------------------------+
bool osc_vetor_circular2::add1(double val, double peso, datetime time, double logRet=0){

    // Gravando msg de debug ateh estabilizar.
    // Deveria entrar aqui somente na inclusao do primeiro elemento na fila ou
    // se passou todo o periodo da fila sem adicoes.
    Print(__FUNCTION__, ":-| Adic Prim Elem:[fila ",m_name,"][val ",val,"][peso ",peso,"][data ",time,"]");

    // calculando a media pela prmeira vez...
    m_somaVal       =  val ;
    m_somaPeso      =  peso;
    m_somaValxPeso  = (peso*val);
  //m_media         = NormalizeDouble(m_somaValxPeso/oneIfZero(m_somaPeso),1 ); (na geladeira por enquanto por lentidao na execucao)
    m_media         =                 m_somaValxPeso/oneIfZero(m_somaPeso)    ;
    m_o2            = 0; //pow( (val-m_media), 2 )/m_somaPeso;
    m_o2LogRet      = 0; 
    m_acelVolume    = 0;
    m_time          = time;
    
    m_alterVal      = 1  ;
    m_freqVal       = 1  ;
    m_orderFlowRet  = 0  ;
    m_freqValIni    = 1  ;
    m_ultVal        = val;
    m_deltaFreqVal  = 1  ;
    
    m_logRet          = logRet;
    m_logRetSoma      = logRet;
    m_logRetxPesoSoma = logRet*peso; 
    m_logRetMedio     = m_logRetxPesoSoma/oneIfZero(m_somaPeso);
    m_logRetPeso      = peso;

    // acrescentando o novo elemento a fila...
    Item* newItem    = new Item;
    newItem.time     = time;
    newItem.val      = val ;
    newItem.peso     = peso;
  //newItem.valxPeso = peso*val;
    newItem.pesoAcum = m_somaPeso;
    newItem.media    = m_media;
    newItem.o2       = m_o2;
    newItem.o2LogRet = m_o2LogRet;

    //newItem.orderflow   = m_orderflow
    newItem.alterVal    = m_alterVal;
    newItem.freqVal     = m_freqVal;

    newItem.logRet      = m_logRet;
    newItem.logRetMedio = m_logRetMedio;
    

    m_vet.Add( newItem );
    m_secondsAtu     = 0;
    m_tamanhoFila    = 1;

    
    if( m_sou_candle ){
        m_candle0.open   = val; 
        m_candle0.close  = val;
        m_candle0.high   = val;
        m_candle0.low    = val;
      //m_candle0.inclHL = 0;
        newItem.high0    = val; newItem.high1 = val; newItem.high2 = val;
        newItem.low0     = val; newItem.low1  = val; newItem.low2  = val;

        // candle com valores medios (na geladeira por enquanto por lentidao na execucao)
        //m_candle0M.open   = m_media; 
        //m_candle0M.close  = m_media;
        //m_candle0M.high   = m_media;
        //m_candle0M.low    = m_media;
        //newItem.high0M    = m_media; newItem.high1M = m_media; newItem.high2M = m_media;
        //newItem.low0M     = m_media; newItem.low1M  = m_media; newItem.low2M  = m_media;
    }
    
    return true;
}

// val    = valor a ser computado estatisticamente. Normalment o preco do ativo.
// peso   = normalmente o volume.
// time   = data da ocorrencia do preco.
// retMin = retorno minimo, em relacao ao ultimo preco neociado, alem do qual,
//          deverah ser calculado novo retorno. Ou seja, se o retorno for menor que 
//          retMin, nao eh calculado um novo retorno.
bool osc_vetor_circular2::add(double val, double peso, datetime time, double retMin=15){

    if(m_vet.Count() == 0){ return add1(val,peso,time);}

    if(time < m_time){Print(__FUNCTION__, ":-( ERRO Tentativa de adicionar um tick mais antigo que o ultimo adicionado!!"); return false;}

    // obtendo o tempo em segundos desde o item mais antigo ateh este que entra na fila...
    Item itemP = m_vet.Peek();
    long elapsed = time - itemP.time;
    if(elapsed < 0){Print(__FUNCTION__, ":-( ERRO Adicao na colecao de ticks deve ser em ordem cronologica!!"); return false;}// adicao deve ser em ordem cronologica

    //Print("elapsed:", elapsed );

    // retirando os itens mais antigos, que ultrapassam o periodo da media...
    // algumas vezes retira um item do periodo atual <TODO: corrigir>
    m_tamanhoFila = m_vet.Count();
    m_atuMinMax   = false;
    while( getComQuemDevoCompararMeuTamanho(elapsed,m_tamanhoFila) > m_secondsMax && m_tamanhoFila>0){


        Item* itemD     = m_vet.Dequeue();
        elapsed         = time - itemD.time;
        m_tamanhoFila--;

        m_orderFlowRet  = m_freqVal-itemD.freqVal; // retorno de orderFlow

        m_somaVal      -= itemD.val;
        m_somaPeso     -= itemD.peso;
        m_somaValxPeso -= ( itemD.val * itemD.peso );
        m_freqVal      -= itemD.alterVal;
        
        m_logRetSoma      -=   itemD.logRet;
        m_logRetxPesoSoma -= ( itemD.logRet * itemD.peso );
        
        if(  m_sou_candle     && 
             m_atuMinMax==false &&
             (   itemD.val  <=m_candle0 .low || itemD.val  >=m_candle0 .high
            //|| itemD.media<=m_candle0M.low || itemD.media>=m_candle0M.high
             ) ){
           
            m_atuMinMax=true;
        }
        
        if( m_sou_candle ){
            m_candle1.high  = itemD.high0; // m_candle1 eh  o ultimo tick retirado da fila
            m_candle1.low   = itemD.low0 ; // m_candle1 eh  o ultimo tick retirado da fila
            m_candle1.close = itemD.val  ; // m_candle1 eh  o ultimo tick retirado da fila
            m_candle2.high  = itemD.high1; // m_candle2 foi o ultimo tick retirado da fila qd m_candle1 entrou na fila
            m_candle2.low   = itemD.low1 ; // m_candle2 foi o ultimo tick retirado da fila qd m_candle1 entrou na fila
          //m_candle2.close = itemD.val  ; // m_candle2 foi o ultimo tick retirado da fila qd m_candle1 entrou na fila
            
            // candles de media (na geladeira por enquanto por lentidao na execucao)
            //m_candle1M.high  = itemD.high0M; // m_candle1 eh  o ultimo tick retirado da fila
            //m_candle1M.low   = itemD.low0M ; // m_candle1 eh  o ultimo tick retirado da fila
            //m_candle1M.close = itemD.media ; // m_candle1 eh  o ultimo tick retirado da fila
            //m_candle2M.high  = itemD.high1M; // m_candle2 foi o ultimo tick retirado da fila qd m_candle1 entrou na fila
            //m_candle2M.low   = itemD.low1M ; // m_candle2 foi o ultimo tick retirado da fila qd m_candle1 entrou na fila
          //m_candle2M.close = itemD.media ; // m_candle2 foi o ultimo tick retirado da fila qd m_candle1 entrou na fila
        }
        delete(itemD);
    }
    // Se, apos retirarmos todos os elementos da media, mesmo assim nao chegamos ao
    // intervalo de tempo maximo, entao iniciamos novamente a fila com o novo elemento
    // que estah sendo inserido.
    if(m_tamanhoFila == 0){return add1(val,peso,time);}    
    
    // "getMaxMin" varre o vetor de ticks. deve ser chamada o menor numero de vezes possivel.
    if(m_atuMinMax) m_vet.getMaxMin(m_candle0.high,m_candle0.low, m_distanciaHL);
    //if(m_atuMinMax) m_vet.getMaxMin(m_candle0 .high,m_candle0 .low, m_distanciaHL,
    //                              m_candle0M.high,m_candle0M.low, m_distanciaHLM);

    m_secondsAtu = elapsed; // salvando o tamanho da fila em segundos...

    // recalculando a media e a distancia do valor mais antigo ateh o atual...
    m_somaVal      +=  val      ;
    m_somaPeso     +=  peso     ;
    m_somaValxPeso += (peso*val);
    m_media         =  m_somaValxPeso/oneIfZero(m_somaPeso);
    m_o2            = (pow( (val-m_media), 2 )*peso)/( oneIfZero(m_somaPeso-1) ); // <TODO> testar
    m_time          = time      ; // atualizando a data do ultimo registro inserido na fila.
    
    if( fabs(val-m_ultVal) >= retMin ){
      //m_logRet           = log(val)-log(m_ultVal);
        m_logRet           =     val -    m_ultVal ;
        m_logRetSoma      += m_logRet;
        m_logRetxPesoSoma += (peso*m_logRet);
        m_logRetMedio      = (m_logRetxPesoSoma)/oneIfZero(m_somaPeso);
        m_o2LogRet         = (pow( (m_logRet-m_logRetMedio), 2 )*peso)/ ( oneIfZero(m_somaPeso-1) ); // <TODO> testar
        
        //Print(__FUNCTION__," :-| ", getName(), " ret=",val-m_ultVal, " ultVal= ",m_ultVal, " val=", val, " loRet=", m_logRet);
        
    //  if( val != m_ultVal && val != 0){ 
            //m_freqVal++; 
            
            //m_alterVal = 1;  
            
            // para que alterval passe a capturar o fluxo de agressoes
            m_alterVal  = val>m_ultVal?peso:-peso; 
            m_freqVal  += m_alterVal; 
            m_ultVal    = val; 
        
    //  }else{
    //      m_alterVal=0;
    //  } // alterou o valor acumulado, adiconamos 1 a frequencia.
    }else{
        m_logRet          = 0;
        m_logRetSoma      = 0;
        m_logRetxPesoSoma = 0;
        m_logRetMedio     = 0;
        m_o2LogRet        = 0;
        m_alterVal        = 0;
        m_logRetPeso     += peso;
    }

  //m_vet.peek(m_item);
    itemP = m_vet.Peek();
  //m_distancia     = log(val) - log(itemP.val);

    m_distancia     = val     - itemP.val  ;
    m_distanciaM    = m_media - itemP.media; // testando o uso do preco medio no calculo da inclinacao.
    
    m_acelVolume    = (  getVolPorSeg() - (itemP.pesoAcum/m_secondsMax)  )  //delta V //usa secondsMax pois nao sei o tempo decorrido na acumulacao de volume mais antigo.
                      /                                                      //dividido
                      oneIfZero( m_secondsAtu );                       //delta T

    // calculando o delta val...
    //m_deltaFreqVal =  (m_freqVal - itemP.freqVal)/itemP.freqVal;
      m_deltaFreqVal =  (m_freqVal/oneIfZero(itemP.freqVal))-1;
    //m_deltaFreqVal =  log(m_freqVal) - log(itemP.freqVal);
      m_freqValIni   = itemP.freqVal;
    
    if(m_sou_candle){
        m_candle0.open  = itemP.val; // valor do primeiro (mais antigo) tick da fila
        m_candle0.close = val;       // valor do ultimo   (mais atual ) tick da fila
        
        // se o tick sendo adicionado está alem dos limites calculados apos a retirada dos ticks antigos, atualizamos agora.
        if(m_candle0.open == 0 ) {m_candle0.open = val;}
        if(m_candle0.low  > val) {m_candle0.low  = val;}
        if(m_candle0.high < val) {m_candle0.high = val;}

        // atualizando a media (na geladeira por enquanto por lentidao na execucao)
        //m_candle0M.open  = itemP.media; // valor do primeiro (mais antigo) tick da fila
        //m_candle0M.close = m_media;       // valor do ultimo   (mais atual ) tick da fila

        // se o tick sendo adicionado está alem dos limites calculados apos a retirada dos ticks antigos, atualizamos agora. (na geladeira por enquanto por lentidao na execucao)
        //if(m_candle0M.open == 0      ) {m_candle0M.open = m_media;}
        //if(m_candle0M.low  >  m_media) {m_candle0M.low  = m_media;}
        //if(m_candle0M.high <  m_media) {m_candle0M.high = m_media;}
    }

    // acrescentando o novo elemento a fila...
    Item* newItem     = new Item;
    newItem.time      = time;
    newItem.val       = val;
    newItem.freqVal   = m_freqVal;
    newItem.alterVal  = m_alterVal;
    //newItem.orderflow = m_orderflow;
    newItem.orderFlowRet = m_orderFlowRet;
    newItem.peso      = peso;
  //newItem.valxPeso  = peso*val;
    newItem.pesoAcum  = m_somaPeso;
    newItem.media     = m_media;
    newItem.o2        = m_o2;
    newItem.o2LogRet  = m_o2LogRet;
    if( m_sou_candle ){
        newItem.high0     = m_candle0.high; newItem.high1 = m_candle1.high; newItem.high2 = m_candle2.high;
        newItem.low0      = m_candle0.low ; newItem.low1  = m_candle1.low ; newItem.low2  = m_candle2.low ;
    
        // atualizando as medias maximas e minimas (na geladeira por enquanto por lentidao na execucao)
        //newItem.high0M    = m_candle0M.high; newItem.high1M = m_candle1M.high; newItem.high2M = m_candle2M.high;
        //newItem.low0M     = m_candle0M.low ; newItem.low1M  = m_candle1M.low ; newItem.low2M  = m_candle2M.low ;
    }
    m_vet.Add( newItem );
    m_tamanhoFila++;
    
    
    return true;
}
