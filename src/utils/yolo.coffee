`#!/usr/bin/env node
`
chalk = require 'chalk'
com = require('commander')
inquirer = require('inquirer')
p = require 'print-tools-js'
moment = require('moment')
term = require('terminal-kit').terminal
ON_DEATH = require('death')
roundNum = require('./miscFunctions').roundNum
colorPrint = require('./miscFunctions').colorPrint
b64Dec = require('./miscFunctions').b64Dec
b64Enc = require('./miscFunctions').b64Enc
dataStore = require('./dataStore')({ initData: true })
updateJson = dataStore.updateJson.bind(dataStore)
overwriteJson = dataStore.overwriteJson.bind(dataStore)
defaults = dataStore.defaults
configData = dataStore.configData
apiSettings = dataStore.apiSettings

#: Init API

api = require('./apiMaster')(
	newLogin: false
	configIndex: 0
	print: true
)

#: Main Program

main = ->

	#: Option Keys

	keys = [
		'login'
		'ticker'
		'url'
		'id'
		'expiry'
		'option_type'
		'strike_type'
		'quantity'
		'price'
		'depth'
		'range'
		'command'
	]

	#: Options

	com
		.option('-l, --login_index <login_index>', 'Change login config index', parseInt)
		.option('-t, --ticker <ticker>', 'Add option ticker')
		.option('-u, --url <url>', 'Add option URL')
		.option('-i, --id <id>', 'Add ID')
		.option('-e, --expiry <expiry>', 'Add option expiry')
		.option('-o, --option_type <option_type>', 'Add option type')
		.option('-s, --strike_type <strike_type>', 'Add option strike type')
		.option('-q, --quantity <quantity>', 'Add option contracts quantity', parseInt)
		.option('-p, --price <price>', 'Add option price', parsePrice)
		.option('-d, --depth <depth>', 'Add option depth', parseInt)
		.option('-r, --range <range>', 'Add option range', parseInt)
		.option('-c, --command_name <command_name>', 'Run command(s) [dashboard, show_accounts, add_account, edit_account, ' +
			'delete_account, edit_settings, edit_apis, show_apis, trades, watch, stop_loss, stop_loss_sim, quote, position, find, ' +
			'buy, sell, cancel, replace]')
		.action(() ->

			try

				nonLoginCommands = ['show_accounts', 'add_account', 'edit_account', 'delete_account',
					'edit_settings', 'edit_apis', 'show_apis']

				#: User Login Index

				if !com.login_index?
					com.login_index = 0
				if configData.length > 0 && com.command_name? && !nonLoginCommands.includes(com.command_name)
					await api.login(configIndex: com.login_index)

				#: List-type options parsing

				for key in keys
					if com[key]? && ',' in com[key]
						com[key] = com[key].split(',')

				#: Commands

				if com.command_name?
					if !Array.isArray(com.command_name)
						com.command_name = [com.command_name]
					for c in com.command_name

						#: Dashboard

						if c == 'dashboard'
							dashboardCom(com)

						#: Show Accounts

						else if c == 'show_accounts'
							showAccountsCom(com)

						#: Add Account

						else if c == 'add_account'
							addAccountCom(com)

						#: Edit Account

						else if c == 'edit_account'
							editAccountCom(com)

						#: Delete Account

						else if c == 'delete_account'
							deleteAccountCom(com)

						#: Edit Settings

						else if c == 'edit_settings'
							editSettingsCom(com)

						#: Edit Apis

						else if c == 'edit_apis'
							editApisCom(com)

						#: Show Apis

						else if c == 'show_apis'
							showApisCom(com)

						#: Trades
						else if c == 'trades'
							tradeCom(com)

						#: Position Watch

						else if c == 'watch'
							posWatchCom(com)

						#: Stop Loss

						else if c == 'stop_loss'
							stopLossWatch(com, true)

						#: Stop Loss Simulation (logs only, WILL NOT SELL)

						else if c == 'stop_loss_sim'
							stopLossWatch(com, false)

						#: Quotes

						else if c == 'quote'
							quoteCom(com)

						#: Position

						else if c == 'position'
							posCom(com)

						#: Find Options

						else if c == 'find'
							findCom(com)

						#: Buy Option

						else if c == 'buy'
							buyCom(com)

						#: Sell Option

						else if c == 'sell'
							sellCom(com)

						#: Cancel Option Order

						else if c == 'cancel'
							cancelCom(com)

						#: Replace Option Order

						else if c == 'replace'
							replaceCom(com)
				else
					console.log(com.helpInformation())

			catch error
				throw error
		)
		.parse(process.argv)

