import time
import numpy as np
import statsmodels.api as sm
import MetaTrader5 as mt5

# Constantes de Estado
PAR_FLAT         = 0
PAR_LONG_SPREAD  = 1
PAR_SHORT_SPREAD = -1

class RollingBuffer:
    """Buffer Circular genérico com vetor único e capacidade fixa (reutilizável em indicadores e estratégias)."""
    def __init__(self, capacity: int = 10):
        self.capacity = capacity if capacity > 0 else 10
        self.buffer = np.zeros(self.capacity, dtype=np.float64)
        self.head = 0
        self.tail = 0
        self.size = 0

    def add(self, value: float):
        """Adiciona um novo elemento. Se cheio, sobrescreve o mais antigo."""
        self.buffer[self.tail] = value
        self.tail = (self.tail + 1) % self.capacity
        
        if self.size < self.capacity:
            self.size += 1
        else:
            self.head = (self.head + 1) % self.capacity

    def set_last(self, value: float):
        """Atualiza o valor do elemento mais recente (útil para atualizações na mesma barra/tick)."""
        if self.size == 0:
            self.add(value)
            return
        actual_index = (self.head + self.size - 1) % self.capacity
        self.buffer[actual_index] = value

    def at(self, index: int) -> float:
        """Acessa o elemento por índice lógico (0 = mais antigo, size-1 = mais recente)."""
        if index < 0 or index >= self.size:
            return 0.0
        actual_index = (self.head + index) % self.capacity
        return self.buffer[actual_index]

    def to_numpy(self) -> np.ndarray:
        """Retorna os dados ordenados do mais antigo para o mais recente em um array NumPy."""
        result = np.zeros(self.size, dtype=np.float64)
        for i in range(self.size):
            result[i] = self.at(i)
        return result

    def clear(self):
        """Limpa o buffer."""
        self.head = 0
        self.tail = 0
        self.size = 0
        self.buffer.fill(0.0)

    def is_full(self) -> bool:
        return self.size == self.capacity


class RollingBufferPair:
    """Gerencia dois RollingBuffers de preços e sincroniza timestamps para estratégias de pares."""
    def __init__(self, capacity: int):
        self.capacity = capacity
        self.buf1 = RollingBuffer(capacity)
        self.buf2 = RollingBuffer(capacity)
        self.timestamps = RollingBuffer(capacity)

    def inicializar(self, precos1, precos2, times):
        """Popula os buffers com o histórico inicial (Warm-up)."""
        self.buf1.clear()
        self.buf2.clear()
        self.timestamps.clear()
        
        for p1, p2, t in zip(precos1, precos2, times):
            self.buf1.add(p1)
            self.buf2.add(p2)
            self.timestamps.add(float(t))

    def atualizar_ou_adicionar(self, p1: float, p2: float, t: int) -> bool:
        """
        Verifica se o timestamp é o mesmo da última barra (atualização de tick/mesma barra) 
        ou se é uma nova barra. Retorna True se for uma nova barra inserida.
        """
        ultimo_t = int(self.timestamps.at(self.timestamps.size - 1)) if self.timestamps.size > 0 else 0
        
        if self.timestamps.size > 0 and ultimo_t == t:
            self.buf1.set_last(p1)
            self.buf2.set_last(p2)
            return False
        else:
            self.buf1.add(p1)
            self.buf2.add(p2)
            self.timestamps.add(float(t))
            return True

    def esta_cheio(self) -> bool:
        return self.buf1.is_full() and self.buf2.is_full()

    def get_arrays(self):
        """Retorna os arrays NumPy sincronizados dos dois ativos."""
        return self.buf1.to_numpy(), self.buf2.to_numpy()


