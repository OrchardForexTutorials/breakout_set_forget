/*
   Breakout Set and Forget
   Copyright 2023, Orchard Forex
   https://www.orchardforex.com

   Strategy from TradePro https://youtu.be/t0taDife5R4

   USDJPY
   Find a 24 hour high low range based on 6pm EST
   Entries are at 7 pips above and below the range
   3 entries above and 3 entries below
   Each entry has sl at 25 pips
   Separate tp targets for each entry, 15 pips, 35 pips and 50 pips

   Risk 1% per position - will be based on the 25 pip stop loss
   total 3% risk per day
   Assumed using equity

   Not stated
   When one entry target is hit cancel the opposite
   If entry is not hit on a day then forget it

   Optional
   When one profit is hit move stop loss to break even, trail, something

*/

#property strict

#define app_copyright "Copyright 2023, Orchard Forex"
#define app_link      "https://www.orchardforex.com"
#define app_version   "8.00"

#ifdef __MQL5__
#include <Trade/Trade.mqh>
CTrade Trade;
#endif

enum ENUM_RISK_TYPE
{
   RISK_TYPE_FIXED_LOTS,     // Fixed lots
   RISK_TYPE_EQUITY_PERCENT, // Percent of equity
};

//+------------------------------------------------------------------+
//|	Inputs
//+------------------------------------------------------------------+
// Time range
input int            InpRangeStartHour   = 1; // Range start hour
input int            InpRangeStartMinute = 0; // Range start minute
input int            InpRangeEndHour     = 1; // Range end hour
input int            InpRangeEndMinute   = 0; // Range end minute

input double         InpRangeGapPips     = 7.0;  // Entry gap from outer range pips
input double         InpStopLossPips     = 25.0; // Stop loss pips
input double         InpTakeProfit1Pips  = 15.0; // Take profit 1 pips
input double         InpTakeProfit2Pips  = 35.0; // Take profit 2 pips
input double         InpTakeProfit3Pips  = 50.0; // Take profit 3 pips

// Management features
input bool           InpUseBreakEven     = false; // Move to break even on first TP

// Standard features
input long           InpMagic            = 232323;               // Magic number
input string         InpTradeComment     = "SnF Breakout";       // Trade comment
input double         InpRisk             = 1.0;                  // Risk
input ENUM_RISK_TYPE InpRiskType         = RISK_TYPE_FIXED_LOTS; // Risk type

//+------------------------------------------------------------------+
//| Global variables
//+------------------------------------------------------------------+
double               RangeGap            = 0;
double               StopLoss            = 0;
double               TakeProfit1         = 0;
double               TakeProfit2         = 0;
double               TakeProfit3         = 0;

datetime             StartTime           = 0;
datetime             EndTime             = 0;
bool                 InRange             = false;

long                 Magic1              = 0;
long                 Magic2              = 0;

double               BuyEntryPrice       = 0;
double               SellEntryPrice      = 0;

