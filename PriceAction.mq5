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

#define PLOT_MAXIMUM_BARS_BACK 250
#define OMIT_OLDEST_BARS 50

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int OnInit(){


   

  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],const double &open[],const double &high[],const double &low[],const double &close[],const long &tick_volume[],const long &volume[],const int &spread[]){
                
                
                

                
                
                
                
  return(rates_total);
}


//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+


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
        name = StringTrimRight(name);  // Trim any extra spaces
        
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

bool IsPriceRetestingOB(double high_price, double low_price, int &retest){

    double current_price = iClose(_Symbol, _Period, 0); // Current price
    double price = iHigh(_Symbol, _Period, 0);  // High price of the current bar
    retest = 0;

    // Check if price is below the OB low and high is above the OB low (retest condition)
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

    return false;  // Price is outside the OB
}


int FindPreviousGreenCandleAboveTrendline(string trendlineName, double currentPrice) {
    
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

