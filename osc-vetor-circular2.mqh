﻿//+------------------------------------------------------------------+
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
#include <oslib/osc-vetor-fila-item.mqh>

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
    long                m_secondsMax  ; //tamanho maximo do vetor em segundos;
    long                m_secondsAtu  ; //tamanho atual  do vetor em segundos;
    Item                m_item        ;
    datetime            m_time        ; //data do ultimo item inserido no vetor. Novas insrcoes com data menor que esta serao descartadas;
    double              m_media       ; //ultima media calculada;
    double              m_somaVal     ; //soma dos valores usados no calculo da media sem os pesos;
    double              m_somaPeso    ; //soma dos pesos   usados no calculo da media;
    double              m_acelVolume  ;
    double              m_somaValxPeso; //soma acumulada dos valores multiplicados pelos pesos;
    double              m_distancia   ;
    double              m_distanciaHL;
    
    candle              m_candle      ;
    candle              m_candleAnt   ;
    bool                m_sou_candle  ; //se verdadeiro, este vetor circular eh um candle. Entao os metodos
                                        //de dados do candle poderao ser executados.

public:
    osc_vetor_circular2(){ initialize(OSC_VETOR_CIRCULAR2_LEN_PADRAO); }

    void setName   (string name){m_name=name;} //identificador da fila
    bool initialize(int seconds){return initialize(seconds, getIdStr() );}
    bool initialize(int seconds, string name);
    bool add1(double val, double peso, datetime time);
    bool add (double val, double peso, datetime time);
    bool add (double val, double peso               ){return add(val,peso,TimeCurrent());}
    bool add (double val                            ){return add(val, 1                );}

    string getName        (){return m_name              ;} //identificador da fila
    double getMedia       (){return m_media             ;} //Media dos elementos do vetor;
    double getSoma        (){return m_somaVal           ;} //Soma  dos elementos do vetor;
    double getSomaPeso    (){return m_somaPeso          ;} //Soma  dos elementos do vetor;
  //double getSomaValxPeso(){return m_somaValxPeso      ;} //Soma  dos valores do vetor multiplicados pelos respectivos pesos;
    double getMediaPeso   (){return m_somaPeso/oneIfZero(m_vet.count());}
    double getDistancia   (){return m_distancia         ;} //Diferenca entre o elemento mais novo e o mais antigo da lista.
    long   getLenVet      (){return m_vet.count()       ;} //Quantidade de elementos no vetor de media.
    long   getLenInSec    (){return m_secondsAtu        ;} //Tamanho do vetor em segundos;
    double getLenInMin    (){return m_secondsAtu/60.0   ;} //Tamanho do vetor em minutos;
    double getLenInHr     (){return m_secondsAtu/3600.0 ;} //Tamanho do vetor em horas  ;

    double getCoefLinear  (){return m_secondsAtu!=0?     m_distancia   /m_secondsAtu:0;} //velocidade de alteracao do preco. inclinacao da reta de variacao de valores ao longo do tempo;
    double getCoefLinearHL(){return m_secondsAtu!=0?     m_distanciaHL /m_secondsAtu:0;} //velocidade de alteracao do preco. inclinacao total da reta (high-low)/tempo;
    double getKyleLambda  (){return m_somaPeso  !=0?fabs(m_distancia  )/m_somaPeso  :0;} //velocidade de alteracao do preco em funcao do volume negociado. inclinacao parcial da reta (close-atu)/volume;
    double getKyleLambdaHL(){return m_somaPeso  !=0?fabs(m_distanciaHL)/m_somaPeso  :0;} //velocidade de alteracao do preco em funcao do volume negociado. inclinacao total   da reta (high-low )/volume;
    
    double getVolPorSeg   (){return m_secondsAtu!=0?m_somaPeso /m_secondsAtu:0;}
    double getAcelVol     (){return m_acelVolume        ;} //aceleracao da velocidade do volume

    int    copyPriceTo (double &price[] ){return m_vet.copyPriceTo(price);}

    void   setSouCandle(bool   souCandle){m_sou_candle = souCandle;}//define se a o vetor representa um candle;
    double getOpen     (){return m_candle.open ;}
    double getClose    (){return m_candle.close;}
    double getHigh     (){return m_candle.high ;}
    double getLow      (){return m_candle.low  ;}
    

 //------------------------------------------------------
};

//+------------------------------------------------------------------------------+
//|Inicializa o vetor de medias definindo a distancia maxima em segundos         |
//|entre o elemento mais antigo e o mais novo.                                   |
//+------------------------------------------------------------------------------+
bool osc_vetor_circular2::initialize(int seconds, string name){

    setName( getIdStr()+" "+name);

    // previnindo array com tamanho invalido;
    if(seconds < 1){
        Print(__FUNCTION__, ":-( Tentativa de inicializar Minion "+getName()+" com [", m_secondsMax/60," sec] falhou para prevenir array com tamanho invalido!");
        return false;
    }

    m_media        = 0;
    m_somaVal      = 0;
    m_somaValxPeso = 0;
    m_acelVolume   = 0;
    m_somaPeso     = 0;
    m_distancia    = 0;
    m_distanciaHL  = 0;
    m_secondsAtu   = 0;
    m_secondsMax   = seconds; // prevenindo para o caso do algoritimo Arrayresize aumente mais que tamanho solicitado. Entao colocamos o novo tamanho do vetor na variavem m_len.
    m_vet.clear()           ; // removendo os itens da fila...
    
    // variaveis para gerenciamento do candle...
    m_sou_candle    = false;
    m_candle.open   = 0;
    m_candle.close  = 0;
    m_candle.high   = 0;
    m_candle.low    = 0;
  //m_candle.inclHL = 0;
    
    Print(__FUNCTION__, ":-) Minion "+getName()+" inicializado corretamente para acumular [",m_secondsMax," sec][", m_secondsMax/60," min]");
    return true             ;
}

