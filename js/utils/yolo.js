var ON_DEATH, addAccountCom, api, b64Dec, b64Enc, buyCom, cancelCom, chalk, colorPrint, com, configData, dashboardCom, dayTrades, defaults, deleteAccountCom, editAccountCom, findCom, inquirer, main, moment, overwriteJson, p, parseInt, parsePrice, posCom, posWatchCom, printFind, printInPlace, printOrder, printPos, printQuotes, quoteCom, replaceCom, roundNum, sellCom, showAccountsCom, stopLossWatch, term, terminatePosition, tradeCom, updateJson,
  indexOf = [].indexOf;

com = require('commander');

moment = require('moment');

term = require('terminal-kit').terminal;

ON_DEATH = require('death');

roundNum = require('./miscFunctions').roundNum;

colorPrint = require('./miscFunctions').colorPrint;

configData = require('../data/config.json');

defaults = require('../data/defaults.json');

b64Dec = require('./miscFunctions').b64Dec;

b64Enc = require('./miscFunctions').b64Enc;

updateJson = require('./miscFunctions').updateJson;

overwriteJson = require('./miscFunctions').overwriteJson;

inquirer = require('inquirer');

p = require('print-tools-js');

chalk = require('chalk');

api = require('./apiMaster')({
  newLogin: false,
  configIndex: 0,
  print: true
});

//: Main Program
main = function() {
  var keys;
  //: Option Keys
  keys = ['login', 'ticker', 'url', 'id', 'expiry', 'option_type', 'strike_type', 'quantity', 'price', 'depth', 'range', 'command'];
  //: Options
  return com.option('-l, --login_index <login_index>', 'Change login config index', parseInt).option('-t, --ticker <ticker>', 'Add option ticker').option('-u, --url <url>', 'Add option URL').option('-i, --id <id>', 'Add ID').option('-e, --expiry <expiry>', 'Add option expiry').option('-o, --option_type <option_type>', 'Add option type').option('-s, --strike_type <strike_type>', 'Add option strike type').option('-q, --quantity <quantity>', 'Add option contracts quantity', parseInt).option('-p, --price <price>', 'Add option price', parsePrice).option('-d, --depth <depth>', 'Add option depth', parseInt).option('-r, --range <range>', 'Add option range', parseInt).option('-c, --command <command>', 'Run command(s) [dashboard, show_accounts, add_account, edit_account, ' + 'delete_account, trades, watch, stop_loss, quote, position, find, buy, sell, cancel, replace]').action(async function() {
    var c, error, j, k, key, len, len1, ref, results;
    try {
      if (com.login_index == null) {
        com.login_index = 0;
      }
      if (configData.length > 0 && !com.command.includes('account')) {
        await api.login({
          configIndex: com.login_index
        });
      }
//: List-type options parsing
      for (j = 0, len = keys.length; j < len; j++) {
        key = keys[j];
        if ((com[key] != null) && indexOf.call(com[key], ',') >= 0) {
          com[key] = com[key].split(',');
        }
      }
      //: Commands
      if (com.command != null) {
        if (!Array.isArray(com.command)) {
          com.command = [com.command];
        }
        ref = com.command;
        results = [];
        for (k = 0, len1 = ref.length; k < len1; k++) {
          c = ref[k];
          //: Dashboard
          if (c === 'dashboard') {
            results.push(dashboardCom(com));
          //: Show Accounts
          } else if (c === 'show_accounts') {
            results.push(showAccountsCom(com));
          //: Add Account
          } else if (c === 'add_account') {
            results.push(addAccountCom(com));
          //: Edit Account
          } else if (c === 'edit_account') {
            results.push(editAccountCom(com));
          //: Delete Account
          } else if (c === 'delete_account') {
            results.push(deleteAccountCom(com));
          //: Trades
          } else if (c === 'trades') {
            results.push(tradeCom(com));
          //: Position Watch
          } else if (c === 'watch') {
            results.push(posWatchCom(com));
          //: Stop Loss
          } else if (c === 'stop_loss') {
            results.push(stopLossWatch(com));
          //: Quotes
          } else if (c === 'quote') {
            results.push(quoteCom(com));
          //: Position
          } else if (c === 'position') {
            results.push(posCom(com));
          //: Find Options
          } else if (c === 'find') {
            results.push(findCom(com));
          //: Buy Option
          } else if (c === 'buy') {
            results.push(buyCom(com));
          //: Sell Option
          } else if (c === 'sell') {
            results.push(sellCom(com));
          //: Cancel Option Order
          } else if (c === 'cancel') {
            results.push(cancelCom(com));
          //: Replace Option Order
          } else if (c === 'replace') {
            results.push(replaceCom(com));
          } else {
            results.push(void 0);
          }
        }
        return results;
      }
    } catch (error1) {
      error = error1;
      throw error;
    }
  }).parse(process.argv);
};

