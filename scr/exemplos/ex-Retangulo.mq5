﻿//+------------------------------------------------------------------+
//|                                                 ex-Retangulo.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+

//--- descrição 
#property description "Script cria objeto gráfico \"Etiqueta Retangular\"." 
//--- janela de exibição dos parâmetros de entrada durante inicialização do script 
#property script_show_inputs 
//--- entrada de parâmetros do script 
input string           InpName="RectLabel";         // Nome etiqueta 
input color            InpBackColor=clrSkyBlue;     // Fundo da cor 
input ENUM_BORDER_TYPE InpBorder=BORDER_FLAT;       // Tipo de Borda 
input ENUM_BASE_CORNER InpCorner=CORNER_LEFT_UPPER; // Canto do gráfico para ancoragem 
input color            InpColor=clrDarkBlue;        // Cor da borda plana (Flat) 
input ENUM_LINE_STYLE  InpStyle=STYLE_SOLID;        // Estilo da borda plana (Flat) 
input int              InpLineWidth=3;              // Largura da borda plana (Flat) 
input bool             InpBack=false;               // Objeto de Fundo 
input bool             InpSelection=true;           // Destaque para mover 
input bool             InpHidden=true;              // Ocultar na lista de objeto 
input long             InpZOrder=0;                 // Prioridade para clique do mouse 
//+------------------------------------------------------------------+ 
//| Criar etiqueta retangular                                        | 
//+------------------------------------------------------------------+ 
bool RectLabelCreate(const long             chart_ID=0,               // ID do gráfico 
                     const string           name="RectLabel",         // nome da etiqueta 
                     const int              sub_window=0,             // índice da sub-janela 
                     const int              x=0,                      // coordenada X 
                     const int              y=0,                      // coordenada Y 
                     const int              width=50,                 // largura 
                     const int              height=18,                // altura 
                     const color            back_clr=C'236,233,216',  // cor do fundo 
                     const ENUM_BORDER_TYPE border=BORDER_SUNKEN,     // tipo de borda 
                     const ENUM_BASE_CORNER corner=CORNER_LEFT_UPPER, // canto do gráfico para ancoragem 
                     const color            clr=clrRed,               // cor da borda plana (Flat) 
                     const ENUM_LINE_STYLE  style=STYLE_SOLID,        // estilo da borda plana 
                     const int              line_width=1,             // largura da borda plana 
                     const bool             back=false,               // no fundo 
                     const bool             selection=false,          // destaque para mover 
                     const bool             hidden=true,              // ocultar na lista de objeto 
                     const long             z_order=0)                // prioridade para clicar no mouse 
  { 
//--- redefine o valor de erro 
   ResetLastError(); 
//--- criar uma etiqueta retangular 
   if(!ObjectCreate(chart_ID,name,OBJ_RECTANGLE_LABEL,sub_window,0,0)) 
     { 
      Print(__FUNCTION__, 
            ": falha ao criar uma etiqueta retangular! Código de erro = ",GetLastError()); 
      return(false); 
     } 
//--- definir coordenadas da etiqueta 
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x); 
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y); 
//--- definir tamanho da etiqueta 
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width); 
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height); 
//--- definir a cor de fundo 
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr); 
//--- definir o tipo de borda 
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_TYPE,border); 
//--- determinar o canto do gráfico onde as coordenadas do ponto são definidas 
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner); 
//--- definir a cor da borda plana (no modo Flat) 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
//--- definir o estilo da linha da borda plana 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style); 
//--- definir a largura da borda plana 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,line_width); 
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
//| Mover a etiqueta retangular                                      | 
//+------------------------------------------------------------------+ 
bool RectLabelMove(const long   chart_ID=0,       // ID do gráfico 
                   const string name="RectLabel", // nome da etiqueta 
                   const int    x=0,              // coordenada X 
                   const int    y=0)              // coordenada Y 
  { 
//--- redefine o valor de erro 
   ResetLastError(); 
//--- mover a etiqueta retangular 
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x)) 
     { 
      Print(__FUNCTION__, 
            ": falha para mover coordenada X do objeto! Código de erro = ",GetLastError()); 
      return(false); 
     } 
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y)) 
     { 
      Print(__FUNCTION__, 
            ": falha para mover coordenada X do objeto! Código de erro = ",GetLastError()); 
      return(false); 
     } 
