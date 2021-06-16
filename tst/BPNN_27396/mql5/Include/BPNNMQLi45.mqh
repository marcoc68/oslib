//
//                 I N D I C A T O R S
//

#define EMPTY  -1

bool _SetIndexBuffer(const int index, double &buffer[], const ENUM_INDEXBUFFER_TYPE type = INDICATOR_DATA)
{
  bool b = ::SetIndexBuffer(index, buffer, type);
  ArraySetAsSeries(buffer, true);
  return b;
}

#define SetIndexBuffer _SetIndexBuffer

void SetIndexStyle(const int index, const int type, const int style = EMPTY, const int width = EMPTY, const color clr = clrNONE)
{
  PlotIndexSetInteger(index, PLOT_DRAW_TYPE, type);
  if(style != EMPTY) PlotIndexSetInteger(index, PLOT_LINE_STYLE, style);
  if(width != EMPTY) PlotIndexSetInteger(index, PLOT_LINE_WIDTH, width);
  if(clr != clrNONE) PlotIndexSetInteger(index, PLOT_LINE_COLOR, clr);
}

void SetIndexShift(const int buffer, const int shift)
{
  PlotIndexSetInteger(buffer, PLOT_SHIFT, shift);
}

void SetIndexLabel(const int index, const string text)
{
  PlotIndexSetString(index, PLOT_LABEL, text);
}

void SetIndexEmptyValue(const int index, const double value)
{
  PlotIndexSetDouble(index, PLOT_EMPTY_VALUE, value);
}

void SetIndexArrow(const int index, const int code)
{
  PlotIndexSetInteger(index, PLOT_ARROW, code);
}

void IndicatorShortName(const string name)
{
  IndicatorSetString(INDICATOR_SHORTNAME, name);
}

void IndicatorDigits(const int digits)
{
  IndicatorSetInteger(INDICATOR_DIGITS, digits);
}

void SetLevelValue(const int level, const double value)
{
  IndicatorSetDouble(INDICATOR_LEVELVALUE, level, value);
}
