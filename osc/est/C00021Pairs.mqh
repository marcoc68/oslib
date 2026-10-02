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
#include <oslib\osc\osc-media2.mqh>

class C00021Pairs{
private:
    double           m_spread    ;
    double           m_spread_std;
    double           m_spread_med;
    uint             m_qtd_seg_entre_ocorrencias;
    uint             m_qtd_ocorrencias;
    osc_media        m_vet_ativo1; // vetor de precos do ativo 1
    osc_media        m_vet_ativo2; // vetor de precos do ativo 2
    osc_media        m_vet_spread; // vetor de spreads deve ter o tamanho da quantidade de segundos
                                   // usados no calculo da media do spread. Eh uma janela.
protected:
public:
     // default sao 60 ocorrencias com uma a cada minuto.
     C00021Pairs(uint qtd_ocorrencias=60, uint qtd_seg_entre_ocorrencias=60){
         initialize(qtd_ocorrencias, qtd_seg_entre_ocorrencias);
     }
    ~C00021Pairs(){}

    double getSpread   (){ return m_spread    ; } // spread instantaneo   
    double getSpreadStd(){ return m_spread_std; } // desvio padrao do spread
    double getSpreadMed(){ return m_spread_med; } // media do spread
    uint   getQtdSegMedia() { return m_qtd_seg_entre_ocorrencias; }

    // inicializacao antes de comecar a acumular.
    // deve informar a quantidade de segundos usados do calculo da media dos spreads.
    // se nao informar, calcularah a media da ultima hora de spreads.
    void initialize(uint qtd_ocorrencias=60, uint qtd_seg_entre_ocorrencias=60){ 
        
        m_vet_ativo1.initialize(qtd_ocorrencias,qtd_seg_entre_ocorrencias);
        m_vet_ativo2.initialize(qtd_ocorrencias,qtd_seg_entre_ocorrencias);
        m_vet_spread.initialize(qtd_ocorrencias,qtd_seg_entre_ocorrencias);
        
        m_qtd_seg_entre_ocorrencias = qtd_seg_entre_ocorrencias;
        m_qtd_ocorrencias           = qtd_ocorrencias;
        m_spread                    = 0;
        m_spread_std                = 0;                
        m_spread_med                = 0;                
    }
    
    void initialize(uint qtd_ocorrencias=60, ENUM_TIMEFRAMES TIMEFRAME=PERIOD_CURRENT){ 
        initialize(qtd_ocorrencias, PeriodSeconds(TIMEFRAME));
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

        double logp1 = log(p1);
        double logp2 = log(p2);
        double spread = logp1 - logp2;
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

        //m_vet_spread.add(m_spread,t1.time); // por enquanto usamos a data ativo1, mas provavelmente
        //                                    // passaremos a usar a data mais recente entre os dois
        //                                    // ativos. Isto serah para evitar o problema causado
        //                                    // quando um dos ativos tem muito mais transações que 
        //                                    // o outro.
        if( m_vet_spread.add(m_spread,t) ){
            m_vet_spread.calcVar();
            m_spread_med = m_vet_spread.getMed();
            m_spread_std = sqrt( m_vet_spread.getVar() );

            m_vet_ativo1.add(p1,t);
            m_vet_ativo2.add(p2,t);
            
            //m_vet_spread.print();
        }

        return m_spread;
    }

    double calcCoefCorr(){ return m_vet_ativo1.calcCoefCorr(m_vet_ativo2); }

    bool parEhCointegrado(){ return m_vet_ativo1.ehCointegradoCom(m_vet_ativo2); }

    double getSpreadStd(double shift){ return getSpreadMed()+getSpreadStd()*shift; }
    
    double regLinFit  (){return m_vet_spread.regLinFit     ();}
    double regLinSlope(){return m_vet_spread.regLinGetSlope();}

    double getLast(MqlTick& tick){
       if(tick.last > 0                ){ return tick.last; }
       if(tick.bid  > 0 && tick.ask > 0){ return (tick.bid+tick.ask)/2; }
       if(tick.ask  > 0                ){ return tick.ask; }
                                          return tick.bid;
    }

