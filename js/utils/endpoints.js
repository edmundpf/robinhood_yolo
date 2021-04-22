var api, cashier, endpoints, intervals, p, queryStr;

p = require('print-tools-js');

queryStr = require('./miscFunctions').queryStr;

//: Api URL
api = 'https://api.robinhood.com';

cashier = 'https://cashier.robinhood.com';

//: Appropriate span/interval combos
intervals = {
  'day': '5minute',
  'week': '10minute',
  'month': 'hour',
  'year': 'day',
  '5year': 'week'
};

//: Endpoints Object
endpoints = {
  //: Api prefix
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
  //: Portfolios
  portfolios: function(accountId) {
    return `${api}/portfolios/${accountId}/`;
  },
  //: Markets
  marketHours: function(date) {
    return `${api}/markets/XNYS/hours/${date}/`;
  },
  //: Transfers
  transfers: function() {
    return `${cashier}/ach/transfers/`;
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
  historicals: function(symbols, span = 'year', bounds = 'regular') {
    var query;
    if (Array.isArray(symbols)) {
      symbols = symbols.join(',');
    }
    query = queryStr({
      symbols: symbols,
      interval: intervals[span],
      span: span,
      bound: bounds
    });
    return `${api}/quotes/historicals/${query}/`;
  },
  //: Get Historical Quotes for options chains
  optionsHistoricals: function(instruments, span = 'year') {
    var query;
    if (Array.isArray(instruments)) {
      instruments = instruments.join(',');
    }
    query = queryStr({
      instruments: instruments,
      interval: intervals[span],
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
  //: Get Stock Orders
  stockOrders: function(id) {
    if (id != null) {
      return `${api}/orders/${id}/`;
    } else {

    }
    return `${api}/orders/`;
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
  },
  //: Get Watchlist
  watchList: function(name = 'Default') {
    return `${api}/watchlists/${name}/`;
  },
  //: Add to Watchlist
  addToWatchList: function(id, name = 'Default') {
    return `${api}/watchlists/${name}/${id}/`;
  },
  //: Reorder Watchlist
  reorderWatchList: function(ids, name = 'Default') {
    if (Array.isArray(ids)) {
      ids = ids.join(',');
    }
    return `${api}/watchlists/${name}/reorder/${ids}/`;
  }
};

//: Exports
module.exports = endpoints;

//::: End Program :::