//::: Commands :::

//: Dashboard Command
dashboardCom = async function(com) {
  var account, day_trades, deposits, j, len, results, trade, transfer, transfers, url, withdraws;
  account = (await api.getAccount());
  transfers = (await api.getTransfers());
  withdraws = deposits = 0;
// Transfers
  for (j = 0, len = transfers.length; j < len; j++) {
    transfer = transfers[j];
    if (!transfer.scheduled && transfer.rhs_state === 'submitted' && transfer.direction === 'withdraw') {
      withdraws += Number(transfer.amount);
    }
    if (!transfer.scheduled && transfer.rhs_state === 'submitted' && transfer.direction === 'deposit') {
      deposits += Number(transfer.amount);
    }
  }
  // Stats
  p.chevron(`Buying Power: ${account.margin_balances.day_trade_buying_power}`, {
    log: false
  });
  p.chevron(`Available for Withdrawal: ${account.margin_balances.cash_available_for_withdrawal}`, {
    log: false
  });
  p.chevron(`Unsettled Funds: ${account.margin_balances.unsettled_funds}`, {
    log: false
  });
  p.chevron(chalk`Deposits: {red $${deposits}}`, {
    log: false
  });
  p.chevron(chalk`Withdrawals: {green $${withdraws}}`, {
    log: false
  });
  // Day Trades
  day_trades = (await dayTrades());
  p.chevron(`Day Trades: ${(Object.keys(day_trades).length)}`, {
    log: false
  });
  results = [];
  for (url in day_trades) {
    trade = day_trades[url];
    results.push(p.bullet(`${trade.symbol}: ${trade.date}`, {
      indent: 1,
      log: false
    }));
  }
  return results;
};

//: Show Accounts Command
showAccountsCom = function(com) {
  var i, j, ref, results;
  results = [];
  for (i = j = 0, ref = configData.length; (0 <= ref ? j < ref : j > ref); i = 0 <= ref ? ++j : --j) {
    results.push(p.chevron(`Index ${i}: ${b64Dec(configData[i].u_n)} | ${b64Dec(configData[i].d_t)}`));
  }
  return results;
};

//: Add Account Commmand
addAccountCom = async function(com) {
  var answer, error, newConfig;
  p.success('This will add a new account to the config.');
  try {
    answer = (await inquirer.prompt([
      {
        type: 'input',
        name: 'username',
        message: 'Enter username:'
      },
      {
        type: 'password',
        name: 'password',
        message: 'Enter password:',
        mask: true
      },
      {
        type: 'input',
        name: 'device_token',
        message: 'Enter device token:'
      }
    ]));
    newConfig = {
      d_t: b64Enc(answer.device_token),
      u_n: b64Enc(answer.username),
      p_w: b64Enc(answer.password),
      a_t: '',
      r_t: '',
      a_b: '',
      a_u: '',
      t_s: 0
    };
    configData.push(newConfig);
    updateJson('../data/config.json', configData);
    return p.success(`${answer.username} added successfully.`);
  } catch (error1) {
    error = error1;
    return p.error('Could not add account.');
  }
};

