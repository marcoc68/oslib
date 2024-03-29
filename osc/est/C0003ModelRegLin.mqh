﻿//+------------------------------------------------------------------+
//|                                              C0003ModelRegLin.mqh|
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

//#include <oslib\osc\est\osc-estatistic3.mqh>

class C0003ModelRegLin{

private:
    string m_msgUltErro;
    int    m_lenY    ; // tamanho do vetor de variaveis de entrada do eixo Y
    int    m_lenX    ; // tamanho do vetor de variaveis de entrada do eixo X
    double m_sxy     ; // somatorio de (x vezes y)
    double m_sx      ; // somatorio de (x)
    double m_sy      ; // somatorio de (y)
    double m_sx2     ; // somatorio de (x ao quadrado)
    double m_xbarra  ; // media dos valores no vetor do eixo X
    double m_ybarra  ; // media dos valores no vetor do eixo Y
    double m_sqt     ; // soma dos quadrados totais
    double m_sqe     ; // soma dos quadrados estimados
    double m_sqr     ; // soma dos quadrados dos residuos
    double m_b0, m_b1; // coeficientes da regressao
    double m_r2      ; // coeficiente de determinacao da regressao

    void initialize();
protected:
public:
    
    bool   compile     (double& y[], double& x[], double& r2);
    double predict     (double x){ return m_b0 + m_b1*x; }
    double getB1       (){ return m_b1; }
    double getSlope    (){ return m_b1; }
    double getIntercept(){ return m_b0; }
    
    string getMsgErro(){return m_msgUltErro;} // mensagem do ultimo erro
};

void C0003ModelRegLin::initialize(void){
    m_lenY   = 0;
    m_lenX   = 0;
    m_sxy    = 0; // somatorio de (x vezes y)
    m_sx     = 0; // somatorio de (x)
    m_sy     = 0; // somatorio de (y)
    m_sx2    = 0; // somatorio de (x ao quadrado)
    m_xbarra = 0;
    m_ybarra = 0;
    m_sqt    = 0; // soma dos quadrados totais
    m_sqe    = 0; // soma dos quadrados estimados
    m_sqr    = 0; // soma dos quadrados dos residuos
}

//-----------------------------------------------------------------------------
// calcula o coefiente linear usando o metodo do minimos quadrados ordinarios
// entrada:
//-----------------------------------------------------------------------------
// y : in  vetor de valores no eixo y
// x : in  vetor de valores no eixo x
// b0: out eh o b0 na funcao y(i)=b0 + b1x(i) - eh o intercepto
// b1: out eh o b0 na funcao y(i)=b0 + b1x(i) - eh o coeficiente linear
// r2: out eh o coeficiente de determinacao da regressao: eh a proporcao da 
//            variabilidade de y que eh explicada pela variabilidade de x.
//            varia de zero a 1 e quanto mais proximo de 1, melhor eh o ajuste
//            do modelo aos dados.
//-----------------------------------------------------------------------------
bool C0003ModelRegLin::compile(double& y[], double& x[], double& r2){

    initialize();
    
    // validando entrada...
    m_lenY = ArraySize(y);
    m_lenX = ArraySize(x);
    if(m_lenY<3 || m_lenX<3 ){m_msgUltErro=__FUNCTION__+" :-( modelo necessita mais de 2 eventos."; return false;}

    //if(m_lenY>m_lenX       ){m_msgUltErro=":-( tamanho do eixo X:"+IntegerToString(m_lenX)+
    //                      " nao corresponde ao tamanho do eixo Y:"+IntegerToString(m_lenY);
    //                      return false;}

    // se os eixos forem de tamanho diferente, fazemos pelo menor eixo    
    if(m_lenY>m_lenX){m_lenY=m_lenX;}
    if(m_lenX>m_lenY){m_lenX=m_lenY;}
    
    //MQO - minimos quadrados ordinarios
    //SQT - soma dos quadrados totais
    //SQE - soma dos quadrados estimados
    //SQR - soma dos quadrados dos residuos
    //SQT = SQE + SQR
    for(int i=0; i<m_lenY; i++){
        m_sxy += (x[i]*y[i]);
        m_sx  += x[i];
        m_sy  += y[i];
        m_sx2 += pow(x[i],2);
    }
    
    if(m_sx2==0){m_msgUltErro=__FUNCTION__+" :-( somatorio de x2 eh zero. Nao eh possivel estimar a regressao";
               Print("Eixo Y"); ArrayPrint(y);
               Print("Eixo X"); ArrayPrint(x);
               return false;}
    
 // if(sx2==pow(sx,2)){msg=":-( somatorio de x2:"+ DoubleToString(sx)
 //                       +" eh igual ao quadrado do somatorio de x:"+ DoubleToString(pow(sx2,2))
 //                       +". Nao eh possivel estimar a regressao";
 //            Print("Eixo Y"); ArrayPrint(y);
 //            Print("Eixo X"); ArrayPrint(x);
 //            return false;}
    
    
    // calculando o b1...
    m_b1 = ( (m_lenY*m_sxy) - (m_sx*m_sy) )/( (m_lenY*m_sx2) - pow(m_sx,2) );
    
    // calculando a media de x e y...
    m_xbarra = m_sx/m_lenY;
    m_ybarra = m_sy/m_lenY;
    
    // calculando o b0...
    m_b0 = m_ybarra - (m_b1*m_xbarra);
    
    //calculando a soma dos quadrados...
    for(int i=0; i<m_lenY; i++){
        m_sqt += pow(y[i]           - m_ybarra      , 2);
        m_sqe += pow(m_b0+m_b1*x[i] - m_ybarra      , 2);
        m_sqr += pow(y[i]           - m_b0+m_b1*x[i], 2);
    }
    
    if(m_sqt==0){m_msgUltErro=__FUNCTION__+" :-( SQT(Soma dos Quadrados Totais) eh zero. Nao eh possivel calcular r2";
               Print("Eixo Y"); ArrayPrint(y);
               Print("Eixo X"); ArrayPrint(x);
               return false;}

    // calculando r2...        
    m_r2 = m_sqe/m_sqt;
    r2   = m_r2;
    
    return true;
}
//-----------------------------------------------------------------------------