class OptimizedPairsStrategy:
    """Estratégia de Pairs Trading utilizando RollingBufferPair e execução incremental."""
    def __init__(self, params: dict):
        self.params = params
        self.symbol1 = params['symbol1']
        self.symbol2 = params['symbol2']
        self.timeframe = params['timeframe']
        self.qtd_periodos = params['qtd_periodos']
        self.magic = params['magic']
        
        self.buffer_par = RollingBufferPair(capacity=self.qtd_periodos)
        self.estado = PAR_FLAT
        self._carregar_historico_inicial()

    def _carregar_historico_inicial(self):
        """Baixa o histórico do MT5 uma única vez para preencher os buffers."""
        rates1 = mt5.copy_rates_from_pos(self.symbol1, self.timeframe, 0, self.qtd_periodos)
        rates2 = mt5.copy_rates_from_pos(self.symbol2, self.timeframe, 0, self.qtd_periodos)
        
        if rates1 is None or rates2 is None or len(rates1) < self.qtd_periodos:
            print(f"Erro ao carregar histórico inicial para {self.symbol1} e {self.symbol2}")
            return

        precos1 = [r['close'] for r in rates1]
        precos2 = [r['close'] for r in rates2]
        times = [r['time'] for r in rates1]
        
        self.buffer_par.inicializar(precos1, precos2, times)
        print(f"Par {self.symbol1}-{self.symbol2} inicializado com sucesso ({self.buffer_par.buf1.size} amostras).")

    def processar(self):
        """Ciclo principal executado de forma incremental a cada 250ms."""
        if not self.buffer_par.esta_cheio():
            return

        # Busca apenas a barra/preço mais recente do MT5 (posição 0)
        rates1 = mt5.copy_rates_from_pos(self.symbol1, self.timeframe, 0, 1)
        rates2 = mt5.copy_rates_from_pos(self.symbol2, self.timeframe, 0, 1)
        
        if rates1 is None or rates2 is None:
            return

        p1 = rates1[0]['close']
        p2 = rates2[0]['close']
        t_atual = rates1[0]['time']

        # Atualiza o buffer de forma incremental
        nova_barra = self.buffer_par.atualizar_ou_adicionar(p1, p2, t_atual)

        # Extrai os arrays para cálculo estatístico em memória
        p1_arr, p2_arr = self.buffer_par.get_arrays()
        
        # Regressão OLS (Engle-Granger)
        X = sm.add_constant(p2_arr)
        model = sm.OLS(p1_arr, X).fit()
        beta = model.params[1]
        intercept = model.params[0]
        
        # Cálculo de Spread e Z-Score
        spread = p1_arr - (beta * p2_arr + intercept)
        spread_med = np.mean(spread)
        spread_std = np.std(spread, ddof=1)
        
        spread_atual = spread[-1]
        zscore = (spread_atual - spread_med) / spread_std if spread_std > 0 else 0.0

        if nova_barra:
            print(f"[{self.symbol1}-{self.symbol2}] Barra fechada | Z-Score: {zscore:.2f} | Beta: {beta:.4f}")


# Bloco de Execução Principal (Exemplo)
if __name__ == "__main__":
    if not mt5.initialize():
        print("Falha ao inicializar o MetaTrader 5")
        quit()

    params_exemplo = {
        'symbol1': "EURUSD",
        'symbol2': "GBPUSD",
        'timeframe': mt5.TIMEFRAME_M3,
        'qtd_periodos': 120,
        'coef_correlacao_min': 0.95,
        'desvios_entrada': 2.5,
        'desvios_saida': 0.5,
        'volume1': 0.01,
        'volume2': 0.01,
        'operacao_automatica': True,
        'magic': 260908001000
    }

    estrategia = OptimizedPairsStrategy(params_exemplo)

    print("Iniciando loop de processamento (250ms). Pressione Ctrl+C para parar.")
    try:
        while True:
            estrategia.processar()
            time.sleep(0.25) # Intervalo de 250 milissegundos
    except KeyboardInterrupt:
        print("Encerrando execução...")
        mt5.shutdown()