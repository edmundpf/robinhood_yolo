var api, endpoints, p, queryStr;

p = require('print-tools-js');

queryStr = require('./miscFunctions').queryStr;

//: Api URL
api = 'https://api.robinhood.com';

//: Endpoints Object
endpoints = {
  api: function(path) {
    return `${api}${path}`;
  },
  //: Login
  login: function() {
    return `${api}/oauth2/token/`;
  },
  //: Accounts
  accounts: function() {
    return `${api}/accounts/`;
  },
  //: Markets
  marketHours: function(date) {
    return `${api}/markets/XNYS/hours/${date}/`;
  },
  //: Transfers
  transfers: function() {
    return `${api}/ach/transfers/`;
  },
  //: Get all orders or fetch by Order ID
  orders: function(id) {
    return `${api}/orders/${id}/`;
  },
  //: Get Quotes for stock or list of stocks
  quotes: function(symbols) {
    if (Array.isArray(symbols)) {
      symbols = symbols.join(',');
      return `${api}/quotes/?symbols=${symbols}`;
    } else {
      return `${api}/quotes/${symbols}/`;
    }
  },
  //: Get Historical Quotes for stock or list of stocks.
  /* ------------------------------------------------
   * interval/span configs:
   * 	5minute | day
   * 	10minute | week
   * 	hour | month
   * 	day | year
   * 	week | 5year
   * bounds:
   * 	regular, extended
   */
  historicals: function(symbols, interval = 'day', span = 'year', bounds = 'regular') {
    var query;
    if (Array.isArray(symbols)) {
      symbols = symbols.join(',');
    }
    query = queryStr({
      symbols: symbols,
      interval: interval,
      span: span,
      bound: bounds
    });
    return `${api}/quotes/historicals/${query}/`;
  },
  //: Get Historical Quotes for options chains
  optionsHistoricals: function(instruments, interval = 'day', span = 'year') {
    var query;
    if (Array.isArray(instruments)) {
      instruments = instruments.join(',');
    }
    query = queryStr({
      instruments: instruments,
      interval: interval,
      span: span
    });
    return `${api}/marketdata/options/historicals/${query}`;
  },
  //: Get Option Chains
  chain: function(instrumentId) {
    return `${api}/options/chains/?equity_instrument_ids=${instrumentId}`;
  },
  //: Get Options
  options: function(chainId, dates, option_type = 'call') {
    var query;
    query = queryStr({
      chain_id: chainId,
      expiration_dates: dates,
      state: 'active',
      tradability: 'tradable',
      type: option_type
    });
    return `${api}/options/instruments/${query}`;
  },
  //: Get All Options (including expired)
  expiredOptions: function(chainId, dates, option_type = 'call') {
    var query;
    query = queryStr({
      chain_id: chainId,
      expiration_dates: dates,
      type: option_type
    });
    return `${api}/options/instruments/${query}`;
  },
  //: Get Options Positions
  optionsPositions: function() {
    return `${api}/options/positions/`;
  },
  //: Get Options Orders
  optionsOrders: function(id) {
    if (id != null) {
      return `${api}/options/orders/${id}/`;
    } else {
      return `${api}/options/orders/`;
    }
  },
  //: Get Market Data
  marketData: function(optionId) {
    return `${api}/marketdata/options/${optionId}/`;
  }
};

//: Exports
module.exports = endpoints;

//::: End Program :::