int                  PositionCount       = 0;
;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {

   bool inputsOK = true;

   // Validate start and end are valid times
   if ( InpRangeStartHour < 0 || InpRangeStartHour > 23 ) {
      Alert( "Start hour must be in the range from 0-23" );
      inputsOK = false;
   }

   if ( InpRangeStartMinute < 0 || InpRangeStartMinute > 59 ) {
      Alert( "Start minute must be in the range from 0-59" );
      inputsOK = false;
   }

   if ( InpRangeEndHour < 0 || InpRangeEndHour > 23 ) {
      Alert( "End hour must be in the range from 0-23" );
      inputsOK = false;
   }

   if ( InpRangeEndMinute < 0 || InpRangeEndMinute > 59 ) {
      Alert( "End minute must be in the range from 0-59" );
      inputsOK = false;
   }

   if ( InpRangeGapPips <= 0 ) {
      Alert( "Range Gap must be > 0" );
      inputsOK = false;
   }

   if ( InpStopLossPips < 0 ) {
      Alert( "Stop Loss must be >= 0" );
      inputsOK = false;
   }

   if ( InpTakeProfit1Pips < 0 ) {
      Alert( "Take Profit 1 must be >= 0" );
      inputsOK = false;
   }

   if ( InpTakeProfit2Pips < 0 ) {
      Alert( "Take Profit 2 must be >= 0" );
      inputsOK = false;
   }

   if ( InpTakeProfit3Pips < 0 ) {
      Alert( "Take Profit 3 must be >= 0" );
      inputsOK = false;
   }

   if ( InpRisk <= 0 ) {
      Alert( "Risk must be > 0" );
      inputsOK = false;
   }

   if ( !inputsOK ) return INIT_PARAMETERS_INCORRECT;

   RangeGap       = PipsToDouble( InpRangeGapPips );
   StopLoss       = PipsToDouble( InpStopLossPips );
   TakeProfit1    = PipsToDouble( InpTakeProfit1Pips );
   TakeProfit2    = PipsToDouble( InpTakeProfit2Pips );
   TakeProfit3    = PipsToDouble( InpTakeProfit3Pips );

   BuyEntryPrice  = 0;
   SellEntryPrice = 0;

   // Not with 3 magics
   //#ifdef __MQL5__
   //   Trade.SetExpertMagicNumber( InpMagic );
   //#endif

   // First find the setup for the starting time range
   datetime now   = TimeCurrent();
   EndTime        = SetNextTime( now + 60, InpRangeEndHour, InpRangeEndMinute );
   StartTime      = SetPrevTime( EndTime, InpRangeStartHour, InpRangeStartMinute );
   InRange        = ( StartTime <= now && EndTime > now );

   Magic1         = InpMagic;
   Magic2         = Magic1 + 1;

   // In case a trade has closed while shut down
   PositionCount  = 0;
   UpdateBreakEven();

   return ( INIT_SUCCEEDED );
}

void OnDeinit( const int reason ) {}

void OnTick() {

   if ( PositionsTotal() != PositionCount ) {
      UpdateBreakEven();
   }

   datetime now              = TimeCurrent();
   bool     currentlyInRange = ( StartTime <= now && now < EndTime );

   if ( InRange && !currentlyInRange ) {
      SetTradeEntries();
   }
   if ( now >= EndTime ) {
      EndTime   = SetNextTime( EndTime + 60, InpRangeEndHour, InpRangeEndMinute );
      StartTime = SetPrevTime( EndTime, InpRangeStartHour, InpRangeStartMinute );
   }
   InRange             = currentlyInRange;

   double currentPrice = 0;
   if ( BuyEntryPrice > 0 ) {
      currentPrice = SymbolInfoDouble( Symbol(), SYMBOL_ASK );
      if ( currentPrice >= BuyEntryPrice ) {
         OpenTrade( ORDER_TYPE_BUY, currentPrice );
         BuyEntryPrice  = 0;
         SellEntryPrice = 0;
      }
   }

   if ( SellEntryPrice > 0 ) {
      currentPrice = SymbolInfoDouble( Symbol(), SYMBOL_BID );
      if ( currentPrice <= SellEntryPrice ) {
         OpenTrade( ORDER_TYPE_SELL, currentPrice );
         BuyEntryPrice  = 0;
         SellEntryPrice = 0;
      }
   }
}

datetime SetNextTime( datetime now, int hour, int minute ) {

   MqlDateTime nowStruct;
   TimeToStruct( now, nowStruct );

   nowStruct.sec     = 0;
   datetime nowTime  = StructToTime( nowStruct );

   nowStruct.hour    = hour;
   nowStruct.min     = minute;
   datetime nextTime = StructToTime( nowStruct );

   while ( nextTime < nowTime || !IsTradingDay( nextTime ) ) {
      nextTime += 86400;
   }

   return nextTime;
}

datetime SetPrevTime( datetime now, int hour, int minute ) {

   MqlDateTime nowStruct;
   TimeToStruct( now, nowStruct );

   nowStruct.sec     = 0;
   datetime nowTime  = StructToTime( nowStruct );

   nowStruct.hour    = hour;
   nowStruct.min     = minute;
   datetime prevTime = StructToTime( nowStruct );

   while ( prevTime >= nowTime || !IsTradingDay( prevTime ) ) {
      prevTime -= 86400;
   }

   return prevTime;
}

bool IsTradingDay( datetime time ) {

   MqlDateTime timeStruct;
   TimeToStruct( time, timeStruct );
   datetime fromTime;
   datetime toTime;
   return SymbolInfoSessionTrade( Symbol(), ( ENUM_DAY_OF_WEEK )timeStruct.day_of_week, 0, fromTime, toTime );
}

double PipsToDouble( double pips ) { return PipsToDouble( Symbol(), pips ); }

