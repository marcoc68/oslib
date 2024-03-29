﻿//+------------------------------------------------------------------+
//|                                               C0001FuzzyModel.mqh|
//|                               Copyright 2020,oficina de software.|
//|                                 http://www.metaquotes.net/marcoc.|
//|                                                                  |
//| VARIAVEIS DE ENTRADA:                                            |
//| - velLiq [velocidade do volume de compra menos a velocidade do   |
//|           volume de venda. eh a velocidade liquida do mercado]   |
//|   - TERMOS:                                                      |
//|      -comprando de -40 a  1000                                   |
//|      -neutro    de -40 a  40                                     |
//|      -vendendo  de  40 a -1000                                   |
//|                                                                  |
//| - acelCompra [aceleracao da velocidade de compra, ou compras]    |
//|   - TERMOS:                                                      |
//|        -compraAcelerando de -2 a  30                             |
//|        -compraMantendo   de -2 a  2                              |
//|        -compraFreiando   de  2 a -30                             |
//|                                                                  |
//| - acelVenda  [aceleracao da velocidade de venda, ou vendas]      |
//|   - TERMOS:                                                      |
//|        -vendaAcelerando de -2 a  30                              |
//|        -vendaMantendo   de -2 a  2                               |
//|        -vendaFreiando   de  2 a -30                              |
//|                                                                  |
//| VARIAVEL DE SAIDA:                                               |
//| - risco  [risco de abrir ou manter a posicao aberta]             |
//|   - TERMOS:                                                      |
//|      -baixo     de 0.0 a 0.3                                     |
//|      -medio     de 0.3 a 0.5                                     |
//|      -alto      de 0.5 a 1.0                                     |
//|                                                                  --------------------------------------------|
//| REGRAS                                                                                                       |
//| - C01 - if mercado estah comprador e compra estah acelerando e volVenda estah freiando   then riscoCompra-01 |
//| - C02 - if mercado estah comprador e compra estah acelerando e volVenda estah acelerando then riscoCompra-02 |
//| - C03 - if mercado estah comprador e compra estah freiando   e volVenda estah freiando   then riscoCompra-02 |
//| - C04 - if mercado estah comprador e compra estah freiando   e volVenda estah acelerando then riscoCompra-03 |
//|                                                                                                              |
//| - V01 - if mercado estah vendedor  e venda estah acelerando e volCompra estah freiando   then riscoVenda-01  |
//| - V02 - if mercado estah vendedor  e venda estah acelerando e volCompra estah acelerando then riscoVenda-02  |
//| - V03 - if mercado estah vendedor  e venda estah freiando   e volCompra estah freiando   then riscoVenda-02  |
//| - V04 - if mercado estah vendedor  e venda estah freiando   e volCompra estah acelerando then riscoVenda-03  |
//|                                                                                                              |
//+--------------------------------------------------------------------------------------------------------------+
#property copyright "2020, Oficina de Software."
#property link      "http://www.os.net"

#include <Math\Fuzzy\mamdanifuzzySystem.mqh>
#include <oslib\osc\est\osc-estatistic3.mqh>

class C0001FuzzyModel{

private:

    double m_minVL;// = -500; // velocidade do volume minima
    double m_maxVL;// = +500; // velocidade do volume maxima
    double m_minA ;// = -15 ; // aceleracao de volume de compta ou venda minima
    double m_maxA ;// = +15 ; // aceleracao de volume de compta ou venda maxima

    CMamdaniFuzzySystem *m_fsMercado;
    
    CFuzzyVariable *m_inputMercado     ;
    CFuzzyVariable *m_inputVolCompra   ;
    CFuzzyVariable *m_inputVolVenda    ;
    CFuzzyVariable *m_inputAcelLiq     ;
    CFuzzyVariable *m_outputRiscoCompra;
    CFuzzyVariable *m_outputRiscoVenda ;

