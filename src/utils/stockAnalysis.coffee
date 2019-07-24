moment = require 'moment'
snakeCase = require 'lodash/snakeCase'
alpha = require('alphavantage')({ key: require('./dataStore')({ initData: true }).apiSettings.alphaVantage })
defaults = require('../data/dataDefaults.json')
bolBandsInd = require('technicalindicators').BollingerBands
rsiInd = require('technicalindicators').RSI
vwapInd = require('technicalindicators').VWAP
macdInd = require('technicalindicators').MACD

class Analyze

	#: Constructor

	constructor: (args) ->
		args = {
			...args
		}

	#: Get Intraday Data

	getIntraday: (symbol, args) ->
		args = {
			interval: 1
			output_size: 'full'
			...args
		}
		data = await alpha.data.intraday(symbol, args.output_size, 'json', "#{String(args.interval)}min")
		data = normalizeTimeData(data, args)
		return data

	#: Get Daily Data

	getDaily: (symbol, args) ->
		args = {
			output_size: 'full'
			...args
		}
		data = await alpha.data.daily(symbol, args.output_size, 'json')
		data = normalizeTimeData(data)
		return data

	#: Get Weekly Data

	getWeekly: (symbol) ->
		data = await alpha.data.weekly(symbol, 'full', 'json')
		data = normalizeTimeData(data, args)
		return data

	#: Get Monthly Data

	getMonthly: (symbol) ->
		data = await alpha.data.monthly(symbol, 'full', 'json')
		data = normalizeTimeData(data, args)
		return data

#: Normalize Time Series Data

normalizeTimeData = (data, args) ->
	try
		args = {
			interval: null
			...args
		}
		newData = {
			meta_data: {}
			time_data: {}
		}
		techData = {
			open: []
			close: []
			high: []
			low: []
			volume: []
		}

		# Meta Data formatting

		parKeys = Object.keys(data)
		interval = snakeCase(parKeys[1].replace('Time Series', '').replace(/[() ]/g, ''))
		for key, val of data['Meta Data']
			newData.meta_data[snakeCase(key.match(/(?<=\d. ).+/)[0])] = val
		if !newData.meta_data.interval?
			newData.meta_data.interval = interval
		if !newData.meta_data.output_size?
			newData.meta_data.output_size = 'full_size'
		else
			newData.meta_data.output_size = snakeCase(newData.meta_data.output_size)
		refreshTime = moment(newData.meta_data.last_refreshed)
		newData.meta_data.refresh_date = refreshTime.format('YYYY-MM-DD')
		newData.meta_data.refresh_time = refreshTime.format('HH:mm:ss')
		delete newData.meta_data.last_refreshed

		# Time Series formatting

		for parKey, parVal of data[parKeys[1]]
			temp = {}
			curTime = moment(parKey)
			temp.date = curTime.format('YYYY-MM-DD')
			if args.interval?
				curTime.subtract(args.interval, 'minutes')
			temp.time = curTime.format('HH:mm:ss')
			if time == '00:00:00'
				time = '09:30:00'
			for chiKey, chiVal of parVal
				temp[snakeCase(chiKey.match(/(?<=\d. ).+/)[0])] = Number(chiVal)
			newData.time_data[curTime.format('YYYY-MM-DD HH:mm:ss')] = temp
			techData.open.push(temp.open)
			techData.close.push(temp.close)
			techData.high.push(temp.high)
			techData.low.push(temp.low)
			techData.volume.push(temp.volume)

		# Technical Analysis

		if defaults.indicators.bollingerBands.include
			techData.bolBands = bolBandsInd.calculate({
				...defaults.indicators.bollingerBands.args
				values: techData.open
			})
		if defaults.indicators.rsi.include
			techData.rsi = rsiInd.calculate({
				...defaults.indicators.rsi.args
				values: techData.open
			})
		if defaults.indicators.vwap.include
			techData.vwap = vwapInd.calculate(
				open: techData.open
				close: techData.close
				low: techData.low
				high: techData.high
				volume: techData.volume
			)
		if defaults.indicators.macd.include
			techData.macd = macdInd.calculate({
				...defaults.indicators.macd.args
				values: techData.open
			})

		# Merge Indicators

		ind = 0
		for key, val of newData.time_data
			if techData.bolBands?
				if techData.bolBands[ind]?
					newData.time_data[key] = {
						...newData.time_data[key]
						lower_bol_band: techData.bolBands[ind].lower
						middle_bol_band: techData.bolBands[ind].middle
						upper_bol_band: techData.bolBands[ind].upper
					}
				else
					newData.time_data[key] = {
						...newData.time_data[key]
						lower_bol_band: null
						middle_bol_band: null
						upper_bol_band: null
					}
			if techData.rsi?
				if techData.rsi[ind]?
					newData.time_data[key].rsi = techData.rsi[ind]
				else
					newData.time_data[key].rsi = null
			if techData.vwap?
				if techData.vwap[ind]?
					newData.time_data[key].vwap = techData.vwap[ind]
			if techData.macd?
				if techData.macd[ind]?
					newData.time_data[key] = {
						...newData.time_data[key]
						macd_val: techData.macd[ind].MACD
						macd_histogram: techData.macd[ind].histogram
						macd_signal: techData.macd[ind].signal
					}
				else
					newData.time_data[key] = {
						...newData.time_data[key]
						macd_val: null
						macd_histogram: null
						macd_signal: null
					}
			ind++

		return newData

	catch error
		throw error

#: Exports

module.exports = Analyze

#::: End Program :::