#::: Commands :::

#: Dashboard Command

dashboardCom = (com) ->
	account = await api.getAccount()
	transfers = await api.getTransfers()
	withdraws = deposits = 0

	# Transfers

	for transfer in transfers
		if not transfer.scheduled and transfer.rhs_state == 'submitted' and transfer.direction == 'withdraw'
			withdraws += Number(transfer.amount)
		if not transfer.scheduled and transfer.rhs_state == 'submitted' and transfer.direction == 'deposit'
			deposits += Number(transfer.amount)

	# Stats

	p.chevron("Buying Power: #{account.margin_balances.day_trade_buying_power}", { log: false })
	p.chevron("Available for Withdrawal: #{account.margin_balances.cash_available_for_withdrawal}", { log: false })
	p.chevron("Unsettled Funds: #{account.margin_balances.unsettled_funds}", { log: false })
	p.chevron(chalk"Deposits: {red $#{deposits}}", { log: false })
	p.chevron(chalk"Withdrawals: {green $#{withdraws}}", { log: false })

	# Day Trades

	day_trades = await dayTrades()
	p.chevron("Day Trades: #{Object.keys(day_trades).length}", { log: false })
	for url, trade of day_trades
		p.bullet("#{trade.symbol}: #{trade.date}", { indent: 1, log: false })

#: Show Accounts Command

showAccountsCom = (com) ->

	for i in [0...configData.length]
		p.chevron("Index #{i}: #{b64Dec(configData[i].u_n)} | #{b64Dec(configData[i].d_t)}")

#: Add Account Commmand

addAccountCom = (com) ->

	p.success('This will add a new account to the config.')

	try
		answer = await inquirer.prompt([
			{
				type: 'input'
				name: 'username'
				message: 'Enter username:'
			},
			{
				type: 'password'
				name: 'password'
				message: 'Enter password:'
				mask: true
			},
			{
				type: 'input'
				name: 'device_token'
				message: 'Enter device token:'
			},
		])
		newConfig =
			d_t: b64Enc(answer.device_token)
			u_n: b64Enc(answer.username)
			p_w: b64Enc(answer.password)
			a_t: ''
			r_t: ''
			a_b: ''
			a_u: ''
			t_s: 0
		configData.push(newConfig)
		updateJson(
			'yolo_config',
			configData
		)
		p.success("#{answer.username} added successfully.")

	catch error
		p.error('Could not add account.')

#: Edit Account Command

editAccountCom = (com) ->

	p.success('This will edit account details in the config.')

	try

		accounts = []
		for account in configData
			accounts.push(b64Dec(account.u_n))

		#: Get Account

		acc = await inquirer.prompt([
				type: 'rawlist'
				name: 'account'
				message: 'Which account would you like to edit?'
				choices: accounts
		])

		#: Edit Account

		answer = await inquirer.prompt([
			{
				type: 'input'
				name: 'username'
				message: 'Enter username:'
			},
			{
				type: 'password'
				name: 'password'
				message: 'Enter password:'
				mask: true
			},
			{
				type: 'input'
				name: 'device_token'
				message: 'Enter device token:'
			},
		])
		newConfig =
			d_t: b64Enc(answer.device_token)
			u_n: b64Enc(answer.username)
			p_w: b64Enc(answer.password)

		configData[accounts.indexOf(acc.account)] = {
			...configData[accounts.indexOf(acc.account)]
			...newConfig
		}
		updateJson(
			'yolo_config',
			configData
		)
		p.success("#{answer.username} edited successfully.")

	catch error
		p.error('Could not edit account.')

#: Delete Account Command

