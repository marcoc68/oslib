//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright   "Smart-Calculator (by Transcendreamer)"
#property description "Fast and simple positions calculator and planner"
#property indicator_chart_window
#property indicator_plots 0
#property strict
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum  POSITION       {buy,sell};
input POSITION       position_side=buy;
input double         position_lot=0.05;
input int            total_positions=1;
input int            step_points=500;
input bool           first_offset=false;
enum  PROGRESSION    {none,equal,linear,fibo,martin};
input PROGRESSION    progression=none;
input double         multiplicator=2;
input bool           open_positions=false;
input bool           limit_orders=false;
input bool           stop_orders=false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int INFO_X=5;
int INFO_Y=1;
int INFO_CORNER=CORNER_LEFT_LOWER;
int INFO_SIZE=12;
string INFO_FONT="Verdana";
color INFO_COLOR=clrMagenta;
color LEVEL_COLOR=clrMagenta;
color TAKE_COLOR=clrGreen;
color STOP_COLOR=clrRed;
int LINE_STYLE=STYLE_DASH;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnInit()
  {
   IndicatorSetString(INDICATOR_SHORTNAME,"Smart-Calc");
   ChartSetInteger(0,CHART_EVENT_OBJECT_CREATE,true);
   ChartSetInteger(0,CHART_EVENT_OBJECT_DELETE,true);
   Setup();
   Update();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectDelete(0,"Info-Label");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(
                const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   if(id==CHARTEVENT_OBJECT_CLICK)
      if(sparam=="Info-Label")
        {
         Clear();
         Setup();
         Update();
        }
   if(id==CHARTEVENT_OBJECT_DELETE) Update();
   if(id==CHARTEVENT_OBJECT_CREATE) Update();
   if(id==CHARTEVENT_OBJECT_CHANGE) Update();
   if(id==CHARTEVENT_OBJECT_DRAG)   Update();
   if(id==CHARTEVENT_CLICK)         Update();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Clear()
  {
   for(int n=ObjectsTotal(0,0,OBJ_HLINE); n>=1; n--)
     {
      string name=ObjectName(0,n-1,0,OBJ_HLINE);
      if(StringFind(name,"Entry-")!=-1) ObjectDelete(0,name);
      if(StringFind(name,"Stop-Loss")!=-1) ObjectDelete(0,name);
      if(StringFind(name,"Take-Profit")!=-1) ObjectDelete(0,name);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Setup()
  {

   int sign=0;
   if(position_side==buy)  sign=+1;
   if(position_side==sell) sign=-1;
   int offset=first_offset?1:0;
   double close=iClose(_Symbol,_Period,0);

   bool no_levels=true;
   for(int n=ObjectsTotal(0,0,OBJ_HLINE); n>=1; n--)
     {
      string name=ObjectName(0,n-1,0,OBJ_HLINE);
      if(StringFind(name,"Entry-")!=-1) no_levels=false;
     }

   if(no_levels)
      for(int n=1; n<=total_positions; n++)
        {
         string name="Entry-"+string(n);
         string text=string(sign*position_lot*GetMember(n));
         double price=close-step_points*_Point*(n-1+offset)*sign;
         PlaceHorizontal(name,text,price,LEVEL_COLOR,LINE_STYLE,false,true,true);
        }

   double stop=NormalizeDouble(close-sign*step_points*_Point*(total_positions+offset),_Digits);
   double take=NormalizeDouble(close+sign*step_points*_Point*(1-offset),_Digits);

   if(ObjectFind(0,"Stop-Loss")==-1)
      PlaceHorizontal("Stop-Loss","SL",stop,STOP_COLOR,LINE_STYLE,false,true,true);
   if(ObjectFind(0,"Take-Profit")==-1)
      PlaceHorizontal("Take-Profit","TP",take,TAKE_COLOR,LINE_STYLE,false,true,true);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Update()
  {

   double TS=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double TV=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);

#ifdef __MQL5__
   double MI,MM;
   ENUM_ORDER_TYPE order=(position_side==buy)?ORDER_TYPE_BUY:ORDER_TYPE_SELL;
   SymbolInfoMarginRate(_Symbol,order,MI,MM);
   long AL=AccountInfoInteger(ACCOUNT_LEVERAGE);
   double rate=SymbolInfoDouble(_Symbol,(position_side==buy)?SYMBOL_ASK:SYMBOL_BID);
   double MR=MI*rate*TV/(TS*AL);
#else
   double MR=MarketInfo(_Symbol,MODE_MARGINREQUIRED);
#endif

   int levels=0;
   double SL=0,TP=0;
   double OPEN[],LOT[];
   int total=ObjectsTotal(0,0,OBJ_HLINE);

   for(int i=total-1; i>=0; i--)
     {
      string name=ObjectName(0,i,0,OBJ_HLINE);
      double price=ObjectGetDouble(0,name,OBJPROP_PRICE);
      if(name=="Stop-Loss")   {SL=price;continue;}
      if(name=="Take-Profit") {TP=price;continue;}
      if(StringFind(name,"Entry-")==-1) continue;
      string text=ObjectGetString(0,name,OBJPROP_TEXT);
      double position=StringToDouble(text);
      levels++;
      ArrayResize(OPEN,levels);
      ArrayResize(LOT,levels);
      OPEN[levels-1]=price;
      LOT[levels-1]=position;
     }

#ifdef __MQL5__
   if(open_positions)
     {
      total=PositionsTotal();
      for(int i=total-1; i>=0; i--)
        {
         ulong ticket=PositionGetTicket(i);
         if(!PositionSelectByTicket(ticket)) continue;
         if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
         long type=PositionGetInteger(POSITION_TYPE);
         levels++;
         ArrayResize(OPEN,levels);
         ArrayResize(LOT,levels);
         OPEN[levels-1]=PositionGetDouble(POSITION_PRICE_OPEN);
         if(type==POSITION_TYPE_BUY)  LOT[levels-1]=+PositionGetDouble(POSITION_VOLUME);
         if(type==POSITION_TYPE_SELL) LOT[levels-1]=-PositionGetDouble(POSITION_VOLUME);
        }
     }
#else
   if(open_positions)
     {
      total=OrdersTotal();
      for(int i=total-1; i>=0; i--)
        {
         if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
         if(OrderSymbol()!=_Symbol) continue;
         int type=OrderType();
         if(type!=OP_BUY && type!=OP_SELL) continue;
         levels++;
         ArrayResize(OPEN,levels);
         ArrayResize(LOT,levels);
         OPEN[levels-1]=OrderOpenPrice();
         if(type==OP_BUY)  LOT[levels-1]=+OrderLots();
         if(type==OP_SELL) LOT[levels-1]=-OrderLots();
        }
     }
#endif

#ifdef __MQL5__
   if(limit_orders)
     {
      total=OrdersTotal();
      for(int i=total-1; i>=0; i--)
        {
         ulong ticket=OrderGetTicket(i);
         if(!OrderSelect(ticket)) continue;
         if(OrderGetString(ORDER_SYMBOL)!=_Symbol) continue;
         long type=OrderGetInteger(ORDER_TYPE);
         if(type!=ORDER_TYPE_BUY_LIMIT && type!=ORDER_TYPE_SELL_LIMIT) continue;
         levels++;
         ArrayResize(OPEN,levels);
         ArrayResize(LOT,levels);
         OPEN[levels-1]=OrderGetDouble(ORDER_PRICE_OPEN);
         if(type==ORDER_TYPE_BUY_LIMIT)  LOT[levels-1]=+OrderGetDouble(ORDER_VOLUME_CURRENT);
         if(type==ORDER_TYPE_SELL_LIMIT) LOT[levels-1]=-OrderGetDouble(ORDER_VOLUME_CURRENT);
        }
     }
#else
   if(limit_orders)
     {
      total=OrdersTotal();
      for(int i=total-1; i>=0; i--)
        {
         if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
         if(OrderSymbol()!=Symbol()) continue;
         int type=OrderType();
         if(OrderType()!=OP_BUYLIMIT && OrderType()!=OP_SELLLIMIT) continue;
         levels++;
         ArrayResize(OPEN,levels);
         ArrayResize(LOT,levels);
         OPEN[levels-1]=OrderOpenPrice();
         if(OrderType()==OP_BUYLIMIT)  LOT[levels-1]=+OrderLots();
         if(OrderType()==OP_SELLLIMIT) LOT[levels-1]=-OrderLots();
        }
     }
#endif

#ifdef __MQL5__
   if(stop_orders)
     {
      total=OrdersTotal();
      for(int i=total-1; i>=0; i--)
        {
         ulong ticket=OrderGetTicket(i);
         if(!OrderSelect(ticket)) continue;
         if(OrderGetString(ORDER_SYMBOL)!=_Symbol) continue;
         long type=OrderGetInteger(ORDER_TYPE);
         if(type!=ORDER_TYPE_BUY_STOP && type!=ORDER_TYPE_SELL_STOP) continue;
         levels++;
         ArrayResize(OPEN,levels);
         ArrayResize(LOT,levels);
         OPEN[levels-1]=OrderGetDouble(ORDER_PRICE_OPEN);
         if(type==ORDER_TYPE_BUY_STOP)  LOT[levels-1]=+OrderGetDouble(ORDER_VOLUME_CURRENT);
         if(type==ORDER_TYPE_SELL_STOP) LOT[levels-1]=-OrderGetDouble(ORDER_VOLUME_CURRENT);
        }
     }
#else
   if(limit_orders)
     {
      total=OrdersTotal();
      for(int i=total-1; i>=0; i--)
        {
         if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
         if(OrderSymbol()!=Symbol()) continue;
         int type=OrderType();
         if(OrderType()!=OP_BUYSTOP && OrderType()!=OP_SELLSTOP) continue;
         levels++;
         ArrayResize(OPEN,levels);
         ArrayResize(LOT,levels);
         OPEN[levels-1]=OrderOpenPrice();
         if(OrderType()==OP_BUYSTOP)  LOT[levels-1]=+OrderLots();
         if(OrderType()==OP_SELLSTOP) LOT[levels-1]=-OrderLots();
        }
     }
#endif

   if(levels<1) return;
   double profit=0,loss=0,margin=0;
   for(int i=0; i<levels; i++)
     {
      if(TP!=0) profit += NormalizeDouble( (TP - OPEN[i]) / TS * TV * LOT[i] , 2);
      if(SL!=0) loss   += NormalizeDouble( (OPEN[i] - SL) / TS * TV * LOT[i] , 2);
      margin+=NormalizeDouble(MR*MathAbs(LOT[i]),2);
     }

   string text="Profit="+DoubleToString(profit,2)+"   ";
   text += "Loss="   + DoubleToString(loss,2)   + "   ";
   text += "Margin=" + DoubleToString(margin,2) + "   ";
   text += AccountInfoString(ACCOUNT_CURRENCY);
   PlaceLabel("Info-Label",INFO_X,INFO_Y,INFO_CORNER,text,INFO_COLOR,INFO_FONT,INFO_SIZE);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetProgression(int n)
  {
   if(progression==none) return(n);
   double sum=0;
   for(int k=1; k<=n; k++)
      sum+=(n-k+1)*GetMember(k);
   return(sum);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetMember(int k)
  {
   if(progression==equal)
     {
      return(1);
     }
   else if(progression==fibo)
     {
      if(k<3) return(1);
      int f=1,s=1;
      while(k>2) { f=f+s*2; s=f-s; f=f-s; k--; }
      return(s);
     }
   else if(progression==martin)
     {
      return(MathPow(multiplicator,k-1));
     }
   else if(progression==linear)
     {
      return(k);
     }
   return(1);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PlaceHorizontal(string name,string text,double price,int colour,int style,bool back,bool selectable,bool selected)
  {
   ObjectCreate(0,name,OBJ_HLINE,ChartWindowFind(),0,price);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_COLOR,colour);
   ObjectSetInteger(0,name,OBJPROP_STYLE,style);
   ObjectSetInteger(0,name,OBJPROP_BACK,back);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,selectable);
   ObjectSetInteger(0,name,OBJPROP_SELECTED,selected);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PlaceLabel(string name,int x,int y,int corner,string text,int colour,string font,int size)
  {
   int anchor=0;
   if(corner==CORNER_LEFT_LOWER) anchor=ANCHOR_LEFT_LOWER;
   else if(corner==CORNER_LEFT_UPPER) anchor=ANCHOR_LEFT_UPPER;
   else if(corner==CORNER_RIGHT_LOWER) anchor=ANCHOR_RIGHT_LOWER;
   else if(corner==CORNER_RIGHT_UPPER) anchor=ANCHOR_RIGHT_UPPER;
   ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,corner);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetString(0,name,OBJPROP_FONT,font);
   ObjectSetInteger(0,name,OBJPROP_COLOR,colour);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,size);
  }
//+------------------------------------------------------------------+
