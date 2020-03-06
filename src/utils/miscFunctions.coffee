path = require 'path'
utf8 = require 'utf8'
base64 = require 'base-64'
chalk = require 'chalk'
p = require 'print-tools-js'
camelCase = require 'lodash/camelCase'
startCase = require 'lodash/startCase'

#: Base64 Decode

b64Dec = (text) ->
	return base64.decode(utf8.encode(text))

#: Base64 Encode

b64Enc = (text) ->
	return base64.encode(utf8.encode(text))

#: Round Number

roundNum = (number, places=2) ->
	return parseFloat(parseFloat(String(number)).toFixed(places))

#: Title Case

titleCase = (text) ->
	return startCase(camelCase(text))

#: Print Detail

detPrint = (text) ->
	if typeof text == 'object'
		console.log(JSON.stringify(text))
		return true
	else
		return console.log(text)
		return true

#: Sort Options

sortOptions = (a, b) ->
	aStrike = Number(a.strike_price)
	bStrike = Number(b.strike_price)
	if (aStrike > bStrike)
		return -1
	else if (bStrike > aStrike)
		return 1
	else
		return 0

#: Query String

queryStr = (obj) ->
	objLength = Object.keys(obj).length
	str = ''
	i = -1
	for key, value of obj
		i++
		if i == 0
			str += '?'
		str += "#{key}=#{value}"
		if i != (objLength - 1)
			str += '&'
	return str

#: Color Print Dictionary

colorPrint = (obj, objOrder, args={ message: null, printSpace: true, places: 3 }) ->
	colors = [
		'green'
		'yellow'
		'blue'
		'magenta'
		'cyan'
		null
		'gray'
		'red'
	]
	colMod = colors.length
	if args.message?
		p.success(args.message)
	for i in [0...objOrder.length]
		val = obj[objOrder[i]]
		if String(val).includes('.') && !isNaN(val)
			val = roundNum(val, args.places)
		if colors[i % colMod] == null
			p.bullet("#{titleCase(objOrder[i])}: #{val}", { log: false})
		else
			p.bullet(chalk"{#{colors[i % colMod]} #{titleCase(objOrder[i])}}: #{val}", { log: false})
	if args.printSpace
		console.log('')
	return true

#: Exports

module.exports =
	queryStr: queryStr
	b64Dec: b64Dec
	b64Enc: b64Enc
	titleCase: titleCase
	colorPrint: colorPrint
	detPrint: detPrint
	roundNum: roundNum
	sortOptions: sortOptions

#::: End Program:::