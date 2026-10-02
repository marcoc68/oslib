//+------------------------------------------------------------------+
//|                                             Correlation_Rank.mq5 |
//|                                  Copyright 2026, Gemini Notebook |
//+------------------------------------------------------------------+
/*
### Como o script funciona:

1. **`StringSplit`**: Recebe a string de ativos configurável no *input*, separa os nomes por vírgulas e remove espaços indesejados.
2. **Matriz/Array de Vetores (`vector prices[]`)**: Instancia uma lista de vetores MQL5 para armazenar as séries temporais dos preços de fechamento (`COPY_RATES_CLOSE`).
3. **`prices[i].CorrCoef(prices[j])`**: Utiliza o método nativo de álgebra linear do MQL5 para calcular o Coeficiente de Pearson entre todas as combinações de ativos \\(\frac{N(N-1)}{2}\\).
4. **Ordenação e Exibição**: Ordena o *array* de estruturas em ordem decrescente de correlação (de +1.0 para -1.0) e imprime o ranking formatado na aba **Especialistas / Experts** do MetaTrader 5.

> **Dica de uso no MetaTrader 5:** Certifique-se de que todos os ativos da lista estejam adicionados à janela **Observatório do Mercado (Market Watch)** antes de rodar o script, para garantir que o MT5 tenha o histórico de preços baixado.
*/
#include <oslib/osc-trade-util.mqh>
#include <oslib/osc/est/CStat.mqh>

#property script_show_inputs

//--- Parâmetros de Entrada
//input string          InpSymbols   = "EURUSD, GBPUSD, USDJPY, AUDUSD, USDCAD, USDCHF"; // Ativos (separados por vírgula)
//input string          InpSymbols   = "AUDCAD, AUDCHF, AUDJPY, AUDNZD, AUDSGD, AUDUSD, CADCHF, CADJPY, CHFJPY, CHFSGD, EURAUD, EURCAD, EURCHF, EURDKK, EURGBP, EURHKD, EURJPY, EURNOK, EURNZD, EURPLN, EURSEK, EURSGD, EURTRY, EURUSD, EURZAR, GBPAUD, GBPCAD, GBPCHF, GBPDKK, GBPJPY, GBPNOK, GBPNZD, GBPSEK, GBPSGD, GBPTRY, GBPUSD, NOKJPY, NOKSEK, NZDCAD, NZDCHF, NZDJPY, NZDUSD, SEKJPY, SGDJPY, USDCAD, USDCHF, USDCNH, USDCZK, USDDKK, USDHKD, USDHUF, USDJPY, USDMXN, USDNOK, USDPLN, USDSEK, USDSGD, USDTHB, USDTRY, USDZAR"; // Ativos (separados por vírgula)
input string          InpSymbols   = "EURUSD, GBPUSD, USDCHF, USDJPY, USDCAD, AUDUSD"; // Ativos (separados por vírgula)


input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M3;   // Timeframe
input int             InpBars      = 60;        // Quantidade de Barras

