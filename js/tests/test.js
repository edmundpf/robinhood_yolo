var a, assert, chalk, dataStore, moment, p, presetList, presetObject, should;

a = require('../utils/apiMaster')({
  newLogin: true
});

p = require('print-tools-js');

chalk = require('chalk');

moment = require('moment');

assert = require('chai').assert;

should = require('chai').should();

dataStore = require('../utils/dataStore')({
  initData: true
});

//: List Preset
presetList = function(func, key, arg1, arg2, arg3, arg4, arg5, arg6) {
  var data;
  data = null;
  before(async function() {
    this.timeout(15000);
    return data = (await func.bind(a)(arg1, arg2, arg3, arg4, arg5, arg6));
  });
  it('Returns array', function() {
    return data.should.be.a('array');
  });
  return it('Key exists', function() {
    return assert.equal(data[0][key] != null, true);
  });
};

//: Object Preset
presetObject = function(func, key, arg1, arg2, arg3, arg4, arg5, arg6) {
  var data;
  data = null;
  before(async function() {
    this.timeout(15000);
    return data = (await func.bind(a)(arg1, arg2, arg3, arg4, arg5, arg6));
  });
  it('Returns object', function() {
    return data.should.be.a('object');
  });
  return it('Key exists', function() {
    return assert.equal(data[key] != null, true);
  });
};

