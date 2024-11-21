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

double Buffer1[];
double Buffer2[];

double Low[];
double High[];

#define PLOT_MAXIMUM_BARS_BACK 250
#define OMIT_OLDEST_BARS 50

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
                
    int limit = rates_total - prev_calculated;
    //--- counting from 0 to rates_total
    ArraySetAsSeries(Buffer1, true);
    ArraySetAsSeries(Buffer2, true);
    //--- initial zero
    if(prev_calculated < 1)
     {
      ArrayInitialize(Buffer1, EMPTY_VALUE);
      ArrayInitialize(Buffer2, EMPTY_VALUE);
     }
    else
      limit++;            
                
    if(CopyLow(Symbol(), PERIOD_CURRENT, 0, rates_total, Low) <= 0) return(rates_total);
    ArraySetAsSeries(Low, true);
    if(CopyHigh(Symbol(), PERIOD_CURRENT, 0, rates_total, High) <= 0) return(rates_total);
    ArraySetAsSeries(High, true);
                
    for(int i = limit-1; i >= 0; i--){

      if(i >= MathMin(PLOT_MAXIMUM_BARS_BACK-1, rates_total-1-OMIT_OLDEST_BARS)) continue; //omit some old rates to prevent "Array out of range" or slow calculation   

      int trendObjects = ObjectsTotal(0, 0, OBJ_TREND);
      for(int j = 0; j < trendObjects; j++){

        string objectName = ObjectName(0, j, 0, OBJ_TREND);
        if(StringFind(objectName, "l") != -1){

          Print("Trendline: ",objectName," detected!");
        
        }
        
        if(StringFind(objectName, "u") != -1){

          Print("Trendline: ",objectName," detected!");
        
        }
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

// trendline functions
double TrendlinePriceLower(int shift) {
    int obj_total = ObjectsTotal(0);  // Get total number of objects on the chart
    double minprice = DBL_MAX;  // Initialize minprice to a very large value
    datetime barTime = iTime(NULL, 0, shift);  // Get the time of the bar at 'shift'
    
    double trendline_prices[];  // Array to store all trendline prices

    for(int i = 0; i < obj_total; i++) {
        string name = ObjectName(0, i);  // Get the object name
        
        
        // Check if the object is a trendline
        if(ObjectGetInteger(0, name, OBJPROP_TYPE) == OBJ_TREND) {
            
            // Use a single condition to detect both "l" and "l1"
            if(StringFind(name, "l") > -1 || StringFind(name, "l1") > -1) {
                
                // Get the trendline price at the time of the bar
                double price = ObjectGetValueByTime(0, name, barTime, 0);
                
                // Check if the price is valid
                if(price > 0) {
                    // Store the trendline price in the array
                    ArrayResize(trendline_prices, ArraySize(trendline_prices) + 1);
                    trendline_prices[ArraySize(trendline_prices) - 1] = price;
                }
            }
        }
    }
    
    // If any trendline prices were found, find the minimum
    if(ArraySize(trendline_prices) > 0) {
        minprice = trendline_prices[0];
        for(int j = 1; j < ArraySize(trendline_prices); j++) {
            if(trendline_prices[j] < minprice) {
                minprice = trendline_prices[j];
            }
        }
    }

    return (minprice == DBL_MAX) ? -1 : minprice;  // Return the lowest trendline price found, or -1 if none
}

double TrendlinePriceUpper(int shift){

    int obj_total = ObjectsTotal(0);  // Get total number of objects on the chart
    double maxprice = -DBL_MAX;  // Initialize maxprice to a very small value
    datetime barTime = iTime(NULL, 0, shift);  // Get the time of the bar at 'shift'
    
    for(int i = 0; i < obj_total; i++){
    
        string name = ObjectName(0, i);  // Get the object name
    
        // Check if the object is a trendline and contains "u" (for upward trendline)
        if(ObjectGetInteger(0, name, OBJPROP_TYPE) == OBJ_TREND && StringFind(name, "u") > -1){
    
            // Get the trendline price at the time of the bar
            double price = ObjectGetValueByTime(0, name, barTime, 0);
            Print("Trendline: ", name, " | Time: ", TimeToString(barTime, TIME_DATE | TIME_MINUTES), " | Trendline Price: ", price);
    
            // Update maxprice if this trendline price is higher than the previous one
            if(price > maxprice && price > 0){
                maxprice = price;
            }
        }

        // Check if the object is a trendline and contains "u1" (for upward trendline)
        if(ObjectGetInteger(0, name, OBJPROP_TYPE) == OBJ_TREND && StringFind(name, "u1") > -1){
    
            // Get the trendline price at the time of the bar
            double price = ObjectGetValueByTime(0, name, barTime, 0);
            //Print("Trendline: ", name, " | Time: ", TimeToString(barTime, TIME_DATE | TIME_MINUTES), " | Trendline Price: ", price);
    
            // Update maxprice if this trendline price is higher than the previous one
            if(price > maxprice && price > 0){
                maxprice = price;
            }
        }
    }
    
    return (maxprice == -DBL_MAX) ? -1 : maxprice;  // Return the highest trendline price found, or -1 if none
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

    // Get the price of the trendline at this bar's time
    double trendlinePrice = ObjectGetValueByTime(0, trendlineName, iTime(_Symbol, _Period, i), 0);
    
    // Ensure trendline price is valid
    if(trendlinePrice == 0) continue;

    double close_price = iClose(_Symbol, _Period, i);

    // Check if the close price is above the trendline
    if(close_price > trendlinePrice) {

      // Check the previous 50 bars for a green candle
      for(int j = i; j <= i + 10 && j < totalBars; j++){

        double prev_open_price = iOpen(_Symbol, _Period, j);
        double prev_close_price = iClose(_Symbol, _Period, j);
        double ob_high = iHigh(_Symbol, _Period, j);
        double ob_low = iLow(_Symbol, _Period, j);

        // Check for a green (bullish) candle
        if(prev_open_price < prev_close_price) {
          Print("Found green candle at index: ", j, " with OB High: ", ob_high, " OB Low: ", ob_low);
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
    if(!ObjectCreate(0, obj_name, OBJ_RECTANGLE, 0, Time[candle_index], high_price, Time[0], low_price))
    {
        Print("Error creating order block: ", GetLastError());
        return;
    }

    // Set the properties of the rectangle (order block)
    ObjectSetInteger(0, obj_name, OBJPROP_COLOR, block_color);    // Set color
    ObjectSetInteger(0, obj_name, OBJPROP_WIDTH, 2);              // Border width
    ObjectSetInteger(0, obj_name, OBJPROP_STYLE, STYLE_SOLID);    // Line style
    ObjectSetInteger(0, obj_name, OBJPROP_RAY_RIGHT, true);       // Extend the rectangle to the right
}


/*//Advanced
int FindPreviousGreenCandleAboveTrendline(string trendlineName, double currentPrice){
    // Get the total number of bars
    int totalBars = Bars(_Symbol, _Period);

    // Start looking from the most recent bar and move backwards
    for(int i = totalBars - 2; i >= 10; i--)
    {
        // Get the trendline price at this bar's time
        double trendlinePrice = ObjectGetValueByTime(0, trendlineName, iTime(_Symbol, _Period, i), 0);

        double close_price = iClose(_Symbol, _Period, i);
        double open_price = iOpen(_Symbol, _Period, i);

        // If the close price is above the trendline, check for a green candle
        if(close_price > trendlinePrice)
        {
            // Look backwards through the previous 10 bars to find a green candle
            for(int j = i; j >= i - 10 && j >= 0; j--)
            {
                double prev_open_price = iOpen(_Symbol, _Period, j);
                double prev_close_price = iClose(_Symbol, _Period, j);

                // Bullish candle: open < close (green candle)
                if(prev_open_price < prev_close_price)
                {
                    return j;  // Return the index of the green candle found
                }
            }

            break;  // Stop if we've checked the past 10 bars for green candles
        }
    }

    return -1;  // No green candle found within the last 10 bars above the trendline
}

void DrawLine(string objname, double price, int count, int start_index) //creates or modifies existing object if necessary
  {
   if((price < 0) && ObjectFind(0, objname) >= 0)
     {
      ObjectDelete(0, objname);
     }
   else if(ObjectFind(0, objname) >= 0 && ObjectGetInteger(0, objname, OBJPROP_TYPE) == OBJ_TREND)
     {
      datetime cTime[];
      ArraySetAsSeries(cTime, true);
      CopyTime(Symbol(), Period(), 0, start_index+count, cTime);
      ObjectSetInteger(0, objname, OBJPROP_TIME, cTime[start_index]);
      ObjectSetDouble(0, objname, OBJPROP_PRICE, price);
      ObjectSetInteger(0, objname, OBJPROP_TIME, 1, cTime[start_index+count-1]);
      ObjectSetDouble(0, objname, OBJPROP_PRICE, 1, price);
     }
   else
     {
      datetime cTime[];
      ArraySetAsSeries(cTime, true);
      CopyTime(Symbol(), Period(), 0, start_index+count, cTime);
      ObjectCreate(0, objname, OBJ_TREND, 0, cTime[start_index], price, cTime[start_index+count-1], price);
      ObjectSetInteger(0, objname, OBJPROP_RAY_LEFT, 0);
      ObjectSetInteger(0, objname, OBJPROP_RAY_RIGHT, 0);
      ObjectSetInteger(0, objname, OBJPROP_COLOR, C'0x00,0x00,0xFF');
      ObjectSetInteger(0, objname, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, objname, OBJPROP_WIDTH, 2);
     }
}*/
