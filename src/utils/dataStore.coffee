fs = require 'fs'
path = require 'path'
jsonFile = require 'jsonfile'
editJson = require 'edit-json-file'
dataDefaults = require('../data/dataDefaults.json')

#: Get Data Path

getDataPath = (filename) ->
	return "/node_json_db/#{filename}.json"

#: Update JSON File

updateJson = (filename, obj) ->
	try
		file = editJson(getDataPath(filename), { autosave: true })
		for key, value of obj
			file.set(key, value)
		return true
	catch error
		throw error

#: Overwrite JSON File

overwriteJson = (filename, obj) ->
	try
		file = getDataPath(filename)
		jsonFile.writeFileSync(file, obj, { spaces: 2 })
	catch error
		throw error

#: Init Data Files

configData = defaults = null
try
	configData = require '/node_json_db/yolo_config.json'
catch error
	configData = dataDefaults.configData
	if !fs.existsSync('/node_json_db')
		fs.mkdirSync('/node_json_db')
	overwriteJson(
		'yolo_config',
		configData
	)
try
	defaults = require '/node_json_db/yolo_defaults.json'
catch error
	defaults = dataDefaults.defaults
	if !fs.existsSync('/node_json_db')
		fs.mkdirSync('/node_json_db')
	overwriteJson(
		'yolo_defaults',
		defaults
	)

#: Exports

module.exports =
	configData: configData
	defaults: defaults
	updateJson: updateJson
	overwriteJson: overwriteJson

#::: End Program :::