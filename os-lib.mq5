//+------------------------------------------------------------------+
//|                                                   os-lib.mqh.mq5 |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property library
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"
//+------------------------------------------------------------------+
//| My function                                                      |
//+------------------------------------------------------------------+
// int MyCalculator(int value,int value2) export
//   {
//    return(value+value2);
//   }
//+------------------------------------------------------------------+
#include "osc-ind-minion-feira.mqh"
double oneIfZero(double p) {return (p==0.0)?1.0:p;}



//+------------------------------------------------------------------+ 
//| Criar a linha horizontal                                         | 
//+------------------------------------------------------------------+ 
bool HLineCreate(const long            chart_ID=0,        // ID de grafico 
                 const string          name="HLine",      // nome da linha 
                 const int             sub_window=0,      // índice da sub-janela 
                 double                price=0,           // line price 
                 const color           clr=clrRed,        // cor da linha 
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // estilo da linha 
                 const int             width=1,           // largura da linha 
                 const bool            back=true,        // no fundo 
                 const bool            selection=false,   // destaque para mover 
                 const bool            hidden=false,      // ocultar na lista de objetos 
                 const long            z_order=0        ) // prioridade para clique do mouse 
  { 
  
   //Print(__FUNCTION__);


   if(!price) price=SymbolInfoDouble(Symbol(),SYMBOL_BID); //--- se o preco nao esta definido, defina-o no atual nível de preco Bid 

   ResetLastError(); //--- redefine o valor de erro 

//--- criar uma linha horizontal 
   if(!ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price)) { 
      Print(__FUNCTION__, ": falha ao criar um linha horizontal! Codigo de erro = ",GetLastError()); 
      return(false); 
   } 
   
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); //--- definir cor da linha 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style); //--- definir o estilo de exibicao da linha 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width); //--- definir a largura da linha 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK ,back); //--- exibir em primeiro plano (false) ou fundo (true) 

   //--- habilitar (true) ou desabilitar (false) o modo do movimento da seta com o mouse 
   //--- ao criar um objeto grafico usando a funcao ObjectCreate, o objeto nao pode ser 
   //--- destacado e movimentado por padrao. Dentro deste metodo, o parametro de selecao 
   //--- e verdade por padrao, tornando possível destacar e mover o objeto 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 

   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); //--- ocultar (true) ou exibir (false) o nome do objeto grafico na lista de objeto  
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); //--- definir a prioridade para receber o evento com um clique do mouse no grafico 
   
   //--- sucesso na execucao 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Mover linha horizontal                                           | 