//: Edit Account Command
editAccountCom = async function(com) {
  var acc, account, accounts, answer, error, j, len, newConfig;
  p.success('This will edit account details in the config.');
  try {
    accounts = [];
    for (j = 0, len = configData.length; j < len; j++) {
      account = configData[j];
      accounts.push(b64Dec(account.u_n));
    }
    //: Get Account
    acc = (await inquirer.prompt([
      {
        type: 'rawlist',
        name: 'account',
        message: 'Which account would you like to edit?',
        choices: accounts
      }
    ]));
    //: Edit Account
    answer = (await inquirer.prompt([
      {
        type: 'input',
        name: 'username',
        message: 'Enter username:'
      },
      {
        type: 'password',
        name: 'password',
        message: 'Enter password:',
        mask: true
      },
      {
        type: 'input',
        name: 'device_token',
        message: 'Enter device token:'
      }
    ]));
    newConfig = {
      d_t: b64Enc(answer.device_token),
      u_n: b64Enc(answer.username),
      p_w: b64Enc(answer.password)
    };
    configData[accounts.indexOf(acc.account)] = {...configData[accounts.indexOf(acc.account)], ...newConfig};
    updateJson('../data/config.json', configData);
    return p.success(`${answer.username} edited successfully.`);
  } catch (error1) {
    error = error1;
    return p.error('Could not edit account.');
  }
};

//: Delete Account Command
deleteAccountCom = async function(com) {
  var acc, account, accounts, error, j, len;
  p.success('This will delete an account from the config.');
  try {
    accounts = [];
    for (j = 0, len = configData.length; j < len; j++) {
      account = configData[j];
      accounts.push(b64Dec(account.u_n));
    }
    //: Get Account
    if (accounts.length > 0) {
      acc = (await inquirer.prompt([
        {
          type: 'rawlist',
          name: 'account',
          message: 'Which account would you like to delete from the config?',
          choices: accounts
        }
      ]));
      configData.splice(accounts.indexOf(acc.account), 1);
      overwriteJson('../data/config.json', configData);
      return p.success(`${acc.account} deleted successfully.`);
    } else {
      return p.error("Config has no accounts.");
    }
  } catch (error1) {
    error = error1;
    p.error('Could not delete account.');
    return console.log(error);
  }
};

//: Trades Command
tradeCom = async function(com) {
  var amt, amtColor, cur_time, data, date, defeats, gains, j, len, losses, net, option, options, time, trade, trades, url, wins;
  trades = {};
  amt = gains = losses = wins = defeats = 0;
  p.success(`Getting trade history for ${api.username}`);
  options = (await api.optionsOrders());
  for (j = 0, len = options.length; j < len; j++) {
    option = options[j];
    date = time = '';
    if (option.state !== 'cancelled') {
      if (option.direction === 'credit') {
        amt = Number(option.processed_premium);
      } else if (option.direction === 'debit') {
        amt = Number(option.processed_premium) !== 0 ? Number(option.processed_premium) * -1 : 0;
      }
      try {
        cur_time = moment(option.legs[0].executions[0].timestamp);
        date = cur_time.format('YYYY/MM/DD');
        time = cur_time.format('HH:mm:ss');
      } catch (error1) {}
      url = option.legs[0].option;
      if (trades[url] == null) {
        trades[url] = {
          amt: amt,
          symbol: option.chain_symbol,
          date: date,
          time: time
        };
      } else {
        trades[url].amt += amt;
        if (trades[url].time === '' && time !== '') {
          trades[url].time = time;
        }
      }
    }
  }
  for (url in trades) {
    trade = trades[url];
    amtColor = 'green';
    data = (await api.getUrl(url));
    Object.assign(trade, {
      strikePrice: data.strike_price,
      expirationDate: data.expiration_date,
      optionType: data.type,
      expirationDate: data.expiration_date
    });
    if (trade.amt >= 0) {
      gains += trade.amt;
      wins += 1;
    } else if (trade.amt < 0) {
      amtColor = 'red';
      losses += trade.amt;
      defeats += 1;
    }
    amt = roundNum(trade.amt);
    p.bullet(chalk`${trade.symbol}-${trade.date}-${trade.optionType}: {${amtColor} $${amt}}`, {
      log: false
    });
  }
  net = gains + losses;
  p.chevron(chalk`{green Gains}: ${gains}`, {
    log: false
  });
  p.chevron(chalk`{red Losses}: ${losses}`, {
    log: false
  });
  if (wins >= defeats) {
    p.arrow(chalk`Record: {green ${wins}-${defeats}}`, {
      log: false
    });
  } else {
    p.arrow(chalk`Record: {red ${wins}-${defeats}}`, {
      log: false
    });
  }
  if (net >= 0) {
    return p.arrow(chalk`Net: {green ${net}}`, {
      log: false
    });
  } else {
    return p.arrow(chalk`Net: {red ${net}}`, {
      log: false
    });
  }
};

