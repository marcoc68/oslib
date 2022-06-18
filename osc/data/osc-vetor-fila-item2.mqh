//+------------------------------------------------------------------+
//|                                          osc-vetor-fila_item.mqh |
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

#include <Object.mqh>
#include <Generic\Queue.mqh>
#include <oslib/osc-padrao.mqh>

class Item : public CObject{

public:
    datetime time     ; // tempo do elemento. Elementos devem ser adicionados em ordem crescente de tempo
    double   val      ; // valor usado no calculo da media
    double   peso     ; // peso usado no calculo da media
    double   pesoAcum ; // peso acumulado na ocasiao
    double   media    ; // media calculada
    double   freqVal  ; // frequencia de alteracao de val
    double   alterVal ; // 1 - alterou o valor em relacao ao anterior. 0 - nao alterou
    //double   orderflow; // -1 agressao de venda, 1 agressao de compra, 0 sem agressao
    double   orderFlowRet; // retornos de orderflow
    
    //-- outras propriedades estatisticas
    double   logRet     ; // log retorno
    double   logRetMedio; // media dos log retornos
    
    //-- dados de mercado
    double high0,high1, high2; // maximas atual, ultima e penultima do ultimo tick retirado da fila
    double low0 ,low1 , low2 ; // minimas atual, ultima e penultima do ultimo tick retirado da fila

    //-- dados de mercado (medios)
    double high0M,high1M, high2M; // maximas atual, ultima e penultima do ultimo tick retirado da fila
    double low0M ,low1M , low2M ; // minimas atual, ultima e penultima do ultimo tick retirado da fila

    //-- variancia movel (tenho feh que serah significativo e ajudara)
    // o2 serah variavel a cada valor acumulado. Isto difere do conceito normal de variancia no qual
    // seria percorrida toda a serie e acumulados os desvios quadrados em torno da media da serie.
    double o2;
    double o2LogRet;
    
    
    int    agr  ; // tag para agressor (1:comprador, -1:vendedor, 0:ambos ou sem agressao)
    double vvol ; // tag para velocidade do volume em volume
    double rvvol; // tag para retorno de velocidade do volume

    virtual int Compare( const CObject*  node,   // Node to compare with 
                         const int       mode=0){// Compare mode 
       if( this.media > ((Item*)node).media ) return  1;
       if( this.media < ((Item*)node).media ) return -1;
                                              return  0;
    }
    
    string toString(){
        string str;
        StringConcatenate(str
                             ,"|time "     ,time
                             ,"|val "      ,val
                             ,"|peso "     ,peso
                             ,"|pesoAcum " ,pesoAcum
                             ,"|media "    ,media 
                             ,"|o2 "       ,o2 
                             ,"|o2 "       ,o2LogRet 
                             ,"|freqVal "  ,freqVal
                          );
        return str;
    }
};

class osc_vetor_fila_item : public CQueue<Item*> {
private:
    // ---------usadas em getMaxMin
    int    m_qtdAux;
    double m_newMin,m_indNewMin; 
    double m_newMax,m_indNewMax;
    
    double m_newMinM,m_indNewMinM; 
    double m_newMaxM,m_indNewMaxM;
    // ---------usadas em getMaxMin
protected:
    
public:
    int    getMaxMin    (double &max , double &min , double &distancia); // grava os valores maximos e minimos respectivamente. Retorna -1 se algo der errado;
    int    getMaxMin    (double &max , double &min , double &distancia,
                         double &maxM, double &minM, double &distanciaM); // grava os valores maximos e minimos respectivamente. Retorna -1 se algo der errado;
    int    copyPriceTo  (double &price[]);
    int    copyPriceTo  (double &price[], double &ind[]);
    
    int    copyMediaTo     (double &media[]);
    int    copyOrderFlowRetTo(double &X[]);
};

