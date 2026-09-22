//+------------------------------------------------------------------+
//|                                               osc-trade-util.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"

#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh>
//+-----------------------------------------------------------------------------------------------+
//| Metodos utilitarios de negociacao, reaproveitaveis por qualquer EA.                            |
//|                                                                                                |
//| Todos os metodos sao estaticos e sem estado. Uso:                                              |
//|    double vol = osc_trade_util::normalizarVolume( "PETR4", 1.37 );                             |
//+-----------------------------------------------------------------------------------------------+

class osc_trade_util {
private:
public:

    //+--------------------------------------------------------------+
    //| Simbolos                                                      |
    //+--------------------------------------------------------------+

    // coloca o ativo na Observacao de Mercado, se ainda nao estiver.
    static bool selecionarSimbolo(const string symb){
        if( !SymbolSelect(symb,true) ){
            Print(":-( ", __FUNCTION__, " nao foi possivel selecionar o ativo ", symb,
                          ". erro=", GetLastError() );
            return false;
        }
        return true;
    }

    // preco de referencia do ativo: ultimo negocio, ou o meio do book, ou o que houver.
    static double precoReferencia(const string symb){
        MqlTick tick;
        if( !SymbolInfoTick(symb,tick) ) return 0;
        return precoReferencia(tick);
    }

    // preco de referencia de um tick: ultimo negocio, ou o meio do book, ou o que houver.
    static double precoReferencia(MqlTick &tick){
        if( tick.last > 0                 ) return tick.last;
        if( tick.bid  > 0 && tick.ask > 0 ) return (tick.bid+tick.ask)/2;
        if( tick.ask  > 0                 ) return tick.ask;
        return tick.bid;
    }

    //+--------------------------------------------------------------+
    //| Volume                                                        |
    //+--------------------------------------------------------------+

    // quantidade de casas decimais correspondente ao passo de volume informado.
    static int digitosDoPasso(const double passo){
        for(int d=0; d<8; d++){
            double escala = MathPow(10,d);
            if( MathAbs( passo*escala - MathRound(passo*escala) ) < 1e-9 ) return d;
        }
        return 8;
    }

    // ajusta o volume ao passo e aos limites (minimo e maximo) do ativo.
    static double normalizarVolume(const string symb, const double vol){
        double passo = SymbolInfoDouble( symb, SYMBOL_VOLUME_STEP );
        double minimo= SymbolInfoDouble( symb, SYMBOL_VOLUME_MIN  );
        double maximo= SymbolInfoDouble( symb, SYMBOL_VOLUME_MAX  );
        return normalizarVolume( vol, passo, minimo, maximo );
    }

    // ajusta o volume ao passo e aos limites (minimo e maximo) do ativo.
    static double normalizarVolume(CSymbolInfo &symb, const double vol){
        return normalizarVolume( vol, symb.LotsStep(), symb.LotsMin(), symb.LotsMax() );
    }

    // ajusta o volume ao passo e aos limites informados.
    static double normalizarVolume(const double vol, const double passo,
                                   const double minimo, const double maximo){
        double p = passo; if( p <= 0 ) p = 0.01;
        double v = MathRound(vol/p)*p;
        if( minimo > 0 && v < minimo ) v = minimo;
        if( maximo > 0 && v > maximo ) v = maximo;
        return NormalizeDouble( v, digitosDoPasso(p) );
    }

    //+--------------------------------------------------------------+
    //| Valor financeiro do movimento de preco                        |
    //+--------------------------------------------------------------+

    // valor, na moeda da conta, de um movimento de delta_preco no ativo, para o volume informado.
    static double valorDoMovimento(const string symb, const double vol, const double delta_preco){
        double tick_size = SymbolInfoDouble( symb, SYMBOL_TRADE_TICK_SIZE  );
        double tick_val  = SymbolInfoDouble( symb, SYMBOL_TRADE_TICK_VALUE );
        if( tick_size <= 0 || tick_val <= 0 ) return 0;
        return vol * (delta_preco/tick_size) * tick_val;
    }