deleteAccountCom = (com) ->

	p.success('This will delete an account from the config.')

	try

		accounts = []
		for account in configData
			accounts.push(b64Dec(account.u_n))

		#: Get Account

		if accounts.length > 0
			acc = await inquirer.prompt([
					type: 'rawlist'
					name: 'account'
					message: 'Which account would you like to delete from the config?'
					choices: accounts
			])

			configData.splice(accounts.indexOf(acc.account), 1)
			overwriteJson(
				'yolo_config',
				configData
			)
			p.success("#{acc.account} deleted successfully.")
		else
			p.error("Config has no accounts.")

	catch error
		p.error('Could not delete account.')

#: Edit Settings Command

editSettingsCom = (com) ->

	p.success('This will edit settings.')
	try
		answer = await inquirer.prompt([
			{
				type: 'input'
				name: 'stopLoss'
				message: 'Enter stop-loss percentage:'
				default: defaults.stopLoss
				validate: isNumber
				filter: parsePrice
			},
			{
				type: 'input'
				name: 'poorFillTime'
				message: 'Enter cut-off time to prevent poor stop-loss fills:'
				default: defaults.poorFillTime
				validate: isNumber
				filter: parseInt
			}
		])
		for key of answer
			defaults[key] = answer[key]
		updateJson(
			'yolo_defaults'
			defaults
		)
		p.success('Settings updated successfully.')
	catch error
		p.error('Could not edit settings.')

#: Edit Apis Command

editApisCom = (com) ->

	p.success('This will edit API settings.')

	try

		#: Get Api

		api = await inquirer.prompt([
				type: 'rawlist'
				name: 'name'
				message: 'Which API would you like to edit?'
				choices: Object.keys(apiSettings)
		])

		#: Edit API

		answer = await inquirer.prompt([
			{
				type: 'input'
				name: 'api_key'
				message: 'Enter API key:'
			}
		])

		apiSettings[api.name] = answer.api_key

		updateJson(
			'yolo_apis',
			apiSettings
		)
		p.success("#{answer.api_key} API key edited successfully.")

	catch error
		p.error('Could not edit API settings.')

#: Show Apis Command

showApisCom = (com) ->

	for key, value of apiSettings
		p.chevron("#{key}: #{value}")

#: Trades Command

tradeCom = (com) ->
	trades = {}
	amt = gains = losses = wins = defeats = 0
	p.success("Getting trade history for #{api.username}")
	options = await api.optionsOrders()
	for option in options
		date = time = ''
		if option.state != 'cancelled'
			if option.direction == 'credit'
				amt = Number(option.processed_premium)
			else if option.direction == 'debit'
				amt = if Number(option.processed_premium) != 0 then Number(option.processed_premium) * -1 else 0
			try
				cur_time = moment(option.legs[0].executions[0].timestamp)
				date = cur_time.format('YYYY/MM/DD')
				time = cur_time.format('HH:mm:ss')
			url = option.legs[0].option
			if !trades[url]?
				trades[url] =
					amt: amt
					symbol: option.chain_symbol
					date: date
					time: time
			else
				trades[url].amt += amt
				if trades[url].time == '' && time != ''
					trades[url].time = time

	for url, trade of trades
		amtColor = 'green'
		data = await api.getUrl(url)
		Object.assign(
			trade,
			strikePrice: data.strike_price
			expirationDate: data.expiration_date
			optionType: data.type
			expirationDate: data.expiration_date
		)
		if trade.amt >= 0
			gains += trade.amt
			wins += 1
		else if trade.amt < 0
			amtColor = 'red'
			losses += trade.amt
			defeats += 1
		amt = roundNum(trade.amt)
		p.bullet(chalk"#{trade.symbol}-#{trade.date}-#{trade.optionType}: {#{amtColor} $#{amt}}", { log: false })

	net = gains + losses
	p.chevron(chalk"{green Gains}: #{gains}", { log: false })
	p.chevron(chalk"{red Losses}: #{losses}", { log: false })
	if wins >= defeats
		p.arrow(chalk"Record: {green #{wins}-#{defeats}}", { log: false })
	else
		p.arrow(chalk"Record: {red #{wins}-#{defeats}}", { log: false })
	if net >= 0
		p.arrow(chalk"Net: {green #{net}}", { log: false })
	else
		p.arrow(chalk"Net: {red #{net}}", { log: false })

