//+------------------------------------------------------------------+
//|                                                osc-pc-p7-001.mqh |
//|                               Copyright 2010,oficina de software.|
//|                                 http://www.metaquotes.net/marcoc.|
//+------------------------------------------------------------------+
#include <Controls\Dialog.mqh>
#include <Controls\CheckGroup.mqh>
#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
#include <Controls\Button.mqh>
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
//--- indents and gaps
#define INDENT_LEFT                         (11)      // indent from left (with allowance for border width)
#define INDENT_TOP                          (11)      // indent from top (with allowance for border width)
#define INDENT_RIGHT                        (11)      // indent from right (with allowance for border width)
#define INDENT_BOTTOM                       (11)      // indent from bottom (with allowance for border width)
#define CONTROLS_GAP_X                      (5)       // gap by X coordinate
#define CONTROLS_GAP_Y                      (5)       // gap by Y coordinate
//--- for buttons
#define BUTTON_WIDTH                        (53)      // size by X coordinate
#define BUTTON_HEIGHT                       (20)      // size by Y coordinate
//--- for the indication area
#define EDIT_WIDTH                          (30)      // size by X coordinate
#define EDIT_HEIGHT                         (20)      // size by Y coordinate
//--- for group controls
#define GROUP_WIDTH                         (230)     // size by X coordinate
#define GROUP_HEIGHT                        (57)      // size by Y coordinate

//--- gerais
#define ALTURA_LINHA                        ( 20)     // size by Y coordinate
#define LARGURA_COLUNA_01                   (100)     // size by X coordinate // era 115
#define LARGURA_COLUNA_02                   ( 90)     // size by X coordinate
#define LARGURA_COLUNA_03                   ( 60)     // size by X coordinate
#define LARGURA_COLUNA_04                   ( 50)     // size by X coordinate

#define INI_COLUNA_01                       (0                )     // size by X coordinate
#define INI_COLUNA_02                       (INI_COLUNA_01+LARGURA_COLUNA_01                 )     // size by X coordinate
#define INI_COLUNA_03                       (INI_COLUNA_02+LARGURA_COLUNA_02+CONTROLS_GAP_X*3)     // size by X coordinate
#define INI_COLUNA_04                       (INI_COLUNA_03+LARGURA_COLUNA_03                 )     // size by X coordinate

#define LARGURA_CONTROL_PANEL               (450)     // size by X coordinate
#define ALTURA_CONTROL_PANEL                (460)     // size by X coordinate

#define COL01_WIDTH                         (100)     // size by X coordinate
#define COL02_WIDTH                         (100)     // size by X coordinate


//+------------------------------------------------------------------+
//| Class osc_control_panel_p7_001                                   |
//| Usage: Painel de Controle para o Expert P7-001                   |
//+------------------------------------------------------------------+
class osc_control_panel_p7_001 : public CAppDialog {
private:
   CCheckGroup       m_check_group;                   // the CheckGroup object

   CLabel            m_labelPosicao;                  // the label object
   CEdit             m_editPosicao;                   // the display field object
   string            m_posicao;                       // informa se estah comprado ou vendido

   CLabel            m_labelT4g;                      // the label object
   CEdit             m_editT4g;                       // the display field object
   int               m_t4g;                           // ticks for gain (primeiro passo)

   CLabel            m_labelPasso;                    // the label object
   CEdit             m_editPasso;                     // the display field object
   int               m_passo    ;                     // passo em ticks;

   CLabel            m_labelProfitPosicao;            // the label object
   CEdit             m_editProfitPosicao;             // the display field object
   double            m_profitPosicao;                 // profit da posicao atual
   
   CLabel            m_labelSaidaPosicao;             // the label object
   CEdit             m_editSaidaPosicao;              // the display field object
   double            m_saidaPosicao;                  // profit da posicao atual

   CLabel            m_labelStopLoss;                 // the label object
   CEdit             m_editStopLoss;                  // the display field object
   double            m_stopLoss;                      // profit da posicao atual

   CLabel            m_labelVolPosicao;               // the label object
   CEdit             m_editVolPosicao;                // the display field object
   string            m_volPosicao;                    // volumetot/volume pendente para fechar a posicao

   CLabel            m_labelPftBruto;              // the label object
   CEdit             m_editPftBruto;               // the display field object
   double            m_pftBruto;                   // Profit bruto do dia mini indice

