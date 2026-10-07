//+------------------------------------------------------------------+
//|                                                      CLog.mqh |
//|                                  Copyright 2026, MetaTrader 5    |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026"
#property link      "https://www.mql5.com"
#property version   "1.00"

enum ENUM_LOG_LEVEL { INFO, WARNING, ERROR };

class Log {
private:
   static string m_fileName;
   static bool   m_initialized;

   // Inicializa o nome do arquivo exclusivo para a sessão atual do terminal/gráfico
   static void InitializeSession() {
      if(m_initialized) return;

      // Obtém o momento exato em que o terminal/programa iniciou nesta sessão
      datetime now = TimeLocal();
      string timeStr = TimeToString(now, TIME_DATE|TIME_SECONDS);
      StringReplace(timeStr, ".", "");
      StringReplace(timeStr, ":", "");
      StringReplace(timeStr, " ", "_");

      // O arquivo será único por Gráfico/Ativo e por Sessão de Inicialização do Terminal
      m_fileName = "Logs\\Log_" + _Symbol + "_" + IntegerToString(ChartID()) + "_" + timeStr + ".log";
      m_initialized = true;
   }

public:

   static void info   (string message, string source = "", bool logExpert=false) { write(message, INFO   , source, logExpert); }
   static void infoExp(string message, string source = "", bool logExpert=true ) { write(message, INFO   , source, logExpert); }
   static void warn   (string message, string source = "", bool logExpert=true ) { write(message, WARNING, source, logExpert); }
   static void error  (string message, string source = "", bool logExpert=true ) { write(message, ERROR  , source, logExpert); }

   // Método estático universal para gravar logs de qualquer lugar
   static void write(string message, ENUM_LOG_LEVEL level = INFO, string source = "", bool logExpert=false) {
      InitializeSession();

      // Abre o arquivo em modo de escrita, leitura e texto, utilizando flags de compartilhamento
      // para permitir que o EA, indicadores e classes escrevam simultaneamente sem conflito.
      int handle = FileOpen(m_fileName, FILE_WRITE|FILE_READ|FILE_TXT|FILE_SHARE_READ|FILE_SHARE_WRITE);
      
      if(handle != INVALID_HANDLE) {
         // Posiciona o cursor no final do arquivo para anexar (Append) as novas linhas
         FileSeek(handle, 0, SEEK_END);

         string levelStr = "INFO";
         if(level == WARNING) levelStr = "WARN";
         if(level == ERROR)   levelStr = "ERROR";

         string timestamp = TimeToString(TimeLocal(), TIME_DATE|TIME_SECONDS);
         string origin = (source != "") ? source : "General";

         // Monta a linha de log formatada
         string logLine = StringFormat("[%s] [%s] [%s] %s", timestamp, levelStr, origin, message);

         // Imprime no log do MetaTrader se for log de Expert
         if(logExpert){ Print(logLine); }

         logLine += "\n";
         FileWriteString(handle, logLine);
         FileClose(handle);
      } else {
         Print("CLog: Erro crítico ao abrir arquivo de log. Erro: ", _LastError);
      }
   }
};

// Declaração obrigatória das variáveis estáticas fora da classe
string Log::m_fileName = "";
bool   Log::m_initialized = false;
