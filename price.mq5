//+------------------------------------------------------------------+
//|                                                  PriceAction.mq5 |
//|                           Copyright 2024, Automated Trading Ltd. |
//|                        https://github.com/H4ck3r217/Trading-Bots |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Automated Trading Ltd."
#property link      "https://github.com/H4ck3r217/Trading-Bots"
#property version   "1.0"
#property description "OnChart-drawn support, resistance and trendlines"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2

#property indicator_type1 DRAW_ARROW
#property indicator_width1 3
#property indicator_color1 0xFFAA00
#property indicator_label1 "Buy"

#property indicator_type2 DRAW_ARROW
#property indicator_width2 3
#property indicator_color2 0x0000FF
#property indicator_label2 "Sell"

#define PLOT_MAXIMUM_BARS_BACK
#define OMIT_OLDEST_BARS

input group "==== Number of Bars ===="
input int PLOT_MAXIMUM_BARS_BACK maxBars = 200;
input int OMIT_OLDEST_BARS oldBars = 50;
input int arrows_num = 50;
input double ArrowDist = 1;

input group "==== SIGNALS ===="
input ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT;
input bool isSupResActive = false;  // Show Support and Resistance Signals
input bool isTrendlineActive = false;  // Show Trendline Signals

input group "==== VARIABLE INPUTS ===="
input bool Audible_Alerts = true;
datetime time_alert; //used when sending alert

double Buffer1[];
double Buffer2[];
double Low[];
double High[];
double Close[];
datetime Time[];


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int OnInit(){


  SetIndexBuffer(0, Buffer1);
  PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
  PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, MathMax(Bars(Symbol(), PERIOD_CURRENT)-PLOT_MAXIMUM_BARS_BACK+1, OMIT_OLDEST_BARS+1));
  PlotIndexSetInteger(0, PLOT_ARROW, 241);
  SetIndexBuffer(1, Buffer2);
  PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
  PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, MathMax(Bars(Symbol(), PERIOD_CURRENT)-PLOT_MAXIMUM_BARS_BACK+1, OMIT_OLDEST_BARS+1));
  PlotIndexSetInteger(1, PLOT_ARROW, 242);

  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],const double &open[],const double &high[],const double &low[],const double &close[],const long &tick_volume[],const long &volume[],const int &spread[]){
                
  if(!IsNewBar()) return 0; // Exit if it's not a new bar 
  
  int limit = rates_total - prev_calculated;
  // Ensure limit is valid
  if (limit <= 0) return rates_total;

  //--- counting from 0 to rates_total
  ArraySetAsSeries(Buffer1, true);
  ArraySetAsSeries(Buffer2, true);
  //--- initial zero
  if(prev_calculated < 1){

    ArrayInitialize(Buffer1, EMPTY_VALUE);
    ArrayInitialize(Buffer2, EMPTY_VALUE);
  }
  else
    limit++;            
              
 if(CopyLow(Symbol(), PERIOD_CURRENT, 0, rates_total, Low) <= 0) return(rates_total);
  ArraySetAsSeries(Low, true);
  if(CopyHigh(Symbol(), PERIOD_CURRENT, 0, rates_total, High) <= 0) return(rates_total);
  ArraySetAsSeries(High, true);
  if(CopyClose(Symbol(), PERIOD_CURRENT, 0, rates_total, Close) <= 0) return(rates_total);
  ArraySetAsSeries(Close, true);
  if(CopyTime(Symbol(), Period(), 0, rates_total, Time) <= 0) return(rates_total);
  ArraySetAsSeries(Time, true);
              
  for(int i = limit-1; i >= 0; i--){

    if (i >= MathMin(maxBars-1, rates_total-1-oldBars)) continue; 

    int trendObjects = ObjectsTotal(0, -1, OBJ_TREND);  // Get total trendline objects
    for(int i = trendObjects - 1; i >= 0; i--){

      double lowerTrendline = TrendlinePriceLower(i);
      if(lowerTrendline != -1){

        string name = ObjectName(0, i);  // Get trendline name
        // Check if the object is a valid trendline
        if(ObjectGetInteger(0, name, OBJPROP_TYPE) == OBJ_TREND){

          datetime currentBarTime = iTime(NULL, 0, 0);  // Current bar's time
          double trendlinePrice = ObjectGetValueByTime(0, name, currentBarTime, 0);  // Trendline price
          
          if(trendlinePrice > 0){  // Ensure a valid price is retrieved

            double currentPrice = Close[0];  // Use the current bid price (or Close[0])
            // Check for a downward cross (price breaks below trendline)
            if(currentPrice < trendlinePrice){

              Print("Price crossed below trendline: ", name, " | Trendline Price: ", trendlinePrice, " | Current Price: ", currentPrice);
              DrawArrowSell("Trend", i,High[1], clrBlack, 10);
              
            }
          }
        }
      }
      

      //double upperTrendline = TrendlinePriceUpper(i);
      //if(upperTrendline != -1){

      //  Print("Upper Trendline detected! Price: ", upperTrendline);
      //}    
    }  
  }
                
  return(rates_total);
}