   CLabel            m_labelTarifa;                // the label object
   CEdit             m_editTarifa;                 // the display field object
   double            m_tarifa;                     // tarifa do dia mini indice

   CLabel            m_labelPftContrat;            // the label object
   CEdit             m_editPftContrat;             // the display field object
   double            m_pftContrat;                 // Profit por contrato do dia mini indice

   CLabel            m_labelPftLiquido;            // the label object
   CEdit             m_editPftLiquido;             // the display field object
   double            m_pftLiquido;                 // Profit liquido do dia mini indice

   CLabel            m_labelVol;                   // the label object
   CEdit             m_editVol;                    // the display field object
   double            m_vol;                        // Profit liquido do dia mini indice

   CLabel            m_labelPUP3;                     // the label object
   CEdit             m_editPUP3;                      // the display field object
   double            m_PUP3;                          // propabilidade do preco subir

   CLabel            m_labelPUP2;                     // the label object
   CEdit             m_editPUP2;                      // the display field object
   double            m_PUP2;                          // propabilidade do preco subir

   CLabel            m_labelPUP1;                     // the label object
   CEdit             m_editPUP1;                      // the display field object
   double            m_PUP1;                          // propabilidade do preco subir

   CLabel            m_labelPUP0;                        // the label object
   CEdit             m_editPUP0;                         // the display field object
   double            m_PUP0;                             // propabilidade do preco subir

   CLabel            m_labelPDW0;                        // the label object
   CEdit             m_editPDW0;                         // the display field object
   double            m_PDW0;                             // propabilidade do preco descer

   CLabel            m_labelPDW1;                        // the label object
   CEdit             m_editPDW1;                         // the display field object
   double            m_PDW1;                             // propabilidade do preco descer

   CLabel            m_labelPDW2;                        // the label object
   CEdit             m_editPDW2;                         // the display field object
   double            m_PDW2;                             // propabilidade do preco descer

   CLabel            m_labelPDW3;                        // the label object
   CEdit             m_editPDW3;                         // the display field object
   double            m_PDW3;                             // propabilidade do preco descer