    // valor, na moeda da conta, de uma variacao percentual do preco do ativo, para o volume
    // informado. pct eh a fracao da variacao: 0.01 = 1%.
    static double valorPorPercentual(const string symb, const double vol, const double pct){
        double preco = precoReferencia(symb);
        if( preco <= 0 ) return 0;
        return valorDoMovimento( symb, vol, preco*pct );
    }

    //+--------------------------------------------------------------+
    //| Equilibrio financeiro entre dois ativos                       |
    //+--------------------------------------------------------------+

    // menor par de volumes (respeitando lote minimo e passo de cada ativo) cujo valor
    // financeiro de uma mesma variacao percentual se equivale nas duas pontas. Eh o volume
    // a partir do qual uma operacao casada (long/short) fica neutra em dinheiro.
    //
    // in  symb1/symb2 : ativos do par
    // in  tolerancia  : desequilibrio aceito, em fracao. 0.01 = 1%
    // in  max_passos  : quantos multiplos do lote minimo do ativo 1 serao testados
    // out vol1/vol2   : volumes sugeridos
    // out erro        : desequilibrio financeiro resultante, em fracao
    // ret             : false se nao foi possivel calcular (sem cotacao ou sem tick value)
    static bool calcVolumesEquilibrio(const string symb1, const string symb2,
                                      double &vol1, double &vol2, double &erro,
                                      const double tolerancia=0.01, const int max_passos=500){
        vol1 = 0; vol2 = 0; erro = 0;

        // valor de uma variacao de 1% do preco, para 1 lote de cada ativo...
        double unit1 = valorPorPercentual( symb1, 1.0, 0.01 );
        double unit2 = valorPorPercentual( symb2, 1.0, 0.01 );
        if( unit1 <= 0 || unit2 <= 0 ) return false;

        double minimo1 = SymbolInfoDouble( symb1, SYMBOL_VOLUME_MIN  );
        double passo1  = SymbolInfoDouble( symb1, SYMBOL_VOLUME_STEP );
        double maximo1 = SymbolInfoDouble( symb1, SYMBOL_VOLUME_MAX  );
        double maximo2 = SymbolInfoDouble( symb2, SYMBOL_VOLUME_MAX  );
        if( passo1  <= 0 ) passo1  = 0.01;
        if( minimo1 <= 0 ) minimo1 = passo1;

        double melhor_erro = DBL_MAX;

        for(int n=0; n<max_passos; n++){

            double v1 = normalizarVolume( symb1, minimo1 + n*passo1 );
            if( maximo1 > 0 && v1 > maximo1 ) break;

            double v2 = normalizarVolume( symb2, v1*unit1/unit2 );
            if( maximo2 > 0 && v2 > maximo2 ) break;

            double e = MathAbs( v1*unit1 - v2*unit2 ) / (v1*unit1);
            if( e < melhor_erro ){
                melhor_erro = e;
                vol1        = v1;
                vol2        = v2;
            }
            if( e <= tolerancia ) break; // o menor par que ja atende a tolerancia
        }

        erro = (melhor_erro==DBL_MAX) ? 0 : melhor_erro;
        return ( vol1 > 0 && vol2 > 0 );
    }

    //+--------------------------------------------------------------+
    //| Posicoes                                                      |
    //+--------------------------------------------------------------+

    // +1 comprado, -1 vendido, 0 sem posicao do magico informado no ativo.
    static int direcaoPosicao(const string symb, const ulong magic){
        for(int i=PositionsTotal()-1; i>=0; i--){
            if( !posicaoDoEA(i,symb,magic) ) continue;
            return ( PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ) ? 1 : -1;
        }
        return 0;
    }

    // volume somado das posicoes do magico informado no ativo.
    static double volumePosicao(const string symb, const ulong magic){
        double volume = 0;
        for(int i=PositionsTotal()-1; i>=0; i--){
            if( !posicaoDoEA(i,symb,magic) ) continue;
            volume += PositionGetDouble(POSITION_VOLUME);
        }
        return volume;
    }

    // resultado nao realizado (lucro + swap) das posicoes do magico informado no ativo.
    static double lucroPosicao(const string symb, const ulong magic){
        double lucro = 0;
        for(int i=PositionsTotal()-1; i>=0; i--){
            if( !posicaoDoEA(i,symb,magic) ) continue;
            lucro += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
        }
        return lucro;
    }