#: Position Watch Command

posWatchCom = (com) ->
	p.success('Getting open positions')
	positions = await api.optionsPositions(
		marketData: true
		orderData: true
	)

	setInterval(() =>
		try
			cur_time = Number(moment().format('HHmmss'))
			spy_quote = await api.quotes('SPY')
			spyPrice = if (cur_time >= 93000 && cur_time < 160000) then roundNum(spy_quote.last_trade_price, 3) else roundNum(spy_quote.last_extended_hours_trade_price, 3)
			spyLog = p.bullet("SPY: #{spyPrice} | Bid - #{spy_quote.bid_size} | Ask - #{spy_quote.ask_size}", { ret: true })
			posText = ''
			for pos in positions
				pos_quote = await api.quotes(pos.chain_symbol)
				pos_market = await api.marketData(pos.option_data.id)
				symbol = pos.chain_symbol
				option_type = if pos.option_data.type == 'call' then 'C' else 'P'
				strike = roundNum(pos.option_data.strike_price, 1)
				expiry = pos.option_data.expiration_date.replace(/-/g, '/')
				quote = if (cur_time >= 93000 && cur_time < 160000) then roundNum(pos_quote.last_trade_price, 3) else roundNum(pos_quote.last_extended_hours_trade_price, 3)
				price = roundNum(pos_market.adjusted_mark_price, 3)
				ask_price = roundNum(pos_market.ask_price)
				ask_count = pos_market.ask_size
				bid_price = roundNum(pos_market.bid_price)
				bid_count = pos_market.bid_size
				delta = roundNum(pos_market.delta, 3)
				theta = roundNum(pos_market.theta, 3)
				volatility = roundNum(pos_market.implied_volatility, 3)
				volume = pos_market.volume

				posLog = p.bullet(
					"#{symbol}-#{option_type}-#{strike}-#{expiry} | Price: #{price} | Quote: #{quote}",
					ret: true
					log: false
				)
				posDet = p.chevron(
					"Bid: #{bid_price} x #{bid_count} | Ask: #{ask_price} x #{ask_count} | Volume: #{volume} | Δ: #{delta} | θ: #{theta} | IV: #{volatility}",
					ret: true
					log: false
					indent: 1
				)
				posUrl = p.arrow(
					"URL: #{pos.option}"
					ret: true
					log: false
					indent: 1
				)
				posText += "#{posLog}\n#{posDet}\n#{posUrl}\n"

			printInPlace("#{spyLog}\n#{posText}")

		catch error

	, 2000)

#: Stop Loss Watch