   CButton           m_button_ok;                     // the button "OK" object

public:
                     osc_control_panel_p7_001(void);
                    ~osc_control_panel_p7_001(void);
   //--- create
   virtual bool      Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2);
   virtual bool      Create();
   //--- chart event handler
   virtual bool      OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam);
   //--- initialization
   virtual bool      Initialization(const bool Mail,const bool Push,const bool Alert_,
                                    const double Lots,const int TakeProfit,
                                    const int  TrailingStop,const int MACDOpenLevel,
                                    const int  MACDCloseLevel,const int MATrendPeriod);
   //--- get values
   virtual void      GetValues(bool &Mail,bool &Push,bool &Alert_,
                               double &Lots,int &TakeProfit,
                               int &TrailingStop,int &MACDOpenLevel,
                               int &MACDCloseLevel,int &MATrendPeriod);
   //--- send notifications
   virtual void      Notifications(const string text);
   //---
   virtual bool      Modification(void) const { return(mModification);          }
   virtual void      Modification(bool value) { mModification=value;            }
   
   void setPosicaoNula  (string p ){ if(p== m_posicao      )return; m_posicao      = p; m_editPosicao      .Text(                 p    ); m_editPosicao.Color(clrGray); }
   void setPosicaoBuy   (string p ){ if(p== m_posicao      )return; m_posicao      = p; m_editPosicao      .Text(                 p    ); m_editPosicao.Color(clrBlue); }
   void setPosicaoSell  (string p ){ if(p== m_posicao      )return; m_posicao      = p; m_editPosicao      .Text(                 p    ); m_editPosicao.Color(clrRed ); }
   void setT4g          (int    p ){ if(p== m_t4g          )return; m_t4g          = p; m_editT4g          .Text( IntegerToString(p  ) ); }
   void setPasso        (int    p ){ if(p== m_passo        )return; m_passo        = p; m_editPasso        .Text( IntegerToString(p  ) ); }
   void setProfitPosicao(double p ){ if(p== m_profitPosicao)return; m_profitPosicao= p; m_editProfitPosicao.Text( DoubleToString (p,2) ); if( p<0)m_editProfitPosicao.Color(clrRed); if(p>0)m_editProfitPosicao.Color(clrBlue); if(p==0)m_editProfitPosicao.Color(clrGray);  }
   void setSaidaPosicao (double p ){ if(p== m_saidaPosicao )return; m_saidaPosicao = p; m_editSaidaPosicao .Text( DoubleToString (p,2) ); if( p<0)m_editSaidaPosicao .Color(clrRed); if(p>0)m_editSaidaPosicao .Color(clrBlue); if(p==0)m_editSaidaPosicao .Color(clrGray);  }
   void setStopLoss     (double p ){ if(p== m_stopLoss     )return; m_stopLoss     = p; m_editStopLoss     .Text( DoubleToString (p,2) ); }
   void setVolPosicao   (string p ){ if(p== m_volPosicao   )return; m_volPosicao   = p; m_editVolPosicao   .Text(                 p    ); }
   void setPftBruto     (double p ){ if(p== m_pftBruto     )return; m_pftBruto     = p; m_editPftBruto     .Text( DoubleToString (p,2) ); if( p<0)m_editPftBruto     .Color(clrRed); if(p>0)m_editPftBruto     .Color(clrBlue); if(p==0)m_editPftBruto     .Color(clrGray);  }
   void setTarifa       (double p ){ if(p==-m_tarifa       )return; m_tarifa       =-p; m_editTarifa       .Text( DoubleToString (p,2) ); if(-p<0)m_editTarifa       .Color(clrRed);                                            if(p==0)m_editTarifa       .Color(clrGray);  }
   void setPftContrat   (double p ){ if(p== m_pftContrat   )return; m_pftContrat   = p; m_editPftContrat   .Text( DoubleToString (p,2) ); if( p<0)m_editPftContrat   .Color(clrRed); if(p>0)m_editPftContrat   .Color(clrBlue); if(p==0)m_editPftContrat   .Color(clrGray);  }
   void setPftLiquido   (double p ){ if(p== m_pftLiquido   )return; m_pftLiquido   = p; m_editPftLiquido   .Text( DoubleToString (p,2) ); if( p<0)m_editPftLiquido   .Color(clrRed); if(p>0)m_editPftLiquido   .Color(clrBlue); if(p==0)m_editPftLiquido   .Color(clrGray);  }
   void setVol          (double p ){ if(p== m_vol          )return; m_vol          = p; m_editVol          .Text( DoubleToString (p,2) ); }
   void setVolTradePorSegDeltaPorc(double p){ if(p==m_PUP3 )return; m_PUP3         = p; m_editPUP3         .Text( DoubleToString (p,2) ); if( p<0)m_editPUP3         .Color(clrRed); if(p>0)m_editPUP3         .Color(clrBlue); if(p==0)m_editPftBruto     .Color(clrGray);  }

   void setPUP3(double p, double lim ){ if(p==m_PUP3)return; m_PUP3=p; m_editPUP3.Text( DoubleToString (p,0) ); if( p>=lim)m_editPUP3.Color(clrBlue); if(p<lim)m_editPUP3.Color(clrBlack); }
   void setPUP2(double p, double lim ){ if(p==m_PUP2)return; m_PUP2=p; m_editPUP2.Text( DoubleToString (p,0) ); if( p>=lim)m_editPUP2.Color(clrBlue); if(p<lim)m_editPUP2.Color(clrBlack); }
   void setPUP1(double p, double lim ){ if(p==m_PUP1)return; m_PUP2=p; m_editPUP1.Text( DoubleToString (p,0) ); if( p>=lim)m_editPUP1.Color(clrBlue); if(p<lim)m_editPUP1.Color(clrBlack); }
   void setPUP0(double p, double lim ){ if(p==m_PUP0)return; m_PUP2=p; m_editPUP0.Text( DoubleToString (p,0) ); if( p>=lim)m_editPUP0.Color(clrBlue); if(p<lim)m_editPUP0.Color(clrBlack); }
   void setPDW0(double p, double lim ){ if(p==m_PDW0)return; m_PDW0=p; m_editPDW0.Text( DoubleToString (p,0) ); if( p>=lim)m_editPDW0.Color(clrBlue); if(p<lim)m_editPDW0.Color(clrBlack); }
   void setPDW1(double p, double lim ){ if(p==m_PDW1)return; m_PDW1=p; m_editPDW1.Text( DoubleToString (p,0) ); if( p>=lim)m_editPDW1.Color(clrBlue); if(p<lim)m_editPDW1.Color(clrBlack); }
   void setPDW2(double p, double lim ){ if(p==m_PDW2)return; m_PDW2=p; m_editPDW2.Text( DoubleToString (p,0) ); if( p>=lim)m_editPDW2.Color(clrBlue); if(p<lim)m_editPDW2.Color(clrBlack); }
   void setPDW3(double p, double lim ){ if(p==m_PDW3)return; m_PDW3=p; m_editPDW3.Text( DoubleToString (p,0) ); if( p>=lim)m_editPDW3.Color(clrBlue); if(p<lim)m_editPDW3.Color(clrBlack); }

