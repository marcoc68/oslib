//+------------------------------------------------------------------+
//|                                                   C00021Pairs.mqh|
//|                               Copyright 2022,oficina de software.|
//|                                 http://www.metaquotes.net/marcoc.|
//|                                                                  |
//| Apoio a analise de pares de ativos.                              |
//|                                                                  |
//| VARIAVEIS DE ENTRADA:                                            |
//| VARIAVEL DE SAIDA:                                               |
//|                                                                  |
//|                                                                  --------------------------------------------|
//| REGRAS                                                                                                       |
//+--------------------------------------------------------------------------------------------------------------+
#property copyright "2020, Oficina de Software."
#property link      "http://www.os.net"

#include <oslib\osc\est\osc-estatistic3.mqh>
#include <oslib\osc\osc-media.mqh>

class C00021Pairs{
private:
    double           m_spread    ;
    double           m_spread_std;
    double           m_spread_med;
    int              m_qtd_seg_media;
    osc_media        m_vet_spread; // vetor de spreads deve ter o tamanho da quantidade de segundos
                                   // usados no calculo da media do spread. Eh uma janela.
    void setQtdSegMedia(const int qtd=60*60){
        
        // inicializa o vetor de spreads para guardar 1h por padrao.
        // acumularemos o spread a cada segundo. Isto fica garantido colocando 1(um) no 
        // segundo parametro da funcao initialize do vetor. Este parametro eh o time_frame,
        // em segundos no qual o metodo de adicao ao vetor aceitara novas adicoes.
        //
        // Isto cria um vetor capaz de acumular 3600 segundos (padrao) e orienta o vetor a 
        // rejeitar adicoes ateh que chegue o proximo segundo.
        m_vet_spread.initialize(qtd,1);
        m_qtd_seg_media = qtd;
    }
protected:
public:
     C00021Pairs(){}
    ~C00021Pairs(){}

    double getSpread   (){ return m_spread    ; } // spread instantaneo   
    double getSpreadStd(){ return m_spread_std; } // desvio padrao do spread
    double getSpreadMed(){ return m_spread_med; } // media do spread
    int    getQtdSegMedia() { return m_qtd_seg_media; }

    // inicializacao antes de comecar a acumular.
    // deve informar a quantidade de segundos usados do calculo da media dos spreads.
    // se nao informar, calcularah a media da ultima hora de spreads.
    void initialize(int qtdSegMedia=60*60){ 
        setQtdSegMedia(qtdSegMedia);
        m_spread         = 0;
        m_spread_std     = 0;                
        m_spread_med     = 0;                
    }
    
    // in  t1    : tick do primeiro ativo
    // in  t2    : tick do segundo  ativo
    // out spread: spread calculado como o retorno do ativo t1 sobre t2: log(t1)-log(t2)
    double calcSpread(MqlTick &t1, MqlTick &t2){ return calcSpread(getLast(t1), getLast(t2), t1.time); }

    // in  p1    : preco do primeiro ativo
    // in  p2    : preco do segundo  ativo
    // in  t     : data dos precos
    // out spread: spread calculado como o retorno preco p1 sobre p2: log(p1)-log(p2)
    double calcSpread(const double p1, const double p2, const datetime t){
        if(p1==0 || p2==0){
            Print("ERRO: Preco invalido! p1=",p1," p2=", p2);
            return m_spread;
        }

        double spread = log(p1) - log(p2);
        if( spread != 0 && MathIsValidNumber(spread) ){ 
            m_spread = spread;
        }else{
            Print("spread invalido: m_spread anterior retornado:", m_spread);
            Print("spread invalido: spread anterior:",   spread);
            Print("spread invalido: spread invalido:",   spread);
            Print("spread invalido: p1             :", p1      );
            Print("spread invalido: p2             :", p2      );
            return m_spread;
        }
      //if( m_spread == 0 || !MathIsValidNumber(m_spread) )return m_spread;
        
        //m_vet_spread.add(m_spread,t1.time); // por enquanto usamos a data ativo1, mas provavelmente
        //                                    // passaremos a usar a data mais recente entre os dois
        //                                    // ativos. Isto serah para evitar o problema causado
        //                                    // quando um dos ativos tem muito mais transações que 
        //                                    // o outro.
        if( m_vet_spread.add(m_spread,t) ){
            m_vet_spread.calcVar();
            m_spread_med = m_vet_spread.getMed();
            m_spread_std = sqrt( m_vet_spread.getVar() );
        }
        
        return m_spread;
    }
    
    double getSpreadStd(double shift){ return getSpreadMed()+getSpreadStd()*shift; }
    
    double regLinFit  (){return m_vet_spread.regLinFit     ();}
    double regLinSlope(){return m_vet_spread.regLinGetSlope();}

    double getLast(MqlTick& tick){
       if(tick.last > 0                ){ return tick.last; }
       if(tick.bid  > 0 && tick.ask > 0){ return (tick.bid+tick.ask)/2; }
       if(tick.ask  > 0                ){ return tick.ask; }
                                          return tick.bid;
    }


};
