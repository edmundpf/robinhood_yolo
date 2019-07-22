p = require 'print-tools-js'
queryStr = require('./miscFunctions').queryStr

#: Api URL

api = 'https://api.robinhood.com'

#: Endpoints Object

endpoints =

	api: (path) ->
		return "#{api}#{path}"

	#: Login

	login: ->
		return "#{api}/oauth2/token/"

	#: Accounts

	accounts: ->
		return "#{api}/accounts/"

	#: Markets

	marketHours: (date) ->
		return "#{api}/markets/XNYS/hours/#{date}/"

	#: Transfers

	transfers: ->
		return "#{api}/ach/transfers/"

	#: Get all orders or fetch by Order ID

	orders: (id) ->
		return "#{api}/orders/#{id}/"

	#: Get Quotes for stock or list of stocks

	quotes: (symbols) ->
		if Array.isArray(symbols)
			symbols = symbols.join(',')
			return "#{api}/quotes/?symbols=#{symbols}"
		else
			return "#{api}/quotes/#{symbols}/"

	#: Get Historical Quotes for stock or list of stocks.
	### ------------------------------------------------
	# interval/span configs:
	# 	5minute | day
	# 	10minute | week
	# 	hour | month
	# 	day | year
	# 	week | 5year
	# bounds:
	# 	regular, extended
	###

	historicals: (symbols, interval='day', span='year', bounds='regular') ->
		if Array.isArray(symbols)
			symbols = symbols.join(',')
		query = queryStr(
			symbols: symbols
			interval: interval
			span: span
			bound: bounds
		)
		return "#{api}/quotes/historicals/#{query}/"

	#: Get Historical Quotes for options chains

	optionsHistoricals: (instruments, interval='day', span='year') ->
		if Array.isArray(instruments)
			instruments = instruments.join(',')
		query = queryStr(
			instruments: instruments
			interval: interval
			span: span
		)
		return "#{api}/marketdata/options/historicals/#{query}"

	#: Get Option Chains

	chain: (instrumentId) ->
		return "#{api}/options/chains/?equity_instrument_ids=#{instrumentId}"

	#: Get Options

	options: (chainId, dates, option_type='call') ->
		query = queryStr(
			chain_id: chainId
			expiration_dates: dates
			state: 'active'
			tradability: 'tradable'
			type: option_type
		)
		return "#{api}/options/instruments/#{query}"

	#: Get All Options (including expired)

	expiredOptions: (chainId, dates, option_type='call') ->
		query = queryStr(
			chain_id: chainId
			expiration_dates: dates
			type: option_type
		)
		return "#{api}/options/instruments/#{query}"

	#: Get Options Positions

	optionsPositions: ->
		return "#{api}/options/positions/"

	#: Get Options Orders

	optionsOrders: (id) ->
		if id?
			return "#{api}/options/orders/#{id}/"
		else
			return "#{api}/options/orders/"

	#: Get Market Data

	marketData: (optionId) ->
		return "#{api}/marketdata/options/#{optionId}/"

	#: Get Watchlist

	watchList: (name='Default') ->
		return "#{api}/watchlists/#{name}/"

	#: Add to Watchlist

	addToWatchList: (id, name='Default') ->
		return "#{api}/watchlists/#{name}/#{id}/"

	#: Reorder Watchlist

	reorderWatchList: (ids, name='Default') ->
		if Array.isArray(ids)
			ids = ids.join(',')
		return "#{api}/watchlists/#{name}/reorder/#{ids}/"

#: Exports

module.exports = endpoints

#::: End Program :::