double PipsToDouble( string symbol, double pips ) {

   int digits = ( int )SymbolInfoInteger( symbol, SYMBOL_DIGITS );
   if ( digits == 3 || digits == 5 ) {
      pips = pips * 10;
   }
   double value = pips * SymbolInfoDouble( symbol, SYMBOL_POINT );
   return value;
}

void SetTradeEntries() {

   int    startBar = iBarShift( Symbol(), Period(), StartTime, false );
   int    endBar   = iBarShift( Symbol(), Period(), EndTime, false ) + 1;

   double high     = iHigh( Symbol(), Period(), iHighest( Symbol(), Period(), MODE_HIGH, startBar - endBar + 1, endBar ) );
   double low      = iLow( Symbol(), Period(), iLowest( Symbol(), Period(), MODE_LOW, startBar - endBar + 1, endBar ) );

   BuyEntryPrice   = high + RangeGap;
   SellEntryPrice  = low - RangeGap;
}

void OpenTrade( ENUM_ORDER_TYPE type, double price ) {

   double sl = 0;

   if ( type == ORDER_TYPE_BUY ) {
      sl = price - StopLoss;
   }
   else {
      sl = price + StopLoss;
   }

   if ( !OpenTrade( type, price, sl, TakeProfit1, Magic1 ) ) return;
   if ( !OpenTrade( type, price, sl, TakeProfit2, Magic2 ) ) return;
   if ( !OpenTrade( type, price, sl, TakeProfit3, Magic2 ) ) return;
}

bool OpenTrade( ENUM_ORDER_TYPE type, double price, double sl, double takeProfit, long magic ) {

   // 1. allow 0 take profit
   if ( takeProfit == 0 ) return true;

   double tp = 0;

   if ( type == ORDER_TYPE_BUY ) {
      tp = price + takeProfit;
   }
   else {
      tp = price - takeProfit;
   }

   int digits    = ( int )SymbolInfoInteger( Symbol(), SYMBOL_DIGITS );
   price         = NormalizeDouble( price, digits );
   sl            = NormalizeDouble( sl, digits );
   tp            = NormalizeDouble( tp, digits );

   // 2. set volume based on risk
   double volume = 0;
   if ( InpRiskType == RISK_TYPE_EQUITY_PERCENT ) {
      volume = GetRiskVolume( InpRisk / 100, MathAbs( price - sl ) );
   }
   else if ( InpRiskType == RISK_TYPE_FIXED_LOTS ) {
      volume = InpRisk;
   }

#ifdef __MQL4__
   int ticket = OrderSend( Symbol(), type, volume, price, 0, sl, tp, InpTradeComment, ( int )magic );
   if ( ticket <= 0 ) {
      PrintFormat( "Error opening trade, type=%s, volume=%f, price=%f, sl=%f, tp=%f", EnumToString( type ), volume, price, sl, tp );
      return false;
   }
#endif

#ifdef __MQL5__
   Trade.SetExpertMagicNumber( magic );
   if ( !Trade.PositionOpen( Symbol(), type, volume, price, sl, tp, InpTradeComment ) ) {
      PrintFormat( "Error opening trade, type=%s, volume=%f, price=%f, sl=%f, tp=%f", EnumToString( type ), volume, price, sl, tp );
      return false;
   }
#endif

   return true;
}

// 3. risk volume function
// risk = fraction of equity to risk
// loss = price movement being risked
double GetRiskVolume( double risk, double loss ) {

   double equity     = AccountInfoDouble( ACCOUNT_EQUITY );
   double riskAmount = equity * risk; // risk in deposit currency

   double tickValue  = SymbolInfoDouble( Symbol(), SYMBOL_TRADE_TICK_VALUE ); // value of a tick in deposit currency
   double tickSize   = SymbolInfoDouble( Symbol(), SYMBOL_TRADE_TICK_SIZE );  // size of a tick price movement
   double lossTicks  = loss / tickSize;                                       // There may be rounding here, loss is in price movement

   double volume     = riskAmount / ( lossTicks * tickValue );
   volume            = NormaliseVolume( volume );

   return volume;
}