//+------------------------------------------------------------------------------+
//|Adiciona ao vetor de medias; se a distancia em tempo, entre o item mais antigo|
//|e valor adicionado for maior que o tamanho em segundos, elimina os itens mais |
//|antigos retirando-os da media.                                                |
//|IMPOTANTE: As adicoes devem ser feitas em ordem crescente de tempo.           |
//+------------------------------------------------------------------------------+
bool osc_vetor_circular2::add1(double val, double peso, datetime time){

    // Gravando msg de debug ateh estabilizar.
    // Deveria entrar aqui somente na inclusao do primeiro elemento na fila ou
    // se passou todo o periodo da fila sem adicoes.
    Print(__FUNCTION__, ":-| Adic Prim Elem:[fila ",m_name,"][val ",val,"][peso ",peso,"][data ",time,"]");

    // calculando a media pela prmeira vez...
    m_somaVal       =  val ;
    m_somaPeso      =  peso;
    m_somaValxPeso  = (peso*val);
    m_media         = m_somaValxPeso/oneIfZero(m_somaPeso);
    m_acelVolume    = 0;
    m_time          = time;

    // acrescentando o novo elemento a fila...
    m_item.time     = time;
    m_item.val      = val;
    m_item.peso     = peso;
  //m_item.valxPeso = peso*val;
    m_item.pesoAcum = m_somaPeso;
    m_item.media    = m_media;
    m_vet.add( m_item );
    m_secondsAtu    = 0;
    
    if( m_sou_candle ){
        m_candle.open   = val; // open nao eh verdadeiro, uma vez que a acumulacao eh continua.
        m_candle.close  = val;
        m_candle.high   = val;
        m_candle.low    = val;
      //m_candle.inclHL = 0;
    }
    
    return true;
}

bool osc_vetor_circular2::add(double val, double peso, datetime time){

    if(m_vet.count() == 0){ return add1(val,peso,time);}

    if(time < m_time){Print(__FUNCTION__, ":-( ERRO Tentativa de adicionar um tick mais antigo que o ultimo adicionado!!"); return false;}

    // obtendo o tempo em segundos desde o item mais antigo ateh este que entra na fila...
    m_vet.peek(m_item);
    long elapsed = time - m_item.time;
    if(elapsed < 0){Print(__FUNCTION__, ":-( ERRO Adicao na colecao de ticks deve ser em ordem cronologica!!"); return false;}// adicao deve ser em ordem cronologica

    //Print("elapsed:", elapsed );

    // retirando os itens mais antigos, que ultrapassam o periodo da media...
    // algumas vezes retira um item do periodo atual <TODO: corrigir>
    long tamanhoFila = m_vet.count();
    bool atuMinMax   = false;
    while(elapsed > m_secondsMax && tamanhoFila>0){

        m_vet.dequeue(m_item);
        elapsed = time - m_item.time;
        tamanhoFila--;

        m_somaVal      -= m_item.val;
        m_somaPeso     -= m_item.peso;
      //m_somaValxPeso -= m_item.valxPeso;
        m_somaValxPeso -= ( m_item.val * m_item.peso );
        
        if(  m_sou_candle     && 
             atuMinMax==false &&
             (m_item.val<=m_candle.low || m_item.val>=m_candle.high) ){
           
           atuMinMax=true;        
        }
    }
    // Se, apos retirarmos todos os elementos da media, mesmo assim nao chegamos ao
    // intervalo de tempo máximo, entao iniciamos novamente a fila com o novo elemento
    // que estah sendo inserido.
    if(tamanhoFila == 0){return add1(val,peso,time);}    
    
    // "getMaxMin" varre o vetor de ticks. deve ser chamada o menor numero de vezes possivel.
    if(atuMinMax) m_vet.getMaxMin(m_candle.high,m_candle.low, m_distanciaHL);

    m_secondsAtu = elapsed; // salvando o tamanho da fila em segundos...

    // recalculando a media e a distancia do valor mais antigo ateh o atual...
    m_somaVal      +=  val      ;
    m_somaPeso     +=  peso     ;
    m_somaValxPeso += (peso*val);
    m_media         = m_somaValxPeso/oneIfZero(m_somaPeso);
    m_time          = time      ; // atualizando a data do ultimo registro inserido na fila.

    m_vet.peek(m_item);
  //m_distancia     = val - m_item.val;
    m_distancia     = log(val) - log(m_item.val);
    //m_distancia     = m_media - m_item.media; // testando o uso do preco medio no calculo da inclinacao.
    m_acelVolume    = (  getVolPorSeg() - (m_item.pesoAcum/m_secondsMax)  )  //delta V //usa secondsMax pois nao sei o tempo decorrido na acumulacao de volume mais antigo.
                      /                                                      //dividido
                      oneIfZero( m_secondsAtu );                       //delta T
    
    if(m_sou_candle){
        m_candle.open  = m_item.val;
        m_candle.close = val;
        if(m_candle.open == 0 ) m_candle.open = val;
        if(m_candle.low  > val) m_candle.low  = val;
        if(m_candle.high < val) m_candle.high = val;
    }

    // acrescentando o novo elemento a fila...
    m_item.time     = time;
    m_item.val      = val;
    m_item.peso     = peso;
  //m_item.valxPeso = peso*val;
    m_item.pesoAcum = m_somaPeso;
    m_item.media    = m_media;
    m_vet.add( m_item );
    
    
    return true;
}
