import time
import numpy as np
import pandas as pd
import statsmodels.api as sm
from statsmodels.tsa.stattools import coint
import MetaTrader5 as mt5

# Constantes de Estado do Par
PAR_FLAT         = 0
PAR_LONG_SPREAD  =  1
PAR_SHORT_SPREAD = -1

class PairsAnalyzer:
    """Equivalente às classes C00021Pairs e CStat do MQL5 para análise estatística[cite: 3, 5]."""
    def __init__(self, symbol1: str, symbol2: str, timeframe, qtd_periodos: int):
        self.symbol1 = symbol1
        self.symbol2 = symbol2
        self.timeframe = timeframe
        self.qtd_periodos = qtd_periodos
        
        self.beta = 0.0
        self.intercept = 0.0
        self.spread_med = 0.0
        self.spread_std = 0.0
        self.zscore = 0.0
        self.coef_correlacao = 0.0
        self.par_eh_cointegrado = False

    def atualizar_dados(self, df1: pd.DataFrame, df2: pd.DataFrame):
        """Atualiza séries temporais, calcula correlação, cointegração e Z-Score."""
        df = pd.merge(df1[['time', 'close']], df2[['time', 'close']], on='time', suffixes=('_1', '_2')).dropna()
        
        if len(df) < self.qtd_periodos:
            return False
            
        # Restringe à janela configurada (últimos N períodos)
        df = df.tail(self.qtd_periodos)
        
        p1 = df['close_1'].values
        p2 = df['close_2'].values
        
        # 1. Correlação de Pearson
        self.coef_correlacao = np.corrcoef(p1, p2)[0, 1]
        
        # 2. Regressão OLS (Engle-Granger) para encontrar Beta e Intercepto
        X = sm.add_constant(p2)
        model = sm.OLS(p1, X).fit()
        self.beta = model.params[1]
        self.intercept = model.params[0]
        
        # 3. Teste de Cointegração ADF via statsmodels
        score, p_value, _ = coint(p1, p2)
        self.par_eh_cointegrado = (p_value < 0.05)
        
        # 4. Geração do Spread (Resíduos da Regressão) e Estatísticas
        spread = p1 - (self.beta * p2 + self.intercept)
        self.spread_med = np.mean(spread)
        self.spread_std = np.std(spread, ddof=1)
        
        # Spread atual (último elemento)
        spread_atual = spread[-1]
        if self.spread_std > 0:
            self.zscore = (spread_atual - self.spread_med) / self.spread_std
        else:
            self.zscore = 0.0
            
        return True


