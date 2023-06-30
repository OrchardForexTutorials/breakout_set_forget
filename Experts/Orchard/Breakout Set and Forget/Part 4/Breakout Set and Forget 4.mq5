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

#property copyright "Copyright 2023, Orchard Forex"
#property link "https://www.orchardforex.com"
#property version "2.00"

#include <Trade/Trade.mqh>
CTrade        Trade;
CPositionInfo PositionInfo;

//+------------------------------------------------------------------+
//|	Inputs
//+------------------------------------------------------------------+
// Time range
input int     InpRangeStartHour   = 1; // Range start hour
input int     InpRangeStartMinute = 0; // Range start minute
input int     InpRangeEndHour     = 1; // Range end hour
input int     InpRangeEndMinute   = 0; // Range end minute

input double  InpRangeGapPips     = 7.0;  // Entry gap from outer range pips
input double  InpStopLossPips     = 25.0; // Stop loss pips
input double  InpTakeProfit1Pips  = 15.0; // Take profit 1 pips
input double  InpTakeProfit2Pips  = 35.0; // Take profit 2 pips
input double  InpTakeProfit3Pips  = 50.0; // Take profit 3 pips

// Standard features
input long    InpMagic            = 232323;         // Magic number
input string  InpTradeComment     = "SnF Breakout"; // Trade comment
input double  InpRiskPercent      = 1.0;            // Risk Percent

//+------------------------------------------------------------------+
//| Global variables
//+------------------------------------------------------------------+
double        RangeGap            = 0;
double        StopLoss            = 0;
double        TakeProfit1         = 0;
double        TakeProfit2         = 0;
double        TakeProfit3         = 0;
double        Risk                = 0;

datetime      StartTime           = 0;
datetime      EndTime             = 0;
bool          InRange             = false;

double        BuyEntryPrice       = 0;
double        SellEntryPrice      = 0;

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

   if ( InpRiskPercent <= 0 ) {
      Alert( "Risk must be > 0" );
      inputsOK = false;
   }

   if ( !inputsOK ) return INIT_PARAMETERS_INCORRECT;

   Risk           = InpRiskPercent / 100;

   RangeGap       = PipsToDouble( InpRangeGapPips );
   StopLoss       = PipsToDouble( InpStopLossPips );
   TakeProfit1    = PipsToDouble( InpTakeProfit1Pips );
   TakeProfit2    = PipsToDouble( InpTakeProfit2Pips );
   TakeProfit3    = PipsToDouble( InpTakeProfit3Pips );

   BuyEntryPrice  = 0;
   SellEntryPrice = 0;

   Trade.SetExpertMagicNumber( InpMagic );

   // First find the setup for the starting time range
   datetime now = TimeCurrent();
   EndTime      = SetNextTime( now + 60, InpRangeEndHour, InpRangeEndMinute );
   StartTime    = SetPrevTime( EndTime, InpRangeStartHour, InpRangeStartMinute );
   InRange      = ( StartTime <= now && EndTime > now );

   return ( INIT_SUCCEEDED );
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit( const int reason ) {}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {

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

   int    startBar = iBarShift( Symbol(), PERIOD_M1, StartTime, false );
   int    endBar   = iBarShift( Symbol(), PERIOD_M1, EndTime - 60, false );

   double high     = iHigh( Symbol(), PERIOD_M1, iHighest( Symbol(), PERIOD_M1, MODE_HIGH, startBar - endBar + 1, endBar ) );
   double low      = iLow( Symbol(), PERIOD_M1, iLowest( Symbol(), PERIOD_M1, MODE_LOW, startBar - endBar + 1, endBar ) );

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

   if ( !OpenTrade( type, price, sl, TakeProfit1 ) ) return;
   if ( !OpenTrade( type, price, sl, TakeProfit2 ) ) return;
   if ( !OpenTrade( type, price, sl, TakeProfit3 ) ) return;
}

bool OpenTrade( ENUM_ORDER_TYPE type, double price, double sl, double takeProfit ) {

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

   double volume = 0.01;

   if ( !Trade.PositionOpen( Symbol(), type, volume, price, sl, tp, InpTradeComment ) ) {
      PrintFormat( "Error opening trade, type=%s, volume=%f, price=%f, sl=%f, tp=%f", EnumToString( type ), volume, price, sl, tp );
      return false;
   }

   return true;
}
