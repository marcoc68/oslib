//+------------------------------------------------------------------+
//|                                              osc-pivo-points.mqh |
//|                             Copyright 2021, Oficina de Software. |
//|                                             https://www.mql5.com |
//|                                                                  |
//|  Calcula o pivo da barra anterior e tambem os pontos de suporte  |
//|  e resistencia.                                                  |
//|                                                                  |
//|                                                                  |
//|  pivo = (barra anterior(high+low+close)/3 )                      |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "2020, Oficina de Software."
#property link      "http://www.os.net"



#include <oslib\os-lib.mq5>
// classe qie calcula os pontos de pivo referentes a barra anterior
class osc_pivo_points{

    private:

    double m_res3   ; // terceira resistencia
    double m_res2   ; // segunda resistencia
    double m_res1   ; // primeira resistencia
    double m_pivo   ; // pivo
    double m_sup1   ; // primeiro suporte
    double m_sup2   ; // segundo suporte
    double m_sup3   ; // terceiro suporte
    double m_cloa   ; // fechamento dia anterior

    public:
    
    // recebe:
    // max  : preco maximo da barra anterior
    // min  : preco minimo da barra anterior
    // close: preco de fechamento da barra anterior
    //
    // faz: calcula o pivo bem como os pontos de suporte e resistencia
    void calc ( const double max, const double min, const double close){
    
         m_pivo = (max+min+close)/3.0;

         m_res1 = 2*m_pivo - min;
         m_sup1 = 2*m_pivo - max;
         
         m_res2 = m_pivo + ( m_res1 - m_sup1 );
         m_sup2 = m_pivo - ( m_res1 - m_sup1 );
         
         m_res3 = (2.0*m_pivo)+ (    max - 2.0*min);
         m_sup3 = (2.0*m_pivo)- (2.0*max -     min);
         
         m_cloa = close;
    }
    
    double getPivo(){ return m_pivo; }
    double getSup1(){ return m_sup1; }
    double getSup2(){ return m_sup2; }
    double getSup3(){ return m_sup3; }
    double getRes1(){ return m_res1; }
    double getRes2(){ return m_res2; }
    double getRes3(){ return m_res3; }
    double getCloA(){ return m_cloa; }
};

// classe que, alem de calcular os pontos de pivo, tem metodos para apresenta-los no grafico do terminal
class osc_pivo_points_lines: public osc_pivo_points{

    private:

    bool   m_line_pivo_criada;
    bool   m_line_sup1_criada;
    bool   m_line_sup2_criada;
    bool   m_line_sup3_criada;
    bool   m_line_res1_criada;
    bool   m_line_res2_criada;
    bool   m_line_res3_criada;

    string m_str_line_pivo;
    string m_str_line_sup1;
    string m_str_line_sup2;
    string m_str_line_sup3;
    string m_str_line_res1;
    string m_str_line_res2;
    string m_str_line_res3;

    public:

    void drawLinePivo(){
        if( m_line_pivo_criada ){ 
            HLineMove( 0, m_str_line_pivo, getPivo() );
        }else{
            HLineCreate(0,m_str_line_pivo,0,getPivo(), clrYellow,STYLE_SOLID,1,false,true,false,0);
            m_line_pivo_criada = true;
        }
        ChartRedraw(0);
    }

    void drawLineSup1(){
        if( m_line_sup1_criada ){ 
            HLineMove( 0, m_str_line_sup1, getSup1() );
        }else{
            HLineCreate(0,m_str_line_sup1,0,getSup1(), clrMediumBlue,STYLE_SOLID,1,false,true,false,0);
            m_line_sup1_criada = true;
        }
        ChartRedraw(0);
    }

    void drawLineSup2(){
        if( m_line_sup2_criada ){ 
            HLineMove( 0, m_str_line_sup2, getSup2() );
        }else{
            HLineCreate(0,m_str_line_sup2,0,getSup2(), clrMediumBlue,STYLE_SOLID,1,false,true,false,0);
            m_line_sup2_criada = true;
        }
        ChartRedraw(0);
    }

    void drawLineSup3(){
        if( m_line_sup3_criada ){ 
            HLineMove( 0, m_str_line_sup3, getSup3() );
        }else{
            HLineCreate(0,m_str_line_sup3,0,getSup3(), clrMediumBlue,STYLE_SOLID,1,false,true,false,0);
            m_line_sup3_criada = true;
        }
        ChartRedraw(0);
    }

    void drawLineRes1(){
        if( m_line_res1_criada ){ 
            HLineMove( 0, m_str_line_res1, getRes1() );
        }else{
            HLineCreate(0,m_str_line_res1,0,getRes1(), clrFireBrick,STYLE_SOLID,1,false,true,false,0);
            m_line_res1_criada = true;
        }
        ChartRedraw(0);
    }

    void drawLineRes2(){
        if( m_line_res2_criada ){ 
            HLineMove( 0, m_str_line_res2, getRes2() );
        }else{
            HLineCreate(0,m_str_line_res2,0,getRes2(), clrFireBrick,STYLE_SOLID,1,false,true,false,0);
            m_line_res2_criada = true;
        }
        ChartRedraw(0);
    }

    void drawLineRes3(){
        if( m_line_res3_criada ){ 
            HLineMove( 0, m_str_line_res3, getRes3() );
        }else{
            HLineCreate(0,m_str_line_res3,0,getRes3(), clrFireBrick,STYLE_SOLID,1,false,true,false,0);
            m_line_res3_criada = true;
        }
        ChartRedraw(0);
    }

};