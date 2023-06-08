//+--------------------------------------------------------------------------------+
//|                                                     osc-coef-entrelacameto.mqh |
//|                                                                         marcoc |
//|                                           https://www.mql5.com/pt/users/marcoc |
//+--------------------------------------------------------------------------------+
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"
//+---------------------------------------------------------------------+
//| Calculo e administracao do coefiente de entrelacamento              |
//+---------------------------------------------------------------------+

#include <oslib\osc-padrao.mqh>
#include <oslib\osc-vetor-circular2.mqh>

class osc_coef_entrelacamento : public osc_padrao {
private:
    osc_vetor_circular2 m_vetCoef;
    double m_minAnt,m_maxAnt;

    double calcCoefEntrelacamento(double minAnt, double maxAnt, double minAtu, double maxAtu);
    bool   add (double min, double max, double peso);
   
public:
    bool initialize ( int qtdPeriodos );

/*
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
*/   
};

bool osc_coef_entrelacamento::initialize ( int qtdPeriodos ){
    m_minAnt=0;m_maxAnt=0;
    return m_vetCoef.initialize(qtdPeriodos);
}



//|--------------------------------------------------------------------------------
//| O coeficiente de entrelacamento eh a porcentagem de intersecao do preco da barra
//| atual em relacao a barra anterior. 
//|
//| Ant   ----------
//| Atu        -------
//| Int        xxxxx
//|
//| Ant    ----------
//| Atu  -------
//| Int    xxxxx
//|
//| Ant    ----------
//| Atu     -------
//| Int     xxxxxxx
//|
//| Ant    ----------
//| Atu               -------
//| Int             
//|
//| Ant    ----------
//| Atu ---
//| Int    
//|
//|--------------------------------------------------------------------------------
double osc_coef_entrelacamento::calcCoefEntrelacamento(double minAnt, double maxAnt, double minAtu, double maxAtu){
   
   double pontosEntre = 0;
   
   // minimo da barra atual estah na barra anterior...
   if( minAtu >= minAnt && minAtu <= maxAnt ){
   
       if( maxAtu > maxAnt ){ 
           // ---------
           //     ---------
           //     xxxxx
           pontosEntre = maxAnt - minAtu;
       }else{
           // ---------
           //     -----
           //     xxxxx
           pontosEntre = maxAtu - minAtu;
       }
   }else{
       // maximo da barra atual estah na barra anterior...
       if( maxAtu >= minAnt && maxAtu <= maxAnt ){
       
           if( minAtu < minAnt ){ 
               //         ---------
               //     ---------
               //         xxxxx
               pontosEntre = maxAtu - minAnt;
           }else{
               // ---------
               // -----
               // xxxxx
               pontosEntre = maxAtu - minAtu;
           }
       }
   }
   
   if(maxAtu-minAtu == 0) return 0;
   
   return pontosEntre/(maxAtu-minAtu);   
}

bool osc_coef_entrelacamento::add(double min, double max, double peso){

    double coef = calcCoefEntrelacamento(m_minAnt,m_maxAnt,min,max);
    return m_vetCoef.add(coef);
}
