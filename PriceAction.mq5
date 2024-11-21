//+------------------------------------------------------------------+
//|                                                  PriceAction.mq5 |
//|                           Copyright 2024, Automated Trading Ltd. |
//|                        https://github.com/H4ck3r217/Trading-Bots |
//+------------------------------------------------------------------+
// God is Good 
#property copyright "Copyright 2024, Automated Trading Ltd."
#property link      "https://github.com/H4ck3r217/Trading-Bots"
#property version   "1.0"
#property description "OnChart-drawn support, resistance and trendlines"
#property strict 

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

long current_AccountNo() { return AccountInfoInteger(ACCOUNT_LOGIN);}

// Edit here for user trading account 
long UserAccounts[] = {24202600,24202602,24202603,24202604};

bool CheckAccountNo(long acc_Inp, long &accounts[], int accountCount){ 

  bool isValid = false; 
  for(int i = 0; i < accountCount; i++){
    if(acc_Inp == accounts[i]){
      isValid = true; 
      break; 
    }
  }

  if(!isValid) {
    Print("Invalid Account Number, Revoking the Indicator Now!!!");
    return(false);
  }
  return(true);
}

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

  string PriceAction = "PriceAction";
  if(!CheckAccountNo(current_AccountNo(), UserAccounts, ArraySize(UserAccounts))) { 
    ChartIndicatorDelete(0,0,PriceAction); 
    return INIT_FAILED;
  }

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
  ArraySetAsSeries(Buffer1, true);
  ArraySetAsSeries(Buffer2, true);
  
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
              
  for(int i = limit-1; i >= 0; i--){

    if(i >= MathMin(PLOT_MAXIMUM_BARS_BACK-1, rates_total-1-OMIT_OLDEST_BARS)) continue; //omit some old rates to prevent "Array out of range" or slow calculation   

    // Get the total number of objects on the chart
    int totalObjects = ObjectsTotal(0, -1, -1);
    double currentPrice = SymbolInfoDouble(Symbol(),SYMBOL_BID);

    for(int i = 0; i < totalObjects; i++){
      // Get the object name
      string LowerTrendline = ObjectName(0, i);  
      
      // Ensure the object exists and is a trendline
      if(ObjectFind(0, LowerTrendline) != -1 && ObjectGetInteger(0, LowerTrendline, OBJPROP_TYPE) == OBJ_TREND){
          
        // Check if the trendline name contains 'l' (can be lowercase or uppercase)
        if(StringFind(LowerTrendline, "l") > -1 || StringFind(LowerTrendline, "L") > -1){

          Print("Found trendline: ", LowerTrendline);  // Debugging output

          // Search for the previous green candlestick (resistance order block)
          int green_candle_index = FindPreviousGreenCandleAboveTrendline(LowerTrendline, currentPrice);

          // Debugging: check if green candle index is valid
          Print("Green candle index: ", green_candle_index);

          if(green_candle_index != -1){

            Print("should draw orderBlock here"); // Debugging output
            
            // Draw the order block (resistance zone)
            DrawOrderBlock(green_candle_index, clrBlack);
            Print("Drawing order block for index: ", green_candle_index);

            // Get high and low of the OB
            double ob_high = iHigh(_Symbol, _Period, green_candle_index);
            double ob_low = iLow(_Symbol, _Period, green_candle_index);

            // Debugging: check if high and low are correct
            Print("OB High: ", ob_high, " OB Low: ", ob_low);

            // Wait for price to retest the OB
            /*if(IsPriceRetestingOB(ob_high, ob_low)) {

              // Retest confirmed, plot sell arrow
              DrawArrowSell("LowerTrendSell", i, dynamic_arrow, clrBlack, arrowSellFilter);
            }*/
          }
        }
      }
    }


    /*int trendObjects = ObjectsTotal(0, 0, OBJ_TREND);
    for(int j = 0; j < trendObjects; j++){

      string objectName = ObjectName(0, j, 0, OBJ_TREND);
      if(StringFind(objectName, "l") != -1){

        Print("Trendline: ",objectName," detected!");
      
      }
      
      if(StringFind(objectName, "u") != -1){

        Print("Trendline: ",objectName," detected!");
      
      }
    }*/           
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
  if(ObjectFind(0, trendlineName) < 0){

    Print("Trendline not found: ", trendlineName);
    return -1;
  }

  // Start looking from the most recent bar and move backwards
  for(int i = 0; i <= 10; i++) {

    // Get the price of the trendline at this bar's time
    double trendlinePrice = TrendlinePriceLower(i);
    
    // Ensure trendline price is valid
    if(trendlinePrice == 0) continue;

    double close_price = iClose(_Symbol, _Period, i);

    // Check if the close price is above the trendline
    if(close_price < trendlinePrice){

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

/*int FindPreviousRedCandleBelowTrendline(string trendlineName, double currentPrice) {
    
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
  if(!ObjectCreate(0, obj_name, OBJ_RECTANGLE, 0, Time[candle_index], high_price, Time[1], low_price)){

    Print("Error creating order block: ", GetLastError());
    return;
  }

  // Set the properties of the rectangle (order block)
  ObjectSetInteger(0, obj_name, OBJPROP_COLOR, block_color);    // Set color
  ObjectSetInteger(0, obj_name, OBJPROP_WIDTH, 2);              // Border width
  ObjectSetInteger(0, obj_name, OBJPROP_STYLE, STYLE_SOLID);    // Line style
  ObjectSetInteger(0, obj_name, OBJPROP_RAY_RIGHT, true);       // Extend the rectangle to the right
}*/

void DrawOrderBlock(int candle_index, color block_color){

  // Access high and low of the candlestick
  double high_price = iHigh(_Symbol, _Period, candle_index);
  double low_price = iLow(_Symbol, _Period, candle_index);

  // Create object name
  string obj_name = "OrderBlock_" + IntegerToString(TimeCurrent()) + "_" + IntegerToString(candle_index);

  // Create order block rectangle
  if(ObjectCreate(0, obj_name, OBJ_RECTANGLE, 0, Time[candle_index], high_price, D'1970.01.01 00:00', low_price)){
    
    // Set the properties of the rectangle (order block)
    ObjectSetInteger(0, obj_name, OBJPROP_COLOR, block_color);    // Set color
    ObjectSetInteger(0, obj_name, OBJPROP_WIDTH, 2);              // Border width
    ObjectSetInteger(0, obj_name, OBJPROP_STYLE, STYLE_SOLID);    // Line style
    ObjectSetInteger(0, obj_name, OBJPROP_RAY_RIGHT, true);       // Extend the rectangle to the right
  }

  else{
        
    Print("Error creating order block: ", GetLastError());
    return;
  }
}

//Advanced
/*int FindPreviousGreenCandleAboveTrendline(string trendlineName, double currentPrice){
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
}


// Function to calculate the resistance or support zone range
double CalculateRange(double high, double low) {
    return (high - low) / 2;
}

// Function to check for resistance zone and handle arrow creation
void CheckResistance(string objectName, double price, double dynamic_arrow, int i) {
    double rectangleHigh = ObjectGetDouble(0, objectName, OBJPROP_PRICE, 0);
    double rectangleLow = ObjectGetDouble(0, objectName, OBJPROP_PRICE, 1);

    if (rectangleLow > price) {
        double closestResistanceHigh = rectangleLow;
        double sellRange = rectangleLow - CalculateRange(rectangleHigh, rectangleLow);
        double sellStop = rectangleHigh + CalculateRange(rectangleHigh, rectangleLow);

        if (price < rectangleHigh) {
            PrintFormat("\nEntered Resistance Zone: Time = %s, Price = %f", TimeToString(TimeLocal()), price);

            if (Close[i+1] > rectangleLow && Close[i] < rectangleLow){
                Print("Checking for sell arrow...");
                DrawArrow("Res_Sell", i, High[i] + dynamic_arrow, clrBlack, arrowSellFilter);
            }
        }

        // Add stop loss or other conditions as needed
        if (price < sellStop && price > rectangleLow) {
            // Price above Resistance Zone, don't put SELL orders
        }
        if (price > sellStop) {
            // Stop Loss
        }
    }
}

// Function to check for support zone and handle arrow creation
void CheckSupport(string objectName, double price, double dynamic_arrow, int i) {
    double rectangleHigh = ObjectGetDouble(0, objectName, OBJPROP_PRICE, 0);
    double rectangleLow = ObjectGetDouble(0, objectName, OBJPROP_PRICE, 1);

    if (rectangleHigh < price) {
        double closestSupportLow = rectangleHigh;
        double buyRange = rectangleHigh + CalculateRange(rectangleHigh, rectangleLow);
        double buyStop = rectangleLow - CalculateRange(rectangleHigh, rectangleLow);

        if (price > rectangleLow) {
            PrintFormat("\nEntered Support Zone: Time = %s, Price = %f", TimeToString(TimeLocal()), price);

            if (Close[i+1] < rectangleHigh && Close[i] > rectangleHigh) {
                Print("Checking for buy arrow...");
                DrawArrow("Sup_Buy", i, Low[i] - dynamic_arrow, clrBlack, arrowBuyFilter);
            }
        }

        // Add stop loss or other conditions as needed
        if (price > buyStop && price < rectangleLow) {
            // Price below Support Zone, don't put BUY orders
        }
        if (price < buyStop) {
            // Stop Loss
        }
    }
}

// Function to draw an arrow if not recently drawn
void DrawArrowSell(string arrowPrefix, int i, double arrowPrice, color arrowColor, int arrowFilter) {
    bool arrowExists = false;
    for (int k = 0; k < maxBars - oldBars; k++) {
        string arrowName = ObjectName(0, k);
        if (StringFind(arrowName, arrowPrefix) > -1) {
            datetime arrowTime = (datetime)ObjectGetInteger(0, arrowName, OBJPROP_TIME);
            if (Time[i] - arrowTime < PeriodSeconds() * arrowFilter) {
                arrowExists = true;
                break;
            }
        }
    }

    if (!arrowExists) {
        string arrowName = arrowPrefix + "#" + IntegerToString(Time[i]);
        if (!IsArrowExists(arrowName, Time[i])) {
            ObjectCreate(0, arrowName, OBJ_ARROW, 0, Time[i], arrowPrice);
            ObjectSetInteger(0, arrowName, OBJPROP_COLOR, arrowColor);
            ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, 3);
            ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE, arrowPrefix == "Res_Sell" ? 234 : 233);
            ObjectSetInteger(0, arrowName, OBJPROP_ANCHOR, arrowPrefix == "Res_Sell" ? ANCHOR_TOP : ANCHOR_BOTTOM);
            ObjectSetInteger(0, arrowName, OBJPROP_HIDDEN, false);
            ObjectSetInteger(0, arrowName, OBJPROP_BACK, true);
        }
    }
}

// Improved Function to Draw Arrows
voidDrawArrowBuy(string arrowPrefix, int i, double arrowPrice, color arrowColor, int arrowFilter){

   bool arrowExists = false;
   int totalObjects = ObjectsTotal();
   
   for (int k = 0; k < totalObjects; k++) {

      string arrowName = ObjectName(0, k);
      if (StringFind(arrowName, arrowPrefix) > -1) {
         datetime arrowTime = (datetime)ObjectGetInteger(0, arrowName, OBJPROP_TIME);
         if (Time[i] - arrowTime < PeriodSeconds() * arrowFilter) {
            arrowExists = true;
            break;
         }
      }
   }

   if (!arrowExists) {
      string arrowName = arrowPrefix + "#" + IntegerToString(Time[i]);
      ObjectCreate(0, arrowName, OBJ_ARROW, 0, Time[i], arrowPrice);
      ObjectSetInteger(0, arrowName, OBJPROP_COLOR, arrowColor);
      ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, 3);
      ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE, arrowPrefix == "Res_Sell" ? 234 : 233);
      ObjectSetInteger(0, arrowName, OBJPROP_ANCHOR, arrowPrefix == "Res_Sell" ? ANCHOR_TOP : ANCHOR_BOTTOM);
      ObjectSetInteger(0, arrowName, OBJPROP_HIDDEN, false);
      ObjectSetInteger(0, arrowName, OBJPROP_BACK, true);
   }
}
*/