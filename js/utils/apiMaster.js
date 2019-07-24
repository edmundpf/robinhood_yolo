var Api, assert, b64Dec, dataStore, detPrint, endpoints, newApiObj, p, request, roundNum, sleep, sortOptions, uuid;

p = require('print-tools-js');

uuid = require('uuid/v4');

assert = require('assert');

endpoints = require('./endpoints');

request = require('request-promise');

b64Dec = require('./miscFunctions').b64Dec;

detPrint = require('./miscFunctions').detPrint;

roundNum = require('./miscFunctions').roundNum;

sortOptions = require('./miscFunctions').sortOptions;

dataStore = require('./dataStore')();

//: API Object
Api = class Api {
  //: Constructor
  constructor(args = {
      newLogin: false,
      configIndex: 0,
      configData: null,
      print: false
    }) {
    args = {
      newLogin: false,
      configIndex: 0,
      configData: null,
      print: false,
      ...args
    };
    this.headers = {
      Accept: '*/*',
      Connection: 'keep-alive',
      'Accept-Encoding': 'gzip, deflate',
      'Accept-Language': 'en;q=1, fr;q=0.9, de;q=0.8, ja;q=0.7, nl;q=0.6, it;q=0.5',
      'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
      'X-Robinhood-API-Version': '1.0.0',
      'User-Agent': 'Robinhood/823 (iPhone; iOS 7.1.2; Scale/2.00)'
    };
    this.clientId = 'c82SH0WZOsabOXGP2sxqcj34FxkvfnWRZBKlBjFS';
    this.session = request.defaults({
      jar: true,
      gzip: true,
      json: true,
      timeout: 3000,
      headers: this.headers
    });
    this.configIndex = args.configIndex;
    this.newLogin = args.newLogin;
    this.print = args.print;
    if (args.configData != null) {
      this.configData = args.configData;
      this.externalConfig = true;
    } else {
      dataStore.getDataFiles();
      this.externalConfig = false;
    }
  }

  //: Login Flow
  async login(args = {
      newLogin: false,
      configIndex: 0
    }) {
    var error;
    args = {
      newLogin: false,
      configIndex: 0,
      ...args
    };
    try {
      if (args.newLogin != null) {
        this.newLogin = args.newLogin;
      }
      await this.auth({
        newLogin: args.newLogin,
        configIndex: args.configIndex
      });
      if (this.print) {
        p.success(`${this.username} logged in.`);
      }
      return true;
    } catch (error1) {
      error = error1;
      if (this.print) {
        p.error(`${this.username} could not login.`);
        detPrint(error);
      }
      throw error;
    }
  }

  //: Authentification
  async auth(args = {
      newLogin: false,
      configIndex: 0
    }) {
    var accUrl, error, res;
    try {
      args = {
        newLogin: false,
        configIndex: 0,
        ...args
      };
      this.configIndex = args.configIndex;
      if (this.configData == null) {
        this.configData = dataStore.configData[this.configIndex];
        this.externalConfig = false;
      }
      this.username = b64Dec(this.configData.u_n);
      if ((Date.now() > this.configData.t_s + 86400000) || args.newLogin) {
        res = (await this.postUrl(endpoints.login(), {
          grant_type: 'password',
          client_id: this.clientId,
          device_token: b64Dec(this.configData.d_t),
          username: this.username,
          password: b64Dec(this.configData.p_w)
        }));
        this.accessToken = res.access_token;
        this.refreshToken = res.refresh_token;
        this.authToken = `Bearer ${this.accessToken}`;
        this.session = this.session.defaults({
          headers: {
            ...this.headers,
            Authorization: this.authToken
          }
        });
        if ((this.configData.a_u != null) || this.configData.a_u === '' || args.newLogin) {
          accUrl = (await this.getAccount());
          this.accountUrl = accUrl.url;
        } else {
          this.accountUrl = this.configData.a_u;
        }
        Object.assign(this.configData, {
          a_t: this.accessToken,
          r_t: this.refreshToken,
          a_b: this.authToken,
          a_u: this.accountUrl,
          t_s: Date.now()
        });
        dataStore.configData[this.configIndex] = this.configData;
        if (!this.externalConfig) {
          dataStore.updateJson('yolo_config', dataStore.configData);
        }
      } else {
        this.accessToken = this.configData.a_t;
        this.refreshToken = this.configData.r_t;
        this.authToken = this.configData.a_b;
        this.accountUrl = this.configData.a_u;
        this.session = this.session.defaults({
          headers: {
            ...this.headers,
            Authorization: this.authToken
          }
        });
      }
      if (!this.externalConfig) {
        return true;
      } else {
        return this.configData;
      }
    } catch (error1) {
      error = error1;
      throw error;
    }
  }

  //: Get Account Info
  async getAccount() {
    var data, error;
    try {
      data = (await this.getUrl(endpoints.accounts(), true));
      return data[0];
    } catch (error1) {
      error = error1;
      throw error;
    }
  }

  //: Get Transfers
  async getTransfers() {
    var error;
    try {
      return (await this.getUrl(endpoints.transfers(), true));
    } catch (error1) {
      error = error1;
      throw error;
    }
  }

  //: Get Market Hours
  async getMarketHours(date) {
    var error;
    try {
      return (await this.getUrl(endpoints.marketHours(date)));
    } catch (error1) {
      error = error1;
      throw error;
    }
  }

  //: Get Watch List
  async getWatchList(args = {
      watchList: 'Default',
      instrumentData: false,
      quoteData: false
    }) {
    var data, error, i, instData, j, k, len, quotes, ref, ticker, tickers;
    try {
      args = {
        watchList: 'Default',
        instrumentData: false,
        quoteData: false,
        ...args
      };
      tickers = [];
      data = (await this.getUrl(endpoints.watchList(args.watchList), true));
      for (j = 0, len = data.length; j < len; j++) {
        ticker = data[j];
        ticker.id = ticker.instrument.match('(?<=instruments\/).[^\/]+')[0];
        if (args.instrumentData) {
          instData = (await this.getUrl(ticker.instrument));
          ticker.instrument_data = instData;
        }
        if (args.quoteData) {
          tickers.push(ticker.instrument_data.symbol);
        }
      }
      if (args.quoteData) {
        quotes = (await this.quotes(tickers));
        for (i = k = 0, ref = data.length; (0 <= ref ? k < ref : k > ref); i = 0 <= ref ? ++k : --k) {
          data[i].quote_data = quotes[i];
        }
      }
      return data;
    } catch (error1) {
      error = error1;
      throw error;
    }
  }

  //: Get Quotes
  async quotes(symbols, args = {
      chainData: false
    }) {
    var data, error, j, len, obj;
    try {
      args = {
        chainData: false,
        ...args
      };
      if (!Array.isArray(symbols)) {
        data = (await this.getUrl(endpoints.quotes(symbols)));
      } else {
        data = (await this.getUrl(endpoints.quotes(symbols), true));
      }
      if (!Array.isArray(data)) {
        data = [data];
      }
      if (args.chainData) {
        for (j = 0, len = data.length; j < len; j++) {
          obj = data[j];
          obj.instrument_data = (await this.getUrl(obj.instrument));
          obj.chain_data = (await this.chain(obj.instrument_data.id));
        }
      }
      if (!Array.isArray(symbols)) {
        return data[0];
      }
      return data;
    } catch (error1) {
      error = error1;
      throw error;
    }
  }

  //: Get Historicals
  async historicals(symbols, args = {
      interval: 'day',
      span: 'year',
      bounds: 'regular'
    }) {
    var arr, data, error, j, len, ref, symbolData;
    try {
      args = {
        interval: 'day',
        span: 'year',
        bounds: 'regular',
        ...args
      };
      data = (await this.getUrl(endpoints.historicals(symbols, args.interval, args.span, args.bounds)));
      if (!Array.isArray(symbols)) {
        return data.results[0].historicals;
      } else {
        symbolData = [];
        ref = data.results;
        for (j = 0, len = ref.length; j < len; j++) {
          arr = ref[j];
          symbolData.push(arr.historicals);
        }
        return symbolData;
      }
    } catch (error1) {
      error = error1;
      throw error;
    }
  }

  //: Get Instrument Data
  async chain(instrumentId) {
    var error;
    try {
      return (await this.getUrl(endpoints.chain(instrumentId), true));
    } catch (error1) {
      error = error1;
      throw error;
    }
  }

  //: Get Market Data
  async marketData(optionId) {
    var error;
    try {
      return (await this.getUrl(endpoints.marketData(optionId)));
    } catch (error1) {
      error = error1;
      throw error;
    }
  }

  //: Get Options
  async getOptions(symbol, expirationDate, args = {
      optionType: 'call',
      marketData: false,
      expired: false
    }) {
    var chainData, chainId, data, error, j, k, len, len1, obj, ticker;
    try {
      args = {
        optionType: 'call',
        marketData: false,
        expired: false,
        ...args
      };
      chainId;
      chainData = (await this.quotes(symbol, {
        chainData: true
      }));
      chainData = chainData.chain_data;
      for (j = 0, len = chainData.length; j < len; j++) {
        ticker = chainData[j];
        if (ticker.symbol === symbol) {
          chainId = ticker.id;
        }
      }
      if (!args.expired) {
        data = (await this.getUrl(endpoints.options(chainId, expirationDate, args.optionType), true));
      } else {
        data = (await this.getUrl(endpoints.expiredOptions(chainId, expirationDate, args.optionType), true));
      }
      if (args.marketData) {
        for (k = 0, len1 = data.length; k < len1; k++) {
          obj = data[k];
          obj.market_data = (await this.marketData(obj.id));
        }
      }
      return data;
    } catch (error1) {
      error = error1;
      throw error;
    }
  }

  //: Find Options
  async findOptions(symbol, expirationDate, args = {
      optionType: 'call',
      strikeType: 'itm',
      strikeDepth: 0,
      marketData: false,
      range: null,
      strike: null,
      expired: false
    }) {
    var curTime, dateNum, error, i, itmIndex, j, k, len, obj, options, quote, ref, strikePrice;
    try {
      args = {
        optionType: 'call',
        strikeType: 'itm',
        strikeDepth: 0,
        marketData: false,
        range: null,
        strike: null,
        expired: false,
        ...args
      };
      curTime = new Date();
      dateNum = (curTime.getHours() * 10000) + (curTime.getMinutes() * 100) + curTime.getSeconds();
      options = (await this.getOptions(symbol, expirationDate, {
        optionType: args.optionType,
        expired: args.expired
      }));
      options.sort(sortOptions);
      if (args.strike != null) {
        args.strike = roundNum(args.strike);
      }
      quote = (await this.quotes(symbol));
      if (dateNum > 93000) {
        quote = roundNum(quote.last_trade_price);
      } else {
        quote = roundNum(quote.last_extended_hours_trade_price);
      }
      itmIndex;
      for (i = j = 0, ref = options.length; (0 <= ref ? j < ref : j > ref); i = 0 <= ref ? ++j : --j) {
        strikePrice = roundNum(options[i].strike_price);
        if (strikePrice === quote || strikePrice === args.strike) {
          itmIndex = i;
          break;
        } else if (args.optionType === 'call' && strikePrice < quote) {
          itmIndex = i;
          break;
        } else if (args.optionType === 'put' && strikePrice < quote) {
          itmIndex = i - 1;
          break;
        }
      }
      if ((args.range == null) && (args.strike == null)) {
        if (args.optionType === 'call' && args.strikeType === 'itm') {
          options = [options[itmIndex + args.strikeDepth]];
        } else if (args.optionType === 'call' && args.strikeType === 'otm') {
          options = [options[itmIndex - 1 - args.strikeDepth]];
        } else if (args.optionType === 'put' && args.strikeType === 'itm') {
          options = [options[itmIndex - args.strikeDepth]];
        } else if (args.optionType === 'put' && args.strikeType === 'otm') {
          options = [options[itmIndex + 1 + args.strikeDepth]];
        }
      } else if (args.range != null) {
        options = options.slice(itmIndex - args.range, itmIndex + args.range);
      } else if (args.strike != null) {
        options = [options[itmIndex]];
      }
      if (args.marketData) {
        for (k = 0, len = options.length; k < len; k++) {
          obj = options[k];
          obj.market_data = (await this.marketData(obj.id));
        }
      }
      if (args.range == null) {
        return options[0];
      } else {
        return options;
      }
    } catch (error1) {
      error = error1;
      throw error;
    }
  }

  //: Get Options Historicals
  async findOptionHistoricals(symbol, expirationDate, args = {
      optionType: 'call',
      strikeType: 'itm',
      strikeDepth: 0,
      strike: null,
      expired: true,
      interval: 'hour',
      span: 'month'
    }) {
    var data, error, option;
    try {
      args = {
        optionType: 'call',
        strikeType: 'itm',
        strikeDepth: 0,
        strike: null,
        expired: true,
        interval: 'hour',
        span: 'month',
        ...args
      };
      option = (await this.findOptions(symbol, expirationDate, args));
      data = (await this.getUrl(endpoints.optionsHistoricals(option.url, args.interval, args.span), true));
      return data[0].data_points;
    } catch (error1) {
      error = error1;
      throw error;
    }
  }

  //: Get Options Postions
  async optionsPositions(args = {
      marketData: false,
      orderData: false,
      openOnly: true,
      notFilled: false
    }) {
    var arg, breakLoop, data, error, j, k, key, l, leg, len, len1, len2, len3, len4, len5, len6, m, n, notFilled, o, obj, openData, options, orderData, orders, pos, q, ref, value;
    try {
      args = {
        markedData: false,
        orderData: false,
        openOnly: true,
        notFilled: false,
        ...args
      };
      data = (await this.getUrl(endpoints.optionsPositions(), true));
      if (args.openOnly) {
        openData = [];
        for (j = 0, len = data.length; j < len; j++) {
          pos = data[j];
          if (Number(pos.quantity) > 0) {
            openData.push(pos);
          }
        }
        data = openData;
      }
      if (args.orderData) {
        orders = [];
        for (k = 0, len1 = data.length; k < len1; k++) {
          obj = data[k];
          orders.push(obj.option);
        }
        if (!args.notFilled) {
          orderData = (await this.optionsOrders({
            urls: orders,
            buyOnly: true
          }));
          for (l = 0, len2 = data.length; l < len2; l++) {
            obj = data[l];
            for (key in orderData) {
              value = orderData[key];
              if (obj.option === key) {
                obj.order_data = value;
                delete orderData[key];
                break;
              }
            }
          }
        } else if (args.notFilled) {
          notFilled = [];
          orderData = (await this.optionsOrders({
            notFilled: true
          }));
          breakLoop = false;
          for (m = 0, len3 = orderData.length; m < len3; m++) {
            obj = orderData[m];
            for (n = 0, len4 = data.length; n < len4; n++) {
              arg = data[n];
              ref = obj.legs;
              for (o = 0, len5 = ref.length; o < len5; o++) {
                leg = ref[o];
                breakLoop = false;
                if (leg.option === arg.option) {
                  breakLoop = true;
                  arg.order_data = obj;
                  notFilled.push(arg);
                  break;
                }
              }
              if (breakLoop) {
                break;
              }
            }
          }
          data = notFilled;
        }
      }
      if (args.marketData) {
        options = [];
        for (q = 0, len6 = data.length; q < len6; q++) {
          obj = data[q];
          obj.option_data = (await this.getUrl(obj.option));
          obj.market_data = (await this.marketData(obj.option_data.id));
        }
      }
      return data;
    } catch (error1) {
      error = error1;
      throw error;
    }
  }

  //: Get Options Orders
  async optionsOrders(args = {
      urls: null,
      id: null,
      notFilled: false,
      buyOnly: false
    }) {
    var data, error, fetchOrders, j, len, notFilled, order;
    try {
      data;
      args = {
        urls: null,
        id: null,
        notFilled: false,
        buyOnly: false,
        ...args
      };
      if (args.id != null) {
        return (await this.getUrl(endpoints.optionsOrders(args.id)));
      }
      if (args.urls != null) {
        fetchOrders = function(data, options) {
          var arg, breakLoop, j, k, l, leg, len, len1, len2, obj, ref, ref1, results;
          results = {};
          breakLoop = false;
          if (!Array.isArray(options.args)) {
            options.args = [options.args];
          }
          ref = options.args;
          for (j = 0, len = ref.length; j < len; j++) {
            arg = ref[j];
            for (k = 0, len1 = data.length; k < len1; k++) {
              obj = data[k];
              ref1 = obj.legs;
              for (l = 0, len2 = ref1.length; l < len2; l++) {
                leg = ref1[l];
                breakLoop = false;
                if (leg.option === arg) {
                  if (options.mod && obj.direction === 'debit' && leg.side === 'buy') {
                    breakLoop = true;
                    results[arg] = obj;
                    break;
                  } else if (!options.mod) {
                    breakLoop = true;
                    results[arg] = obj;
                    break;
                  }
                }
              }
              if (breakLoop) {
                break;
              }
            }
          }
          return results;
        };
        data = (await this.getDataFromUrl(endpoints.optionsOrders(), fetchOrders, {
          args: args.urls,
          mod: args.buyOnly
        }));
      } else {
        data = (await this.getUrl(endpoints.optionsOrders(), true));
      }
      if (args.notFilled) {
        notFilled = [];
        if (!Array.isArray(data)) {
          data = [data];
        }
        for (j = 0, len = data.length; j < len; j++) {
          order = data[j];
          if (order.cancel_url != null) {
            notFilled.push(order);
          }
        }
        data = notFilled;
      }
      return data;
    } catch (error1) {
      error = error1;
      throw error;
    }
  }

  //: Place Option Order
  async placeOptionOrder(option, quantity, price, args = {
      direction: 'debit',
      side: 'buy',
      positionEffect: 'open',
      legs: null
    }) {
    var error, legs;
    try {
      legs;
      args = {
        direction: 'debit',
        side: 'buy',
        positionEffect: 'open',
        legs: null,
        ...args
      };
      assert(typeof option === 'string');
      assert(!isNaN(quantity));
      assert(!isNaN(price));
      assert(['debit', 'credit'].includes(args.direction));
      assert(['buy', 'sell'].includes(args.side));
      assert(['open', 'close'].includes(args.positionEffect));
      if (args.legs == null) {
        legs = [
          {
            option: option,
            side: args.side,
            position_effect: args.positionEffect,
            ratio_quantity: 1
          }
        ];
      } else {
        legs = args.legs;
      }
      try {
        if (option === 'null' && args.direction === 'credit' && legs[0].side === 'sell') {
          if (this.print) {
            p.warning('Will sleep before placing sell order...');
          }
          await sleep(1000);
        }
        return (await this.placeOrderFlow(quantity, price, args, legs));
      } catch (error1) {
        error = error1;
        if (error.statusCode === 400 && (error.error != null) && (error.error.detail != null) && error.error.detail.includes('order is invalid')) {
          if (this.print) {
            p.error('Could not place sell order, will sleep and try again...');
          }
          await sleep(1000);
          return (await this.placeOrderFlow(quantity, price, args, legs));
        } else {
          throw error;
        }
      }
    } catch (error1) {
      error = error1;
      throw error;
    }
  }

  //: Cancel Option Order
  async cancelOptionOrder(cancelUrl) {
    var data, error;
    try {
      assert(typeof cancelUrl === 'string');
      data = (await this.postUrl(cancelUrl, {}));
      if (data = {}) {
        return true;
      } else {
        return false;
      }
    } catch (error1) {
      error = error1;
      throw error;
    }
  }

  //: Replace Option Order
  async replaceOptionOrder(quantity, price, args = {
      order: null,
      orderId: null
    }) {
    var data, error;
    try {
      data;
      args = {
        order: null,
        orderId: null,
        ...args
      };
      assert((args.order != null) || (args.orderId != null));
      if ((args.order == null) && (args.orderId != null)) {
        data = (await this.optionsOrders({
          id: args.orderId
        }));
      } else {
        data = args.order;
      }
      if ((await this.cancelOptionOrder(data.cancel_url))) {
        return (await this.placeOptionOrder('null', quantity, price, {
          direction: data.direction,
          legs: data.legs
        }));
      } else {
        return false;
      }
    } catch (error1) {
      error = error1;
      throw error;
    }
  }

  //: Place Order Flow
  async placeOrderFlow(quantity, price, args, legs) {
    return (await this.postUrl(endpoints.optionsOrders(), {
      account: this.accountUrl,
      direction: args.direction,
      legs: legs,
      price: price,
      quantity: quantity,
      time_in_force: 'gfd',
      trigger: 'immediate',
      type: 'limit',
      override_day_trade_checks: false,
      override_dtbp_checks: false,
      ref_id: uuid()
    }));
  }

  //: Get URL
  async getUrl(url, consume = false) {
    var data, error, pages;
    try {
      if (!consume) {
        return (await this.session.get({
          uri: url
        }));
      } else {
        data = (await this.session.get({
          uri: url
        }));
        pages = data.results;
        while (data.next != null) {
          data = (await this.session.get({
            uri: data.next
          }));
          pages.push(...data.results);
        }
        return pages;
      }
    } catch (error1) {
      error = error1;
      if ((error.cause != null) && error.cause.code === 'ETIMEDOUT') {
        return (await this.getUrl(url, consume));
      } else {
        throw error;
      }
    }
  }

  //: Post URL
  async postUrl(url, data) {
    var error;
    try {
      return (await this.session.post({
        uri: url,
        body: data,
        headers: {
          ...this.headers,
          'Content-Type': 'application/json'
        }
      }));
    } catch (error1) {
      error = error1;
      throw error;
    }
  }

  //: Get Data from URL based on Condition
  async getDataFromUrl(url, conditionFunc, args) {
    var data, error, hasArrayArgs, res, resKeys, results;
    try {
      results = {};
      resKeys;
      hasArrayArgs = Array.isArray(args.args);
      data = (await this.session.get({
        uri: url
      }));
      results = conditionFunc(data.results, args);
      while (data.next != null) {
        data = (await this.session.get({
          uri: data.next
        }));
        res = conditionFunc(data.results, args);
        results = {...results, ...res};
        resKeys = Object.keys(results);
        if (hasArrayArgs && args.args.length === resKeys.length) {
          return results;
        } else if (!hasArrayArgs && resKeys.length === 1) {
          return results[resKeys[0]];
        }
      }
      return results;
    } catch (error1) {
      error = error1;
      throw error;
    }
  }

};

//: Sleep
sleep = function(time) {
  return new Promise(function(resolve) {
    return setTimeout(resolve, time);
  });
};

//: New API Object
newApiObj = function(args = {
    newLogin: false,
    configIndex: 0,
    configData: null,
    print: false
  }) {
  args = {
    newLogin: false,
    configIndex: 0,
    configData: null,
    print: false,
    ...args
  };
  return new Api({
    newLogin: args.newLogin,
    configIndex: args.configIndex,
    configData: args.configData,
    print: args.print
  });
};

//: Exports
module.exports = newApiObj;

//::: End Program :::