//: Position Watch Command
posWatchCom = async function(com) {
  var positions;
  p.success('Getting open positions');
  positions = (await api.optionsPositions({
    marketData: true,
    orderData: true
  }));
  return setInterval(async() => {
    var ask_count, ask_price, bid_count, bid_price, cur_time, delta, error, expiry, j, len, option_type, pos, posDet, posLog, posText, posUrl, pos_market, pos_quote, price, quote, spyLog, spyPrice, spy_quote, strike, symbol, theta, volatility, volume;
    try {
      spy_quote = (await api.quotes('SPY'));
      spyPrice = (cur_time >= 93000 && cur_time < 160000) ? roundNum(spy_quote.last_trade_price, 3) : roundNum(spy_quote.last_extended_hours_trade_price, 3);
      spyLog = p.bullet(`SPY: ${spyPrice} | Bid - ${spy_quote.bid_size} | Ask - ${spy_quote.ask_size}`, {
        ret: true
      });
      posText = '';
      for (j = 0, len = positions.length; j < len; j++) {
        pos = positions[j];
        pos_quote = (await api.quotes(pos.chain_symbol));
        pos_market = (await api.marketData(pos.option_data.id));
        symbol = pos.chain_symbol;
        cur_time = Number(moment().format('HHmmss'));
        option_type = pos.option_data.type === 'call' ? 'C' : 'P';
        strike = roundNum(pos.option_data.strike_price, 1);
        expiry = pos.option_data.expiration_date.replace(/-/g, '/');
        quote = (cur_time >= 93000 && cur_time < 160000) ? roundNum(pos_quote.last_trade_price, 3) : roundNum(pos_quote.last_extended_hours_trade_price, 3);
        price = roundNum(pos_market.adjusted_mark_price, 3);
        ask_price = roundNum(pos_market.ask_price);
        ask_count = pos_market.ask_size;
        bid_price = roundNum(pos_market.bid_price);
        bid_count = pos_market.bid_size;
        delta = roundNum(pos_market.delta, 3);
        theta = roundNum(pos_market.theta, 3);
        volatility = roundNum(pos_market.implied_volatility, 3);
        volume = pos_market.volume;
        posLog = p.bullet(`${symbol}-${option_type}-${strike}-${expiry} | Price: ${price} | Quote: ${quote}`, {
          ret: true,
          log: false
        });
        posDet = p.chevron(`Bid: ${bid_price} x ${bid_count} | Ask: ${ask_price} x ${ask_count} | Volume: ${volume} | Δ: ${delta} | θ: ${theta} | IV: ${volatility}`, {
          ret: true,
          log: false,
          indent: 1
        });
        posUrl = p.arrow(`URL: ${pos.option}`, {
          ret: true,
          log: false,
          indent: 1
        });
        posText += `${posLog}\n${posDet}\n${posUrl}\n`;
      }
      return printInPlace(`${spyLog}\n${posText}`);
    } catch (error1) {
      error = error1;
    }
  }, 2000);
};