protected:

   bool              CreateLabel2(int coluna, int lenColuna, int linha, string nome, CLabel &objLabel, string strValor );
   bool              CreateEdit2 (int coluna, int lenColuna, int linha, string nome, CEdit  &objEdit , string strValor );

   //--- create dependent controls
   bool              CreateCheckGroup(void);
   bool              CreateButtonOK(int posicao);

   //--- set check for element
   bool              SetCheck(const int idx,const bool check);

   //--- handlers of the dependent controls events
   void              OnChangeCheckGroup(void);
   //void              OnChangeEditPasso(void);
   //void              OnChangeEditProfitPosicao(void);
   //void              OnChangeEdit3(void);
   //void              OnChangeEdit4(void);
   //void              OnChangeEdit5(void);
   //void              OnChangeEdit6(void);
   void              OnClickButtonOK(void);

private:
   //--- get check for element
   virtual int       GetCheck(const int idx);
   //---
   bool              mMail;
   bool              mPush;
   bool              mAlert_;
   double            mLots;               // Lots
   int               mTakeProfit;         // Take Profit (in pips)
   int               mTrailingStop;       // Trailing Stop Level (in pips)
   int               mMACDOpenLevel;      // MACD open level (in pips)
   int               mMACDCloseLevel;     // MACD close level (in pips)
   int               mMATrendPeriod;      // MA trend period
   //---
   bool              mModification;       // Values have changed
  };
//+------------------------------------------------------------------+
//| Event Handling                                                   |
//+------------------------------------------------------------------+
EVENT_MAP_BEGIN(osc_control_panel_p7_001)
//ON_EVENT(ON_CHANGE,m_check_group,OnChangeCheckGroup)
//ON_EVENT(ON_CHANGE,m_editPasso,OnChangeEditPasso)
//ON_EVENT(ON_END_EDIT,m_editPasso,OnChangeEditPasso)
//ON_EVENT(ON_END_EDIT,m_ProfitPosicao,OnChangeProfitPosicao)
//ON_EVENT(ON_END_EDIT,m_edit3,OnChangeEdit3)
//ON_EVENT(ON_END_EDIT,m_edit4,OnChangeEdit4)
//ON_EVENT(ON_END_EDIT,m_edit5,OnChangeEdit5)
//ON_EVENT(ON_END_EDIT,m_edit6,OnChangeEdit6)
//ON_EVENT(ON_CLICK,m_button_ok,OnClickButtonOK)
EVENT_MAP_END(CAppDialog)
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
osc_control_panel_p7_001::osc_control_panel_p7_001(void) : mMail(false),
                                         mPush(false),
                                         mAlert_(true),
                                         mLots(0.1),
                                         mTakeProfit(50),
                                         mTrailingStop(30),
                                         mMACDOpenLevel(3),
                                         mMACDCloseLevel(2),
                                         mMATrendPeriod(26),
                                         mModification(false)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
osc_control_panel_p7_001::~osc_control_panel_p7_001(void)
  {
  }
