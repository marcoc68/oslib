﻿//+------------------------------------------------------------------+
//|                                                     osc-util.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"
//+---------------------------------------------------------------------+
//| Informacoes uteis sobre o ambiente de execucao                      |
//+---------------------------------------------------------------------+

#include <oslib/osc-padrao.mqh>

class osc_util : public osc_padrao {
private:
public:
   //--- memoria
   static int getTermMemFisica(){ return TerminalInfoInteger(TERMINAL_MEMORY_PHYSICAL ); }//Memória física no sistema, MB
   static int getTermMemTotal (){ return TerminalInfoInteger(TERMINAL_MEMORY_TOTAL    ); }//Memória disponível para o processo do terminal (agente), MB
   static int getTermMemDisp  (){ return TerminalInfoInteger(TERMINAL_MEMORY_AVAILABLE); }//Memória livre do processo do terminal (agente), MB
   static int getTermMemUsada (){ return TerminalInfoInteger(TERMINAL_MEMORY_USED     ); }//Memória usada pelo terminal (agente), MB

   //--- cpu
   static int getTermCpuCores       (){ return TerminalInfoInteger(TERMINAL_CPU_CORES     ); }//O número de núcleos de CPU no sistema
   static int getTermCpuX64         (){ return TerminalInfoInteger(TERMINAL_X64           ); }//Indicação do "terminal 64-bit"
   static int getTermCpuOpenClSuport(){ return TerminalInfoInteger(TERMINAL_OPENCL_SUPPORT); }//A versão do OpenCL suportado no formato 0x00010002 = 1.2.  "0" significa que OpenCL não é suportado

   //--- disco
   static int getTermDiskSpace(){ return TerminalInfoInteger(TERMINAL_DISK_SPACE); }//Espaço livre de disco para a pasta MQL5\Files do terminal (agente), MB

   //--- retorno em formato string das funcoes acima
   static string getTermMemFisicaStr      (){ return IntegerToString( getTermMemFisica      () ); }//Memória física no sistema, MB
   static string getTermMemTotalStr       (){ return IntegerToString( getTermMemTotal       () ); }//Memória disponível para o processo do terminal (agente), MB
   static string getTermMemDispStr        (){ return IntegerToString( getTermMemDisp        () ); }//Memória livre do processo do terminal (agente), MB
   static string getTermMemUsadaStr       (){ return IntegerToString( getTermMemUsada       () ); }//Memória usada pelo terminal (agente), MB
   static string getTermCpuCoresStr       (){ return IntegerToString( getTermCpuCores       () ); }//O número de núcleos de CPU no sistema
   static string getTermCpuX64Str         (){ return IntegerToString( getTermCpuX64         () ); }//Indicação do "terminal 64-bit"
   static string getTermCpuOpenClSuportStr(){ return IntegerToString( getTermCpuOpenClSuport() ); }//A versão do OpenCL suportado no formato 0x00010002 = 1.2.  "0" significa que OpenCL não é suportado
   static string getTermDiskSpaceStr      (){ return IntegerToString( getTermDiskSpace      () ); }//Espaço livre de disco para a pasta MQL5\Files do terminal (agente), MB
   
    // divide numerador por denominador. retorna default caso o denominador seja zero.
    static double div(double _num, double _den, double _default){ 
        if(_den==0) return _default;
        return _num/_den;
    }
};
