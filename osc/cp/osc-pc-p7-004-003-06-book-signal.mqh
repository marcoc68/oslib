//+----------------------------------------------------------------------+
//|                                 osc-pc-p7-004-003-06-book-signal.mqh |
//|                                   Copyright 2022,oficina de software.|
//|                                                    http://www.os.org |
//+----------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
//| Class osc_control_panel_p7_004_003_06                            |
//| Usage: Painel de Controle para o Expert P7-004-003-06-BOOK-SIGNAL|
//+------------------------------------------------------------------+
class osc_control_panel_p7_004_003_06 : public CAppDialog {
private:
   CCheckGroup       m_check_group;                   // the CheckGroup object

//====================================================================================
   CLabel            m_labelPosicao;                  // the label object
   CEdit             m_editPosicao;                   // the display field object
   string            m_posicao;                       // informa se estah comprado ou vendido

   CLabel            m_labelT4g;                      // the label object
   CEdit             m_editT4g;                       // the display field object
   double            m_t4g;                           // ticks for gain (primeiro passo)

   CLabel            m_labelTarWIN;                    // the label object
   CEdit             m_editTarWIN;                     // the display field object
   double            m_tarWIN    ;                     // passo em ticks;

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
//====================================================================================
   CLabel            m_labelIWFV;                  // the label object
   CEdit             m_editIWFV;                   // the display field object
   double            m_IWFV;                       // IWFV

   CLabel            m_labelTLFV;                  // the label object
   CEdit             m_editTLFV;                   // the display field object
   double            m_TLFV;                       // TLFV

   CLabel            m_labelImbal;                 // the label object
   CEdit             m_editImbal;                  // the display field object
   double            m_imbal;                      // desbalanceamento do book

   CLabel            m_labelSinalBook;             // the label object
   CEdit             m_editSinalBook;              // the display field object
   double            m_sinalBook;                  // sinal do book 1(compre), -1(venda), 0(mantenha)

   CLabel            m_labelVTLen;                        // the label object
   CEdit             m_editVTLen;                         // the display field object
   double            m_VTLen;                             // propabilidade do preco descer

   CLabel            m_labelSinalBook2;                        // the label object
   CEdit             m_editSinalBook2;                         // the display field object
   double            m_sinalBook2;                             // media de velocidade da direcao do trade.

   CLabel            m_labelLEN1;                        // the label object
   CEdit             m_editLEN1;                         // the display field object
   double            m_LEN1;                             // propabilidade do preco descer

   CLabel            m_labelLEN0;                        // the label object
   CEdit             m_editLEN0;                         // the display field object
   double            m_LEN0;                             // propabilidade do preco descer

   CButton           m_button_ok;                     // the button "OK" object

