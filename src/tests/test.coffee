a = require('../utils/apiMaster')(newLogin: true)
p = require 'print-tools-js'
chalk = require 'chalk'
moment = require 'moment'
assert = require('chai').assert
should = require('chai').should()
dataStore = require('../utils/dataStore')({ initData: true })

#: List Preset

presetList = (func, key, arg1, arg2, arg3, arg4, arg5, arg6) ->
	data = null
	before(() ->
		this.timeout(15000)
		data = await func.bind(a)(arg1, arg2, arg3, arg4, arg5, arg6)
	)
	it 'Returns array', ->
		data.should.be.a('array')
	it 'Key exists', ->
		assert.equal(data[0][key]?, true)

#: Object Preset

presetObject = (func, key, arg1, arg2, arg3, arg4, arg5, arg6) ->
	data = null
	before(() ->
		this.timeout(15000)
		data = await func.bind(a)(arg1, arg2, arg3, arg4, arg5, arg6)
	)
	it 'Returns object', ->
		data.should.be.a('object')
	it 'Key exists', ->
		assert.equal(data[key]?, true)

if dataStore.configData.length > 0

	#: Test Constructor

	describe 'constructor()', ->
		before(() ->
			await a.login()
		)
		it 'Is object', ->
			a.should.be.a('object')
		it 'Has username', ->
			a.username.should.be.a('string')
		it 'Has access token', ->
			a.accessToken.should.be.a('string')
		it 'Has refresh token', ->
			a.refreshToken.should.be.a('string')
		it 'Has auth token', ->
			assert.equal(a.authToken.indexOf('Bearer'), 0)
		it 'Has account URL', ->
			a.accountUrl.should.be.a('string')

	#: Test Account

	describe 'getAccount()', ->
		presetObject(
			a.getAccount,
			'margin_balances'
		)

	#: Test Portfolio

	describe 'getPortfolioInfo()', ->
		presetObject(
			a.getPortfolioInfo,
			'equity'
		)

	#: Test Get Equity

	describe 'getAccountEquity()', ->
		it 'Returns number', ->
			data = await a.getAccountEquity()
			data.should.be.a('number')

	#: Test Market Hours

	describe 'getMarketHours()', ->
		presetObject(
			a.getMarketHours,
			'is_open'
			'2019-07-04'
		)

	#: Test Transfers

	describe 'getTransfers()', ->
		presetList(
			a.getTransfers,
			'scheduled'
		)

	#: Test Stock Orders

	describe 'stockOrders()', ->
		presetList(
			a.stockOrders,
			'instrument'
		)

	#: Test Get Watchlist

	describe 'getWatchList()', ->
		presetList(
			a.getWatchList,
			'quote_data',
			instrumentData: true
			quoteData: true
		)

	#: Test Quotes for single instrument

	describe 'quotes() - single', ->
		presetObject(
			a.quotes,
			'chain_data',
			'GE',
			chainData: true
		)

	#: Test Quotes for multiple instruments

	describe 'quotes() - multiple', ->
		presetList(
			a.quotes,
			'chain_data',
			['GE', 'AAPL'],
			chainData: true
		)

	#: Test Historicals

	describe 'historicals()', ->
		presetList(
			a.historicals,
			'close_price',
			'GE',
			interval: 'day'
			span: 'year'
			bounds: 'regular'
		)
		it 'Test Multiple instruments', ->
			data = await a.historicals(['GE', 'AAPL'])
			data[0].should.be.a('array')

	#: Test Options Historicals

	describe 'optionsHistoricals()', ->
		presetList(
			a.findOptionHistoricals,
			'begins_at',
			'GE',
			moment().subtract(moment().day() + 2, 'days').format('YYYY-MM-DD')
		)

	#: Test Get Options

	describe 'getOptions()', ->
		presetList(
			a.getOptions,
			'market_data',
			'GE',
			'2021-01-15',
			optionType: 'call'
			marketData: true
		)

	#: Test Find Options for single option

	describe 'findOptions() - single', ->
		presetObject(
			a.findOptions,
			'market_data',
			'GE',
			'2021-01-15',
			optionType: 'call'
			strikeType: 'itm'
			strikeDepth: 0
			marketData: true
		)

	#: Test Find Options by strike price

	describe 'findOptions() - strike', ->
		presetObject(
			a.findOptions,
			'market_data',
			'GE',
			'2021-01-15',
			optionType: 'call'
			strike: 11.00
			marketData: true
		)

	#: Test Find Options for multiple options

	describe 'findOptions() - range', ->
		presetList(
			a.findOptions,
			'strike_price',
			'GE',
			'2021-01-15',
			optionType: 'call'
			range: 3
		)

	#: Test Options Positions for all

	describe 'optionsPositions() - all', ->
		presetList(
			a.optionsPositions,
			'chain_symbol',
			marketData: false
			orderData: false
			openOnly: false
		)

	#: Test Options Positions for open only

	describe 'optionsPositions() - open only', ->
		data = null
		before(() ->
			this.timeout(15000)
			data = await a.optionsPositions(
				marketData: true
				orderData: true
			)
		)
		it 'Returns array', ->
			data.should.be.a('array')
		it 'Key exists', ->
			if data? && data.length != 0
				p.success("Has open positions, testing.")
				assert.equal(data[0]['market_data']?, true)
			else
				p.warning(chalk'No open positions, skipping {cyan optionsPositions() - open only} - {magenta Key exists}.')
				this.skip()

	#: Test Options Orders for all orders

	describe 'optionsOrders() - all', ->
		presetList(
			a.optionsOrders,
			'legs',
		)

	#: Test Options Orders for not filled

	describe 'optionsOrders() - not filled', ->
		data = null
		before(() ->
			this.timeout(15000)
			data = await a.optionsOrders(
				notFilled: true
			)
		)
		it 'Returns array', ->
			data.should.be.a('array')
		it 'Key exists', ->
			if data? && data.length > 0
				p.success("Has unfilled orders, testing.")
				assert.equal(data[0]['legs']?, true)
			else
				p.warning(chalk'No unfilled orders, skipping {cyan optionsOrders() - not filled} - {magenta Key exists}.')
				this.skip()

	#: Test Options Orders for single order

	describe 'optionsOrders() - single', ->
		presetObject(
			a.optionsOrders,
			'legs',
			id: 'af8d5deb-df2f-42a7-974e-7e16729937f7'
		)

	#: Test get history

	describe 'getHistory()', ->
		presetList(
			a.getHistory,
			'amount'
		)

	#: Test Placing Options orders, replacing, and canceling

	describe 'Placing Orders', ->
		curTime = new Date()
		buy = replace = cancel = null
		dateNum = (curTime.getHours() * 10000) + (curTime.getMinutes() * 100) + curTime.getSeconds()
		before(() ->
			this.timeout(15000)
			doTest = true
			accountData = await a.getAccount()
			if Number(accountData.buying_power) <= 0
				p.warning("Account has no buying power, skipping")
				doTest = false
			if dateNum <= 160100
				p.warning(chalk"Markets are open (#{dateNum}), skipping {cyan Placing Orders} - {magenta all}.")
				doTest = false
			if doTest
				p.success("Markets are closed (#{dateNum}), will test placing orders.")
				data = await a.findOptions(
					'TSLA',
					'2021-01-15',
					strikeDepth: 3
				)
				buy = await a.placeOptionOrder(data.url, 1, 0.01)
				replace = await a.replaceOptionOrder(1, 0.02, { orderId: buy.id })
				cancel = await a.cancelOptionOrder(replace.cancel_url)
			else
				this.skip()
		)

		it 'Buy returns object', ->
			buy.should.be.a('object')
		it 'Buy key exists', ->
			assert.equal(buy.id?, true)
		it 'Replace returns object', ->
			replace.should.be.a('object')
		it 'Replace key exists', ->
			assert.equal(replace.id?, true)
		it 'Cancel returns true', ->
			assert.equal(cancel, true)

else
	p.error('No accounts in config file. Exiting.')

#::: End Program :::