// Estrutura para armazenar o par e sua correlação
struct PairCorr
{
   string symbolA;
   string symbolB;
   double correlation;
   double absCorrelation;
   string cointegracao;
};

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart(){
   // 1. Separar a lista de ativos por vírgula
   string symbols[];
   ushort u_sep = StringGetCharacter(",", 0);
   int totalSymbols = StringSplit(InpSymbols, u_sep, symbols);

   // Limpar espaços em branco dos nomes dos ativos
   for(int i = 0; i < totalSymbols; i++)
   {
      StringTrimLeft(symbols[i]);
      StringTrimRight(symbols[i]);
   }

   if(totalSymbols < 2)
   {
      Print("Erro: Insira pelo menos 2 ativos separados por vírgula.");
      return;
   }

   // 2. Carregar os vetores de preços de fechamento (Close) para cada ativo
   vector prices[];
   ArrayResize(prices, totalSymbols);

   int validCount = 0;
   string validSymbols[];
   ArrayResize(validSymbols, totalSymbols);

   for(int i = 0; i < totalSymbols; i++)
   {
      // Tenta copiar os preços históricos para o vetor
      if(prices[validCount].CopyRates(symbols[i], InpTimeframe, COPY_RATES_CLOSE, 0, InpBars))
      {
         validSymbols[validCount] = symbols[i];
         validCount++;
      }
      else
      {
         PrintFormat("Aviso: Não foi possível carregar dados para o ativo '%s'. Verifique se está no Observatório do Mercado.", symbols[i]);
      }
   }

   if(validCount < 2)
   {
      Print("Erro: Menos de 2 ativos válidos para calcular a correlação.");
      return;
   }

   // 3. Calcular a correlação para todas as combinações únicas de pares
   int totalPairs = (validCount * (validCount - 1)) / 2;
   PairCorr pairList[];
   ArrayResize(pairList, totalPairs);

   int pairIndex = 0;
   for(int i = 0; i < validCount - 1; i++)
   {
      for(int j = i + 1; j < validCount; j++)
      {
         pairList[pairIndex].symbolA = validSymbols[i];
         pairList[pairIndex].symbolB = validSymbols[j];
         
         // Cálculo nativo da correlação de Pearson via MQL5 vector
         pairList[pairIndex].correlation    = prices[i].CorrCoef(prices[j]);
         pairList[pairIndex].absCorrelation = MathAbs(pairList[pairIndex].correlation);
         pairList[pairIndex].cointegracao   = calcCointegracao(prices[i],prices[j]);
         pairIndex++;
      }
   }

   // 4. Ordenar a lista da maior correlação para a menor (Selection Sort)
   for(int i = 0; i < totalPairs - 1; i++)
   {
      for(int j = i + 1; j < totalPairs; j++)
      {
         if(pairList[j].absCorrelation > pairList[i].absCorrelation)
         {
            PairCorr temp = pairList[i];
            pairList[i] = pairList[j];
            pairList[j] = temp;
         }
      }
   }

   // 5. Exibir o Ranking de Correlação no Log
   PrintFormat("==================================================");
   PrintFormat(" RANKING DE CORRELAÇÃO DE ATIVOS (%d BARRAS, %s)", InpBars, EnumToString(InpTimeframe));
   PrintFormat(" Total de ativos válidos: %d | Total de pares: %d", validCount, totalPairs);
   PrintFormat("==================================================");

   double pesoLote1, pesoLote2, erro;
   for(int i = 0; i < totalPairs; i++) {

      if( !osc_trade_util::calcVolumesEquilibrio( pairList[i].symbolA, pairList[i].symbolB, pesoLote1, pesoLote2, erro, 0.10 ) ){
          pesoLote1 = 0;
          pesoLote2 = 0;
      }

      PrintFormat("#%02d | %s vs %s : Correlação = %.4f | Lote %s = %.4f | Lote %s = %.4f | %s",
                  i + 1, 
                  pairList[i].symbolA, 
                  pairList[i].symbolB, 
                  pairList[i].correlation,
                  pairList[i].symbolA,
                  pesoLote1,
                  pairList[i].symbolB,
                  pesoLote2,
                  pairList[i].cointegracao);
   }
   PrintFormat("==================================================");
}

string calcCointegracao(vector &prices1, vector &prices2){
    double betaOut, tStatOut;
    bool isCointegratedOut;
    string explicacao = "tStudent deve ser < que -2.86";
    string retorno = "ERRO AO_CALCULAR_COINTEGRACAO";

    if(CStat::testarCointegracaoADF( prices1,
                                  prices2,
                                  betaOut,
                                  tStatOut,
                                  isCointegratedOut)){
        retorno = "tStudent=" + DoubleToString(tStatOut, 2) + " | " + (isCointegratedOut ? "COINTEGRADOS" : "NAO_COINTEGRADOS | " + explicacao);
    }
    return retorno;
}