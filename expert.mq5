//+------------------------------------------------------------------+
//|                                         Breakout_Expert_MT5.mq5 |
//|                                  Copyright 2024, Isa Syrgakov    |
//|                                             https://github.com/  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Isa Syrgakov"
#property link      "https://github.com/"
#property version   "1.00"
#property strict

//--- Input Parameters
input int      InpPeriod      = 20;          // Period for High/Low calculation
input double   InpLotSize     = 0.1;         // Trading Lot Size
input int      InpStopLoss    = 300;         // Stop Loss in points
input int      InpTakeProfit  = 600;         // Take Profit in points
input int      InpMagicNumber = 123456;      // Magic Number
input int      InpATRPeriod   = 14;          // ATR Period for volatility filter

//--- Global Variables
int handleATR;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Get handle for ATR indicator
   handleATR = iATR(_Symbol, _Period, InpATRPeriod);
   if(handleATR == INVALID_HANDLE)
   {
      Print("Failed to get ATR handle");
      return(INIT_FAILED);
   }
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(handleATR);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Check if we already have open positions
   if(PositionsTotal() > 0) return;

   //--- Get High and Low of the previous N bars
   double highBuffer[];
   double lowBuffer[];
   ArraySetAsSeries(highBuffer, true);
   ArraySetAsSeries(lowBuffer, true);

   if(CopyHigh(_Symbol, _Period, 1, InpPeriod, highBuffer) < InpPeriod ||
      CopyLow(_Symbol, _Period, 1, InpPeriod, lowBuffer) < InpPeriod) return;

   double highestPrice = highBuffer[ArrayMaximum(highBuffer)];
   double lowestPrice  = lowBuffer[ArrayMinimum(lowBuffer)];

   //--- Get current price
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   //--- Breakout Logic
   // Buy if price breaks above the highest point of the period
   if(ask > highestPrice)
   {
      ExecuteTrade(ORDER_TYPE_BUY, ask);
   }
   // Sell if price breaks below the lowest point of the period
   else if(bid < lowestPrice)
   {
      ExecuteTrade(ORDER_TYPE_SELL, bid);
   }
}

//+------------------------------------------------------------------+
//| Function to execute trades                                       |
//+------------------------------------------------------------------+
void ExecuteTrade(ENUM_ORDER_TYPE type, double price)
{
   MqlTradeRequest request = {};
   MqlTradeResult  result  = {};

   request.action       = TRADE_ACTION_DEAL;
   request.symbol       = _Symbol;
   request.volume       = InpLotSize;
   request.type         = type;
   request.magic        = InpMagicNumber;
   request.price        = price;
   request.deviation    = 10;
   request.type_filling = ORDER_FILLING_IOC;

   double sl = (type == ORDER_TYPE_BUY) ? price - InpStopLoss * _Point : price + InpStopLoss * _Point;
   double tp = (type == ORDER_TYPE_BUY) ? price + InpTakeProfit * _Point : price - InpTakeProfit * _Point;

   request.sl = sl;
   request.tp = tp;

   if(!OrderSend(request, result))
      Print("OrderSend error: ", GetLastError());
}