    static string buscarParAdequado(string symbol, string InpSymbols, int InpBars, ENUM_TIMEFRAMES InpTimeframe=PERIOD_CURRENT) {

       // Estrutura para armazenar o par e sua correlação
       struct PairCorr {
          string symbolA;
          string symbolB;
          double correlation;
          double absCorrelation;
          bool   saoCointegrados;
       };

       // 1. Separar a lista de ativos por vírgula
       string symbols[];
       ushort u_sep = StringGetCharacter(",", 0);
       int totalSymbols = StringSplit(InpSymbols, u_sep, symbols);

       // Limpar espaços em branco dos nomes dos ativos
       for(int i = 0; i < totalSymbols; i++){
          StringTrimLeft(symbols[i]);
          StringTrimRight(symbols[i]);
       }

       if(totalSymbols < 1){ return "PAR_CANDIDATO_NAO_INFORMADO"; }
       if(totalSymbols < 2){ return symbols[0]; }

       // 2. Carregar os vetores de preços de fechamento (Close) para cada ativo
       vector prices[];
       ArrayResize(prices, totalSymbols);

       int validCount = 0;
       string validSymbols[];
       ArrayResize(validSymbols, totalSymbols);

       for(int i = 0; i < totalSymbols; i++){
          // Tenta copiar os preços históricos para o vetor
          if(prices[validCount].CopyRates(symbols[i], InpTimeframe, COPY_RATES_CLOSE, 0, InpBars)) {
             validSymbols[validCount] = symbols[i];
             validCount++;
          }else{
             PrintFormat("Aviso: Não foi possível carregar dados para o ativo '%s'. Verifique se está na Observação do Mercado.", symbols[i]);
          }
       }

       if(validCount < 1){ return "COTACOES_NAO_ENCONTRADAS_PARA_OS_PARES_CANDIDATO"; }
       if(validCount < 2){ return validSymbols[0]; }

       // 3. Calcular a correlação para todas as combinações com o ativo informado
       int totalPairs = (validCount * (validCount - 1)) / 2;
       PairCorr pairList[];
       ArrayResize(pairList, totalPairs);

       int pairIndex = 0;
       for(int i = 0; i < validCount - 1; i++) {
          for(int j = i + 1; j < validCount; j++) {
             pairList[pairIndex].symbolA = validSymbols[i];
             pairList[pairIndex].symbolB = validSymbols[j];

             // Cálculo nativo da correlação de Pearson via MQL5 vector
             pairList[pairIndex].correlation    = prices[i].CorrCoef(prices[j]);
             pairList[pairIndex].absCorrelation = MathAbs(pairList[pairIndex].correlation);
             pairList[pairIndex].saoCointegrados = CStat::parEhCointegrado(prices[i], prices[j]);
             pairIndex++;
          }
       }

       // 4. Ordenar a lista da maior correlação para a menor (Selection Sort)
       for(int i = 0; i < totalPairs - 1; i++){
          for(int j = i + 1; j < totalPairs; j++){
             if(pairList[j].absCorrelation > pairList[i].absCorrelation){
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

      // 6. Procurar o par mais adequado para o ativo informado. Se achar um cointegrado, dah prioridade a ele. Se nao achar, retorna o par com maior correlacao.
       for(int i = 0; i < totalPairs; i++) {

           if( pairList[i].saoCointegrados && (pairList[i].symbolA == symbol || pairList[i].symbolB == symbol) ) {
                PrintFormat("Par Cointegrado: %s - %s | Correlação: %.4f", pairList[i].symbolA, pairList[i].symbolB, pairList[i].correlation);
              if(pairList[i].symbolA == symbol)
                return pairList[i].symbolB;
              else
                return pairList[i].symbolA;
           }
       }

       // Nao achou um cointegrado... Busca o maior correlacionado.
       for(int i = 0; i < totalPairs; i++) {

           if( pairList[i].symbolA == symbol || pairList[i].symbolB == symbol ) {
                PrintFormat("Par nao Cointegrado: %s - %s | Correlação: %.4f", pairList[i].symbolA, pairList[i].symbolB, pairList[i].correlation);
              if(pairList[i].symbolA == symbol)
                return pairList[i].symbolB;
              else
                return pairList[i].symbolA;
           }
       }
       return "PAR_NAO_ENCONTRADO";
    }
};
