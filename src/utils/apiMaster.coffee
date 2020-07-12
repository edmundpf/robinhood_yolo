p = require 'print-tools-js'
assert = require 'assert'
uuid = require('uuidv4').uuid
endpoints = require './endpoints'
axios = require 'axios'
b64Dec = require('./miscFunctions').b64Dec
detPrint = require('./miscFunctions').detPrint
roundNum = require('./miscFunctions').roundNum
sortOptions = require('./miscFunctions').sortOptions
dataStore = require('./dataStore')()

#: API Object

class Api

	#: Constructor

	constructor: (args={ newLogin: false, configIndex: 0, configData: null, print: false }) ->
		args = {
			newLogin: false
			configIndex: 0
			configData: null
			print: false
			...args
		}
		this.headers =
			Accept: '*/*'
			Connection: 'keep-alive'
			'Accept-Encoding': 'gzip, deflate'
			'Accept-Language': 'en;q=1, fr;q=0.9, de;q=0.8, ja;q=0.7, nl;q=0.6, it;q=0.5'
			'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8'
			'X-Robinhood-API-Version': '1.0.0'
			'User-Agent': 'Robinhood/823 (iPhone; iOS 7.1.2; Scale/2.00)'
		this.clientId = 'c82SH0WZOsabOXGP2sxqcj34FxkvfnWRZBKlBjFS'
		this.session = axios.create(
			timeout: 10000
			headers: this.headers
		)
		this.configIndex = args.configIndex
		this.newLogin = args.newLogin
		this.print = args.print
		if args.configData?
			this.configData = args.configData
			this.externalConfig = true
		else
			dataStore.getDataFiles()
			this.configData = dataStore.configData[this.configIndex]
			this.externalConfig = false

	#: Login Flow

	login: (args={ newLogin: false, configIndex: 0 }) ->
		args = {
			newLogin: false
			configIndex: 0
			...args
		}
		try
			if args.newLogin?
				this.newLogin = args.newLogin
			await this.auth(
				newLogin: args.newLogin
				configIndex: args.configIndex
			)
			if this.print
				p.success("#{this.username} logged in.")
			return true
		catch error
			if this.print
				p.error("#{this.username} could not login.")
				detPrint(error)
			throw error

	#: Authentification

	auth: (args={ newLogin: false, configIndex: 0 }) ->
		try
			args = {
				newLogin: false
				configIndex: 0
				...args
			}

			this.configIndex = args.configIndex
			if !this.configData?
				this.configData = dataStore.configData[this.configIndex]
				this.externalConfig = false
			this.username = b64Dec(this.configData.u_n)

			if (Date.now() > this.configData.t_s + 86400000) || args.newLogin
				res = await this.postUrl(
					endpoints.login(),
					grant_type: 'password'
					client_id: this.clientId
					device_token: b64Dec(this.configData.d_t)
					username: this.username
					password: b64Dec(this.configData.p_w)
				)
				this.accessToken = res.access_token
				this.refreshToken = res.refresh_token
				this.authToken = "Bearer #{this.accessToken}"
				this.session.defaults.headers.common['Authorization'] = this.authToken
				if this.configData.a_u? || this.configData.a_u == '' || args.newLogin
					accUrl = await this.getAccount()
					this.accountUrl = accUrl.url
					this.accountId = accUrl.account_number
				else
					this.accountUrl = this.configData.a_u
					this.accountId = this.configData.a_i
				Object.assign(
					this.configData,
					a_t: this.accessToken
					r_t: this.refreshToken
					a_b: this.authToken
					a_u: this.accountUrl
					a_i: this.accountId
					t_s: Date.now()
				)
				dataStore.configData[this.configIndex] = this.configData
				if !this.externalConfig
					dataStore.updateJson(
						'yolo_config',
						dataStore.configData
					)

			else
				this.accessToken = this.configData.a_t
				this.refreshToken = this.configData.r_t
				this.authToken = this.configData.a_b
				this.accountUrl = this.configData.a_u
				this.accountId = this.configData.a_i
				this.session.defaults.headers.common['Authorization'] = this.authToken
			if !this.externalConfig
				return true
			else
				return this.configData
		catch error
			throw error

	#: Get Account Info

	getAccount: (args={consume: true}) ->
		try
			args = {
				consume: true
				...args
			}
			data = await this.getUrl(endpoints.accounts(), args.consume)
			return data[0]
		catch error
			throw error

	#: Get Portfolio Info

	getPortfolioInfo: () ->
		try
			if !this.accountId?
				accountInfo = await this.getAccount()
				this.accountId = accountInfo.account_number
			return await this.getUrl(endpoints.portfolios(this.accountId))
		catch error
			throw error

	#: Get Account Equity

	getAccountEquity: () ->
		try
			portfolioInfo = await this.getPortfolioInfo()
			curTime = new Date()
			dateNum = (curTime.getHours() * 10000) + (curTime.getMinutes() * 100) + curTime.getSeconds()
			equity = if (dateNum >= 93000 and dateNum <= 160000) then portfolioInfo.equity else portfolioInfo.extended_hours_equity
			return Number(equity)
		catch error
			throw error

	#: Get Transfers

	getTransfers: (args={consume: true}) ->
		try
			args = {
				consume: true
				...args
			}
			return await this.getUrl(endpoints.transfers(), args.consume)
		catch error
			throw error

	#: Get Market Hours

	getMarketHours: (date) ->
		try
			return await this.getUrl(endpoints.marketHours(date))
		catch error
			throw error

	#: Get Watch List

	getWatchList: (args={ watchList: 'Default', instrumentData: false, quoteData: false, consume: true }) ->
		try
			args = {
				watchList: 'Default'
				instrumentData: false
				quoteData: false
				consume: true
				...args
			}
			tickers = []
			data = await this.getUrl(endpoints.watchList(args.watchList), args.consume)
			for ticker in data
				ticker.id = ticker.instrument.match('(?<=instruments\/).[^\/]+')[0]
				if args.instrumentData
					instData = await this.getUrl(ticker.instrument)
					ticker.instrument_data = instData
				if args.quoteData
					tickers.push(ticker.instrument_data.symbol)
			if args.quoteData
				quotes = await this.quotes(tickers)
				for i in [0...data.length]
					data[i].quote_data = quotes[i]
			return data
		catch error
			throw error

	#: Get History

	getHistory: (args={ options: true, stocks: true, banking: true }) ->
		try
			args = {
				options: true
				stocks: true
				banking: true
				consume: true
				...args
			}
			defaultRecord =
				broker: 'Robinhood'
				account: this.username
				type: ''
				direction: ''
				date: ''
				ticker: ''
				strategy: ''
				amount: 0
				quantity: 0
			defaultLeg =
				price: 0
				quantity: 0
				strike: 0
				type: ''
				expiration: ''
				side: ''
			requests = []
			typeIndex = 0
			typeIndexes = {
				options: -1
				stocks: -1
				transfers: -1
			}
			if args.options
				requests.push(this.optionsOrders())
				typeIndexes.options = typeIndex
				typeIndex += 1
			if args.stocks
				requests.push(this.stockOrders())
				typeIndexes.stocks = typeIndex
				typeIndex += 1
			if args.banking
				requests.push(this.getTransfers())
				typeIndexes.transfers = typeIndex
				typeIndex += 1
			histRes = await Promise.all(requests)
			allOptions = if typeIndexes.options == -1 then [] else histRes[typeIndexes.options]
			allStocks = if typeIndexes.stocks == -1 then [] else histRes[typeIndexes.stocks]
			allTransfers = if typeIndexes.transfers == -1 then [] else histRes[typeIndexes.transfers]
			allHistory = []
			legChains = []
			instruments = []

			# Options Transactions

			for order in allOptions
				if (Number(order.processed_premium) > 0)
					newOrder = {
						...defaultRecord
						type: 'option'
						direction: order.direction
						date: order.updated_at
						ticker: order.chain_symbol
						strategy: order.opening_strategy || order.closing_strategy || ''
						amount: Number(order.processed_premium)
						quantity: Number(order.processed_quantity)
						legIndex: legChains.length
						legs: []
					}
					for leg in order.legs
						legPrice = 0
						legQuantity = 0
						for execution in leg.executions
							legPrice += Number(execution.price)
							legQuantity += Number(execution.quantity)
						legChains.push(this.getUrl(leg.option))
						newOrder.legs.push({
							...defaultLeg
							price: legPrice
							quantity: legQuantity
							side: leg.side
						})
					allHistory.push(newOrder)
			optionIndex = 0
			legIndex = 0
			endIndex = if allHistory[optionIndex + 1]? then allHistory[optionIndex + 1].legIndex else allHistory.length
			chainRes = await Promise.all(legChains)
			for chainIndex of chainRes
				if chainIndex >= endIndex
					optionIndex += 1
					legIndex = allHistory[optionIndex].legIndex
					endIndex = if allHistory[optionIndex + 1]? then allHistory[optionIndex + 1].legIndex else allHistory.length
				if allHistory[optionIndex].legIndex?
					delete allHistory[optionIndex].legIndex
				allHistory[optionIndex].legs[chainIndex - legIndex] = {
					...allHistory[optionIndex].legs[chainIndex - legIndex]
					strike: Number(chainRes[chainIndex].strike_price)
					type: chainRes[chainIndex].type
					expiration: chainRes[chainIndex].expiration_date
				}

			# Stock Transactions

			stockStartIndex = allHistory.length
			for stock in allStocks
				if (stock.executed_notional? and Number(stock.executed_notional.amount) > 0)
					allHistory.push({
						...defaultRecord
						type: 'stock'
						direction: if stock.side == 'sell' then 'credit' else 'debit'
						date: stock.updated_at
						amount: Number(stock.executed_notional.amount) - Number(stock.fees)
						quantity: Number(stock.cumulative_quantity)
						legs: []
					})
					instruments.push(this.getUrl(stock.instrument))
			instRes = await Promise.all(instruments)
			for instIndex of instRes
				allHistory[stockStartIndex + Number(instIndex)].ticker = instRes[instIndex].symbol

			# Account Transactions

			for transfer in allTransfers
				if (transfer.state == 'completed')
					allHistory.push({
						...defaultRecord
						type: 'transfer'
						direction: if transfer.direction == 'withdraw' then 'debit' else 'credit'
						date: transfer.updated_at
						amount: Number(transfer.amount)
						legs: []
					})

			allHistory.sort((a, b) => if (a.date > b.date) then -1 else 1)
			return allHistory
		catch error
			throw error

	#: Get Quotes

	quotes: (symbols, args={ chainData: false, consume: true }) ->
		try
			args = {
				chainData: false
				consume: true
				...args
			}
			if !Array.isArray(symbols)
				data = await this.getUrl(endpoints.quotes(symbols))
			else
				data = await this.getUrl(endpoints.quotes(symbols), args.consume)
			if !Array.isArray(data)
				data = [data]
			if args.chainData
				for obj in data
					obj.instrument_data = await this.getUrl(obj.instrument)
					obj.chain_data = await this.chain(obj.instrument_data.id)
			if !Array.isArray(symbols)
				return data[0]
			return data
		catch error
			throw error

	#: Get Historicals

	historicals: (symbols, args={ span: 'month', bounds: 'regular' }) ->
		try
			args = {
				span: 'month'
				bounds: 'regular'
				...args
			}
			data = await this.getUrl(endpoints.historicals(symbols, args.span, args.bounds))
			if !Array.isArray(symbols)
				return data.results[0].historicals
			else
				symbolData = []
				for arr in data.results
					symbolData.push(arr.historicals)
				return symbolData
		catch error
			throw error

	#: Get Instrument Data

	chain: (instrumentId, args={consume: true}) ->
		try
			args = {
				consume: true
				...args
			}
			return await this.getUrl(endpoints.chain(instrumentId), args.consume)
		catch error
			throw error

	#: Get Market Data

	marketData: (optionId) ->
		try
			return await this.getUrl(endpoints.marketData(optionId))
		catch error
			throw error

	#: Get Options

	getOptions: (symbol, expirationDate, args={ optionType: 'call', marketData: false, expired: false, consume: true }) ->
		try
			args = {
				optionType: 'call'
				marketData: false
				expired: false
				consume: true
				...args
			}
			chainId
			chainData = await this.quotes(symbol, { chainData: true })
			chainData = chainData.chain_data
			for ticker in chainData
				if ticker.symbol == symbol
					chainId = ticker.id
			if !args.expired
				data = await this.getUrl(endpoints.options(chainId, expirationDate, args.optionType), args.consume)
			else
				data = await this.getUrl(endpoints.expiredOptions(chainId, expirationDate, args.optionType), args.consume)
			if args.marketData
				for obj in data
					obj.market_data = await this.marketData(obj.id)
			return data
		catch error
			throw error

	#: Find Options

	findOptions: (symbol, expirationDate, args={ optionType: 'call', strikeType: 'itm', strikeDepth: 0, marketData: false, range: null, strike: null, expired: false }) ->
		try
			args = {
				optionType: 'call'
				strikeType: 'itm'
				strikeDepth: 0
				marketData: false
				range: null
				strike: null
				expired: false
				...args
			}
			curTime = new Date()
			dateNum = (curTime.getHours() * 10000) + (curTime.getMinutes() * 100) + curTime.getSeconds()
			options = await this.getOptions(symbol, expirationDate, { optionType: args.optionType, expired: args.expired })
			options.sort(sortOptions)
			if args.strike?
				args.strike = roundNum(args.strike)
			quote = await this.quotes(symbol)
			if dateNum > 93000
				quote = roundNum(quote.last_trade_price)
			else
				quote = roundNum(quote.last_extended_hours_trade_price)
			itmIndex
			for i in [0...options.length]
				strikePrice = roundNum(options[i].strike_price)
				if strikePrice == quote || strikePrice == args.strike
					itmIndex = i
					break
				else if args.optionType == 'call' && strikePrice < quote
					itmIndex = i
					break
				else if args.optionType == 'put' && strikePrice < quote
					itmIndex = i - 1
					break
			if !args.range? && !args.strike?
				if args.optionType == 'call' && args.strikeType == 'itm'
					options = [options[itmIndex + args.strikeDepth]]
				else if args.optionType == 'call' && args.strikeType == 'otm'
					options = [options[itmIndex - 1 - args.strikeDepth]]
				else if args.optionType == 'put' && args.strikeType == 'itm'
					options = [options[itmIndex - args.strikeDepth]]
				else if args.optionType == 'put' && args.strikeType == 'otm'
					options = [options[itmIndex + 1 + args.strikeDepth]]
			else if args.range?
				options = options.slice(itmIndex - args.range, itmIndex + args.range)
			else if args.strike?
				options = [options[itmIndex]]
			if args.marketData
				for obj in options
					obj.market_data = await this.marketData(obj.id)
			if !args.range?
				return options[0]
			else
				return options
		catch error
			throw error

	#: Get Options Historicals

	findOptionHistoricals: (symbol, expirationDate, args={ optionType: 'call', strikeType: 'itm', strikeDepth: 0, strike: null, expired: true, span: 'month', consume: true }) ->
		try
			args = {
				optionType: 'call'
				strikeType: 'itm'
				strikeDepth: 0
				strike: null
				expired: true
				interval: 'hour'
				span: 'month'
				consume: true
				...args
			}
			option = await this.findOptions(symbol, expirationDate, args)
			data = await this.getUrl(endpoints.optionsHistoricals(option.url, args.span), args.consume)
			return data[0].data_points
		catch error
			throw error

	#: Get Options Postions

	optionsPositions: (args={ marketData: false, orderData: false, openOnly: true, notFilled: false, consume: true }) ->
		try
			args = {
				markedData: false
				orderData: false
				openOnly: true
				notFilled: false
				consume: true
				...args
			}
			data = await this.getUrl(endpoints.optionsPositions(), args.consume)
			if args.openOnly
				openData = []
				for pos in data
					if Number(pos.quantity) > 0
						openData.push(pos)
				data = openData
			if args.orderData
				orders = []
				for obj in data
					orders.push(obj.option)
				if !args.notFilled
					orderData = await this.optionsOrders({ urls: orders, buyOnly: true })
					for obj in data
						for key, value of orderData
							if obj.option == key
								obj.order_data = value
								delete orderData[key]
								break
				else if args.notFilled
					notFilled = []
					orderData = await this.optionsOrders({ notFilled: true })
					breakLoop = false
					for obj in orderData
						for arg in data
							for leg in obj.legs
								breakLoop = false
								if leg.option == arg.option
									breakLoop = true
									arg.order_data = obj
									notFilled.push(arg)
									break
							if breakLoop
								break
					data = notFilled
			if args.marketData
				options = []
				for obj in data
					obj.option_data = await this.getUrl(obj.option)
					obj.market_data = await this.marketData(obj.option_data.id)
			return data
		catch error
			throw error

	#: Get Options Orders

	optionsOrders: (args={ urls: null, id: null, notFilled: false, buyOnly: false, consume: true }) ->
		try
			data = null
			args = {
				urls: null
				id: null
				notFilled: false
				buyOnly: false
				consume: true
				...args
			}
			if args.id?
				return await this.getUrl(endpoints.optionsOrders(args.id))
			if args.urls?
				fetchOrders = (data, options) ->
					results = {}
					breakLoop = false
					if !Array.isArray(options.args)
						options.args = [options.args]
					for arg in options.args
						for obj in data
							for leg in obj.legs
								breakLoop = false
								if leg.option == arg
									if options.mod && obj.direction == 'debit' && leg.side == 'buy'
										breakLoop = true
										results[arg] = obj
										break
									else if !options.mod
										breakLoop = true
										results[arg] = obj
										break
							if breakLoop
								break
					return results

				data = await this.getDataFromUrl(
					endpoints.optionsOrders(),
					fetchOrders,
					args: args.urls
					mod: args.buyOnly
				)
			else
				data = await this.getUrl(
					endpoints.optionsOrders(),
					args.consume
				)
			if args.notFilled
				notFilled = []
				if !Array.isArray(data)
					data = [data]
				for order in data
					if order.cancel_url?
						notFilled.push(order)
				data = notFilled
			return data
		catch error
			throw error

	#: Stock Orders

	stockOrders: (args={ consume: true }) ->
		try
			args = {
				consume: true
				...args
			}
			data = await this.getUrl(
				endpoints.stockOrders(),
				args.consume
			)
			return data
		catch error
			throw error

	#: Place Option Order

	placeOptionOrder: (option, quantity, price, args={ direction: 'debit', side: 'buy', positionEffect: 'open', legs: null }) ->
		try
			legs = null
			args = {
				direction: 'debit'
				side: 'buy'
				positionEffect: 'open'
				legs: null
				...args
			}

			assert(typeof option == 'string')
			assert(!isNaN(quantity))
			assert(!isNaN(price))
			assert(['debit', 'credit'].includes(args.direction))
			assert(['buy', 'sell'].includes(args.side))
			assert(['open', 'close'].includes(args.positionEffect))
			if !args.legs?
				legs = [
					option: option
					side: args.side
					position_effect: args.positionEffect
					ratio_quantity: 1
				]
			else
				legs = args.legs

			if option == 'null' && args.direction == 'credit' && legs[0].side == 'sell'
				if this.print
					p.warning('Will sleep before placing sell order...')
				await sleep(1000)
			return await this.placeOrderFlow(quantity, price, args, legs)

		catch error
			throw error

	#: Cancel Option Order

	cancelOptionOrder: (cancelUrl) ->
		try
			assert(typeof cancelUrl == 'string')
			data = await this.postUrl(cancelUrl, {})
			if data = {}
				return true
			else
				return false
		catch error
			throw error

	#: Replace Option Order

	replaceOptionOrder: (quantity, price, args={ order: null, orderId: null }) ->
		try
			data = null
			args = {
				order: null
				orderId: null
				...args
			}
			assert(args.order? || args.orderId?)
			if !args.order? && args.orderId?
				data = await this.optionsOrders({ id: args.orderId })
			else
				data = args.order
			if await this.cancelOptionOrder(data.cancel_url)
				return await this.placeOptionOrder(
					'null'
					quantity
					price
					direction: data.direction
					legs: data.legs
				)
			else
				return false
		catch error
			throw error

	#: Place Order Flow

	placeOrderFlow: (quantity, price, args, legs) ->
		return await this.postUrl(
			endpoints.optionsOrders()
			account: this.accountUrl
			direction: args.direction
			legs: legs
			price: price
			quantity: quantity
			time_in_force: 'gfd'
			trigger: 'immediate'
			type: 'limit'
			override_day_trade_checks: false
			override_dtbp_checks: false
			ref_id: uuid()
		)

	#: Get URL

	getUrl: (url, consume=false) ->
		try
			if !consume
				return (await this.session.get(url)).data
			else
				data = (await this.session.get(url)).data
				pages = data.results
				while data.next?
					data = (await this.session.get(data.next)).data
					pages.push(...data.results)
				return pages
		catch error
			if (error.response? and error.response.data?)
				return error.response.data
			else
				throw error

	#: Post URL

	postUrl: (url, data) ->
		try
			return (await this.session.post(
				url,
				data,
				{
					headers: {
						'Content-Type': 'application/json'
					}
				}
			)).data
		catch error
			if (error.response? and error.response.data?)
				return error.response.data
			else
				throw error

	#: Get Data from URL based on Condition

	getDataFromUrl: (url, conditionFunc, args) ->
		try
			results = {}
			resKeys
			hasArrayArgs = Array.isArray(args.args)
			data = (await this.session.get(url)).data
			results = conditionFunc(data.results, args)
			while data.next?
				data = (await this.session.get(data.next)).data
				res = conditionFunc(data.results, args)
				results = { ...results, ...res }
				resKeys = Object.keys(results)
				if hasArrayArgs && args.args.length == resKeys.length
					return results
				else if !hasArrayArgs && resKeys.length == 1
					return results[resKeys[0]]
			return results
		catch error
			if (error.response? and error.response.data?)
				return error.response.data
			else
				throw error

#: Sleep

sleep = (time) ->
  new Promise((resolve) ->
    setTimeout(resolve, time)
)

#: New API Object

newApiObj = (args={ newLogin: false, configIndex: 0, configData: null, print: false }) ->
	args = {
		newLogin: false
		configIndex: 0
		configData: null
		print: false
		...args
	}
	return new Api(
		newLogin: args.newLogin
		configIndex: args.configIndex
		configData: args.configData
		print: args.print
	)

#: Exports

module.exports = newApiObj

#::: End Program :::