stopLossWatch = (com, placeOrder=false) ->
	p.success('Getting open positions')
	day_trades = await dayTrades()
	TRADE_COUNT = Object.keys(day_trades).length
	MAX_LOSS = defaults.stopLoss
	market_time = moment()
	pos_data = {}

	p.success("Starting stop-loss watch: #{market_time.format('HH:mm:ss')}")
	market_time = market_time.format('HHmmss')

	if market_time < 93000 || market_time > 160000
		p.error('Exiting stop-loss watch, market is not currently open.')
		return false
	else if market_time >= 93000 && market_time < defaults.poorFillTime
		answer = await inquirer.prompt([
				type: 'rawlist'
				name: 'continue'
				message: 'Market has just opened and stop-loss could trigger poor fills due to low volume. Continue?'
				choices: ['Yes', 'No']
		])
		if answer.continue == 'No'
			p.error('Exiting stop-loss watch.')
			return false

	setInterval(() =>
		try
			positions = await api.optionsPositions(
				marketData: true
			)
			posText = ''
			openPos = []
			for pos in positions

				# Data

				symbol = pos.chain_symbol
				option_type = if pos.option_data.type == 'call' then 'C' else 'P'
				strike = roundNum(pos.option_data.strike_price, 1)
				expiry = pos.option_data.expiration_date.replace(/-/g, '/')

				current_price = Number(pos.market_data.adjusted_mark_price)
				buy_price = Number(pos.average_price) / 100
				bid_price = Number(pos.market_data.bid_price)
				high = if current_price > buy_price then current_price else buy_price
				stop_loss = 0
				openPos.push(pos.id)

				# Data Collection

				if !pos_data[pos.id]?
					pos_data[pos.id] =
						price: buy_price
						high: high
						status: 'open'
						sell_id: null
				else
					if pos_data[pos.id].high < high
						pos_data[pos.id].high = high

				# Sell Arguments

				sell_args =
					url: pos.option
					quantity: pos.quantity
					price: bid_price
					id: pos_data[pos.id].id

				cur_pos = pos_data[pos.id]

				# High < Price * 1.1

				if cur_pos.high < (cur_pos.price * (1 + MAX_LOSS / 2))
					stop_loss = roundNum(cur_pos.high - (cur_pos.price * MAX_LOSS))
					if bid_price <= stop_loss
						posText += p.error(
							"Stop-Loss (Max Loss) triggered: Symbol: #{symbol} | Current Price: #{current_price} | Bid Price: #{bid_price} | Stop Loss: #{stop_loss}"
							ret: true
							log: true
						) + '\n'
						if TRADE_COUNT < 3 && placeOrder
							terminatePosition(cur_pos, sell_args)

				# High >= Price * 1.2

				else if cur_pos.high >= (cur_pos.price * (1 + MAX_LOSS))
					stop_loss = if (cur_pos.high - (cur_pos.price * MAX_LOSS)) >= (cur_pos.price + 0.01) then roundNum(cur_pos.high - (cur_pos.price * MAX_LOSS)) else roundNum(cur_pos.price + 0.01)
					if bid_price <= stop_loss
						posText += p.error(
							"Stop-Loss (Preserve Gains) triggered: Symbol: #{symbol} | Current Price: #{current_price} | Bid Price: #{bid_price} | Stop Loss: #{stop_loss}"
							ret: true
							log: true
						) + '\n'
						if TRADE_COUNT < 3 && placeOrder
							terminatePosition(cur_pos, sell_args)

				# Log

				posLog = p.chevron(
					"#{symbol}-#{option_type}-#{strike}-#{expiry} | Buy Price: #{buy_price}",
					ret: true
					log: true
				)
				posDet = p.bullet(
					"Current Price: #{current_price} | Bid Price: #{bid_price} | Stop Loss: #{stop_loss}"
					ret: true
					log: false
					indent: 1
				)
				posText += "#{posLog}\n#{posDet}\n"

			soldPosition = false
			for id, pos of pos_data
				if !openPos.includes(id) && pos.status == 'selling'
					soldPosition = true
					delete pos_data[id]
			if soldPosition
				day_trades = await dayTrades()
				TRADE_COUNT = Object.keys(day_trades).length

			printInPlace(posText)

		catch error

	, 5000)

#: Quote Command

quoteCom = (com) ->
	p.success("Getting quote for #{com.ticker}")
	data = await api.quotes(com.ticker)
	printQuotes(data)

#: Position Command

posCom = (com) ->
	p.success('Getting open positions')
	data = await api.optionsPositions(
		marketData: true
		orderData: true
	)
	printPos(data)
	p.success('Getting unfilled orders')
	data = await api.optionsPositions(
		marketData: true
		orderData: true
		openOnly: false
		notFilled: true
	)
	printPos(data, true)

#: Find Command

findCom = (com) ->
	args =
		symbol: com.ticker
		expiry: com.expiry
		optionType: com.option_type || 'call'
		strikeType: com.strike_type || 'itm'
		strikeDepth: com.depth || 0
		range: com.range
		price: com.price

	if !args.range? && !args.price?
		p.success("Finding option #{args.symbol}-#{args.expiry.replace(/-/g, '/')}-#{args.optionType}-#{args.strikeType}-#{args.strikeDepth}")
	else if args.price?
		p.success("Finding option #{args.symbol}-#{args.expiry.replace(/-/g, '/')}-#{args.optionType}-#{args.price}")
	else if args.range?
		p.success("Finding option #{args.symbol}-#{args.expiry.replace(/-/g, '/')}-#{args.optionType}-(+-#{args.range})")

	data = await api.findOptions(
		args.symbol
		args.expiry
		optionType: args.optionType
		strikeType: args.strikeType
		strikeDepth: args.strikeDepth
		range: args.range
		strike: args.price
		marketData: true
	)
	printFind(data)

