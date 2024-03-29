﻿//+------------------------------------------------------------------+
//|                                            C0002ArbitragemPar.mqh|
//|                               Copyright 2020,oficina de software.|
//|                                 http://www.metaquotes.net/marcoc.|
//|                                                                  |
//| VARIAVEIS DE ENTRADA:                                            |
//|                                                                  |
//|                                                                  |
//| VARIAVEL DE SAIDA:                                               |
//|                                                                  |
//|                                                                  |
//|                                                                  --------------------------------------------|
//| REGRAS                                                                                                       |
//|                                                                                                              |
//|                                                                                                              |
//+--------------------------------------------------------------------------------------------------------------+
#property copyright "2020, Oficina de Software."
#property link      "http://www.os.net"

#include <oslib\osc\est\osc-estatistic3.mqh>
#include <oslib\osc\osc-media.mqh>

#define MULTIPLICADOR  1000.0


class C0002ArbitragemPar{
private:

    osc_estatistic3* m_est1; // estatisticas de ticks e book de ofertas do primeiro ativo
    osc_estatistic3* m_est2; // estatisticas de ticks e book de ofertas do segundo  ativo
    osc_media        m_media; // media dos ratios
    osc_media        m_media_spread; // media do spread
    double           m_ratio; // ratio instantaneo.
    double           m_ratio_dp; // ratio instantaneo medido em unidades de desvio padrao 
    double           m_ratio_medio; // ratio medio.
    double           m_ratio_medio_dp; // desvio padrao do ratio medio.
    double           m_qtdSegMediaTicks; // quantidade de segundos acumulando estatisticas de ticks;
    double           m_qtdSegMediaRatio; // quantidade de segundos para calcular a media de ratios.
    datetime         m_dt, m_dtAnt;

    double           m_spread    ;
    double           m_spread_std;
    double           m_spread_med;
    
    void setQtdSegMediaTicks(const int qtd=60){
        
        delete(m_est1);
        delete(m_est2);
        
        m_est1 = new osc_estatistic3();
        m_est2 = new osc_estatistic3();
        
        m_est1.initialize(qtd,true); 
        m_est2.initialize(qtd,true);
        m_qtdSegMediaTicks = qtd;  
    }
    
    void setQtdSegMediaRatio(const int qtd=60*21){m_media.initialize(qtd);
                                                  m_media_spread.initialize(qtd);
                                                  m_qtdSegMediaRatio = qtd;     }

    void calcRatio(); // calcula o ratio e armazena no vetor de medias de ratio;
    void calcSpread(); // calcula o spread e armazena no vetor de spreads;

protected:
public:

    ~C0002ArbitragemPar(){delete(m_est1); delete(m_est2);}

    // metodos de inicializacao...
    void initialize(int qtdSegMediaTicks, int qtdSegMediaRatio){setQtdSegMediaTicks(qtdSegMediaTicks);
                                                                setQtdSegMediaRatio(qtdSegMediaRatio);
                                                                m_dt=TimeCurrent(); 
                                                                m_dtAnt=m_dt;
                                                                m_ratio_medio_dp = 0;
                                                                m_spread         = 0;
                                                                m_spread_std     = 0;                
                                                                m_spread_med     = 0;                
    }
    
    osc_estatistic3* getEstAtivo1(){ return m_est1; }

    // metodos de refresh...
    void addTick1(MqlTick& tick){ m_est1.addTick(tick); calcRatio();}
    void addTick2(MqlTick& tick){ m_est2.addTick(tick); calcRatio();}
    void addTick (MqlTick& tick1, MqlTick& tick2){ m_est1.addTick(tick1); m_est2.addTick(tick2); calcRatio(); }
    void addTickSpread (MqlTick& tick1, MqlTick& tick2){ m_est1.addTick(tick1); m_est2.addTick(tick2); calcSpread(); }

    // metodos de calculo e obtencao de indicares e resultados...
    double getRatio       (){ return m_ratio          ; } // ratio instantaneo   
    double getRatioDP     (){ return m_ratio_dp       ; } // ratio instantaneo calculado em unidades de desvio padrao
    double getRatioMedio  (){ return m_ratio_medio    ; } // ratio medio
    double getRatioMedioDP(){ return m_ratio_medio_dp ; } // desvio da distribuicao de ratios

    double getSpread      (){ return m_spread         ; } // spread instantaneo   
    double getSpreadStd   (){ return m_spread_std     ; } // desvio padrao do spread
    double getSpreadMed   (){ return m_spread_med     ; } // media do spread
};

// calcula o ratio e sua respectiva media e armazena no vetor de medias de ratio;
void C0002ArbitragemPar::calcRatio(){
    if( m_est2.getPrecoMedTrade() == 0 ){
        //Print(__FUNCSIG__," WARN Repetido ratio anterior pois preco medio do segundo ativo estah zerado.");
        return;
    }
    
    if(m_est1.getPrecoMedTrade() != 0) m_ratio    = (m_est1.getPrecoMedTrade()/(m_est2.getPrecoMedTrade()*MULTIPLICADOR))-1.0;
    
    if(m_ratio_medio_dp          != 0) m_ratio_dp = (m_ratio - m_ratio_medio) / m_ratio_medio_dp; // ratio instantaneo calculado em unidades de desvio padrao
                 
    
    // a cada segundo adiciona o ratio instantaneo ao vetor de media de ratios e relacula o ratio medio.
    m_dt = TimeCurrent();
    if( m_dt != m_dtAnt ){
        m_ratio_medio    =           m_media.add(m_ratio); // recalculando o ratio medio
        m_ratio_medio_dp = MathSqrt( m_media.calcVar() ) ; // recalculando o desvio padrao do ratio medio
        m_dtAnt = m_dt;
    }
}

// calcula o spread (baseado na regressao linear);
void C0002ArbitragemPar::calcSpread(){

    if( m_est1.getPrecoMedTrade() == 0 || m_est2.getPrecoMedTrade() == 0 ){
        //Print(__FUNCSIG__," WARN Repetido ratio anterior pois preco medio do segundo ativo estah zerado.");
        return;
    }
    
    double r2 = 0;
    double vetX[];
    m_est2.copyPriceTo(vetX);
    
    if ( ! m_est1.regLinCompile(vetX, r2) ){ Print(__FUNCSIG__," WARN Repetindo spread anterior pois nao consegui calcular regressao."); return; }
    
    double edge_ratio = m_est1.regLinGetSlope();
    m_spread = m_est2.getPrecoMedTrade() - ( m_est1.getPrecoMedTrade() * edge_ratio + m_est1.regLinGetIntercept() );
    

    //def calc_edge_spread(s1,s2):
    //    lr = LinearRegression()
    //    lr.fit(s1.values.reshape(-1,1),s2.values.reshape(-1,1))
    //    hedge_ratio = lr.coef_[0][0]
    //    intercept = lr.intercept_[0]
    //    spread = s2 - (s1 * hedge_ratio + intercept)
    //return spread
    
    //if(m_ratio_medio_dp != 0) m_ratio_dp = (m_ratio - m_ratio_medio) / m_ratio_medio_dp; // ratio instantaneo calculado em unidades de desvio padrao
                 
    
    // a cada segundo adiciona o ratio instantaneo ao vetor de media de ratios e relacula o desvio padrao.do spread
    m_dt = TimeCurrent();
    if( m_dt != m_dtAnt ){
        m_spread_med = m_media_spread.add(m_spread); // recalculando o spread medio
        m_spread_std = MathSqrt( m_media_spread.calcVar(true) ) ; // recalculando o desvio padrao do spread
        m_dtAnt = m_dt;
    }
}

