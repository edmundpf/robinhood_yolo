p = require 'print-tools-js'
uuid = require 'uuid/v4'
assert = require 'assert'
endpoints = require './endpoints'
request = require 'request-promise'
b64Dec = require('./miscFunctions').b64Dec
detPrint = require('./miscFunctions').detPrint
roundNum = require('./miscFunctions').roundNum
sortOptions = require('./miscFunctions').sortOptions
updateJson = require('./dataStore').updateJson
defaults = require('./dataStore').defaults
configData = require('./dataStore').configData

#: API Object

class Api

	#: Constructor

	constructor: (args={ newLogin: false, configIndex: 0, print: false }) ->
		args = {
			newLogin: false
			configIndex: 0
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
		this.session = request.defaults(
			jar: true
			gzip: true
			json: true
			timeout: 2000
			headers: this.headers
		)
		this.configIndex = args.configIndex
		this.newLogin = args.newLogin
		this.print = args.print

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
			this.username = b64Dec(configData[this.configIndex].u_n)
			if (Date.now() > configData[this.configIndex].t_s + 86400000) || args.newLogin
				res = await this.postUrl(
					endpoints.login(),
					grant_type: 'password'
					client_id: this.clientId
					device_token: b64Dec(configData[this.configIndex].d_t)
					username: this.username
					password: b64Dec(configData[this.configIndex].p_w)
				)
				this.accessToken = res.access_token
				this.refreshToken = res.refresh_token
				this.authToken = "Bearer #{this.accessToken}"
				this.session = this.session.defaults(
					headers: {
						...this.headers,
						Authorization: this.authToken
					}
				)
				accUrl = await this.getAccount()
				this.accountUrl = accUrl.url
				Object.assign(
					configData[this.configIndex],
					a_t: this.accessToken
					r_t: this.refreshToken
					a_b: this.authToken
					a_u: this.accountUrl
					t_s: Date.now()
				)
				updateJson(
					'yolo_config',
					configData
				)
			else
				this.accessToken = configData[this.configIndex].a_t
				this.refreshToken = configData[this.configIndex].r_t
				this.authToken = configData[this.configIndex].a_b
				this.accountUrl = configData[this.configIndex].a_u
				this.session = this.session.defaults(
					headers: {
						...this.headers,
						Authorization: this.authToken
					}
				)
			return true
		catch error
			throw error

	#: Get Account Info

	getAccount: ->
		try
			data = await this.getUrl(endpoints.accounts(), true)
			return data[0]
		catch error
			throw error

	#: Get Transfers

	getTransfers: ->
		try
			return await this.getUrl(endpoints.transfers(), true)
		catch error
			throw error

	#: Get Market Hours

	getMarketHours: (date) ->
		try
			return await this.getUrl(endpoints.marketHours(date))
		catch error
			throw error

	#: Get Watch List

	getWatchList: (args={ watchList: 'Default', instrumentData: false, quoteData: false }) ->
		try
			args = {
				watchList: 'Default'
				instrumentData: false
				quoteData: false
				...args
			}
			tickers = []
			data = await this.getUrl(endpoints.watchList(args.watchList), true)
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

	#: Get Quotes

	quotes: (symbols, args={ chainData: false }) ->
		try
			args = {
				chainData: false
				...args
			}
			if !Array.isArray(symbols)
				data = await this.getUrl(endpoints.quotes(symbols))
			else
				data = await this.getUrl(endpoints.quotes(symbols), true)
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

	historicals: (symbols, args={ interval: 'day', span: 'year', bounds: 'regular' }) ->
		try
			args = {
				interval: 'day'
				span: 'year'
				bounds: 'regular'
				...args
			}
			data = await this.getUrl(endpoints.historicals(symbols, args.interval, args.span, args.bounds))
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

	chain: (instrumentId) ->
		try
			return await this.getUrl(endpoints.chain(instrumentId), true)
		catch error
			throw error

	#: Get Market Data

	marketData: (optionId) ->
		try
			return await this.getUrl(endpoints.marketData(optionId))
		catch error
			throw error

	#: Get Options

	getOptions: (symbol, expirationDate, args={ optionType: 'call', marketData: false, expired: false }) ->
		try
			args = {
				optionType: 'call'
				marketData: false
				expired: false
				...args
			}
			chainId
			chainData = await this.quotes(symbol, { chainData: true })
			chainData = chainData.chain_data
			for ticker in chainData
				if ticker.symbol == symbol
					chainId = ticker.id
			if !args.expired
				data = await this.getUrl(endpoints.options(chainId, expirationDate, args.optionType), true)
			else
				data = await this.getUrl(endpoints.expiredOptions(chainId, expirationDate, args.optionType), true)
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

	findOptionHistoricals: (symbol, expirationDate, args={ optionType: 'call', strikeType: 'itm', strikeDepth: 0, strike: null, expired: true, interval: 'hour', span: 'month' }) ->
		try
			args = {
				optionType: 'call'
				strikeType: 'itm'
				strikeDepth: 0
				strike: null
				expired: true
				interval: 'hour'
				span: 'month'
				...args
			}
			option = await this.findOptions(symbol, expirationDate, args)
			data = await this.getUrl(endpoints.optionsHistoricals(option.url, args.interval, args.span), true)
			return data[0].data_points
		catch error
			throw error

	#: Get Options Postions

	optionsPositions: (args={ marketData: false, orderData: false, openOnly: true, notFilled: false }) ->
		try
			args = {
				markedData: false
				orderData: false
				openOnly: true
				notFilled: false
				...args
			}
			data = await this.getUrl(endpoints.optionsPositions(), true)
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

	optionsOrders: (args={ urls: null, id: null, notFilled: false, buyOnly: false }) ->
		try
			data
			args = {
				urls: null
				id: null
				notFilled: false
				buyOnly: false
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
					true
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

	#: Place Option Order

	placeOptionOrder: (option, quantity, price, args={ direction: 'debit', side: 'buy', positionEffect: 'open', legs: null }) ->
		try
			legs
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

			try
				if option == 'null' && args.direction == 'credit' && legs[0].side == 'sell'
					p.warning('Will sleep before placing sell order...')
					await sleep(1000)
				return await this.placeOrderFlow(quantity, price, args, legs)
			catch error
				if error.statusCode == 400 && error.error? && error.error.detail? && error.error.detail.includes('order is invalid')
					p.error('Could not place sell order, will sleep and try again...')
					await sleep(1000)
					return await this.placeOrderFlow(quantity, price, args, legs)
				else
					throw error

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
			data
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
				return await this.session.get(
					uri: url
				)
			else
				data = await this.session.get(
					uri: url
				)
				pages = data.results
				while data.next?
					data = await this.session.get(
						uri: data.next
					)
					pages.push(...data.results)
				return pages
		catch error
			if error.cause? && error.cause.code == 'ETIMEDOUT'
				return this.getUrl(url, consume)
			else
				throw error

	#: Post URL

	postUrl: (url, data) ->
		try
			return await this.session.post(
				uri: url
				body: data
				headers: {
					...this.headers,
					'Content-Type': 'application/json'
				}
			)
		catch error
			throw error

	#: Get Data from URL based on Condition

	getDataFromUrl: (url, conditionFunc, args) ->
		try
			results = {}
			resKeys
			hasArrayArgs = Array.isArray(args.args)
			data = await this.session.get(
					uri: url
				)
			results = conditionFunc(data.results, args)
			while data.next?
				data = await this.session.get(
					uri: data.next
				)
				res = conditionFunc(data.results, args)
				results = { ...results, ...res }
				resKeys = Object.keys(results)
				if hasArrayArgs && args.args.length == resKeys.length
					return results
				else if !hasArrayArgs && resKeys.length == 1
					return results[resKeys[0]]
			return results
		catch error
			throw error

#: Sleep

sleep = (time) ->
  new Promise((resolve) ->
    setTimeout(resolve, time)
)

#: New API Object

newApiObj = (args={ newLogin: false, configIndex: 0, print: false }) ->
	args = {
		newLogin: false
		configIndex: 0
		print: false
		...args
	}
	return new Api(
		newLogin: args.newLogin
		configIndex: args.configIndex
		print: args.print
	)

#: Exports

module.exports = newApiObj

#::: End Program :::