#: Buy Command

buyCom = (com) ->
	option = await api.getUrl(com.url)
	p.success("Attempting to buy #{option.chain_symbol}-#{option.expiration_date}-#{option.type}-#{option.strike_price}")
	buy = await api.placeOptionOrder(com.url, com.quantity, com.price)
	quote = await api.quotes(option.chain_symbol)
	if buy.id?
		p.success('Order placed successfully')
		printOrder(option, quote, buy)
		return buy
	else
		p.error('Could not place order!')
		return false

#: Sell Command

sellCom = (com) ->
	option = await api.getUrl(com.url)
	p.success("Attempting to sell #{option.chain_symbol}-#{option.expiration_date}-#{option.type}-#{option.strike_price}")
	sell = await api.placeOptionOrder(
		com.url,
		com.quantity,
		com.price
		direction: 'credit'
		side: 'sell'
		positionEffect: 'close'
	)
	quote = await api.quotes(option.chain_symbol)
	if sell.id?
		p.success('Order placed successfully')
		printOrder(option, quote, sell)
		return sell
	else
		p.error('Could not place order!')
		return false

#: Cancel Command

cancelCom = (com) ->
	p.success("Attempting to cancel option order")
	data = await api.cancelOptionOrder(com.url)
	if data
		p.success('Order cancelled successfully')
		return true

#: Replace Command

replaceCom = (com) ->
	order = await api.optionsOrders({ id: com.id })
	option = await api.getUrl(order.legs[0].option)
	p.success("Attempting to replace order #{option.chain_symbol}-#{option.expiration_date}-#{option.type}-#{option.strike_price}")
	buy = await api.replaceOptionOrder(com.quantity, com.price, { order: order })
	quote = await api.quotes(option.chain_symbol)
	if buy.id?
		p.success('Order replaced successfully')
		printOrder(option, quote, buy)
		return buy
	else
		p.error('Could not replace order!')
		return false

#::: Print Methods :::

#: Print Quotes

printQuotes = (data) ->
	if !Array.isArray(data)
		data = [data]
	for rec in data
		obj =
			symbol: rec.symbol
			askSize: rec.ask_size
			bidSize: rec.bid_size
			price: rec.last_trade_price
			extendedPrice: rec.last_extended_hours_trade_price
		objOrder = ['symbol', 'price', 'extendedPrice', 'askSize', 'bidSize']
		colorPrint(
			obj,
			objOrder,
		)

#: Print Position

printPos = (data, notFilled=false) ->
	for rec in data
		obj =
			symbol: rec.chain_symbol
			buyPrice: rec.average_price
			strikePrice: rec.option_data.strike_price
			expiry: rec.option_data.expiration_date
			quantity: rec.quantity
			type: rec.order_data.opening_strategy
			bidPrice: rec.market_data.bid_price
			bidSize: rec.market_data.bid_size
			askPrice: rec.market_data.ask_price
			askSize: rec.market_data.ask_size
			optionPrice: rec.market_data.adjusted_mark_price
			volume: rec.market_data.volume
			openInterest: rec.market_data.open_interest
			impliedVolatility: rec.market_data.implied_volatility
			delta: rec.market_data.delta
			theta: rec.market_data.theta
			orderId: rec.order_data.id
			optionUrl: rec.option
		objOrder = ['symbol', 'buyPrice', 'strikePrice', 'expiry', 'quantity',
			'type', 'delta', 'theta', 'bidPrice', 'bidSize', 'askPrice', 'askSize',
			'optionPrice', 'volume', 'openInterest', 'impliedVolatility', 'orderId',
			'optionUrl']
		if notFilled
			obj.cancelUrl = rec.order_data.cancel_url
			objOrder.push('cancelUrl')
		colorPrint(
			obj,
			objOrder,
		)

#: Print Find Options

