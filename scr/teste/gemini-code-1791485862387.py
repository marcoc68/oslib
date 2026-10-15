if __name__ == "__main__":
    if not mt5.initialize():
        print("Falha ao inicializar o MetaTrader 5")
        quit()

    # Listas de candidatos idênticas às do seu input MQL5
    candidatos1 = ["EURUSD", "GBPUSD", "USDCHF", "USDJPY", "USDCAD", "AUDUSD"]
    candidatos2 = ["AUDNZD", "AUDCAD", "AUDCHF", "AUDJPY", "CHFJPY", "EURGBP"]

    # Parâmetros base compartilhados
    params = {
        'timeframe': mt5.TIMEFRAME_M3,
        'qtd_periodos': 60,
        'coef_correlacao_min': 0.80,
        'desvios_entrada': 3.0,
        'desvios_saida': 0.0,
        'volume1': 0.01,
        'volume2': 0.01,
        'stop_financeiro': 0.0,
        'operacao_automatica': True
    }

    # Inicializa o gerenciador de múltiplos pares
    gerenciador = MultiPairsManager(candidatos1, candidatos2, params)

    # Inicia a varredura a cada 250 milissegundos
    gerenciador.executar_loop(intervalo_ms=250)

    mt5.shutdown()