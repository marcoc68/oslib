﻿//+------------------------------------------------------------------+
//|                                                      ex-Edit.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

//--- descrição 
#property description "Script cria objeto \"Edit\"." 
//--- janela de exibição dos parâmetros de entrada durante inicialização do script 
#property script_show_inputs 
//--- entrada de parâmetros do script 
input string           InpName="Edit";              // Nome do objeto 
input string           InpText="Text";              // Texto de objeto 
input string           InpFont="Arial";             // Fonte 
input int              InpFontSize=14;              // Tamanho da fonte 
input ENUM_ALIGN_MODE  InpAlign=ALIGN_CENTER;       // Tipo de alinhamento de texto 
input bool             InpReadOnly=false;           // Habilidade de editar 
input ENUM_BASE_CORNER InpCorner=CORNER_LEFT_UPPER; // Canto do gráfico para ancoragem 
input color            InpColor=clrBlack;           // Cor do texto 
input color            InpBackColor=clrWhite;       // Fundo da cor 
input color            InpBorderColor=clrBlack;     // Cor da borda 
input bool             InpBack=false;               // Objeto de Fundo 
input bool             InpSelection=false;          // Destaque para mover 
input bool             InpHidden=true;              // Ocultar na lista de objeto 
input long             InpZOrder=0;                 // Prioridade para clique do mouse 
//+------------------------------------------------------------------+ 
//| Criar o objeto Edit                                              | 
//+------------------------------------------------------------------+ 
bool EditCreate(const long             chart_ID=0,               // ID do gráfico 
                const string           name="Edit",              // nome do objeto 
                const int              sub_window=0,             // índice da sub-janela 
                const int              x=0,                      // coordenada X 
                const int              y=0,                      // coordenada Y 
                const int              width=50,                 // largura 
                const int              height=18,                // altura 
                const string           text="Text",              // texto 
                const string           font="Arial",             // fonte 
                const int              font_size=10,             // tamanho da fonte 
                const ENUM_ALIGN_MODE  align=ALIGN_CENTER,       // tipo de alinhamento 
                const bool             read_only=false,          // habilidade para editar 
                const ENUM_BASE_CORNER corner=CORNER_LEFT_UPPER, // canto do gráfico para ancoragem 
                const color            clr=clrBlack,             // cor do texto 
                const color            back_clr=clrWhite,        // cor do fundo 
                const color            border_clr=clrNONE,       // cor da borda 
                const bool             back=false,               // no fundo 
                const bool             selection=false,          // destaque para mover 
                const bool             hidden=true,              // ocultar na lista de objeto 
                const long             z_order=0)                // prioridade para clicar no mouse 
  { 
//--- redefine o valor de erro 
   ResetLastError(); 
//--- criar campo de edição 
   if(!ObjectCreate(chart_ID,name,OBJ_EDIT,sub_window,0,0)) 
     { 
      Print(__FUNCTION__, 
            ": falha ao criar objeto \"Edit\"! Código de erro = ",GetLastError()); 
      return(false); 
     } 
//--- definir coordenadas do objeto 
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x); 
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y); 
//--- definir tamanho do objeto 
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width); 
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height); 
//--- definir o texto 
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text); 
//--- definir o texto fonte 
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font); 
//--- definir tamanho da fonte 
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size); 
//--- definir o tipo de alinhamento do texto no objeto 
   ObjectSetInteger(chart_ID,name,OBJPROP_ALIGN,align); 
//--- habilitar (true) ou cancelar (false) modo de somente leitura 
   ObjectSetInteger(chart_ID,name,OBJPROP_READONLY,read_only); 
//--- definir o canto do gráfico onde as coordenadas do objeto são definidas 
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner); 
//--- definir a cor do texto 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
//--- definir a cor de fundo 
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr); 
//--- definir a cor da borda 
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,border_clr); 
//--- exibir em primeiro plano (false) ou fundo (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
//--- Habilitar (true) ou desabilitar (false) o modo de movimento da etiqueta pelo mouse 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
//--- ocultar (true) ou exibir (false) o nome do objeto gráfico na lista de objeto  
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
//--- definir a prioridade para receber o evento com um clique do mouse no gráfico 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
//--- sucesso na execução 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Mover objeto Edit                                                | 
//+------------------------------------------------------------------+ 
bool EditMove(const long   chart_ID=0,  // ID do gráfico 
              const string name="Edit", // nome do objeto 
              const int    x=0,         // coordenada X 
              const int    y=0)         // coordenada Y 
  { 
//--- redefine o valor de erro 
   ResetLastError(); 
//--- mover o objeto 
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x)) 
     { 
      Print(__FUNCTION__, 
            ": falha para mover coordenada X do objeto! Código de erro = ",GetLastError()); 
      return(false); 
     } 
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y)) 
     { 
      Print(__FUNCTION__, 
            ": falha para mover coordenada Y do objeto! Código de erro = ",GetLastError()); 
      return(false); 
     } 