//+------------------------------------------------------------------+ 
bool HLineMove(const long   chart_ID=0      ,  // ID do grafico 
               const string name    ="HLine",  // nome da linha 
               double       price   =0      ){ // preco da linha 
   //Print(__FUNCTION__);

   //--- se o preco nao estah definido, defina-o no atual nivel de preco Bid 
   if(!price) price=SymbolInfoDouble(Symbol(),SYMBOL_BID); 
   
   ResetLastError(); //--- redefine o valor de erro 

//--- mover um linha horizontal  
   if(!ObjectMove(chart_ID,name,0,0,price)) { 
      Print(__FUNCTION__, ": falha ao mover um linha horizontal! Codigo de erro = ",GetLastError()); 
      return(false); 
   } 

   return(true); //--- sucesso na execucao 
} 
//+------------------------------------------------------------------+ 
//| Excluir uma linha horizontal                                     | 
//+------------------------------------------------------------------+ 
bool HLineDelete(const long   chart_ID=0,   // ID do grafico 
                 const string name="HLine") // nome da linha 
  { 
//--- redefine o valor de erro 
   ResetLastError(); 
//--- excluir uma linha horizontal 
   if(!ObjectDelete(chart_ID,name)) 
     { 
      Print(__FUNCTION__, 
            ": falha ao Excluir um linha horizontal! Codigo de erro = ",GetLastError()); 
      return(false); 
     } 
//--- sucesso na execucao 
   return(true); 
  } 
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+ 
//| Criar a linha vertical                                           | 
//+------------------------------------------------------------------+ 
bool VLineCreate(const long            chart_ID=0,        // ID do grafico 
                 const string          name="VLine",      // nome da linha 
                 const int             sub_window=0,      // índice da sub-janela 
                 datetime              time=0,            // tempo da linha 
                 const color           clr=clrRed,        // cor da linha 
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // estilo da linha 
                 const int             width=1,           // largura da linha 
                 const bool            back=true,         // no fundo 
                 const bool            selection=false,   // destaque para mover 
                 const bool            ray=true,          // continuacao da linha para baixo 
                 const bool            hidden=false,      //ocultar na lista de objetos 
                 const long            z_order=0)         // prioridade para clique do mouse 
  { 
//--- se o tempo de linha nao esta definido, desenha-lo atraves da última barra 
   if(!time) 
      time=TimeCurrent(); 
//--- redefine o valor de erro 
   ResetLastError(); 
//--- criar uma linha vertical 
   if(!ObjectCreate(chart_ID,name,OBJ_VLINE,sub_window,time,0)) 
     { 
      Print(__FUNCTION__, 
            ": falha ao criar uma linha vertical! Codigo de erro = ",GetLastError()); 
      return(false); 
     } 
//--- definir cor da linha 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
//--- definir o estilo de exibicao da linha 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style); 
//--- definir a largura da linha 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width); 
//--- exibir em primeiro plano (false) ou fundo (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
//--- habilitar (true) ou desabilitar (false) o modo do movimento da seta com o mouse 
//--- ao criar um objeto grafico usando a funcao ObjectCreate, o objeto nao pode ser 
//--- destacado e movimentado por padrao. Dentro deste metodo, o parâmetro de selecao 
//--- e verdade por padrao, tornando possível destacar e mover o objeto 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
//--- habilitar (verdadeiro) ou desabilitar (falso) o modo de exibicao da linha no grafico sub-janelas 
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY,ray); 
//--- ocultar (true) ou exibir (false) o nome do objeto grafico na lista de objeto  
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
//--- definir a prioridade para receber o evento com um clique do mouse no grafico 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
//--- sucesso na execucao 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Mover a linha vertical                                           | 
//+------------------------------------------------------------------+ 
bool VLineMove(const long   chart_ID=0,   // ID do grafico 
               const string name="VLine", // nome da linha 
               datetime     time=0)       // tempo da linha 
  { 
//--- se o tempo de linha nao esta definido, mover a linha para a última barra 
   if(!time) 
      time=TimeCurrent(); 
//--- redefine o valor de erro 
   ResetLastError(); 
//--- mover a linha vertical 
   if(!ObjectMove(chart_ID,name,0,time,0)) 
     { 
      Print(__FUNCTION__, 
            ": falhou ao mover a linha vertical! Codigo de erro = ",GetLastError()); 
      return(false); 
     } 
//--- sucesso na execucao 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Excluir a linha vertical                                         | 
//+------------------------------------------------------------------+ 
bool VLineDelete(const long   chart_ID=0,   // ID do grafico 
                 const string name="VLine") // nome da linha 
  { 
//--- redefine o valor de erro 
   ResetLastError(); 
//--- excluir a linha vertical 
   if(!ObjectDelete(chart_ID,name)) 
     { 
      Print(__FUNCTION__, 
            ": falha ao deletar a linha vertical! Codigo de erro = ",GetLastError()); 
      return(false); 
     } 
//--- sucesso na execucao 
   return(true); 
}

string TimeMscToString(long time_in_milis, int flags=TIME_SECONDS){
    datetime time_in_seconds = (datetime)(time_in_milis/1000);
    int      mili            = (int     )(time_in_milis%1000);
    
    return TimeToString(time_in_seconds,flags) + "," + IntegerToString(mili);
}