   void setEditValue(double p, CEdit &edit, double lim, color cup, color cdw, color clim ){ 
        
        //edit=p; 
        edit.Text( DoubleToString (p,2) ); 
        
        if(p>lim){
            edit.Color(cup);
        }else{ 
            if(p<lim){
                edit.Color(cdw);
            }else{ 
                edit.Color(clim);
            }
        }
   }

public:
                     osc_control_panel_p7_004_003_06(void);
                    ~osc_control_panel_p7_004_003_06(void);
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
   void setT4g          (double p ){ if(p== m_t4g          )return; m_t4g          = p; m_editT4g          .Text( DoubleToString (p,2) ); }
 //void setTarWIN       (double p ){ if(p== m_tarWIN       )return; m_tarWIN       = p; m_editTarWIN       .Text( DoubleToString (p,2 )); }
   void setProfitPosicao(double p ){ if(p== m_profitPosicao)return; m_profitPosicao= p; m_editProfitPosicao.Text( DoubleToString (p,2) ); if( p<0)m_editProfitPosicao.Color(clrRed   ); if(p>0)m_editProfitPosicao.Color(clrBlue); if(p==0)m_editProfitPosicao.Color(clrGray);  }
   void setSaidaPosicao (double p ){ if(p== m_saidaPosicao )return; m_saidaPosicao = p; m_editSaidaPosicao .Text( DoubleToString (p,2) ); if( p<0)m_editSaidaPosicao .Color(clrRed   ); if(p>0)m_editSaidaPosicao .Color(clrBlue); if(p==0)m_editSaidaPosicao .Color(clrGray);  }
   void setStopLoss     (double p ){ if(p== m_stopLoss     )return; m_stopLoss     = p; m_editStopLoss     .Text( DoubleToString (p,2) );         m_editStopLoss     .Color(clrLightSalmon); }
   void setVolPosicao   (string p ){ if(p== m_volPosicao   )return; m_volPosicao   = p; m_editVolPosicao   .Text(                 p    ); }
   void setPftBruto     (double p ){ if(p== m_pftBruto     )return; m_pftBruto     = p; m_editPftBruto     .Text( DoubleToString (p,2) ); if( p<0)m_editPftBruto     .Color(clrRed); if(p>0)m_editPftBruto     .Color(clrBlue); if(p==0)m_editPftBruto     .Color(clrGray);  }
   void setTarifa       (double p ){ if(p==-m_tarifa       )return; m_tarifa       =-p; m_editTarifa       .Text( DoubleToString (p,2) ); if(-p<0)m_editTarifa       .Color(clrRed);                                            if(p==0)m_editTarifa       .Color(clrGray);  }
   void setPftContrat   (double p ){ if(p== m_pftContrat   )return; m_pftContrat   = p; m_editPftContrat   .Text( DoubleToString (p,2) ); if( p<0)m_editPftContrat   .Color(clrRed); if(p>0)m_editPftContrat   .Color(clrBlue); if(p==0)m_editPftContrat   .Color(clrGray);  }
   void setPftLiquido   (double p ){ if(p== m_pftLiquido   )return; m_pftLiquido   = p; m_editPftLiquido   .Text( DoubleToString (p,2) ); if( p<0)m_editPftLiquido   .Color(clrRed); if(p>0)m_editPftLiquido   .Color(clrBlue); if(p==0)m_editPftLiquido   .Color(clrGray);  }
   void setVol          (double p ){ if(p== m_vol          )return; m_vol          = p; m_editVol          .Text( DoubleToString (p,2) ); }

   void setTarWIN   (double p, double limiar=0 ){ if(p==m_tarWIN   )return; m_tarWIN   =p; setEditValue(p,m_editTarWIN   ,limiar,clrRed ,clrBlue,clrGray); }
   void setIWFV     (double p, double limiar=0 ){ if(p==m_IWFV     )return; m_IWFV     =p; setEditValue(p,m_editIWFV     ,limiar,clrRed ,clrBlue,clrGray); }
   void setTLFV     (double p, double limiar=0 ){ if(p==m_TLFV     )return; m_TLFV     =p; setEditValue(p,m_editTLFV     ,limiar,clrBlue,clrRed ,clrGray); }
   void setImbal    (double p, double limiar=0 ){ if(p==m_imbal    )return; m_imbal    =p; setEditValue(p,m_editImbal    ,limiar,clrBlue,clrRed ,clrGray); }
   void setSinalBook(double p, double limiar=0 ){ if(p==m_sinalBook)return; m_sinalBook=p; setEditValue(p,m_editSinalBook,limiar,clrBlue,clrRed ,clrGray); }

   void setVTLen (double p, double limiar=0 ){ if(p==m_VTLen     )return; m_VTLen     =p; setEditValue(p,m_editVTLen     ,limiar,clrBlue,clrRed ,clrGray); }
   void setVTDir2(double p, double limiar=0 ){ if(p==m_sinalBook2)return; m_sinalBook2=p; setEditValue(p,m_editSinalBook2,limiar,clrBlue,clrRed ,clrGray); }
   void setLEN0  (double p, double limiar=0 ){ if(p==m_LEN0      )return; m_LEN0      =p; setEditValue(p,m_editLEN0      ,limiar,clrBlue,clrRed ,clrGray); }
   void setLEN1  (double p, double limiar=0 ){ if(p==m_LEN1      )return; m_LEN1      =p; setEditValue(p,m_editLEN1      ,limiar,clrBlue,clrRed ,clrGray); }