// busca maximos e minimos na fila
int osc_vetor_fila_item::getMaxMin(double &max , double &min , double &distancia){
   
    Item* vet[];
    m_qtdAux = Count();
    CopyTo(vet);
    m_newMin = vet[0].val; m_indNewMin=0;
    m_newMax = vet[0].val; m_indNewMax=0;

    for(int i=0; i<m_qtdAux; i++){
        if( MathIsValidNumber(vet[i].val) && vet[i].val != 0 ){
            if( vet[i].val > m_newMax ) { m_newMax = vet[i].val;m_indNewMax=i;} else
            if( vet[i].val < m_newMin ) { m_newMin = vet[i].val;m_indNewMin=i;}
        }
    }
   
    max  = m_newMax;
    min  = m_newMin;
   
    // max aconteceu apos min, distancia serah positiva, senao negativa.
    if( (m_indNewMax-m_indNewMin)<0 ){ 
        distancia = (max-min)*-1;
    }else{
        distancia = (max-min)   ;
    }
    
   //info = info + " max=" + max + " newMax=" + newMax + " min=" + min + " newMin=" + newMin;
   //Print(info);
    return 0;
}

// busca maximos e minimos e os respectivos medios na fila
int osc_vetor_fila_item::getMaxMin(double &max , double &min , double &distancia,
                                   double &maxM, double &minM, double &distanciaM){
   
    Item* vet[];
    m_qtdAux = Count();
    CopyTo(vet);
    m_newMin = vet[0].val; m_indNewMin=0;
    m_newMax = vet[0].val; m_indNewMax=0;

    // para busca dos maximos e minimos medios
    m_newMinM = vet[0].media; m_indNewMinM=0;
    m_newMaxM = vet[0].media; m_indNewMaxM=0;
   
    for(int i=0; i<m_qtdAux; i++){
        if( MathIsValidNumber(vet[i].val) && vet[i].val != 0 ){
            if( vet[i].val > m_newMax ) { m_newMax = vet[i].val;m_indNewMax=i;} else
            if( vet[i].val < m_newMin ) { m_newMin = vet[i].val;m_indNewMin=i;}

            if( vet[i].media > m_newMaxM ) { m_newMaxM = vet[i].media;m_indNewMaxM=i;} else
            if( vet[i].media < m_newMinM ) { m_newMinM = vet[i].media;m_indNewMinM=i;}
        }
    }
   
    max  = m_newMax;
    min  = m_newMin;
    maxM = m_newMaxM;
    minM = m_newMinM;
    
   
    // max aconteceu apos min, distancia serah positiva, senao negativa.
    if( (m_indNewMax-m_indNewMin)<0 ){ 
        distancia = (max-min)*-1;
    }else{
        distancia = (max-min)   ;
    }

    // max medio aconteceu apos min medio, distancia media serah positiva, senao negativa.
    if( (m_indNewMaxM-m_indNewMinM)<0 ){ 
        distanciaM = (maxM-minM)*-1;
    }else{
        distanciaM = (maxM-minM)   ;
    }
   
   //info = info + " max=" + max + " newMax=" + newMax + " min=" + min + " newMin=" + newMin;
   //Print(info);
    return 0;
}

int osc_vetor_fila_item::copyPriceTo(double &price[]){ 

    ArrayResize( price,Count() );
    Item* vet[];
    CopyTo(vet);
    for(int i=0; i<Count(); i++) price[i] = vet[i].val;        
    return Count(); 
}

int osc_vetor_fila_item::copyPriceTo(double &price[], double &ind[]){ 

    ArrayResize( price,Count() );
    ArrayResize( ind  ,Count() );
    Item* vet[];
    CopyTo(vet);
    for(int i=0; i<Count(); i++){
        price[i] = vet[i].val;
        ind  [i] = i+1       ;
    }        
    return Count(); 
}

int osc_vetor_fila_item::copyMediaTo(double &media[]){ 
    ArrayResize( media,Count() );
    Item* vet[];
    CopyTo(vet);
    for(int i=0; i<Count(); i++) media[i] = vet[i].media;        
    return Count(); 
}

int osc_vetor_fila_item::copyOrderFlowRetTo(double &X[]){ 
    ArrayResize( X,Count() );
    Item* vet[];
    CopyTo(vet);
    for(int i=0; i<Count(); i++) X[i] = vet[i].orderFlowRet;        
    return Count(); 
}
