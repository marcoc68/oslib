//+------------------------------------------------------------------+
//|                                            C0008NetPerceptron.mqh|
//|                               Copyright 2021,oficina de software.|
//|                                 http://www.metaquotes.net/marcoc.|
//|                                                                  |
//|   Modelo de floresta randomica de arvores de decisao.            |
//|                                                                  |
//|                                                                  |
//|                                                                  |
//| VARIAVEIS DE ENTRADA:                                            |
//| - velLiq [velocidade do volume de compra menos a velocidade do   |
//|           volume de venda. eh a velocidade liquida do mercado]   |
//|   - TERMOS:                                                      |
//|      -comprando de -40 a  1000                                   |
//|      -neutro    de -40 a  40                                     |
//|      -vendendo  de  40 a -1000                                   |
//|                                                                  |
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
//|                                                                                                              |
//| - V01 - if mercado estah vendedor  e venda estah acelerando e volCompra estah freiando   then riscoVenda-01  |
//| - V02 - if mercado estah vendedor  e venda estah acelerando e volCompra estah acelerando then riscoVenda-02  |
//|                                                                                                              |
//+--------------------------------------------------------------------------------------------------------------+
#property copyright "2020, Oficina de Software."
#property link      "http://www.os.net"

//#include <Math\Alglib\dataanalysis.mqh>

class C0008NetPerceptron{

private:
protected:
public:
    // retorna 1 se receber parametro nao negativo.
    uint step_function(double x){ return x<0?0:1; }
    
    // retorna 1 se o perceptron disparar e zero se nao.
    uint perceptron_output(double &weights[], double bias, double &x[] ){
        return 1;
    }
};