    // fecha todas as posicoes do magico informado no ativo. true se nao restou posicao.
    static bool fecharSimbolo(CTrade &trade, const string symb, const ulong magic, const ulong desvio){
        bool ok = true;
        for(int i=PositionsTotal()-1; i>=0; i--){
            if( !posicaoDoEA(i,symb,magic) ) continue;

            ulong ticket = PositionGetInteger(POSITION_TICKET);
            trade.SetTypeFillingBySymbol( symb );
            if( !trade.PositionClose( ticket, desvio ) ){
                Print(":-( ", __FUNCTION__, " falha ao fechar ", symb, " ticket:", ticket,
                              " retcode:", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription() );
                ok = false;
            }
        }
        return ok;
    }

    // envia ordem a mercado para o ativo informado.
    static bool enviarMercado(CTrade &trade, const string symb, const ENUM_ORDER_TYPE tipo,
                              const double volume, const string comentario){
        trade.SetTypeFillingBySymbol( symb );

        bool ok = false;
        if( tipo == ORDER_TYPE_BUY ){
            ok = trade.Buy ( volume, symb, 0.0, 0.0, 0.0, comentario );
        }else{
            ok = trade.Sell( volume, symb, 0.0, 0.0, 0.0, comentario );
        }

        if( !ok ){
            Print(":-( ", __FUNCTION__, " ", symb, " ", EnumToString(tipo), " vol:", volume,
                          " retcode:", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription() );
            return false;
        }

        Print(":-) ", __FUNCTION__, " ", symb, " ", EnumToString(tipo), " vol:", volume,
                      " preco:", trade.ResultPrice() );
        return true;
    }

    //+--------------------------------------------------------------+
    //| Teclado                                                       |
    //+--------------------------------------------------------------+

    // os keystates do terminal devolvem o mesmo codigo da GetKeyState do Windows:
    // o bit mais alto ligado (valor negativo) significa tecla pressionada.
    static bool teclaCtrl (){ return ( TerminalInfoInteger(TERMINAL_KEYSTATE_CONTROL) < 0 ); }
    static bool teclaShift(){ return ( TerminalInfoInteger(TERMINAL_KEYSTATE_SHIFT  ) < 0 ); }

    // TERMINAL_KEYSTATE_MENU corresponde ao VK_MENU do Windows, que eh a tecla ALT
    // (a documentacao da MQL5 chama de tecla "Windows"). Vale conferir no seu ambiente:
    // o EA loga os modificadores detectados quando a combinacao nao confere.
    static bool teclaAlt  (){ return ( TerminalInfoInteger(TERMINAL_KEYSTATE_MENU   ) < 0 ); }

    // true quando exatamente os modificadores pedidos estao pressionados.
    static bool modificadoresPressionados(const bool ctrl, const bool alt, const bool shift){
        return ( teclaCtrl() == ctrl && teclaAlt() == alt && teclaShift() == shift );
    }

    // descricao da combinacao de teclas. Ex: "CTRL+ALT+A"
    static string descreverTecla(const bool ctrl, const bool alt, const bool shift, const int tecla){
        string s = "";
        if( ctrl  ) s += "CTRL+" ;
        if( alt   ) s += "ALT+"  ;
        if( shift ) s += "SHIFT+";
        if( tecla >= 32 && tecla <= 126 ) return s + CharToString((uchar)tecla);
        return s + "(" + IntegerToString(tecla) + ")";
    }

private:
    // a posicao do indice informado pertence ao EA e ao ativo?
    // seleciona a posicao, de modo que PositionGetXXX ja responde por ela.
    static bool posicaoDoEA(const int indice, const string symb, const ulong magic){
        ulong ticket = PositionGetTicket(indice);
        if( ticket == 0                                              ) return false;
        if( PositionGetInteger(POSITION_MAGIC ) != (long)magic       ) return false;
        if( PositionGetString (POSITION_SYMBOL) != symb              ) return false;
        return true;
    }
};
//+------------------------------------------------------------------+