    CDictionary_Obj_Double *m_dictMercado    ;
    CDictionary_Obj_Double *m_dictAcelCompra ;
    CDictionary_Obj_Double *m_dictAcelVenda  ;
    CDictionary_Obj_Double *m_dictAcelLiq    ;
    CDictionary_Obj_Double *m_dictRiscoCompra;
    CDictionary_Obj_Double *m_dictRiscoVenda ;

    CList *m_inputs, *m_outputs;

    CMamdaniFuzzyRule *m_ruleRiscoCompra1; 
    CMamdaniFuzzyRule *m_ruleRiscoCompra2; 
    CMamdaniFuzzyRule *m_ruleRiscoCompra3; 
    CMamdaniFuzzyRule *m_ruleRiscoCompra4; 
    CMamdaniFuzzyRule *m_ruleRiscoCompra5; 
    CMamdaniFuzzyRule *m_ruleRiscoCompra6; 
    CMamdaniFuzzyRule *m_ruleRiscoVenda1 ; 
    CMamdaniFuzzyRule *m_ruleRiscoVenda2 ; 
    CMamdaniFuzzyRule *m_ruleRiscoVenda3 ; 
    CMamdaniFuzzyRule *m_ruleRiscoVenda4 ;
    CMamdaniFuzzyRule *m_ruleRiscoVenda5 ;
    CMamdaniFuzzyRule *m_ruleRiscoVenda6 ;
    
    double m_topVelLiq , m_indVelLiq ,
           m_topAcelVol, m_indAcelVol;
    
    double normalizarVelLiq (double _velLiq);
    double normalizarAcelVol(double _velLiq);
    
protected:
public:
    
        ~C0001FuzzyModel() {deletarModelo();};
    void initialize();
    void compilarModelo();
    void deletarModelo();
    void CalcularRisco( double _velLiq, double _acelCompra, double _acelVenda, double &_riscoVenda, double &_riscoCompra);
    void CalcularRisco( osc_estatistic3 &_est2, double &_riscoVenda, double &_riscoCompra );

};


//    -1000 +1000
//    -1    +1
//    
//    ind = 1    -(-1   )
//          -------------
//          1000 -(-1000)
double C0001FuzzyModel::normalizarVelLiq (double _velLiq){

    if( _velLiq > m_maxVL ) return m_maxVL;
    if( _velLiq < m_minVL ) return m_minVL;

    double absVelLiq = MathAbs(_velLiq);
    if( absVelLiq > m_topVelLiq ){
        double indVelLiq = ( m_maxVL   - m_minVL   )
                            /
                           ( absVelLiq - absVelLiq );
        Print(__FUNCTION__, " Novo topo velLiq recebido!! Anterior=",m_topVelLiq, " novo=",absVelLiq);
        Print(__FUNCTION__, " Recalculado indice normalizacao velLiq!! Anterior=",m_indVelLiq, " novo=",indVelLiq);
        m_topVelLiq = absVelLiq;
        m_indVelLiq = indVelLiq;
    }
    
    return _velLiq*m_indVelLiq;
}
double C0001FuzzyModel::normalizarAcelVol (double _acelVol){

    if( _acelVol > m_maxA ) return m_maxA;
    if( _acelVol < m_minA ) return m_minA;

    double absAcelVol = MathAbs(_acelVol);
    if( absAcelVol > m_topAcelVol ){
        double indAcelVol = ( m_maxA     - m_minA      )
                            /
                            ( absAcelVol - absAcelVol  );
        Print(__FUNCTION__, " Novo topo AcelVol recebido!! Anterior=",m_topAcelVol, " novo=",absAcelVol);
        Print(__FUNCTION__, " Recalculado indice normalizacao AcelVol!! Anterior=",m_indAcelVol, " novo=",indAcelVol);
        m_topAcelVol = absAcelVol;
        m_indAcelVol = indAcelVol;
    }
    
    return _acelVol*m_indAcelVol;
}