printFind = (data) ->
	if !Array.isArray(data)
		data = [data]
	for rec in data
		obj =
			symbol: rec.chain_symbol
			strikePrice: rec.strike_price
			expiry: rec.expiration_date
			bidPrice: rec.market_data.bid_price
			bidSize: rec.market_data.bid_size
			askPrice: rec.market_data.ask_price
			askSize: rec.market_data.ask_size
			optionPrice: rec.market_data.adjusted_mark_price
			volume: rec.market_data.volume
			openInterest: rec.market_data.open_interest
			impliedVolatility: rec.market_data.implied_volatility
			delta: rec.market_data.delta
			theta: rec.market_data.theta
			url: rec.url
		objOrder = ['symbol', 'strikePrice', 'expiry', 'delta', 'theta',
			'bidPrice', 'bidSize', 'askPrice', 'askSize', 'optionPrice',
			'volume', 'openInterest', 'impliedVolatility', 'url']
		colorPrint(
			obj,
			objOrder,
		)

#: Print Order

printOrder = (option, quote, buy) ->
	obj =
		symbol: buy.chain_symbol
		strategy: buy.opening_strategy
		strikePrice: option.strike_price
		expiry: option.expiration_date
		price: buy.price
		quote: quote.last_trade_price
		quantity: buy.quantity
		cancelUrl: buy.cancel_url
		orderId: buy.id
	objOrder = ['symbol', 'strategy', 'expiry', 'strikePrice',
		'price', 'quote', 'quantity', 'cancelUrl', 'orderId']
	colorPrint(
		obj,
		objOrder,
	)

#::: Helpers :::

#: Check if number

isNumber = (text) ->
	if text.length == 0 or !isNaN(text)
		return true
	else
		return 'Please enter a valid number.'

#: Check if not empty

notEmpty = (text) ->
	if text.length > 0
		return true
	else
		return 'Please enter a valid string.'

#: Parse Int

parseInt = (val) ->
	return roundNum(val, 0)

#: Parse Price

parsePrice = (val) ->
	return roundNum(val)

#: Print in Place

printInPlace = (text) ->
	term.saveCursor()
	process.stdout.write("#{text}\r")
	term.restoreCursor()

#: Terminate Position

terminatePosition = (cur_pos, sell_args) ->
	if cur_pos.status == 'open'
		order = await sellCom(sell_args)
		cur_pos.status = 'selling'
		cur_pos.sell_id = order.id
	else if cur_pos.status == 'selling'
		order = await replaceCom(sell_args)
		cur_pos.sell_id = order.id

#: Get Day Trades

dayTrades = () ->
	orders = await api.optionsOrders()
	cutoff_date = 0
	day_trades = {}
	days = []
	for i in [0...14]
		if days.length < 5
			date = moment().subtract(i, 'days').format('YYYY-MM-DD')
			date_status = await api.getMarketHours(date)
			if date_status.is_open? && date_status.is_open
				days.push(date_status.date)
			if days.length == 5
				cutoff_date = Number(moment().subtract(i, 'days').format('YYYYMMDD'))
		else
			break
	for i in [0...orders.length]
		if orders[i].legs[0].executions.length > 0 && Number(moment(orders[i].legs[0].executions[0].timestamp).format('YYYYMMDD')) < cutoff_date
			break
		if orders[i].state == 'filled' && orders[i].legs[0].executions.length > 0 && orders[i].legs[0].side == 'sell' && orders[i].legs[0].position_effect == 'close'
			sell_date = moment(orders[i].legs[0].executions[0].timestamp).format('YYYY-MM-DD')

			if days.includes(sell_date)
				for x in [(i + 1)...orders.length]
					if (orders[x].state == 'filled' && orders[i].legs[0].option == orders[x].legs[0].option && orders[x].legs[0].executions.length > 0 &&
						orders[x].legs[0].side == 'buy' && orders[x].legs[0].position_effect == 'open')
							buy_date = moment(orders[x].legs[0].executions[0].timestamp).format('YYYY-MM-DD')
							if buy_date == sell_date
								day_trades[orders[i].legs[0].option] =
									date: sell_date
									symbol: orders[i].chain_symbol
							break
	return day_trades

#: Run Program

ON_DEATH((signal, err) ->
	term.eraseDisplayBelow()
	process.exit()
)

main()

#::: End Program :::