//+------------------------------------------------------------------+
//| Create                                                           |
//+------------------------------------------------------------------+
bool osc_control_panel_p7_001::Create(){ return Create(0,"Painel de Controle P7-001",0,100,100,LARGURA_CONTROL_PANEL,ALTURA_CONTROL_PANEL); }
bool osc_control_panel_p7_001::Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2)
  {
   if(!CAppDialog::Create(chart,name,subwin,x1,y1,x2,y2))
      return(false);

//--- create dependent controls
 //if(!CreateCheckGroup()) return(false);

   // posicao comprada ou vendida
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, 0, "Posicao",m_labelPosicao,"Posicao"                   )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, 0, "Posicao",m_editPosicao ,m_posicao                   )) return(false);
   if(!CreateLabel2(INI_COLUNA_03, LARGURA_COLUNA_03, 0, "PUP3"   ,m_labelPUP3   ,"PUP3"                      )) return(false);
   if(!CreateEdit2 (INI_COLUNA_04, LARGURA_COLUNA_04, 0, "PUP3"   ,m_editPUP3    ,DoubleToString(m_PUP3,0)    )) return(false);

   // ticks for gain. Antes do primeiro passo rajada
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, 1, "T4g",m_labelT4g  ,"Ticks4Gain"             )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, 1, "T4g",m_editT4g   ,IntegerToString(m_t4g)   )) return(false);
   if(!CreateLabel2(INI_COLUNA_03, LARGURA_COLUNA_03, 1, "PUP2",m_labelPUP2,"PUP2"                   )) return(false);
   if(!CreateEdit2 (INI_COLUNA_04, LARGURA_COLUNA_04, 1, "PUP2",m_editPUP2 ,DoubleToString(m_PUP2,0) )) return(false);

   // passo rajada
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, 2, "PassoRajada",m_labelPasso,"PassoRajada"            )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, 2, "PassoRajada",m_editPasso ,IntegerToString(m_passo) )) return(false);
   if(!CreateLabel2(INI_COLUNA_03, LARGURA_COLUNA_03, 2, "PUP1"       ,m_labelPUP1 ,"PUP1"                   )) return(false);
   if(!CreateEdit2 (INI_COLUNA_04, LARGURA_COLUNA_04, 2, "PUP1"       ,m_editPUP1  ,DoubleToString(m_PUP1,0) )) return(false);

   // profit da posicao
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, 3, "ProfitPosic",m_labelProfitPosicao,"ProfitPosic"                     )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, 3, "ProfitPosic",m_editProfitPosicao ,DoubleToString(m_profitPosicao,2) )) return(false);
   if(!CreateLabel2(INI_COLUNA_03, LARGURA_COLUNA_03, 3, "PUP0"       ,m_labelPUP0         ,"PUP0"                            )) return(false);
   if(!CreateEdit2 (INI_COLUNA_04, LARGURA_COLUNA_04, 3, "PUP0"       ,m_editPUP0          ,DoubleToString(m_PUP0,0)          )) return(false);

   // saida esperada da posicao
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, 4, "SaidaPosic",m_labelSaidaPosicao,"SaidaPosic"                  )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, 4, "SaidaPosic",m_editSaidaPosicao ,DoubleToString(m_saidaPosicao,2) )) return(false);
   if(!CreateLabel2(INI_COLUNA_03, LARGURA_COLUNA_03, 4, "PDW0"      ,m_labelPDW0        ,"PDW0"                           )) return(false);
   if(!CreateEdit2 (INI_COLUNA_04, LARGURA_COLUNA_04, 4, "PDW0"      ,m_editPDW0         ,DoubleToString(m_PDW0,0)         )) return(false);

   // stop_loss da posicao
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, 5, "StopLoss",m_labelStopLoss,"StopLoss"                   )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, 5, "StopLoss",m_editStopLoss ,DoubleToString(m_stopLoss,2) )) return(false);
   if(!CreateLabel2(INI_COLUNA_03, LARGURA_COLUNA_03, 5, "PDW1"    ,m_labelPDW1    ,"PDW1"                       )) return(false);
   if(!CreateEdit2 (INI_COLUNA_04, LARGURA_COLUNA_04, 5, "PDW1"    ,m_editPDW1     ,DoubleToString(m_PDW1,0)     )) return(false);

   // volume da posicao
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, 6, "VolPosicao",m_labelVolPosicao,"VolPosicao"             )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, 6, "VolPosicao",m_editVolPosicao ,m_volPosicao             )) return(false);
   if(!CreateLabel2(INI_COLUNA_03, LARGURA_COLUNA_03, 6, "PDW2"      ,m_labelPDW2      ,"PDW2"                   )) return(false);
   if(!CreateEdit2 (INI_COLUNA_04, LARGURA_COLUNA_04, 6, "PDW2"      ,m_editPDW2       ,DoubleToString(m_PDW2,0) )) return(false);

   // profit bruto do dia WIN+WDO+OUTROS
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, 7, "PtfBruto",m_labelPftBruto,"PtfBruto"                   )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, 7, "PtfBruto",m_editPftBruto ,DoubleToString(m_pftBruto,2) )) return(false);
   if(!CreateLabel2(INI_COLUNA_03, LARGURA_COLUNA_03, 7, "PDW3"    ,m_labelPDW3    ,"PDW3"                       )) return(false);
   if(!CreateEdit2 (INI_COLUNA_04, LARGURA_COLUNA_04, 7, "PDW3"    ,m_editPDW3     ,DoubleToString(m_PDW3,0)     )) return(false);

   // tarifa do dia WIN+WDO+OUTROS
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, 8, "Tarifa",m_labelTarifa,"Tarifa"                   )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, 8, "Tarifa",m_editTarifa ,DoubleToString(m_tarifa,2) )) return(false);

   // profit por contrato do dia WIN+WDO+OUTROS
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, 9, "PftContrat",m_labelPftContrat,"PftContrat"                   )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, 9, "PftContrat",m_editPftContrat ,DoubleToString(m_pftContrat,2) )) return(false);

   // profit liquido do dia WIN+WDO+OUTROS
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, 10, "PftLiquido",m_labelPftLiquido,"PftLiquido"                   )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, 10, "PftLiquido",m_editPftLiquido ,DoubleToString(m_pftLiquido,2) )) return(false);

   // volume do dia WIN+WDO+OUTROS
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, 11, "Vol",m_labelVol,"Vol"                   )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, 11, "Vol",m_editVol ,DoubleToString(m_vol,2) )) return(false);

   if(!CreateButtonOK(12)) return(false);

