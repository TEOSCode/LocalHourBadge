//+------------------------------------------------------------------+
//|                                                    LocalHour.mq5 |
//|                                        Copyright 2026, LemuzLabs |
//|                                  https://lemuzlabs.blogspot.com/ |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                     CustomCrosshairTime.mq5      |
//|                                  Etiqueta de Tiempo Personalizada|
//+------------------------------------------------------------------+
#property copyright "Copyright 2026"
#property link      ""
#property version   "1.10"
#property indicator_chart_window


//--- Lista de Formatos Disponibles
enum ENUM_DATE_FORMAT
{
   FMT_LUN_25_JUN_26_400PM, // Lun 25 Jun 26 4:00PM
   FMT_25_JUN_2026_1630,    // 25 Jun 2026 16:30
   FMT_YYYY_MM_DD_1630,     // 2026.06.25 16:30
   FMT_DD_MM_YYYY_1630,     // 25/06/2026 16:30
   FMT_MM_DD_1630,          // 06/25 16:30
   FMT_LUN_1630,            // Lun 16:30
   FMT_1630_ONLY            // 16:30 (Solo hora)
};

//--- Parámetros de Entrada (Inputs)
input group "--- Configuración de Tiempo ---"
input int               InpTimeOffsetHours = -7;                       // Desplazamiento de Horas (ej. -7, +2)
input ENUM_DATE_FORMAT  InpDateFormat      = FMT_LUN_25_JUN_26_400PM; // Formato de fecha y hora

input group "--- Apariencia Visual ---"
input color             InpTextColor       = clrWhite;                 // Color del texto
input color             InpBgColor         = clrBlack;                 // Color de fondo
input color             InpBorderColor     = clrDarkGray;              // Color del borde
input int               InpFontSize        = 9;                        // Tamaño de fuente
input string            InpFontName        = "Arial";               // Fuente (Monospaced recomendada)
input int               InpYOffsetPixels   = 10;                       // Distancia desde el borde inferior (px)

//--- Nombres de Objetos
#define OBJ_BG_NAME   "CustomCH_Time_BG"
#define OBJ_TEXT_NAME "CustomCH_Time_Text"

bool g_crosshair_active = false;

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit()
{
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
   DeleteAllObjects();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| OnDeinit                                                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, false);
   DeleteAllObjects();
}

int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[],
                const double &open[], const double &high[], const double &low[],
                const double &close[], const long &tick_volume[], const long &volume[],
                const int &spread[])
{
   return(rates_total);
}

//+------------------------------------------------------------------+
//| OnChartEvent                                                     |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   // 1. Activar / Desactivar con Tecla 'F'
   if(id == CHARTEVENT_KEYDOWN)
   {
      if(lparam == 70) // Tecla F
      {
         g_crosshair_active = !g_crosshair_active;
         if(!g_crosshair_active) DeleteAllObjects();
      }
   }

   // 2. Movimiento de Ratón
   if(id == CHARTEVENT_MOUSE_MOVE)
   {
      uint flags = (uint)StringToInteger(sparam);
      bool is_middle_click = ((flags & 16) != 0);
      bool is_left_click   = ((flags & 1) != 0);

      // Si hace clic izquierdo, se apaga la etiqueta
      if(is_left_click && !is_middle_click)
      {
         g_crosshair_active = false;
         DeleteAllObjects();
         return;
      }

      // Si se mantiene presionada la rueda del ratón, la etiqueta se mantiene activa
      if(is_middle_click)
      {
         g_crosshair_active = true;
      }

      // Si NO está activa, asegurar que los objetos se borren
      if(!g_crosshair_active)
      {
         DeleteAllObjects();
         return;
      }

      // --- DIBUJAR SOLAMENTE LA ETIQUETA ---
      int x = (int)lparam;
      int y = (int)dparam;
      int subwindow = 0;
      datetime t;
      double p;

      if(ChartXYToTimePrice(0, x, y, subwindow, t, p))
      {
         datetime adjusted_time = t + (InpTimeOffsetHours * 3600);
         string time_str = FormatCustomDate(adjusted_time, InpDateFormat);
         
         int chart_height = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
         int label_y = chart_height - InpYOffsetPixels;

         DrawOrUpdateLabel(x, label_y, time_str);
         ChartRedraw(0);
      }
   }
}