   //void setVTLen (double p, double lim ){ if(p==m_VTLen )return; m_VTLen=p; m_editVTLen.Text( DoubleToString (p,0) ); if( p>=lim)m_editVTLen.Color(clrBlue); if(p<lim)m_editVTLen.Color(clrBlack); }
   //void setVTDir2 (double p, double lim ){ if(p==m_sinalBook2 )return; m_sinalBook2=p; m_editSinalBook2.Text( DoubleToString (p,0) ); if( p>=lim)m_editSinalBook2.Color(clrBlue); if(p<lim)m_editSinalBook2.Color(clrBlack); }
   //void setLEN1 (double p, double lim=0 ){ if(p==m_LEN1 )return; m_LEN1=p; m_editLEN1.Text( DoubleToString (p,0) ); if( p>=lim)m_editLEN1.Color(clrBlue); if(p<lim)m_editLEN1.Color(clrBlack); }
   //void setLEN0 (double p, double lim=0 ){ if(p==m_LEN0 )return; m_LEN0=p; m_editLEN0.Text( DoubleToString (p,0) ); if( p>=lim)m_editLEN0.Color(clrBlue); if(p<lim)m_editLEN0.Color(clrBlack); }

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
EVENT_MAP_BEGIN(osc_control_panel_p7_004_003_06)
//ON_EVENT(ON_CHANGE,m_check_group,OnChangeCheckGroup)
//ON_EVENT(ON_CHANGE,m_editTarWIN,OnChangeEditPasso)
//ON_EVENT(ON_END_EDIT,m_editTarWIN,OnChangeEditPasso)
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
osc_control_panel_p7_004_003_06::osc_control_panel_p7_004_003_06(void):mMail(false),
                                                                 mPush(false),
                                                                 mAlert_(true),
                                                                 mLots(0.1),
                                                                 mTakeProfit(50),
                                                                 mTrailingStop(30),
                                                                 mMACDOpenLevel(3),
                                                                 mMACDCloseLevel(2),
                                                                 mMATrendPeriod(26),
                                                                 mModification(false)  {}
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
osc_control_panel_p7_004_003_06::~osc_control_panel_p7_004_003_06(void){}
//+------------------------------------------------------------------+
//| Create                                                           |
//+------------------------------------------------------------------+
bool osc_control_panel_p7_004_003_06::Create(){ return Create(0,"Painel de Controle P7-004-003-06",0,100,100,LARGURA_CONTROL_PANEL,ALTURA_CONTROL_PANEL); }
bool osc_control_panel_p7_004_003_06::Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2)
  {
   if(!CAppDialog::Create(chart,name,subwin,x1,y1,x2,y2))
      return(false);

//--- create dependent controls
 //if(!CreateCheckGroup()) return(false);

   int linha = 0;
   // posicao comprada ou vendida
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, linha, "Posicao",m_labelPosicao,"Posicao"                 )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, linha, "Posicao",m_editPosicao ,m_posicao                 )) return(false);
   if(!CreateLabel2(INI_COLUNA_03, LARGURA_COLUNA_03, linha, "IWFV"   ,m_labelIWFV   ,"IWFV"                    )) return(false);
   if(!CreateEdit2 (INI_COLUNA_04, LARGURA_COLUNA_04, linha, "IWFV"   ,m_editIWFV    ,DoubleToString(m_IWFV,0)  )) return(false);

   // ticks for gain. Antes do primeiro passo rajada
   linha++;
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, linha, "T4g"  ,m_labelT4g  ,"Ticks4Gain"              )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, linha, "T4g"  ,m_editT4g   ,DoubleToString(m_t4g,2)   )) return(false);
   if(!CreateLabel2(INI_COLUNA_03, LARGURA_COLUNA_03, linha, "TLFV" ,m_labelTLFV ,"TLFV"                    )) return(false);
   if(!CreateEdit2 (INI_COLUNA_04, LARGURA_COLUNA_04, linha, "TLFV" ,m_editTLFV  ,DoubleToString(m_TLFV,0)  )) return(false);

   // passo rajada
   linha++;
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, linha, "UmaTarifWIN" ,m_labelTarWIN ,"UmaTarifWIN"             )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, linha, "UmaTarifWIN" ,m_editTarWIN  ,DoubleToString(m_tarWIN,2) )) return(false);
   if(!CreateLabel2(INI_COLUNA_03, LARGURA_COLUNA_03, linha, "IMBAL"       ,m_labelImbal ,"IMBAL"                   )) return(false);
   if(!CreateEdit2 (INI_COLUNA_04, LARGURA_COLUNA_04, linha, "IMBAL"       ,m_editImbal  ,DoubleToString(m_imbal,2) )) return(false);

   // profit da posicao
   linha++;
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, linha, "ProfitPosic",m_labelProfitPosicao,"ProfitPosic"                     )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, linha, "ProfitPosic",m_editProfitPosicao ,DoubleToString(m_profitPosicao,2) )) return(false);
   if(!CreateLabel2(INI_COLUNA_03, LARGURA_COLUNA_03, linha, "SINAL"       ,m_labelSinalBook   ,"SINAL"                           )) return(false); // desvio padrao da banda de bolinguer
   if(!CreateEdit2 (INI_COLUNA_04, LARGURA_COLUNA_04, linha, "SINAL"       ,m_editSinalBook    ,DoubleToString(m_sinalBook,0)     )) return(false); // desvio padrao da banda de bolinguer

   // saida esperada da posicao
   linha++;
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, linha, "SaidaPosic",m_labelSaidaPosicao,"SaidaPosic"                     )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, linha, "SaidaPosic",m_editSaidaPosicao ,DoubleToString(m_saidaPosicao,2) )) return(false);
   if(!CreateLabel2(INI_COLUNA_03, LARGURA_COLUNA_03, linha, "VTLen"      ,m_labelVTLen      ,"VTLen"                          )) return(false);
   if(!CreateEdit2 (INI_COLUNA_04, LARGURA_COLUNA_04, linha, "VTLen"      ,m_editVTLen       ,DoubleToString(m_VTLen,0)        )) return(false);

   // stop_loss da posicao
   linha++;
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, linha, "StopLoss",m_labelStopLoss,"StopLoss"                   )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, linha, "StopLoss",m_editStopLoss ,DoubleToString(m_stopLoss,2) )) return(false);
   if(!CreateLabel2(INI_COLUNA_03, LARGURA_COLUNA_03, linha, "VTDir2"  ,m_labelSinalBook2  ,"VTDir2"                     )) return(false);
   if(!CreateEdit2 (INI_COLUNA_04, LARGURA_COLUNA_04, linha, "VTDir2"  ,m_editSinalBook2   ,DoubleToString(m_sinalBook2,2)   )) return(false);

   // volume da posicao
   linha++;
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, linha, "VolPosicao",m_labelVolPosicao,"VolPosicao"             )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, linha, "VolPosicao",m_editVolPosicao ,m_volPosicao             )) return(false);
   if(!CreateLabel2(INI_COLUNA_03, LARGURA_COLUNA_03, linha, "LEN1"      ,m_labelLEN1      ,"LEN1"                   )) return(false);
   if(!CreateEdit2 (INI_COLUNA_04, LARGURA_COLUNA_04, linha, "LEN1"      ,m_editLEN1       ,DoubleToString(m_LEN1,2) )) return(false);

   // profit bruto do dia WIN+WDO+OUTROS
   linha++;
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, linha, "PtfBruto",m_labelPftBruto,"PtfBruto"                   )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, linha, "PtfBruto",m_editPftBruto ,DoubleToString(m_pftBruto,2) )) return(false);
   if(!CreateLabel2(INI_COLUNA_03, LARGURA_COLUNA_03, linha, "LEN0"    ,m_labelLEN0    ,"LEN0"                       )) return(false);
   if(!CreateEdit2 (INI_COLUNA_04, LARGURA_COLUNA_04, linha, "LEN0"    ,m_editLEN0     ,DoubleToString(m_LEN0,2)     )) return(false);

   // tarifa do dia WIN+WDO+OUTROS
   linha++;
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, linha, "Tarifa",m_labelTarifa,"Tarifa"                   )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, linha, "Tarifa",m_editTarifa ,DoubleToString(m_tarifa,2) )) return(false);

   // profit por contrato do dia WIN+WDO+OUTROS
   linha++;
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, linha, "PftContrat",m_labelPftContrat,"PftContrat"                   )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, linha, "PftContrat",m_editPftContrat ,DoubleToString(m_pftContrat,2) )) return(false);

   // profit liquido do dia WIN+WDO+OUTROS
   linha++;
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, linha, "PftLiquido",m_labelPftLiquido,"PftLiquido"                   )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, linha, "PftLiquido",m_editPftLiquido ,DoubleToString(m_pftLiquido,2) )) return(false);

   // volume do dia WIN+WDO+OUTROS
   linha++;
   if(!CreateLabel2(INI_COLUNA_01, LARGURA_COLUNA_01, linha, "Vol",m_labelVol,"Vol"                   )) return(false);
   if(!CreateEdit2 (INI_COLUNA_02, LARGURA_COLUNA_02, linha, "Vol",m_editVol ,DoubleToString(m_vol,2) )) return(false);

   linha++;
   if(!CreateButtonOK(linha)) return(false);

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
bool osc_control_panel_p7_004_003_06::CreateCheckGroup(void)
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
bool osc_control_panel_p7_004_003_06::CreateLabel2(int coluna, int lenColuna, int linha, string nome, CLabel &objLabel, string strValor ){
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
bool osc_control_panel_p7_004_003_06::CreateEdit2(int coluna, int lenColuna, int linha, string nome, CEdit &objEdit, string strValor ){
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
bool osc_control_panel_p7_004_003_06::CreateButtonOK(int posicao)
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
void osc_control_panel_p7_004_003_06::OnChangeCheckGroup(void)
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
//void osc_control_panel_p7_004_003_06::OnChangeEditPasso(void)
//  {
//   double temp=StringToDouble(m_editTarWIN.Text());
//   if(temp==0.0)
//     {
//      MessageBox("In the input field \"Lots\" not a number","Input error",0);
//      m_editTarWIN.Text(DoubleToString(mLots,2));
//     }
//   else
//     {
//      m_editTarWIN.Text(DoubleToString(temp,2));
//     }
//  }
/*  
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void osc_control_panel_p7_004_003_06::OnChangeProfitPosicao(void)
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
void osc_control_panel_p7_004_003_06::OnChangeEdit3(void)
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
void osc_control_panel_p7_004_003_06::OnChangeEdit4(void)
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
void osc_control_panel_p7_004_003_06::OnChangeEdit5(void)
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
void osc_control_panel_p7_004_003_06::OnChangeEdit6(void)
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
void osc_control_panel_p7_004_003_06::OnClickButtonOK(void)
  {
//--- verifying changes
   if(m_check_group.Check(0)!=mMail  ) mModification=true;
   if(m_check_group.Check(1)!=mPush  ) mModification=true;
   if(m_check_group.Check(2)!=mAlert_) mModification=true;

   //if(StringToInteger(m_editTarWIN.Text())!=m_tarWIN)
   //  {
   //   m_tarWIN=StringToInteger(m_editTarWIN.Text());
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
bool osc_control_panel_p7_004_003_06::SetCheck(const int idx,const bool check)
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
bool osc_control_panel_p7_004_003_06::Initialization(const bool Mail,const bool Push,const bool Alert_,
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
void osc_control_panel_p7_004_003_06::GetValues(bool &Mail,bool &Push,bool &Alert_,
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
void osc_control_panel_p7_004_003_06::Notifications(const string text)
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
int osc_control_panel_p7_004_003_06::GetCheck(const int idx)
  {
   return(m_check_group.Check(idx));
  }
//+------------------------------------------------------------------+