//: Stop Loss Watch
stopLossWatch = async function(com) {
  var MAX_LOSS, TRADE_COUNT, answer, day_trades, market_time, pos_data;
  p.success('Getting open positions');
  day_trades = (await dayTrades());
  TRADE_COUNT = Object.keys(day_trades).length;
  MAX_LOSS = defaults.stopLoss;
  market_time = moment();
  pos_data = {};
  p.success(`Starting stop-loss watch: ${market_time.format('HH:mm:ss')}`);
  market_time = market_time.format('HHmmss');
  if (market_time < 93000 || market_time > 160000) {
    p.error('Exiting stop-loss watch, market is not currently open.');
  } else if (market_time >= 93000 && market_time < defaults.poorFillTime) {
    answer = (await inquirer.prompt([
      {
        type: 'rawlist',
        name: 'continue',
        message: 'Market has just opened and stop-loss could trigger poor fills due to low volume. Continue?',
        choices: ['Yes',
      'No']
      }
    ]));
    if (answer.continue === 'No') {
      p.error('Exiting stop-loss watch.');
      return false;
    }
  }
  return setInterval(async() => {
    var bid_price, buy_price, cur_pos, current_price, error, expiry, high, id, j, len, openPos, option_type, pos, posDet, posLog, posText, positions, sell_args, soldPosition, stop_loss, strike, symbol;
    try {
      positions = (await api.optionsPositions({
        marketData: true
      }));
      posText = '';
      openPos = [];
      for (j = 0, len = positions.length; j < len; j++) {
        pos = positions[j];
        // Data
        symbol = pos.chain_symbol;
        option_type = pos.option_data.type === 'call' ? 'C' : 'P';
        strike = roundNum(pos.option_data.strike_price, 1);
        expiry = pos.option_data.expiration_date.replace(/-/g, '/');
        current_price = Number(pos.market_data.adjusted_mark_price);
        buy_price = Number(pos.average_price) / 100;
        bid_price = Number(pos.market_data.bid_price);
        high = current_price > buy_price ? current_price : buy_price;
        stop_loss = 0;
        openPos.push(pos.id);
        if (pos_data[pos.id] == null) {
          pos_data[pos.id] = {
            price: buy_price,
            high: high,
            status: 'open',
            sell_id: null
          };
        } else {
          if (pos_data[pos.id].high < high) {
            pos_data[pos.id].high = high;
          }
        }
        // Sell Arguments
        sell_args = {
          url: pos.option,
          quantity: pos.quantity,
          price: bid_price,
          id: pos_data[pos.id].id
        };
        cur_pos = pos_data[pos.id];
        // High < Price * 1.1
        if (cur_pos.high < (cur_pos.price * (1 + MAX_LOSS / 2))) {
          stop_loss = roundNum(cur_pos.high - (cur_pos.price * MAX_LOSS));
          if (current_price <= stop_loss) {
            p.error(`Stop-Loss (Max Loss) triggered: Symbol: ${symbol} | Current Price: ${current_price} | Bid Price: ${bid_price} | Stop Loss: ${stop_loss}`);
            if (TRADE_COUNT < 3) {
              terminatePosition(cur_pos, sell_args);
            }
          }
        // High >= Price * 1.1 && High < Price * 1.2
        } else if (cur_pos.high >= (cur_pos.price * (1 + MAX_LOSS / 2)) && cur_pos.high < (cur_pos.price * (1 + MAX_LOSS))) {
          stop_loss = roundNum(cur_pos.price + 0.01);
          if (current_price <= stop_loss) {
            posText += p.error(`Stop-Loss (Prevent Defeat) triggered: Symbol: ${symbol} | Current Price: ${current_price} | Bid Price: ${bid_price} | Stop Loss: ${stop_loss}`);
            if (TRADE_COUNT < 3) {
              terminatePosition(cur_pos, sell_args);
            }
          }
        // High >= Price * 1.2
        } else if (cur_pos.high >= (cur_pos.price * (1 + MAX_LOSS))) {
          stop_loss = (cur_pos.high - (cur_pos.price * MAX_LOSS)) >= (current_price + 0.01) ? roundNum(cur_pos.high - (cur_pos.price * MAX_LOSS)) : roundNum(current_price + 0.01);
          if (current_price <= stop_loss) {
            posText += p.error(`Stop-Loss (Preserve Gains) triggered: Symbol: ${symbol} | Current Price: ${current_price} | Bid Price: ${bid_price} | Stop Loss: ${stop_loss}`);
            if (TRADE_COUNT < 3) {
              terminatePosition(cur_pos, sell_args);
            }
          }
        }
        // Log
        posLog = p.chevron(`${symbol}-${option_type}-${strike}-${expiry} | Buy Price: ${buy_price}`, {
          ret: true,
          log: false
        });
        posDet = p.bullet(`Current Price: ${current_price} | Bid Price: ${bid_price} | Stop Loss: ${stop_loss}`, {
          ret: true,
          log: false,
          indent: 1
        });
        posText += `${posLog}\n${posDet}\n`;
      }
      soldPosition = false;
      for (id in pos_data) {
        pos = pos_data[id];
        if (!openPos.includes(id) && pos.status === 'selling') {
          soldPosition = true;
          delete pos_data[id];
        }
      }
      if (soldPosition) {
        day_trades = (await dayTrades());
        TRADE_COUNT = Object.keys(day_trades).length;
      }
      return printInPlace(posText);
    } catch (error1) {
      error = error1;
    }
  }, 5000);
};