//--- sucesso na execução 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Redimensionar objeto Edit                                        | 
//+------------------------------------------------------------------+ 
bool EditChangeSize(const long   chart_ID=0,  // ID do gráfico 
                    const string name="Edit", // nome do objeto 
                    const int    width=0,     // largura 
                    const int    height=0)    // altura 
  { 
//--- redefine o valor de erro 
   ResetLastError(); 
//--- alterar o tamanho do objeto 
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width)) 
     { 
      Print(__FUNCTION__, 
            ": falha ao alterar a largura do objeto! Código de erro = ",GetLastError()); 
      return(false); 
     } 
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height)) 
     { 
      Print(__FUNCTION__, 
            ": falha ao alterar a altura do objeto! Código de erro = ",GetLastError()); 
      return(false); 
     } 
//--- sucesso na execução 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Alterar texto do objeto Edit                                     | 
//+------------------------------------------------------------------+ 
bool EditTextChange(const long   chart_ID=0,  // ID do gráfico 
                    const string name="Edit", // nome do objeto 
                    const string text="Text") // texto 
  { 
//--- redefine o valor de erro 
   ResetLastError(); 
//--- alterar texto do objeto 
   if(!ObjectSetString(chart_ID,name,OBJPROP_TEXT,text)) 
     { 
      Print(__FUNCTION__, 
            ": falha ao alterar texto! Código de erro = ",GetLastError()); 
      return(false); 
     } 
//--- sucesso na execução 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Retornar texto de objeto                                         | 
//+------------------------------------------------------------------+ 
bool EditTextGet(string      &text,        // texto 
                 const long   chart_ID=0,  // ID do gráfico 
                 const string name="Edit") // nome do objeto 
  { 
//--- redefine o valor de erro 
   ResetLastError(); 
//--- obter texto do objeto 
   if(!ObjectGetString(chart_ID,name,OBJPROP_TEXT,0,text)) 
     { 
      Print(__FUNCTION__, 
            ": falha ao obter o texto! Código de erro = ",GetLastError()); 
      return(false); 
     } 
//--- sucesso na execução 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Excluir objeto Edit                                              | 
//+------------------------------------------------------------------+ 
bool EditDelete(const long   chart_ID=0,  // ID do gráfico 
                const string name="Edit") // nome do objeto 
  { 
//--- redefine o valor de erro 
   ResetLastError(); 
//--- excluir a etiqueta 
   if(!ObjectDelete(chart_ID,name)) 
     { 
      Print(__FUNCTION__, 
            ": falha ao deletar objeto \"Edit\"! Código de erro = ",GetLastError()); 
      return(false); 
     } 
//--- sucesso na execução 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Programa Script da função start (iniciar)                        | 
//+------------------------------------------------------------------+ 
void OnStart() 
  { 
//--- tamanho da janela do gráfico 
   long x_distance; 
   long y_distance; 
//--- definir tamanho da janela 
   if(!ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0,x_distance)) 
     { 
      Print("Falha ao obter a largura do gráfico! Código de erro = ",GetLastError()); 
      return; 
     } 
   if(!ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0,y_distance)) 
     { 
      Print("Falha ao obter a altura do gráfico! Código de erro = ",GetLastError()); 
      return; 
     } 
//--- definir o passo para mudar o campo edit 
   int x_step=(int)x_distance/64; 
//--- definir coordenadas do campo edit e seu tamanho 
   int x=(int)x_distance/8; 
   int y=(int)y_distance/2; 
   int x_size=(int)x_distance/8; 
   int y_size=InpFontSize*2; 
//--- armazenar o texto na variável local 
   string text=InpText; 
//--- criar campo de edição 
   if(!EditCreate(0,InpName,0,x,y,x_size,y_size,InpText,InpFont,InpFontSize,InpAlign,InpReadOnly, 
      InpCorner,InpColor,InpBackColor,InpBorderColor,InpBack,InpSelection,InpHidden,InpZOrder)) 
     { 
      return; 
     } 
//--- redesenhar o gráfico e esperar por um segundo 
   ChartRedraw(); 
   Sleep(1000); 
//--- estender o campo edit 
   while(x_size-x<x_distance*5/8) 
     { 
      //--- aumentar a largura do campo edit 
      x_size+=x_step; 
      if(!EditChangeSize(0,InpName,x_size,y_size)) 
         return; 
      //--- verificar se o funcionamento do script foi desativado a força 
      if(IsStopped()) 
         return; 
      //--- redesenhar o gráfico e esperar por 0.05 segundos 
      ChartRedraw(); 
      Sleep(50); 
     } 
//--- meio segundo de atraso 
   Sleep(500); 
//--- alterar o texto 
   for(int i=0;i<20;i++) 
     { 
      //--- adicionar "+" no início e no final 
      text="+"+text+"+"; 
      if(!EditTextChange(0,InpName,text)) 
         return; 
      //--- verificar se o funcionamento do script foi desativado a força 
      if(IsStopped()) 
         return; 
      //--- redesenhar o gráfico e esperar por 0.1 segundos 
      ChartRedraw(); 
      Sleep(100); 
     } 
//--- meio segundo de atraso 
   Sleep(500); 
//--- excluir campo edit 
   EditDelete(0,InpName); 
   ChartRedraw(); 
//--- esperar por um segundo 
   Sleep(1000); 
//--- 
  }