void C0001FuzzyModel::initialize(){
     m_minVL = -800;
     m_maxVL = +800;
     m_minA  = -40 ;
     m_maxA  = +40 ;

     m_topAcelVol = m_maxA ; m_indAcelVol = 1;
     m_topVelLiq  = m_maxVL; m_indVelLiq  = 1;

     compilarModelo();
}

void C0001FuzzyModel::deletarModelo(){
    
    delete m_fsMercado;
    
    delete m_inputMercado     ;
    delete m_inputVolCompra   ;
    delete m_inputVolVenda    ;
    delete m_inputAcelLiq     ;
    delete m_outputRiscoCompra;
    delete m_outputRiscoVenda ;

    delete m_dictMercado    ;
    delete m_dictAcelCompra ;
    delete m_dictAcelVenda  ;
    delete m_dictAcelLiq    ;
    delete m_dictRiscoCompra;
    delete m_dictRiscoVenda ;
    
    delete m_inputs ; 
    delete m_outputs;

    delete m_ruleRiscoCompra1; 
    delete m_ruleRiscoCompra2; 
    delete m_ruleRiscoCompra3; 
    delete m_ruleRiscoCompra4; 
    delete m_ruleRiscoCompra5; 
    delete m_ruleRiscoCompra6; 
    delete m_ruleRiscoVenda1 ; 
    delete m_ruleRiscoVenda2 ; 
    delete m_ruleRiscoVenda3 ; 
    delete m_ruleRiscoVenda4 ;
    delete m_ruleRiscoVenda5 ;
    delete m_ruleRiscoVenda6 ;
}