//: Quote Command
quoteCom = async function(com) {
  var data;
  p.success(`Getting quote for ${com.ticker}`);
  data = (await api.quotes(com.ticker));
  return printQuotes(data);
};

//: Position Command
posCom = async function(com) {
  var data;
  p.success('Getting open positions');
  data = (await api.optionsPositions({
    marketData: true,
    orderData: true
  }));
  printPos(data);
  p.success('Getting unfilled orders');
  data = (await api.optionsPositions({
    marketData: true,
    orderData: true,
    openOnly: false,
    notFilled: true
  }));
  return printPos(data, true);
};

//: Find Command
findCom = async function(com) {
  var args, data;
  args = {
    symbol: com.ticker,
    expiry: com.expiry,
    optionType: com.option_type || 'call',
    strikeType: com.strike_type || 'itm',
    strikeDepth: com.depth || 0,
    range: com.range,
    price: com.price
  };
  if ((args.range == null) && (args.price == null)) {
    p.success(`Finding option ${args.symbol}-${args.expiry.replace(/-/g, '/')}-${args.optionType}-${args.strikeType}-${args.strikeDepth}`);
  } else if (args.price != null) {
    p.success(`Finding option ${args.symbol}-${args.expiry.replace(/-/g, '/')}-${args.optionType}-${args.price}`);
  } else if (args.range != null) {
    p.success(`Finding option ${args.symbol}-${args.expiry.replace(/-/g, '/')}-${args.optionType}-(+-${args.range})`);
  }
  data = (await api.findOptions(args.symbol, args.expiry, {
    optionType: args.optionType,
    strikeType: args.strikeType,
    strikeDepth: args.strikeDepth,
    range: args.range,
    strike: args.price,
    marketData: true
  }));
  return printFind(data);
};

//: Buy Command
buyCom = async function(com) {
  var buy, option, quote;
  option = (await api.getUrl(com.url));
  p.success(`Attempting to buy ${option.chain_symbol}-${option.expiration_date}-${option.type}-${option.strike_price}`);
  buy = (await api.placeOptionOrder(com.url, com.quantity, com.price));
  quote = (await api.quotes(option.chain_symbol));
  if (buy.id != null) {
    p.success('Order placed successfully');
    printOrder(option, quote, buy);
    return buy;
  } else {
    p.error('Could not place order!');
    return false;
  }
};

//: Sell Command
sellCom = async function(com) {
  var option, quote, sell;
  option = (await api.getUrl(com.url));
  p.success(`Attempting to sell ${option.chain_symbol}-${option.expiration_date}-${option.type}-${option.strike_price}`);
  sell = (await api.placeOptionOrder(com.url, com.quantity, com.price, {
    direction: 'credit',
    side: 'sell',
    positionEffect: 'close'
  }));
  quote = (await api.quotes(option.chain_symbol));
  if (sell.id != null) {
    p.success('Order placed successfully');
    printOrder(option, quote, sell);
    return sell;
  } else {
    p.error('Could not place order!');
    return false;
  }
};

