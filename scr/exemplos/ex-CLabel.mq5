//+------------------------------------------------------------------+
//|                                                    ex-CLabel.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+ 
//|                                                ControlsLabel.mq5 | 
//|                        Copyright 2017, MetaQuotes Software Corp. | 
//|                                             https://www.mql5.com | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright 2017, MetaQuotes Software Corp." 
#property link      "https://www.mql5.com" 
#property version   "1.00" 
#property description "Control Panels and Dialogs. Demonstration class CLabel" 
#include <Controls\Dialog.mqh> 
#include <Controls\Label.mqh> 
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
#define BUTTON_WIDTH                        (100)     // size by X coordinate 
#define BUTTON_HEIGHT                       (20)      // size by Y coordinate 
//--- for the indication area 
#define EDIT_HEIGHT                         (20)      // size by Y coordinate 
//--- for group controls 
#define GROUP_WIDTH                         (150)     // size by X coordinate 
#define LIST_HEIGHT                         (179)     // size by Y coordinate 
#define RADIO_HEIGHT                        (56)      // size by Y coordinate 
#define CHECK_HEIGHT                        (93)      // size by Y coordinate 
//+------------------------------------------------------------------+ 
//| Class CControlsDialog                                            | 
//| Usage: main dialog of the Controls application                   | 
//+------------------------------------------------------------------+ 
class CControlsDialog : public CAppDialog 
  { 
private: 
   CLabel            m_label;                         // CLabel object 
   CLabel            m_label2;                        // CLabel object 
public: 
                     CControlsDialog(void); 
                    ~CControlsDialog(void); 
   //--- create 
   virtual bool      Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2); 
   //--- chart event handler 
   virtual bool      OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam); 

CLabel* addLabel(string strLabel);
//void alterLabel(long id, string strLabel);

//protected: 
   //--- create dependent controls 
   bool              CreateLabel(void); 
   //--- handlers of the dependent controls events 
   void              OnClickLabel(void); 
  }; 
//+------------------------------------------------------------------+ 
//| Event Handling                                                   | 
//+------------------------------------------------------------------+ 
EVENT_MAP_BEGIN(CControlsDialog) 
  
EVENT_MAP_END(CAppDialog) 
//+------------------------------------------------------------------+ 
//| Constructor                                                      | 
//+------------------------------------------------------------------+ 
CControlsDialog::CControlsDialog(void) 
  { 
  } 
//+------------------------------------------------------------------+ 
//| Destructor                                                       | 
//+------------------------------------------------------------------+ 
CControlsDialog::~CControlsDialog(void) 
  { 
  } 
//+------------------------------------------------------------------+ 
//| Create                                                           | 
//+------------------------------------------------------------------+ 
bool CControlsDialog::Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2) 
  { 
   if(!CAppDialog::Create(chart,name,subwin,x1,y1,x2,y2)) 
      return(false); 
//--- create dependent controls 
   if(!CreateLabel()) 
      return(false); 
//--- succeed 
   return(true); 
  } 
//+-------------------------------------------------------------------------+ 
//| Adicional uma classe "CLabel" logo apos a ulima e com o texto informado.|
//| Retorna o id do label, o que possibilita posterior alteracao.           |
//+-------------------------------------------------------------------------+
#define ALTURA_LINHA 20
int m_linha_label =  ALTURA_LINHA;
int m_x1=INDENT_RIGHT; 
int m_y1=INDENT_TOP+CONTROLS_GAP_Y; 
int m_x2=m_x1+100; 
int m_y2=m_y1+ALTURA_LINHA; 

CLabel* CControlsDialog::addLabel(string strLabel){
   CLabel* label;
    
   if(!label.Create(m_chart_id,m_name+"strLabel",m_subwin,m_x1,m_y1+ALTURA_LINHA,m_x2,m_y2) ) return(NULL); 
   if(!label.Text(strLabel) ) return(NULL); 
   if(!Add(label)           ) return(NULL);
   m_y1 += ALTURA_LINHA;
   return label;
}

//void CControlsDialog::alterLabel(long id, string strLabel){
//   CLabel label;
//   (label.ControlFind(id)).Text(strLabel);
//}

//+------------------------------------------------------------------+ 
//| Create the "CLabel"                                              | 
//+------------------------------------------------------------------+ 
bool CControlsDialog::CreateLabel(void){
//--- coordinates 
   int x1=INDENT_RIGHT; 
   int y1=INDENT_TOP+CONTROLS_GAP_Y; 
   int x2=x1+100; 
   int y2=y1+20; 
//--- create 
   if(!m_label.Create(m_chart_id,m_name+"Labelxxx",m_subwin,x1,y1,x2,y2)) return(false); 
   if(!m_label.Text("Labelxxx")) return(false); 
   if(!Add(m_label)            ) return(false); 
//--- succeed 
   //if(!m_label2.Create(m_chart_id,m_name+"Label2xxx",m_subwin,x1,y1+20,x2,y2)) return(false); 
   //if(!m_label2.Text("Label2xxx")) return(false); 
   //if(!Add(m_label2)            ) return(false); 

   //if(!m_label2.Text("Label3xxx\nxxx")) return(false); 
   return(true); 
}
  
//+------------------------------------------------------------------+ 
//| Global Variables                                                 | 
//+------------------------------------------------------------------+ 
CControlsDialog ExtDialog; 
//+------------------------------------------------------------------+ 
//| Expert initialization function                                   | 
//+------------------------------------------------------------------+ 
int OnInit() 
  { 
//--- create application dialog 
   if(!ExtDialog.Create(0,"Controls",0,40,40,380,344)) 
      return(INIT_FAILED); 
//--- run application 
   ExtDialog.Run(); 
//--- succeed 
   return(INIT_SUCCEEDED); 
  } 
//+------------------------------------------------------------------+ 
//| Expert deinitialization function                                 | 
//+------------------------------------------------------------------+ 
void OnDeinit(const int reason) 
  { 
//---  
   Comment(""); 
//--- destroy dialog 
   ExtDialog.Destroy(reason); 
  } 
//+------------------------------------------------------------------+ 
//| Expert chart event function                                      | 
//+------------------------------------------------------------------+ 
void OnChartEvent(const int id,         // event ID   
                  const long& lparam,   // event parameter of the long type 
                  const double& dparam, // event parameter of the double type 
                  const string& sparam) // event parameter of the string type 
  { 
   ExtDialog.ChartEvent(id,lparam,dparam,sparam); 
  }