//+---------------------------------------------------------------------------------------+
//|                                                                                       |
//| Compila o modelo fuzzy para tratamento de volume de agressoes.                        |
//|                                                                                       |
//+---------------------------------------------------------------------------------------+
void C0001FuzzyModel::compilarModelo(){

    m_inputs = new CList();
    
    //1. criando o ponteiro para o modelo...
    //Print(__FUNCSIG__," criando o ponteiro para o modelo...");
    m_fsMercado=new CMamdaniFuzzySystem();
    
    //2. criando as variaveis
    //Print(__FUNCSIG__," criando variaveis...");
    m_inputMercado     =new CFuzzyVariable("mercado"    ,m_minVL,m_maxVL );
    m_inputVolCompra   =new CFuzzyVariable("volCompra"  ,m_minA ,m_maxA  );
    m_inputVolVenda    =new CFuzzyVariable("volVenda"   ,m_minA ,m_maxA  );
    m_inputAcelLiq     =new CFuzzyVariable("acelLiq"    ,m_minA ,m_maxA  );
    m_outputRiscoCompra=new CFuzzyVariable("riscoCompra",0      ,1       );
    m_outputRiscoVenda =new CFuzzyVariable("riscoVenda" ,0      ,1       );
    
    //Print(__FUNCSIG__," criando termos para usar posteriormente no calculo...");
    m_dictMercado    =new CDictionary_Obj_Double;
    m_dictAcelCompra =new CDictionary_Obj_Double;
    m_dictAcelVenda  =new CDictionary_Obj_Double;
    m_dictAcelLiq    =new CDictionary_Obj_Double;
  //m_dictRiscoCompra=new CDictionary_Obj_Double;
  //m_dictRiscoVenda =new CDictionary_Obj_Double;

    //Print(__FUNCSIG__," criando termos e adicionando a variavel input m_inputMercado...");
    m_inputMercado.Terms().Add(new CFuzzyTerm  ("vendedor" , new CZ_ShapedMembershipFunction(m_minVL    ,m_maxVL*0.1)));
    m_inputMercado.Terms().Add(new CFuzzyTerm  ("neutro"   , new CNormalMembershipFunction  ( 0         ,m_maxVL*0.1)));
    m_inputMercado.Terms().Add(new CFuzzyTerm  ("comprador", new CS_ShapedMembershipFunction(m_minVL*0.1,m_maxVL    )));
    m_fsMercado.Input().Add(m_inputMercado);    

    //Print(__FUNCSIG__," criando termos e adicionando a variavel input m_inputVolCompra...");
    m_inputVolCompra.Terms().Add(new CFuzzyTerm("freiando"  , new CZ_ShapedMembershipFunction(m_minA    , m_maxA*0.1)));
    m_inputVolCompra.Terms().Add(new CFuzzyTerm("mantendo"  , new CNormalMembershipFunction  ( 0        , m_maxA*0.1)));
    m_inputVolCompra.Terms().Add(new CFuzzyTerm("acelerando", new CS_ShapedMembershipFunction(m_minA*0.1, m_maxA    )));
    m_fsMercado.Input().Add(m_inputVolCompra);    

    //Print(__FUNCSIG__," criando termos e adicionando a variavel input m_inputVolVenda...");
    m_inputVolVenda.Terms().Add(new CFuzzyTerm ("freiando"  , new CZ_ShapedMembershipFunction(m_minA    , m_maxA*0.1)));
    m_inputVolVenda.Terms().Add(new CFuzzyTerm ("mantendo"  , new CNormalMembershipFunction  ( 0        , m_maxA*0.1)));
    m_inputVolVenda.Terms().Add(new CFuzzyTerm ("acelerando", new CS_ShapedMembershipFunction(m_minA*0.1, m_maxA    )));
    m_fsMercado.Input().Add(m_inputVolVenda);    

    //Print(__FUNCSIG__," criando termos e adicionando a variavel input m_inputAcelLiq...");
    m_inputAcelLiq.Terms().Add(new CFuzzyTerm  ("positiva", new CZ_ShapedMembershipFunction  (m_minA    ,m_maxA*0.1)));
    m_inputAcelLiq.Terms().Add(new CFuzzyTerm  ("neutra"  , new CNormalMembershipFunction    ( 0        ,m_maxA*0.1)));
    m_inputAcelLiq.Terms().Add(new CFuzzyTerm  ("negativa", new CS_ShapedMembershipFunction  (m_minA*0.1,m_maxA    )));
    m_fsMercado.Input().Add(m_inputAcelLiq);    

  //m_outputRiscoCompra.Terms().Add(new CFuzzyTerm ("baixo", new CZ_ShapedMembershipFunction(0.0, 0.6)));//0-1-2-3-4-5-6
  //m_outputRiscoCompra.Terms().Add(new CFuzzyTerm ("medio", new CNormalMembershipFunction  (0.5, 0.1)));//        4-5-6  
  //m_outputRiscoCompra.Terms().Add(new CFuzzyTerm ("alto" , new CS_ShapedMembershipFunction(0.4, 1.0)));//        4-5-6-7-8-9-10

    m_outputRiscoCompra.Terms().Add(new CFuzzyTerm ("muitobaixo", new CZ_ShapedMembershipFunction(0.0, 0.3))); //0-1-2-3
    m_outputRiscoCompra.Terms().Add(new CFuzzyTerm ("baixo"     , new CNormalMembershipFunction  (0.4, 0.1))); //      3-4-5      
    m_outputRiscoCompra.Terms().Add(new CFuzzyTerm ("medio"     , new CNormalMembershipFunction  (0.5, 0.1))); //        4-5-6
    m_outputRiscoCompra.Terms().Add(new CFuzzyTerm ("alto"      , new CS_ShapedMembershipFunction(0.6, 1.0))); //            6-7-8-9-10
    m_fsMercado.Output().Add(m_outputRiscoCompra);    

  //m_outputRiscoVenda.Terms().Add(new CFuzzyTerm ("baixo", new CZ_ShapedMembershipFunction(0.0, 0.6)));//0-1-2-3-4-5-6
  //m_outputRiscoVenda.Terms().Add(new CFuzzyTerm ("medio", new CNormalMembershipFunction  (0.5, 0.1)));//        4-5-6
  //m_outputRiscoVenda.Terms().Add(new CFuzzyTerm ("alto" , new CS_ShapedMembershipFunction(0.4, 1.0)));//        4-5-6-7-8-9-10

    m_outputRiscoVenda.Terms().Add(new CFuzzyTerm ("muitobaixo", new CZ_ShapedMembershipFunction(0.0, 0.3))); //0-1-2-3
    m_outputRiscoVenda.Terms().Add(new CFuzzyTerm ("baixo"     , new CNormalMembershipFunction  (0.4, 0.1))); //      3-4-5      
    m_outputRiscoVenda.Terms().Add(new CFuzzyTerm ("medio"     , new CNormalMembershipFunction  (0.5, 0.1))); //        4-5-6
    m_outputRiscoVenda.Terms().Add(new CFuzzyTerm ("alto"      , new CS_ShapedMembershipFunction(0.6, 1.0))); //            6-7-8-9-10
    m_fsMercado.Output().Add(m_outputRiscoVenda);    

//| - C01 - if mercado estah comprador e compra estah acelerando e volVenda estah freiando   then riscoCompra-01 |
//| - C02 - if mercado estah comprador e compra estah acelerando e volVenda estah acelerando then riscoCompra-02 |
//| - C03 - if mercado estah comprador e compra estah freiando   e volVenda estah freiando   then riscoCompra-02 |
//| - C04 - if mercado estah comprador e compra estah freiando   e volVenda estah acelerando then riscoCompra-03 |
    //Print(__FUNCSIG__," criando regras para a variavel de saida riscoCompra...");
    m_ruleRiscoCompra1 = m_fsMercado.ParseRule("if (mercado is comprador) and (volCompra is acelerando) and (volVenda  is freiando  ) then (riscoCompra is baixo)");
    m_ruleRiscoCompra2 = m_fsMercado.ParseRule("if (mercado is comprador) and (volCompra is acelerando) and (volVenda  is acelerando) then (riscoCompra is medio)");
    m_ruleRiscoCompra3 = m_fsMercado.ParseRule("if (mercado is comprador) and (volCompra is freiando  ) and (volVenda  is freiando  ) then (riscoCompra is medio)");
    m_ruleRiscoCompra4 = m_fsMercado.ParseRule("if (mercado is comprador) and (volCompra is freiando  ) and (volVenda  is acelerando) then (riscoCompra is alto )");
    m_ruleRiscoCompra5 = m_fsMercado.ParseRule("if (mercado is vendedor )                                                             then (riscoCompra is alto )");
    m_ruleRiscoCompra6 = m_fsMercado.ParseRule("if (mercado is comprador) and (volCompra is acelerando) and (volVenda  is freiando  ) and (acelLiq is positiva) then (riscoCompra is muitobaixo)");

//acelLiq

//| - V01 - if mercado estah vendedor  e venda estah acelerando e volCompra estah freiando   then riscoVenda-01  |
//| - V02 - if mercado estah vendedor  e venda estah acelerando e volCompra estah acelerando then riscoVenda-02  |
//| - V03 - if mercado estah vendedor  e venda estah freiando   e volCompra estah freiando   then riscoVenda-02  |
//| - V04 - if mercado estah vendedor  e venda estah freiando   e volCompra estah acelerando then riscoVenda-03  |
    //Print(__FUNCSIG__," criando regras para a variavel de saida riscoVenda...");
    m_ruleRiscoVenda1 = m_fsMercado.ParseRule ("if (mercado is vendedor  ) and (volVenda  is acelerando) and (volCompra is freiando  ) then (riscoVenda  is baixo)");
    m_ruleRiscoVenda2 = m_fsMercado.ParseRule ("if (mercado is vendedor  ) and (volVenda  is acelerando) and (volCompra is acelerando) then (riscoVenda  is medio)");
    m_ruleRiscoVenda3 = m_fsMercado.ParseRule ("if (mercado is vendedor  ) and (volVenda  is freiando  ) and (volCompra is freiando  ) then (riscoVenda  is medio)");
    m_ruleRiscoVenda4 = m_fsMercado.ParseRule ("if (mercado is vendedor  ) and (volVenda  is freiando  ) and (volCompra is acelerando) then (riscoVenda  is alto )");
    m_ruleRiscoVenda5 = m_fsMercado.ParseRule ("if (mercado is comprador )                                                             then (riscoVenda  is alto )");
    m_ruleRiscoVenda6 = m_fsMercado.ParseRule ("if (mercado is vendedor  ) and (volVenda  is acelerando) and (volCompra is freiando  ) and (acelLiq is negativa) then (riscoVenda  is muitobaixo)");

    //Print(__FUNCSIG__," adicionando regras ao sistema m_fsMercado...");
    m_fsMercado.Rules().Add(m_ruleRiscoCompra1);
    m_fsMercado.Rules().Add(m_ruleRiscoCompra2);
    m_fsMercado.Rules().Add(m_ruleRiscoCompra3);
    m_fsMercado.Rules().Add(m_ruleRiscoCompra4);
    m_fsMercado.Rules().Add(m_ruleRiscoCompra5);
    m_fsMercado.Rules().Add(m_ruleRiscoCompra6);
    m_fsMercado.Rules().Add(m_ruleRiscoVenda1 );
    m_fsMercado.Rules().Add(m_ruleRiscoVenda2 );
    m_fsMercado.Rules().Add(m_ruleRiscoVenda3 );
    m_fsMercado.Rules().Add(m_ruleRiscoVenda4 );
    m_fsMercado.Rules().Add(m_ruleRiscoVenda5 );
    m_fsMercado.Rules().Add(m_ruleRiscoVenda6 );
}