//: Cancel Command
cancelCom = async function(com) {
  var data;
  p.success("Attempting to cancel option order");
  data = (await api.cancelOptionOrder(com.url));
  if (data) {
    p.success('Order cancelled successfully');
    return true;
  }
};

//: Replace Command
replaceCom = async function(com) {
  var buy, option, order, quote;
  order = (await api.optionsOrders({
    id: com.id
  }));
  option = (await api.getUrl(order.legs[0].option));
  p.success(`Attempting to replace order ${option.chain_symbol}-${option.expiration_date}-${option.type}-${option.strike_price}`);
  buy = (await api.replaceOptionOrder(com.quantity, com.price, {
    order: order
  }));
  quote = (await api.quotes(option.chain_symbol));
  if (buy.id != null) {
    p.success('Order replaced successfully');
    printOrder(option, quote, buy);
    return buy;
  } else {
    p.error('Could not replace order!');
    return false;
  }
};

//::: Print Methods :::

//: Print Quotes
printQuotes = function(data) {
  var j, len, obj, objOrder, rec, results;
  if (!Array.isArray(data)) {
    data = [data];
  }
  results = [];
  for (j = 0, len = data.length; j < len; j++) {
    rec = data[j];
    obj = {
      symbol: rec.symbol,
      askSize: rec.ask_size,
      bidSize: rec.bid_size,
      price: rec.last_trade_price,
      extendedPrice: rec.last_extended_hours_trade_price
    };
    objOrder = ['symbol', 'price', 'extendedPrice', 'askSize', 'bidSize'];
    results.push(colorPrint(obj, objOrder));
  }
  return results;
};

//: Print Position
printPos = function(data, notFilled = false) {
  var j, len, obj, objOrder, rec, results;
  results = [];
  for (j = 0, len = data.length; j < len; j++) {
    rec = data[j];
    obj = {
      symbol: rec.chain_symbol,
      buyPrice: rec.average_price,
      strikePrice: rec.option_data.strike_price,
      expiry: rec.option_data.expiration_date,
      quantity: rec.quantity,
      type: rec.order_data.opening_strategy,
      bidPrice: rec.market_data.bid_price,
      bidSize: rec.market_data.bid_size,
      askPrice: rec.market_data.ask_price,
      askSize: rec.market_data.ask_size,
      optionPrice: rec.market_data.adjusted_mark_price,
      volume: rec.market_data.volume,
      openInterest: rec.market_data.open_interest,
      impliedVolatility: rec.market_data.implied_volatility,
      delta: rec.market_data.delta,
      theta: rec.market_data.theta,
      orderId: rec.order_data.id,
      optionUrl: rec.option
    };
    objOrder = ['symbol', 'buyPrice', 'strikePrice', 'expiry', 'quantity', 'type', 'delta', 'theta', 'bidPrice', 'bidSize', 'askPrice', 'askSize', 'optionPrice', 'volume', 'openInterest', 'impliedVolatility', 'orderId', 'optionUrl'];
    if (notFilled) {
      obj.cancelUrl = rec.order_data.cancel_url;
      objOrder.push('cancelUrl');
    }
    results.push(colorPrint(obj, objOrder));
  }
  return results;
};

//: Print Find Options
printFind = function(data) {
  var j, len, obj, objOrder, rec, results;
  if (!Array.isArray(data)) {
    data = [data];
  }
  results = [];
  for (j = 0, len = data.length; j < len; j++) {
    rec = data[j];
    obj = {
      symbol: rec.chain_symbol,
      strikePrice: rec.strike_price,
      expiry: rec.expiration_date,
      bidPrice: rec.market_data.bid_price,
      bidSize: rec.market_data.bid_size,
      askPrice: rec.market_data.ask_price,
      askSize: rec.market_data.ask_size,
      optionPrice: rec.market_data.adjusted_mark_price,
      volume: rec.market_data.volume,
      openInterest: rec.market_data.open_interest,
      impliedVolatility: rec.market_data.implied_volatility,
      delta: rec.market_data.delta,
      theta: rec.market_data.theta,
      url: rec.url
    };
    objOrder = ['symbol', 'strikePrice', 'expiry', 'delta', 'theta', 'bidPrice', 'bidSize', 'askPrice', 'askSize', 'optionPrice', 'volume', 'openInterest', 'impliedVolatility', 'url'];
    results.push(colorPrint(obj, objOrder));
  }
  return results;
};