//---
   SetCheck(0,mMail);
   SetCheck(1,mPush);
   SetCheck(2,mAlert_);

//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "CheckGroup" element                                  |
//+------------------------------------------------------------------+
bool osc_control_panel_p7_001::CreateCheckGroup(void)
  {
//--- coordinates
   int x1=INDENT_LEFT;
   int y1=INDENT_TOP;
   int x2=x1+GROUP_WIDTH;
   int y2=y1+GROUP_HEIGHT;
//--- create
   if(!m_check_group.Create(m_chart_id,m_name+"CheckGroup",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!Add(m_check_group))
      return(false);
//--- fill out with strings
   if(!m_check_group.AddItem("Mail if Trade event",1<<0))
      return(false);
   if(!m_check_group.AddItem("Push if Trade event",1<<1))
      return(false);
   if(!m_check_group.AddItem("Alert if Trade event",1<<2))
      return(false);
   Comment("Value="+IntegerToString(m_check_group.Value())+
           "\nElement 0 has a state: "+IntegerToString(m_check_group.Check(0))+
           "\nElement 1 has a state: ",IntegerToString(m_check_group.Check(1))+
           "\nElement 2 has a state: ",IntegerToString(m_check_group.Check(2)));
//--- succeed
   return(true);
  }

//+------------------------------------------------------------------+
//| Create the "Label" generico                                      |
//+------------------------------------------------------------------+
bool osc_control_panel_p7_001::CreateLabel2(int coluna, int lenColuna, int linha, string nome, CLabel &objLabel, string strValor ){
//--- coordinates
   int x1=INDENT_LEFT+coluna;
   int y1=INDENT_TOP +CONTROLS_GAP_Y+linha*(BUTTON_HEIGHT+CONTROLS_GAP_Y);
   int x2=x1+lenColuna;
   int y2=y1+ALTURA_LINHA;
//--- create
   if(!objLabel.Create(m_chart_id,m_name+"Label"+nome,m_subwin,x1,y1,x2,y2)) return(false);
   if(!objLabel.Text(strValor)                                     ) return(false);
   if(!Add(objLabel)                                               ) return(false);
//--- succeed
   return(true);
}

//+------------------------------------------------------------------+
//| Create the "Edit" generico                                      |
//+------------------------------------------------------------------+
bool osc_control_panel_p7_001::CreateEdit2(int coluna, int lenColuna, int linha, string nome, CEdit &objEdit, string strValor ){
//--- coordinates
   int x1=INDENT_LEFT+coluna;
   int y1=INDENT_TOP +CONTROLS_GAP_Y+linha*(BUTTON_HEIGHT+CONTROLS_GAP_Y);
   int x2=x1+lenColuna;
   int y2=y1+ALTURA_LINHA;
//--- create
   if(!objEdit.Create(m_chart_id,m_name+"Edit"+nome,m_subwin,x1,y1,x2,y2)) return(false);
   if(!objEdit.Text(strValor)                                     ) return(false);
   if(!Add(objEdit)                                               ) return(false);
//--- succeed
   return(true);
}
  
//+------------------------------------------------------------------+
//| Create the "ButtonOK" button                                     |
//+------------------------------------------------------------------+
bool osc_control_panel_p7_001::CreateButtonOK(int posicao)
  {
//--- coordinates
   int x1=INDENT_LEFT;
   int y1=INDENT_TOP+GROUP_HEIGHT+CONTROLS_GAP_Y+posicao*(BUTTON_HEIGHT+CONTROLS_GAP_Y);
   int x2=x1+BUTTON_WIDTH*3;
   int y2=y1+BUTTON_HEIGHT;
//--- create
   if(!m_button_ok.Create(m_chart_id,m_name+"ButtonOK",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_button_ok.Text("Apply changes"))
      return(false);
   if(!Add(m_button_ok))
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void osc_control_panel_p7_001::OnChangeCheckGroup(void)
  {
   Comment("Value="+IntegerToString(m_check_group.Value())+
           "\nElement 0 has a state: "+IntegerToString(m_check_group.Check(0))+
           "\nElement 1 has a state: ",IntegerToString(m_check_group.Check(1))+
           "\nElement 2 has a state: ",IntegerToString(m_check_group.Check(2)));
   mMail=m_check_group.Check(0);
   mPush=m_check_group.Check(1);
   mAlert_=m_check_group.Check(2);
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
//void osc_control_panel_p7_001::OnChangeEditPasso(void)
//  {
//   double temp=StringToDouble(m_editPasso.Text());
//   if(temp==0.0)
//     {
//      MessageBox("In the input field \"Lots\" not a number","Input error",0);
//      m_editPasso.Text(DoubleToString(mLots,2));
//     }
//   else
//     {
//      m_editPasso.Text(DoubleToString(temp,2));
//     }
//  }
/*  
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void osc_control_panel_p7_001::OnChangeProfitPosicao(void)
  {
   int temp=(int)StringToInteger(m_edit2.Text());
   if(temp==0)
     {
      MessageBox("In the input field \"Take Profit (in pips)\" not a number","Input error",0);
      m_edit2.Text(IntegerToString(mTakeProfit));
     }
   else
     {
      m_edit2.Text(IntegerToString(temp,2));
     }
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void osc_control_panel_p7_001::OnChangeEdit3(void)
  {
   int temp=(int)StringToInteger(m_edit3.Text());
   if(temp==0)
     {
      MessageBox("In the input field \"Trailing Stop Level (in pips)\" not a number","Input error",0);
      m_edit3.Text(IntegerToString(mTrailingStop));
     }
   else
     {
      m_edit3.Text(IntegerToString(temp,2));
     }
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void osc_control_panel_p7_001::OnChangeEdit4(void)
  {
   int temp=(int)StringToInteger(m_edit4.Text());
   if(temp==0)
     {
      MessageBox("In the input field \"MACD open level (in pips)\" not a number","Input error",0);
      m_edit4.Text(IntegerToString(mMACDOpenLevel));
     }
   else
     {
      m_edit4.Text(IntegerToString(temp,2));
     }
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void osc_control_panel_p7_001::OnChangeEdit5(void)
  {
   int temp=(int)StringToInteger(m_edit5.Text());
   if(temp==0)
     {
      MessageBox("In the input field \"MACD close level (in pips)\" not a number","Input error",0);
      m_edit5.Text(IntegerToString(mMACDCloseLevel));
     }
   else
     {
      m_edit5.Text(IntegerToString(temp,2));
     }
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void osc_control_panel_p7_001::OnChangeEdit6(void)
  {
   int temp=(int)StringToInteger(m_edit6.Text());
   if(temp==0)
     {
      MessageBox("In the input field \"MA trend period\" not a number","Input error",0);
      m_edit6.Text(IntegerToString(mMATrendPeriod));
     }
   else
     {
      m_edit6.Text(IntegerToString(temp,2));
     }
  }
*/
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void osc_control_panel_p7_001::OnClickButtonOK(void)
  {
//--- verifying changes
   if(m_check_group.Check(0)!=mMail  ) mModification=true;
   if(m_check_group.Check(1)!=mPush  ) mModification=true;
   if(m_check_group.Check(2)!=mAlert_) mModification=true;

   //if(StringToInteger(m_editPasso.Text())!=m_passo)
   //  {
   //   m_passo=StringToInteger(m_editPasso.Text());
   //   mModification=true;
   //  }
   //if(StringToInteger(m_edit2.Text())!=mTakeProfit)
   //  {
   //   mTakeProfit=(int)StringToDouble(m_edit2.Text());
   //   mModification=true;
   //  }
   //if(StringToInteger(m_edit3.Text())!=mTrailingStop)
   //  {
   //   mTrailingStop=(int)StringToDouble(m_edit3.Text());
   //   mModification=true;
   //  }
   //if(StringToInteger(m_edit4.Text())!=mMACDOpenLevel)
   //  {
   //   mMACDOpenLevel=(int)StringToDouble(m_edit4.Text());
   //   mModification=true;
   //  }
   //if(StringToInteger(m_edit5.Text())!=mMACDCloseLevel)
   //  {
   //   mMACDCloseLevel=(int)StringToDouble(m_edit5.Text());
   //   mModification=true;
   //  }
   //if(StringToInteger(m_edit6.Text())!=mMATrendPeriod)
   //  {
   //   mMATrendPeriod=(int)StringToDouble(m_edit6.Text());
   //   mModification=true;
   //  }
  }
//+------------------------------------------------------------------+
//| Set check for element                                            |
//+------------------------------------------------------------------+
bool osc_control_panel_p7_001::SetCheck(const int idx,const bool check)
  {
   bool rezult=m_check_group.Check(idx,check);
   Comment("Value="+IntegerToString(m_check_group.Value())+
           "\nElement 0 has a state: "+IntegerToString(m_check_group.Check(0))+
           "\nElement 1 has a state: ",IntegerToString(m_check_group.Check(1))+
           "\nElement 2 has a state: ",IntegerToString(m_check_group.Check(2)));
   return(rezult);
  }
//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
bool osc_control_panel_p7_001::Initialization(const bool Mail,const bool Push,const bool Alert_,
                                     const double Lots,const int TakeProfit,
                                     const int  TrailingStop,const int MACDOpenLevel,
                                     const int  MACDCloseLevel,const int MATrendPeriod)
  {
   mMail=Mail;
   mPush=Push;
   mAlert_=Alert_;

   mLots=Lots;
   mTakeProfit=TakeProfit;
   mTrailingStop=TrailingStop;
   mMACDOpenLevel=MACDOpenLevel;
   mMACDCloseLevel=MACDCloseLevel;
   mMATrendPeriod=MATrendPeriod;
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Get values                                                       |
//+------------------------------------------------------------------+
void osc_control_panel_p7_001::GetValues(bool &Mail,bool &Push,bool &Alert_,
                                double &Lots,int &TakeProfit,
                                int &TrailingStop,int &MACDOpenLevel,
                                int &MACDCloseLevel,int &MATrendPeriod)
  {
   Mail=mMail;
   Push=mPush;
   Alert_=mAlert_;

   Lots=mLots;
   TakeProfit=mTakeProfit;
   TrailingStop=mTrailingStop;
   MACDOpenLevel=mMACDOpenLevel;
   MACDCloseLevel=mMACDCloseLevel;
   MATrendPeriod=mMATrendPeriod;
  }
//+------------------------------------------------------------------+
//|  Send notifications                                              |
//+------------------------------------------------------------------+
void osc_control_panel_p7_001::Notifications(const string text)
  {
   int i=m_check_group.ControlsTotal();
   if(GetCheck(0))
      SendMail(" ",text);
   if(GetCheck(1))
      SendNotification(text);
   if(GetCheck(2))
      Alert(text);
  }
//+------------------------------------------------------------------+
//| Get check for element                                            |
//+------------------------------------------------------------------+
int osc_control_panel_p7_001::GetCheck(const int idx)
  {
   return(m_check_group.Check(idx));
  }
//+------------------------------------------------------------------+
