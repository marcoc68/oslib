//+--------------------------------------------------------------------------------+
//|                                                                 osc-inclue.mqh |
//|                                                                                |
//|                                           https://www.mql5.com/pt/users/marcoc |
//|                                                                                |
//|  Variaveis usadas para apoiar o funcionamento dos experts advisors e           |
//|  classes correlacionadas.                                                      |
//|                                                                                |
//+--------------------------------------------------------------------------------+


//+---------------------------------------------------------------------+
//| Expert Advisors Variables                                           |
//| Variaveis usadas por experts advisors                               |
//+---------------------------------------------------------------------+
struct Eav{
    // ticker
    string   symbol_str ; // string com o ticker do simbolo.
    
    // cotacoes
    double   ask        ; // cotacao ask atual
    double   bid        ; // cotacao bid atual
    double   pmAsk      ; // media de cotacao ask. Baseado nos niveis de cotacoes do book de ofertas.
    double   pmBid      ; // media de cotacao bid. Baseado nos niveis de cotacoes do book de ofertas.

    // dados de posicoes
    long     positionId ;
    double   breakeven  ; // preco medio de abertura da posicao (sem normalizar). Obtido com PositionGetDouble(POSITION_PRICE_OPEN)

    double   vol_lot_ini; // tamanho do lote em uma ordem ou pedido de execucao de ordem
};