void C0001FuzzyModel::CalcularRisco( osc_estatistic3 &_est2, double &_riscoVenda, double &_riscoCompra ){
    
    CalcularRisco(_est2.getVolTradeLiqPorSeg(),
                  _est2.getAceVolBuy        (),
                  _est2.getAceVolSel        (),
                  _riscoVenda                ,
                  _riscoCompra               );
}

void C0001FuzzyModel::CalcularRisco( double _velLiq, double _acelCompra, double _acelVenda, double &_riscoVenda, double &_riscoCompra){

    deletarModelo();
    compilarModelo(); //<TODO> CORRIGIR para nao necessitar compilar a cada calculo do risco.

    m_dictMercado   .SetAll( m_inputMercado  , normalizarVelLiq (_velLiq                ) );
    m_dictAcelCompra.SetAll( m_inputVolCompra, normalizarAcelVol(_acelCompra            ) );
    m_dictAcelVenda .SetAll( m_inputVolVenda , normalizarAcelVol(_acelVenda             ) );
    m_dictAcelLiq   .SetAll( m_inputAcelLiq  , normalizarAcelVol(_acelCompra-_acelVenda ) );
       
    m_inputs.Clear();
    m_inputs.Add(m_dictMercado   );
    m_inputs.Add(m_dictAcelCompra);
    m_inputs.Add(m_dictAcelVenda );
    m_inputs.Add(m_dictAcelLiq   );
      
    m_outputs=m_fsMercado.Calculate(m_inputs);

    m_dictRiscoCompra = m_outputs.GetNodeAtIndex(0);
    m_dictRiscoVenda  = m_outputs.GetNodeAtIndex(1);

    _riscoCompra = m_dictRiscoCompra.Value();
    _riscoVenda  = m_dictRiscoVenda.Value();
    
  //delete   outputs;
  //delete m_outputs;
  //delete m_dictRiscoCompra;
  //delete m_dictRiscoVenda;
    return;
}