if (dataStore.configData.length > 0) {
  //: Test Constructor
  describe('constructor()', function() {
    before(async function() {
      return (await a.login());
    });
    it('Is object', function() {
      return a.should.be.a('object');
    });
    it('Has username', function() {
      return a.username.should.be.a('string');
    });
    it('Has access token', function() {
      return a.accessToken.should.be.a('string');
    });
    it('Has refresh token', function() {
      return a.refreshToken.should.be.a('string');
    });
    it('Has auth token', function() {
      return assert.equal(a.authToken.indexOf('Bearer'), 0);
    });
    return it('Has account URL', function() {
      return a.accountUrl.should.be.a('string');
    });
  });
  //: Test Account
  describe('account()', function() {
    return presetObject(a.getAccount, 'margin_balances');
  });
  //: Test Market Hours
  describe('getMarketHours()', function() {
    return presetObject(a.getMarketHours, 'is_open', '2019-07-04');
  });
  //: Test Transfers
  describe('getTransfers()', function() {
    return presetList(a.getTransfers, 'scheduled');
  });
  //: Test Stock Orders
  describe('stockOrders()', function() {
    return presetList(a.stockOrders, 'instrument');
  });
  //: Test Get Watchlist
  describe('getWatchList()', function() {
    return presetList(a.getWatchList, 'quote_data', {
      instrumentData: true,
      quoteData: true
    });
  });
  //: Test Quotes for single instrument
  describe('quotes() - single', function() {
    return presetObject(a.quotes, 'chain_data', 'GE', {
      chainData: true
    });
  });
  //: Test Quotes for multiple instruments
  describe('quotes() - multiple', function() {
    return presetList(a.quotes, 'chain_data', ['GE', 'AAPL'], {
      chainData: true
    });
  });
  //: Test Historicals
  describe('historicals()', function() {
    presetList(a.historicals, 'close_price', 'GE', {
      interval: 'day',
      span: 'year',
      bounds: 'regular'
    });
    return it('Test Multiple instruments', async function() {
      var data;
      data = (await a.historicals(['GE', 'AAPL']));
      return data[0].should.be.a('array');
    });
  });
  //: Test Options Historicals
  describe('optionsHistoricals()', function() {
    return presetList(a.findOptionHistoricals, 'begins_at', 'GE', moment().subtract(moment().day() + 2, 'days').format('YYYY-MM-DD'));
  });
  //: Test Get Options
  describe('getOptions()', function() {
    return presetList(a.getOptions, 'market_data', 'GE', '2021-01-15', {
      optionType: 'call',
      marketData: true
    });
  });
  //: Test Find Options for single option
  describe('findOptions() - single', function() {
    return presetObject(a.findOptions, 'market_data', 'GE', '2021-01-15', {
      optionType: 'call',
      strikeType: 'itm',
      strikeDepth: 0,
      marketData: true
    });
  });
  //: Test Find Options by strike price
  describe('findOptions() - strike', function() {
    return presetObject(a.findOptions, 'market_data', 'GE', '2021-01-15', {
      optionType: 'call',
      strike: 11.00,
      marketData: true
    });
  });
  //: Test Find Options for multiple options
  describe('findOptions() - range', function() {
    return presetList(a.findOptions, 'strike_price', 'GE', '2021-01-15', {
      optionType: 'call',
      range: 3
    });
  });
  //: Test Options Positions for all
  describe('optionsPositions() - all', function() {
    return presetList(a.optionsPositions, 'chain_symbol', {
      marketData: false,
      orderData: false,
      openOnly: false
    });
  });
  //: Test Options Positions for open only
  describe('optionsPositions() - open only', function() {
    var data;
    data = null;
    before(async function() {
      this.timeout(15000);
      return data = (await a.optionsPositions({
        marketData: true,
        orderData: true
      }));
    });
    it('Returns array', function() {
      return data.should.be.a('array');
    });
    return it('Key exists', function() {
      if ((data != null) && data.length !== 0) {
        p.success("Has open positions, testing.");
        return assert.equal(data[0]['market_data'] != null, true);
      } else {
        p.warning(chalk`No open positions, skipping {cyan optionsPositions() - open only} - {magenta Key exists}.`);
        return this.skip();
      }
    });
  });
  //: Test Options Orders for all orders
  describe('optionsOrders() - all', function() {
    return presetList(a.optionsOrders, 'legs');
  });
  //: Test Options Orders for not filled
  describe('optionsOrders() - not filled', function() {
    var data;
    data = null;
    before(async function() {
      this.timeout(15000);
      return data = (await a.optionsOrders({
        notFilled: true
      }));
    });
    it('Returns array', function() {
      return data.should.be.a('array');
    });
    return it('Key exists', function() {
      if ((data != null) && data.length > 0) {
        p.success("Has unfilled orders, testing.");
        return assert.equal(data[0]['legs'] != null, true);
      } else {
        p.warning(chalk`No unfilled orders, skipping {cyan optionsOrders() - not filled} - {magenta Key exists}.`);
        return this.skip();
      }
    });
  });
  //: Test Options Orders for single order
  describe('optionsOrders() - single', function() {
    return presetObject(a.optionsOrders, 'legs', {
      id: 'af8d5deb-df2f-42a7-974e-7e16729937f7'
    });
  });
  //: Test Placing Options orders, replacing, and canceling
  describe('Placing Orders', function() {
    var buy, cancel, curTime, dateNum, replace;
    curTime = new Date();
    buy = replace = cancel = null;
    dateNum = (curTime.getHours() * 10000) + (curTime.getMinutes() * 100) + curTime.getSeconds();
    before(async function() {
      var data;
      this.timeout(15000);
      if (dateNum > 160100) {
        p.success(`Markets are closed (${dateNum}), will test placing orders.`);
        data = (await a.findOptions('TSLA', '2021-01-15', {
          strikeDepth: 3
        }));
        buy = (await a.placeOptionOrder(data.url, 1, 0.01));
        replace = (await a.replaceOptionOrder(1, 0.02, {
          orderId: buy.id
        }));
        return cancel = (await a.cancelOptionOrder(replace.cancel_url));
      } else {
        p.warning(chalk`Markets are open (${dateNum}), skipping {cyan Placing Orders} - {magenta all}.`);
        return this.skip();
      }
    });
    it('Buy returns object', function() {
      return buy.should.be.a('object');
    });
    it('Buy key exists', function() {
      return assert.equal(buy.id != null, true);
    });
    it('Replace returns object', function() {
      return replace.should.be.a('object');
    });
    it('Replace key exists', function() {
      return assert.equal(replace.id != null, true);
    });
    return it('Cancel returns true', function() {
      return assert.equal(cancel, true);
    });
  });
} else {
  p.error('No accounts in config file. Exiting.');
}

//::: End Program :::
