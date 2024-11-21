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

// Check if price has crossed the trendline
if(PriceCrossedTrendline(LowertrendlinePrice)){
  
  // Check if it's a downtrend
  if(iClose(_Symbol, _Period, 0) < LowertrendlinePrice){

    for(int i = 0; i < totalObjects; i++) {

      string LowerTrendline = ObjectName(0, i);  // Get the object name

      if(ObjectFind(0, LowerTrendline) != -1 && ObjectGetInteger(0, LowerTrendline, OBJPROP_TYPE) == OBJ_TREND){

        if(StringFind(LowerTrendline, "l") > -1){ 

          Print("Trendline Name: ", LowerTrendline);

          // Search for the previous green candlestick (resistance order block)
          int green_candle_index = FindPreviousGreenCandleAboveTrendline(LowerTrendline, currentPrice);

          if(green_candle_index != -1){
            
            // Draw the order block (resistance zone)
            DrawOrderBlock(green_candle_index, clrLime);

            // Get high and low of the OB
            double ob_high = iHigh(_Symbol, _Period, green_candle_index);
            double ob_low = iLow(_Symbol, _Period, green_candle_index);

            // Price inside the OB
            if(IsPriceWithinOB(ob_high, ob_low)){
              
              int retest = 0;
              // Wait for price to retest the OB
              if(IsPriceRetestingOB(ob_high, ob_low, retest)){
                
                if(Close[i+1] > ob_low && Close[i] < ob_low && retest >= 1){

                  // Retest confirmed, plot sell arrow
                  if(i == 1 && Time[1] != time_alert) myAlert("indicator", "OrderBlock Retest Sell"); // Alert on next bar open
                  time_alert = Time[1];
                  
                  // Check if the last arrow was drawn more than 10 bars ago
                  bool arrowExists = false;
                  for(int k = 0; k < maxBars-oldBars; k++){

                    string arrowName = ObjectName(0, k);
                    if(StringFind(arrowName, "Retest_Sell#") > -1){

                      datetime arrowTime = (datetime)ObjectGetInteger(0, arrowName, OBJPROP_TIME);
                      if(Time[i] - arrowTime < PeriodSeconds() * arrowSellFilter){

                        arrowExists = true;
                        break;
                      }
                    }
                  }
                  
                  if(!arrowExists){

                    color SellColor = clrBlue;
                    string obj_name="Retest_Sell#"+IntegerToString(Time[i]);
                    ObjectCreate(0, obj_name, OBJ_ARROW, 0, Time[i], High[i+1]);
                    ObjectSetInteger(0, obj_name, OBJPROP_COLOR, SellColor);
                    ObjectSetInteger(0, obj_name, OBJPROP_WIDTH, 3); // Adjust width as needed
                    ObjectSetInteger(0, obj_name, OBJPROP_ARROWCODE, 234);
                    ObjectSetInteger(0, obj_name, OBJPROP_ANCHOR, ANCHOR_TOP);
                    ObjectSetInteger(0, obj_name, OBJPROP_HIDDEN, false);
                    ObjectSetInteger(0, obj_name, OBJPROP_BACK, true);
                    arrow_count++;   
                  }
                }
              }
            }
          }
        }
      }
    }  
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

// main function trendline
for(int i = limit - 1; i >= 0; i--) {
    double range = High[i] - Low[i];
    double dynamic_arrow = range * ArrowDist;

    if (i >= MathMin(maxBars-1, rates_total-1-oldBars)) continue; // Omit old rates

    if (getBid() > TrendlinePriceLower(i)) {
        Print("Trendline name > ", "l", " : ", TrendlinePriceLower(i));
    }

    // Check for crossing above the trendline
    if (Close[1 + i] <= TrendlinePriceUpper(1 + i) && Close[i] > TrendlinePriceUpper(i)) {
        Buffer1[i] = Low[i];  // Set indicator value at Candlestick Low
        
        if (i == 0 && Time[0] != time_alert) { 
            myAlert("indicator", "Buy"); 
            time_alert = Time[0]; 
        }  // Instant alert, only once per bar

        bool arrowExists = false;
        
        for (int k = 0; k < maxBars - oldBars; k++) {
            string arrowName = ObjectName(0, k);
            if (StringFind(arrowName, "StochBuy#") > -1) {
                datetime arrowTime = (datetime)ObjectGetInteger(0, arrowName, OBJPROP_TIME);
                
                if (Time[i] - arrowTime < PeriodSeconds() * arrowSellFilter) {
                    arrowExists = true;
                    break;
                }
            }
        }

        if (!arrowExists) {
            color BuyColor = clrBlue;
            string obj_name = "StochBuy#" + IntegerToString(Time[i]);

            if (!IsArrowSellExists(obj_name, Time[i])) {
                ObjectCreate(0, obj_name, OBJ_ARROW, 0, Time[i], Low[i] + dynamic_arrow);
                ObjectSetInteger(0, obj_name, OBJPROP_COLOR, BuyColor);
                ObjectSetInteger(0, obj_name, OBJPROP_WIDTH, 3);  // Adjust width as needed
                ObjectSetInteger(0, obj_name, OBJPROP_ARROWCODE, 233);
                ObjectSetInteger(0, obj_name, OBJPROP_ANCHOR, ANCHOR_TOP);
                ObjectSetInteger(0, obj_name, OBJPROP_HIDDEN, false);
                ObjectSetInteger(0, obj_name, OBJPROP_BACK, true);
                arrow_count++;
            }
        }
    } else {
        Buffer1[i] = EMPTY_VALUE;
    }
}

// trendline function
double TrendlinePriceLower(int shift) {
    int obj_total = ObjectsTotal(0);  // Get total number of objects on the chart
    double minprice = DBL_MAX;  // Initialize minprice to a very large value
    datetime barTime = iTime(NULL, 0, shift);  // Get the time of the bar at 'shift'
    
    double trendline_prices[];  // Array to store all trendline prices

    for(int i = 0; i < obj_total; i++) {
        string name = ObjectName(0, i);  // Get the object name
        name = StringTrimLeft(StringTrimRight(name));  // Trim any extra spaces
        
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
