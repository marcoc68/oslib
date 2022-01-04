//+------------------------------------------------------------------+
//|                                                    osc-cusum.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"
//+---------------------------------------------------------------------+
//| Implementacoes CUSUM - Cumulative Sum.                              |
//+---------------------------------------------------------------------+
#property description "Soma cumulativa."

#include <Object.mqh>
#include <Generic\Queue.mqh>
#include <oslib/osc-padrao.mqh>


class osc_cusum : public CObject{
private:
    double m_c_mais , m_c_mais_ant ;
    double m_c_menos, m_c_menos_ant;
    int    m_acumular_a_cada;
    int    m_tot_acum;
protected:
    
public:
    osc_cusum(void): m_c_mais         (0),
                     m_c_mais_ant     (0),
                     m_c_menos        (0),
                     m_c_menos_ant    (0),
                     m_acumular_a_cada(0),
                     m_tot_acum       (0){}
    //-- 
    // const double xi   eh a ocorrencia sendo monitorada (preco)
    // const double T    eh o alvo. Normalmente a media
    // const double K    eh o desvio minimo para que se acumule em uma das direcoes
    // const double H    eh o limiar (alarme)
    // bool& strikeHmais   true - C+ estah acima de H 
    // bool& strikeHmenos  true - C- estah acima de H
    // bool& strikeMais    true - C+ cresceu
    // bool& strikeMenos   true - C- cresceu
    void calcC(const double xi, const double T, const double K, const double H, bool& strikeHmais, bool& strikeHmenos, bool& strikeMais, bool& strikeMenos);

    double getCmais (){return m_c_mais ;}
    double getCmenos(){return m_c_menos;}
    void   setAcumularAcadaXTicks(int ticks){ m_acumular_a_cada = ticks; }
};

//-- 
// xi   eh a ocorrencia sendo monitorada (preco)
// T    eh o alvo. Normalmente a media
// K    eh o desvio minimo para que se acumule em uma das direcoes
// H    eh o limiar (alarme)
// bool& strikeHmais   true - C+ estah acima de H 
// bool& strikeHmenos  true - C- estah acima de H
// bool& strikeMais    true - C+ cresceu
// bool& strikeMenos   true - C- cresceu
void osc_cusum::calcC(const double xi, const double T, const double K, const double H, bool& strikeHmais, bool& strikeHmenos, bool& strikeMais, bool& strikeMenos){
    
    if( m_tot_acum++ < m_acumular_a_cada ) return;
    m_tot_acum = 0;
    
    if( xi == 0 ) return; //<TODO> VER PORQUE ESTAH CHEGANDO COM ZERO
    
    strikeHmais  = false;
    strikeHmenos = false;
    strikeMais   = false;
    strikeMenos  = false;

    m_c_mais = MathMax(0, xi - (T+K) + m_c_mais_ant );
    //if( m_c_mais > m_c_mais_ant) strikeMais  = true;
    //if( m_c_mais > H           ) strikeHmais = true;
    
    m_c_menos = MathMax(0, (T-K) - xi + m_c_menos_ant );
    //if( m_c_menos > m_c_menos_ant ) strikeMenos  = true;
    //if( m_c_menos > H             ) strikeHmenos = true;
    
    // quem crescer mais penaliza o oponente no tanto que cresceu a mais...
    double dif_c_mais  = m_c_mais  - m_c_mais_ant;
    double dif_c_menos = m_c_menos - m_c_menos_ant;
    if( dif_c_mais > dif_c_menos && dif_c_mais > 0 ){
        m_c_menos = m_c_menos - dif_c_mais;
        if(m_c_menos<0) m_c_menos=0;
    }else if( dif_c_menos > dif_c_mais && dif_c_menos > 0 ){
        m_c_mais = m_c_mais - dif_c_menos;
        if(m_c_mais<0) m_c_mais=0;
    }
    
    if( m_c_mais > m_c_mais_ant) strikeMais  = true;
    if( m_c_mais > H           ) strikeHmais = true;

    if( m_c_menos > m_c_menos_ant ) strikeMenos  = true;
    if( m_c_menos > H             ) strikeHmenos = true;

    m_c_mais_ant   = m_c_mais;
    m_c_menos_ant  = m_c_menos;   

/*
    Print(  "[xi:"   ,DoubleToString(xi           ,_Digits)
          ,"][T:"    ,DoubleToString(T            ,_Digits)
          ,"][K:"    ,DoubleToString(K            ,_Digits)
          ,"][H:"    ,DoubleToString(H            ,_Digits)
          ,"][C+:"   ,DoubleToString(m_c_mais     ,_Digits)
          ,"][C-:"   ,DoubleToString(m_c_menos    ,_Digits)
          //,"][C+A:"  ,DoubleToString(m_c_mais_ant ,_Digits)
          //,"][C-A:"  ,DoubleToString(m_c_menos_ant,_Digits)
          ,"][stC+:" ,strikeMais
          ,"][stC-:" ,strikeHmenos
          ,"][stH+:" ,strikeHmais
          ,"][stH-:" ,strikeHmenos
    );
*/
}