//+------------------------------------------------------------------+
//| Elimina los objetos de la etiqueta                               |
//+------------------------------------------------------------------+
void DeleteAllObjects()
{
   bool redraw = false;
   string objs[] = {OBJ_BG_NAME, OBJ_TEXT_NAME};
   
   for(int i = 0; i < 2; i++)
   {
      if(ObjectFind(0, objs[i]) >= 0)
      {
         ObjectDelete(0, objs[i]);
         redraw = true;
      }
   }
   if(redraw) ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Formateador de Fechas                                            |
//+------------------------------------------------------------------+
string FormatCustomDate(datetime time, ENUM_DATE_FORMAT format_type)
{
   MqlDateTime dt;
   TimeToStruct(time, dt);
   
   string days[]   = {"Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"};
   string months[] = {"Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"};

   switch(format_type)
   {
      case FMT_LUN_25_JUN_26_400PM:
      {
         string am_pm = (dt.hour >= 12) ? " PM" : " AM";
         int hour_12  = dt.hour % 12;
         if(hour_12 == 0) hour_12 = 12;
         return StringFormat("%s %02d %s %02d %d:%02d%s", 
                             days[dt.day_of_week], dt.day, months[dt.mon - 1], 
                             dt.year % 100, hour_12, dt.min, am_pm);
      }
      case FMT_25_JUN_2026_1630: return StringFormat("%02d %s %d %02d:%02d", dt.day, months[dt.mon - 1], dt.year, dt.hour, dt.min);
      case FMT_YYYY_MM_DD_1630:  return StringFormat("%d.%02d.%02d %02d:%02d", dt.year, dt.mon, dt.day, dt.hour, dt.min);
      case FMT_DD_MM_YYYY_1630:  return StringFormat("%02d/%02d/%d %02d:%02d", dt.day, dt.mon, dt.year, dt.hour, dt.min);
      case FMT_MM_DD_1630:       return StringFormat("%02d/%02d %02d:%02d", dt.mon, dt.day, dt.hour, dt.min);
      case FMT_LUN_1630:         return StringFormat("%s %02d:%02d", days[dt.day_of_week], dt.hour, dt.min);
      case FMT_1630_ONLY:        return StringFormat("%02d:%02d", dt.hour, dt.min);
   }
   return TimeToString(time, TIME_DATE | TIME_MINUTES);
}

//+------------------------------------------------------------------+
//| Dibuja Etiqueta                                                  |
//+------------------------------------------------------------------+
void DrawOrUpdateLabel(int x, int y, string text)
{
   int width = StringLen(text) * 7 + 2; 
   int height = 18;

   if(ObjectFind(0, OBJ_BG_NAME) < 0)
   {
      ObjectCreate(0, OBJ_BG_NAME, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, OBJ_BG_NAME, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, OBJ_BG_NAME, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, OBJ_BG_NAME, OBJPROP_BACK, false);
   }
   
   ObjectSetInteger(0, OBJ_BG_NAME, OBJPROP_XDISTANCE, x - (width / 2));
   ObjectSetInteger(0, OBJ_BG_NAME, OBJPROP_YDISTANCE, y - (height / 2));
   ObjectSetInteger(0, OBJ_BG_NAME, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, OBJ_BG_NAME, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, OBJ_BG_NAME, OBJPROP_BGCOLOR, InpBgColor);
   ObjectSetInteger(0, OBJ_BG_NAME, OBJPROP_BORDER_COLOR, InpBorderColor);
   ObjectSetInteger(0, OBJ_BG_NAME, OBJPROP_BORDER_TYPE, BORDER_FLAT);

   if(ObjectFind(0, OBJ_TEXT_NAME) < 0)
   {
      ObjectCreate(0, OBJ_TEXT_NAME, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, OBJ_TEXT_NAME, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, OBJ_TEXT_NAME, OBJPROP_ANCHOR, ANCHOR_CENTER);
      ObjectSetInteger(0, OBJ_TEXT_NAME, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, OBJ_TEXT_NAME, OBJPROP_BACK, false);
   }
   
   ObjectSetInteger(0, OBJ_TEXT_NAME, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, OBJ_TEXT_NAME, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, OBJ_TEXT_NAME, OBJPROP_TEXT, text);
   ObjectSetString(0, OBJ_TEXT_NAME, OBJPROP_FONT, InpFontName);
   ObjectSetInteger(0, OBJ_TEXT_NAME, OBJPROP_FONTSIZE, InpFontSize);
   ObjectSetInteger(0, OBJ_TEXT_NAME, OBJPROP_COLOR, InpTextColor);
}