//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+

void myAlert(string type, string message){
   if(type == "print")
      Print(message);
   else if(type == "error")
     {
      Print(type+" | trendlines @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
     }
   else if(type == "order")
     {
     }
   else if(type == "modify")
     {
     }
}

bool IsPriceRetestingOB(double high_price, double low_price, int &retest){

  double current_price = iClose(_Symbol, _Period, 0); // Current price
  double price =  iHigh(_Symbol, _Period, 0);

  if(current_price < low_price && price > low_price){

    retest++;
    Print("Price retesting OB, retest count: ", retest);
    return true;  // Price is retesting the OB
  }
  return false;  // No retest detected
}

bool IsPriceWithinOB(double high_price, double low_price){

  double current_price = iClose(_Symbol, _Period, 0); // Current price

  // Check if price is within the OB range
  if(current_price >= low_price && current_price <= high_price){

    Print("Price within OB");
    return true;  // Price is within the OB
  }
  return false;  // No retest detected
}

// Trendline Price
double GetTrendlinePrice(datetime time, datetime start_time, double start_price, datetime end_time, double end_price){
  
  if(end_time == start_time){
    return start_price;  // Avoid division by zero
  }
  double slope = (end_price - start_price) / (end_time - start_time);
  double price = start_price + slope * (time - start_time);
  Print("Calculated trendline price: ", price);
  return price;
}

// Custom function to find an element in an array
int ArrayFind(string &arr[], string value) {
    for(int i = 0; i < ArraySize(arr); i++) {
        if(arr[i] == value) {
            return i; // Return the index if found
        }
    }
    return -1; // Return -1 if not found
}

double TrendlinePriceLower(int shift){
  
  int obj_total = ObjectsTotal(0);  // Total number of objects on the chart
  double minprice = DBL_MAX;        // Initialize with the highest possible value
  datetime barTime = iTime(NULL, 0, shift);  // Time of the bar at 'shift'
  
  for (int i = 0; i < obj_total; i++){
    string name = ObjectName(0, i);  // Get the object name
    int type = (int)ObjectGetInteger(0, name, OBJPROP_TYPE);

    // Debug: Log all object names and types
    //Print("Object Name: ", name, " | Type: ", type);

    // Check if the object is a trendline and contains "l" (or "l1")
    if (type == OBJ_TREND && StringFind(name, "l") > -1) {
      double price = ObjectGetValueByTime(0, name, barTime, 0);  // Get trendline price

      // Debug: Log the price retrieval
      Print("Checking Trendline: ", name, " | Time: ", TimeToString(barTime), " | Price: ", price);

      if (price > 0 && price < minprice) {
        minprice = price;  // Update the minimum price
      }
    }
  }

  return (minprice == DBL_MAX) ? -1 : minprice;  // Return the lowest price, or -1 if none found
}

int FindPreviousGreenCandleAboveTrendline(string trendlineName, double currentPrice){
    // Get current bar count
    int totalBars = Bars(_Symbol, _Period);

    // Check if the trendline object exists
    if(ObjectFind(0, trendlineName) < 0) {
        Print("Trendline not found: ", trendlineName);
        return -1;
    }

    // Start looking from the most recent bar and move backwards
    for(int i = 0; i <= 10; i++) {
        if(i >= totalBars) continue; // Ensure we do not exceed totalBars

        // Get the price of the trendline at this bar's time
        double trendlinePrice = ObjectGetValueByTime(0, trendlineName, iTime(_Symbol, _Period, i), 0);
        
        // Ensure trendline price is valid
        if(trendlinePrice == 0) continue;

        double close_price = iClose(_Symbol, _Period, i);

        // Check if the close price is above the trendline
        if(close_price > trendlinePrice) {
            // Check the previous 50 bars for a green candle
            for(int j = i; j < totalBars && j < i + 10; j++){
                if(j >= totalBars) continue; // Ensure we do not exceed totalBars

                double prev_open_price = iOpen(_Symbol, _Period, j);
                double prev_close_price = iClose(_Symbol, _Period, j);

                // Check for a green (bullish) candle
                if(prev_open_price < prev_close_price) {
                    Print("Found green candle at index: ", j);
                    return j;  // Return the index of the green candle
                }
            }
        }
    }

    // Return -1 if no green candle was found above the trendline
    Print("No green candle found above the trendline within the last 10 bars.");
    return -1;
}

int FindPreviousRedCandleBelowTrendline(string trendlineName, double currentPrice) {
    
  // Get current bar count
  int totalBars = Bars(_Symbol, _Period);

  // Check if the trendline object exists
  if(ObjectFind(0, trendlineName) < 0) {
    Print("Trendline not found: ", trendlineName);
    return -1;
  }

  // Start looking from the most recent bar and move backwards
  for(int i = 0; i <= 10; i++) {

    // Get the price of the trendline at this bar's time
    double trendlinePrice = ObjectGetValueByTime(0, trendlineName, iTime(_Symbol, _Period, i), 0);
    
    // Ensure trendline price is valid
    if(trendlinePrice == 0) continue;

    double close_price = iClose(_Symbol, _Period, i);

    // Check if the close price is below the trendline
    if(close_price < trendlinePrice) {

      // Check the previous 10 bars for a red candle
      for(int j = i; j <= i + 10 && j < totalBars; j++){

        double prev_open_price = iOpen(_Symbol, _Period, j);
        double prev_close_price = iClose(_Symbol, _Period, j);
        double ob_high = iHigh(_Symbol, _Period, j);
        double ob_low = iLow(_Symbol, _Period, j);

        // Check for a red (bearish) candle
        if(prev_open_price > prev_close_price) {
          Print("Found red candle at index: ", j, " with OB High: ", ob_high, " OB Low: ", ob_low);
          return j;  // Return the index of the red candle
        }
      }
    }
  }

  // Return -1 if no red candle was found below the trendline
  Print("No red candle found below the trendline within the last 10 bars.");
  return -1;
}

void DrawOrderBlock(int candle_index, color block_color){

  // Get the high and low of the identified candlestick
  double high_price = iHigh(_Symbol, _Period, candle_index);
  double low_price = iLow(_Symbol, _Period, candle_index);

  // Create a unique object name based on the timestamp
  string obj_name = "OrderBlock_" + IntegerToString(TimeCurrent());

  // Create a rectangle representing the order block
  if(!ObjectCreate(0, obj_name, OBJ_RECTANGLE, 0, Time[candle_index], high_price, Time[0], low_price)){

    Print("Error creating order block: ", GetLastError());
    return;
  }

  // Set the properties of the rectangle (order block)
  ObjectSetInteger(0, obj_name, OBJPROP_COLOR, block_color);    // Set color
  ObjectSetInteger(0, obj_name, OBJPROP_WIDTH, 2);              // Border width
  ObjectSetInteger(0, obj_name, OBJPROP_STYLE, STYLE_SOLID);    // Line style
  ObjectSetInteger(0, obj_name, OBJPROP_RAY_RIGHT, true);       // Extend the rectangle to the right
}



//+------------------------------------------------------------------+
//| Wayback functions                                                |
//+------------------------------------------------------------------+

bool IsArrowSellExists(string arrowName, datetime time){

  // Iterate through all objects on the chart
  int totalObjects = ObjectsTotal(0, 0, OBJ_ARROW);
  for(int i = 0; i < totalObjects; i++){

    string name = ObjectName(0, i);  // Get the object's name
    // Check if the object name matches the arrow name
    if(StringFind(name, arrowName) > -1){

      datetime arrowTime = (datetime)ObjectGetInteger(0, name, OBJPROP_TIME);
      // Check if the time matches the arrow's time
      if(arrowTime == time){
      
        return true;  // Arrow already exists
      }
    }
  }
  return false;  // No matching arrow found
}

bool IsArrowBuyExists(string arrowName, datetime time){

  // Iterate through all objects on the chart
  int totalObjects = ObjectsTotal(0, 0, OBJ_ARROW);
  for(int i = 0; i < totalObjects; i++){

    string name = ObjectName(0, i);  // Get the object's name
    // Check if the object name matches the arrow name
    if(StringFind(name, arrowName) > -1){

      datetime arrowTime = (datetime)ObjectGetInteger(0, name, OBJPROP_TIME);
      // Check if the time matches the arrow's time
      if(arrowTime == time){

        return true;  // Buy arrow already exists
      }
    }
  }
  return false;  // No matching buy arrow found
}

void DrawArrowSell(string arrowPrefix, int i, double arrowPrice, color arrowColor, int arrowFilter){

  bool arrowExists = false;
  for(int k = 0; k < maxBars - oldBars; k++){

    string arrowName = ObjectName(0, k);
    if (StringFind(arrowName, arrowPrefix) > -1){

      datetime arrowTime = (datetime)ObjectGetInteger(0, arrowName, OBJPROP_TIME);
      if(Time[i] - arrowTime < PeriodSeconds(PERIOD_CURRENT) * arrowFilter){

        arrowExists = true;
        break;
      }
    }
  }
  if(!arrowExists){

    string arrowName = arrowPrefix + "#" + IntegerToString(Time[i]);

    if(!IsArrowSellExists(arrowName, Time[i]))
    if(!IsArrowBuyExists(arrowName, Time[i]))

    ObjectCreate(0, arrowName, OBJ_ARROW, 0, Time[i], arrowPrice);
    ObjectSetInteger(0, arrowName, OBJPROP_COLOR, arrowColor);
    ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, 3);
    ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE,234);
    ObjectSetInteger(0, arrowName, OBJPROP_ANCHOR,ANCHOR_TOP);
    ObjectSetInteger(0, arrowName, OBJPROP_HIDDEN, false);
    ObjectSetInteger(0, arrowName, OBJPROP_BACK, true);
  }
}

bool IsNewBar(){
  static datetime previousTime = 0;
  datetime currentTime = iTime(_Symbol,PERIOD_M5,0);
  if(previousTime != currentTime){

    previousTime = currentTime;
    return true;
  }
  return false;
}
