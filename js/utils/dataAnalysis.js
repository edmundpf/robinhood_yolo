var Analysis, dataStore, queryStr, request;

request = require('request-promise');

dataStore = require('./dataStore')();

queryStr = require('./miscFunctions').queryStr;

Analysis = class Analysis {
  //: Constructor
  constructor(args) {
    args = {
      apiKey: null,
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
    this.session = request.defaults({
      jar: true,
      gzip: true,
      json: true,
      timeout: 5000,
      headers: this.headers
    });
    this.apiUrl = 'https://www.quandl.com/api/v3/datasets/WIKI';
    if (args.apiKey != null) {
      this.apiKey = args.apiKey;
    } else {
      dataStore.getDataFiles();
      this.apiKey = dataStore.apiSettings.quandl;
    }
  }

  //: Api Url
  api(symbol, args) {
    args = {
      api_key: this.apiKey,
      ...args
    };
    return `${this.apiUrl}/${symbol}/data.json${queryStr(args)}`;
  }

  //: Get URL
  async getUrl(url) {
    var error;
    try {
      return (await this.session.get({
        uri: url
      }));
    } catch (error1) {
      error = error1;
      if ((error.cause != null) && error.cause.code === 'ETIMEDOUT') {
        return (await this.getUrl(url));
      } else {
        throw error;
      }
    }
  }

  //: Get Data
  async getData(symbol, args) {
    var data;
    args = {
      start_date: '',
      end_date: '',
      frequency: 'daily',
      ...args
    };
    data = (await this.getUrl(this.api(symbol, args)));
    return data;
  }

};

//: Exports
module.exports = Analysis;

//::: End Program :::