double NormaliseVolume( double volume ) {

   if ( volume <= 0 ) return 0; // nothing to do

   double max    = SymbolInfoDouble( Symbol(), SYMBOL_VOLUME_MAX );
   double min    = SymbolInfoDouble( Symbol(), SYMBOL_VOLUME_MIN );
   double step   = SymbolInfoDouble( Symbol(), SYMBOL_VOLUME_STEP );

   double result = MathRound( volume / step ) * step;
   if ( result > max ) result = max;
   if ( result < min ) result = min;

   return result;
}

// Move trades to b/e at trigger price
void UpdateBreakEven() {

   if ( !InpUseBreakEven ) return;

   for ( int i = PositionsTotal() - 1; i >= 0; i-- ) {

      if ( !PositionSelectByIndex( i, Magic2 ) ) continue;       // Only select the secondary trades
      if ( PositionStopLoss() == PositionPriceOpen() ) continue; // already at b/e

      datetime timeOpen   = PositionTimeOpen();

      // Capture these because the IsPrimaryOpen fn will change
      //		the selected position
      long     ticket     = PositionTicket();
      double   priceOpen  = PositionPriceOpen();
      double   takeProfit = PositionTakeProfit();

      // Find the primary trade if it still exists
      if ( !IsPrimaryOpen( timeOpen ) ) { // Note the ! here, looking for no primary
         SetBreakEven( ticket, priceOpen, takeProfit );
      }
   }

   PositionCount = PositionsTotal();
}

bool IsPrimaryOpen( datetime timeOpen ) {

   // Find the primary trade if it still exists
   bool primaryOpen = false;
   for ( int i = PositionsTotal() - 1; i >= 0; i-- ) {

      // If a trade matches magic and time open then found
      if ( PositionSelectByIndex( i, Magic1, timeOpen ) ) return true;
   }

   return false; // No current primary trade
}

void SetBreakEven( long ticket, double priceOpen, double takeProfit ) {

// Now just update the stop loss
#ifdef __MQL4__
   bool success = OrderModify( ( int )ticket, priceOpen, priceOpen, takeProfit, 0 );
#endif
#ifdef __MQL5__
   Trade.PositionModify( ticket, priceOpen, takeProfit );
#endif
}

bool PositionSelectByIndex( int index, long magic, datetime groupTime ) {

   if ( !PositionSelectByIndex( index, magic ) ) return false;
   if ( MathAbs( PositionTimeOpen() - groupTime ) > 300 ) return false;
   return true;
}

#ifdef __MQL4__
bool PositionSelectByIndex( int index, long magic ) {

   if ( !OrderSelect( index, SELECT_BY_POS, MODE_TRADES ) ) return false;
   if ( OrderSymbol() != Symbol() ) return false;
   if ( OrderMagicNumber() != magic ) return false;
   if ( OrderType() != ORDER_TYPE_BUY && OrderType() != ORDER_TYPE_SELL ) return false;
   return true;
}

// for easier compatibility
int      PositionsTotal() { return OrdersTotal(); }
double   PositionStopLoss() { return OrderStopLoss(); }
double   PositionPriceOpen() { return OrderOpenPrice(); }
int      PositionTicket() { return OrderTicket(); }
datetime PositionTimeOpen() { return OrderOpenTime(); }
double   PositionTakeProfit() { return OrderTakeProfit(); }
int      PositionType() { return OrderType(); }
long     PositionMagic() { return OrderMagicNumber(); }

#endif

#ifdef __MQL5__

bool PositionSelectByIndex( int index, long magic ) {

   ulong ticket = PositionGetTicket( index );
   if ( ticket <= 0 ) return false;
   if ( PositionSymbol() != Symbol() ) return false;
   if ( PositionMagic() != magic ) return false;

   return true;
}

// Some to make compatibility easier
// There are native PositionGet... fns for these but I'll use the object

long     PositionMagic() { return PositionGetInteger( POSITION_MAGIC ); }
double   PositionPriceOpen() { return PositionGetDouble( POSITION_PRICE_OPEN ); }
double   PositionStopLoss() { return PositionGetDouble( POSITION_SL ); }
string   PositionSymbol() { return PositionGetString( POSITION_SYMBOL ); }
double   PositionTakeProfit() { return PositionGetDouble( POSITION_TP ); }
long     PositionTicket() { return PositionGetInteger( POSITION_TICKET ); }
datetime PositionTimeOpen() { return ( datetime )PositionGetInteger( POSITION_TIME ); }
int      PositionType() { return ( int )PositionGetInteger( POSITION_TYPE ); }

#endif
