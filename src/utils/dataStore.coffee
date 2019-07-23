fs = require 'fs'
os = require 'os'
path = require 'path'
jsonFile = require 'jsonfile'
editJson = require 'edit-json-file'
dataDefaults = require('../data/dataDefaults.json')

#: Get Data Path

getDataPath = (filename) ->
	return path.resolve("#{os.homedir()}/node_json_db/#{filename}.json")

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
	configData = require(getDataPath('yolo_config'))
catch error
	configData = dataDefaults.configData
	homeDir = "#{os.homedir()}/node_json_db"
	if !fs.existsSync(homeDir)
		fs.mkdirSync(homeDir)
	overwriteJson(
		'yolo_config',
		configData
	)
try
	defaults = require(getDataPath('yolo_defaults'))
catch error
	defaults = dataDefaults.defaults
	homeDir = "#{os.homedir()}/node_json_db"
	if !fs.existsSync(homeDir)
		fs.mkdirSync(homeDir)
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