//: Print Order
printOrder = function(option, quote, buy) {
  var obj, objOrder;
  obj = {
    symbol: buy.chain_symbol,
    strategy: buy.opening_strategy,
    strikePrice: option.strike_price,
    expiry: option.expiration_date,
    price: buy.price,
    quote: quote.last_trade_price,
    quantity: buy.quantity,
    cancelUrl: buy.cancel_url,
    orderId: buy.id
  };
  objOrder = ['symbol', 'strategy', 'expiry', 'strikePrice', 'price', 'quote', 'quantity', 'cancelUrl', 'orderId'];
  return colorPrint(obj, objOrder);
};

//::: Helpers :::

//: Parse Int
parseInt = function(val) {
  return Number(val);
};

//: Parse Price
parsePrice = function(val) {
  return roundNum(val);
};

//: Print in Place
printInPlace = function(text) {
  term.saveCursor();
  process.stdout.write(`${text}\r`);
  return term.restoreCursor();
};

//: Terminate Position
terminatePosition = async function(cur_pos, sell_args) {
  var order;
  if (cur_pos.status === 'open') {
    order = (await sellCom(sell_args));
    cur_pos.status = 'selling';
    return cur_pos.sell_id = order.id;
  } else if (cur_pos.status === 'selling') {
    order = (await replaceCom(sell_args));
    return cur_pos.sell_id = order.id;
  }
};

//: Get Day Trades
dayTrades = async function() {
  var buy_date, cutoff_date, date, date_status, day_trades, days, i, j, k, l, orders, ref, ref1, ref2, sell_date, x;
  orders = (await api.optionsOrders());
  cutoff_date = 0;
  day_trades = {};
  days = [];
  for (i = j = 0; j < 14; i = ++j) {
    if (days.length < 5) {
      date = moment().subtract(i, 'days').format('YYYY-MM-DD');
      date_status = (await api.getMarketHours(date));
      if ((date_status.is_open != null) && date_status.is_open) {
        days.push(date_status.date);
      }
      if (days.length === 5) {
        cutoff_date = Number(moment().subtract(i, 'days').format('YYYYMMDD'));
      }
    } else {
      break;
    }
  }
  for (i = k = 0, ref = orders.length; (0 <= ref ? k < ref : k > ref); i = 0 <= ref ? ++k : --k) {
    if (orders[i].legs[0].executions.length >= 1 && Number(moment(orders[i].legs[0].executions[0].timestamp).format('YYYYMMDD')) < cutoff_date) {
      break;
    }
    if (orders[i].state === 'filled' && orders[i].legs[0].executions.length >= 1 && orders[i].legs[0].side === 'sell' && orders[i].legs[0].position_effect === 'close') {
      sell_date = moment(orders[i].legs[0].executions[0].timestamp).format('YYYY-MM-DD');
      if (days.includes(sell_date)) {
        for (x = l = ref1 = i + 1, ref2 = orders.length; (ref1 <= ref2 ? l < ref2 : l > ref2); x = ref1 <= ref2 ? ++l : --l) {
          if (orders[i].option === orders[x].option && orders[x].legs[0].executions.length >= 1 && orders[x].legs[0].side === 'buy' && orders[x].legs[0].position_effect === 'open') {
            buy_date = moment(orders[x].legs[0].executions[0].timestamp).format('YYYY-MM-DD');
            if (buy_date === sell_date) {
              day_trades[orders[i].legs[0].option] = {
                date: sell_date,
                symbol: orders[i].chain_symbol
              };
            }
            break;
          }
        }
      }
    }
  }
  return day_trades;
};

//: Run Program
ON_DEATH(function(signal, err) {
  term.eraseDisplayBelow();
  return process.exit();
});

main();

//::: End Program :::