//--- sucesso na execução 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Alterar o tamanho da etiqueta retangular                         | 
//+------------------------------------------------------------------+ 
bool RectLabelChangeSize(const long   chart_ID=0,       // ID do gráfico 
                         const string name="RectLabel", // nome da etiqueta 
                         const int    width=50,         // largura da etiqueta 
                         const int    height=18)        // altura da etiqueta 
  { 
//--- redefine o valor de erro 
   ResetLastError(); 
//--- alterar tamanho da etiqueta 
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width)) 
     { 
      Print(__FUNCTION__, 
            ": falha ao alterar a largura da etiqueta! Código de erro = ",GetLastError()); 
      return(false); 
     } 
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height)) 
     { 
      Print(__FUNCTION__, 
            ": falha ao alterar a altura da etiqueta! Código de erro = ",GetLastError()); 
      return(false); 
     } 
//--- sucesso na execução 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Alterar o tipo de borda da etiqueta retangular                   | 
//+------------------------------------------------------------------+ 
bool RectLabelChangeBorderType(const long             chart_ID=0,           // ID do gráfico 
                               const string           name="RectLabel",     // nome da etiqueta 
                               const ENUM_BORDER_TYPE border=BORDER_SUNKEN) // tipo de borda 
  { 
//--- redefine o valor de erro 
   ResetLastError(); 
//--- alterar tipo de borda 
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_TYPE,border)) 
     { 
      Print(__FUNCTION__, 
            ": falha ao alterar tipo de borda! Código de erro = ",GetLastError()); 
      return(false); 
     } 
//--- sucesso na execução 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Excluir etiqueta retangular                                      | 
//+------------------------------------------------------------------+ 
bool RectLabelDelete(const long   chart_ID=0,       // ID do gráfico 
                     const string name="RectLabel") // nome da etiqueta 
  { 
//--- redefine o valor de erro 
   ResetLastError(); 
//--- excluir a etiqueta 
   if(!ObjectDelete(chart_ID,name)) 
     { 
      Print(__FUNCTION__, 
            ": falha ao excluir a etiqueta retangular! Código de erro = ",GetLastError()); 
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
//--- definir as coordenadas da etiqueta retangular 
   int x=(int)x_distance/4; 
   int y=(int)y_distance/4; 
//--- definir tamanho da etiqueta 
   int width=(int)x_distance/4; 
   int height=(int)y_distance/4; 
//--- criar uma etiqueta retangular 
   if(!RectLabelCreate(0,InpName,0,x,y,width,height,InpBackColor,InpBorder,InpCorner, 
      InpColor,InpStyle,InpLineWidth,InpBack,InpSelection,InpHidden,InpZOrder)) 
     { 
      return; 
     } 
//--- redesenhar o gráfico e esperar um segundo 
   ChartRedraw(); 
   Sleep(1000); 
//--- alterar o tamanho da etiqueta retangular 
   int steps=(int)MathMin(x_distance/4,y_distance/4); 
   for(int i=0;i<steps;i++) 
     { 
      //--- redimensionar 
      width+=1; 
      height+=1; 
      if(!RectLabelChangeSize(0,InpName,width,height)) 
         return; 
      //--- verificar se o funcionamento do script foi desativado a força 
      if(IsStopped()) 
         return; 
      //--- redesenhar o gráfico e esperar por 0.01 segundos 
      ChartRedraw(); 
      Sleep(10); 
     } 
//--- 1 segundo de atraso 
   Sleep(1000); 
//--- alterar tipo de borda 
   if(!RectLabelChangeBorderType(0,InpName,BORDER_RAISED)) 
      return; 
//--- redesenhar o gráfico e esperar por um segundo 
   ChartRedraw(); 
   Sleep(1000); 
//--- alterar tipo de borda 
   if(!RectLabelChangeBorderType(0,InpName,BORDER_SUNKEN)) 
      return; 
//--- redesenhar o gráfico e esperar por um segundo 
   ChartRedraw(); 
   Sleep(1000); 
//--- excluir a etiqueta 
   RectLabelDelete(0,InpName); 
   ChartRedraw(); 
//--- esperar por um segundo 
   Sleep(1000); 
//--- 
  }