class PairsTradingStrategy:
    """Equivalente à classe C0701StrategyPairsTrading do MQL5[cite: 2]."""
    def __init__(self, params: dict):
        self.params = params
        self.symbol1 = params['symbol1']
        self.symbol2 = params['symbol2']
        self.magic = params['magic']
        
        self.analyzer = PairsAnalyzer(
            self.symbol1, self.symbol2, 
            params['timeframe'], params['qtd_periodos']
        )
        
        self.estado = PAR_FLAT
        self.lucro_par = 0.0
        self.abertura_reg = False
        self.spread_abert = 0.0

    def processar(self):
        """Ciclo principal de execução (equivalente ao processar() do MQL5)[cite: 2]."""
        if not self._carregar_e_atualizar_historico():
            return

        self._reconhecer_posicoes()

        # Verifica Stop Financeiro
        if self.params['stop_financeiro'] > 0 and self.lucro_par <= -self.params['stop_financeiro']:
            self._fechar_par("Stop Financeiro Atingido")
            return

        if self.estado == PAR_FLAT:
            self._verificar_entrada()
        else:
            self._verificar_saida()

    def _carregar_e_atualizar_historico(self):
        """Baixa os dados históricos do MetaTrader 5 para análise."""
        rates1 = mt5.copy_rates_from_pos(self.symbol1, self.params['timeframe'], 0, self.params['qtd_periodos'] * 2)
        rates2 = mt5.copy_rates_from_pos(self.symbol2, self.params['timeframe'], 0, self.params['qtd_periodos'] * 2)
        
        if rates1 is None or rates2 is None:
            return False
            
        df1 = pd.DataFrame(rates1)
        df2 = pd.DataFrame(rates2)
        
        return self.analyzer.atualizar_dados(df1, df2)

    def _verificar_entrada(self):
        """Avalia regras de abertura baseadas nas bandas de Z-Score[cite: 2]."""
        z = self.analyzer.zscore
        corr = self.analyzer.coef_correlacao
        min_corr = self.params['coef_correlacao_min']
        
        if corr < min_corr:
            return

        if z > self.params['desvios_entrada'] and self.analyzer.par_eh_cointegrado:
            # Ativo 1 caro em relação ao ativo 2: Vende spread (Vende 1 / Compra 2)
            self._abrir_par(PAR_SHORT_SPREAD)
            
        elif z < -self.params['desvios_entrada'] and self.analyzer.par_eh_cointegrado:
            # Ativo 1 barato em relação ao ativo 2: Compra spread (Compra 1 / Vende 2)
            self._abrir_par(PAR_LONG_SPREAD)

    def _verificar_saida(self):
        """Avalia regras de fechamento da operação[cite: 2]."""
        z = self.analyzer.zscore
        alvo_saida = self.params['desvios_saida']
        
        if self.estado == PAR_SHORT_SPREAD and z <= alvo_saida:
            self._fechar_par("Retorno ao Alvo de Saida (Short Spread)")
        elif self.estado == PAR_LONG_SPREAD and z >= -alvo_saida:
            self._fechar_par("Retorno ao Alvo de Saida (Long Spread)")

    def _abrir_par(self, direcao: int):
        """Envia ordens para abrir as pernas no MetaTrader 5[cite: 2]."""
        if not self.params['operacao_automatica']:
            print(f"[SIMULADO] Abriria par na direção {direcao}")
            return

        tipo1 = mt5.ORDER_TYPE_BUY if direcao == PAR_LONG_SPREAD else mt5.ORDER_TYPE_SELL
        tipo2 = mt5.ORDER_TYPE_SELL if direcao == PAR_LONG_SPREAD else mt5.ORDER_TYPE_BUY

        # Execução das pernas (simplificada para demonstração)
        self._enviar_ordem(self.symbol1, tipo1, self.params['volume1'])
        self._enviar_ordem(self.symbol2, tipo2, self.params['volume2'])
        
        self.estado = direcao
        self.abertura_reg = True
        self.spread_abert = self.analyzer.spread_med

    def _fechar_par(self, motivo: str):
        """Fecha as posições abertas de ambas as pernas[cite: 2]."""
        print(f"Fechando par ({motivo})...")
        # Implementação de fechamento de posições abertas baseada no Magic Number
        positions = mt5.positions_get(magic=self.magic)
        if positions:
            for pos in positions:
                # Código de fechamento de posição via mt5.order_send()
                pass
        self.estado = PAR_FLAT
        self.abertura_reg = False

    def _reconhecer_posicoes(self):
        """Identifica se já existem posições abertas ativas no terminal (para reinicialização)[cite: 2]."""
        positions = mt5.positions_get(magic=self.magic)
        if not positions or len(positions) == 0:
            self.estado = PAR_FLAT
            self.lucro_par = 0.0
        else:
            self.lucro_par = sum([pos.profit + pos.swap for pos in positions])
            # Lógica para mapear o estado atual com base nas ordens abertas

    def _enviar_ordem(self, symbol, order_type, volume):
        # Estrutura padrão de envio de ordem para a API Python do MT5
        tick = mt5.symbol_info_tick(symbol)
        price = tick.ask if order_type == mt5.ORDER_TYPE_BUY else tick.bid
        request = {
            "action": mt5.TRADE_ACTION_DEAL,
            "symbol": symbol,
            "volume": volume,
            "type": order_type,
            "price": price,
            "deviation": 20,
            "magic": self.magic,
            "comment": "Python Pairs Bot",
            "type_time": mt5.ORDER_TIME_GTC,
            "type_filling": mt5.ORDER_FILLING_FOK,
        }
        return mt5.order_send(request)