fs = require 'fs'
os = require 'os'
path = require 'path'
jsonFile = require 'jsonfile'
editJson = require 'edit-json-file'
dataDefaults = require('../data/dataDefaults.json')

class Database

	#: Constructor

	constructor: (args={ initData: false }) ->
		args = {
			initData: false
			...args
		}
		if !args.initData
			this.configData = dataDefaults.configData
			this.defaults = dataDefaults.defaults
		else
			this.getDataFiles()

	#: Get Data Files

	getDataFiles: ->
		try
			this.configData = require(this.getDataPath('yolo_config'))
		catch error
			this.initDatabase()
			overwriteJson(
				'yolo_config',
				this.configData
			)
		try
			this.defaults = require(this.getDataPath('yolo_defaults'))
		catch error
			this.initDatabase()
			overwriteJson(
				'yolo_defaults',
				this.defaults
			)

	#: Create Database Directory

	initDatabase: ->
		homeDir = "#{os.homedir()}/node_json_db"
		if !fs.existsSync(homeDir)
			fs.mkdirSync(homeDir)

	#: Get Data Path

	getDataPath: (filename) ->
		return path.resolve("#{os.homedir()}/node_json_db/#{filename}.json")

	#: Update JSON File

	updateJson: (filename, obj) ->
		try
			file = editJson(this.getDataPath(filename), { autosave: true })
			for key, value of obj
				file.set(key, value)
			return true
		catch error
			throw error

	#: Overwrite JSON File

	overwriteJson: (filename, obj) ->
		try
			file = this.getDataPath(filename)
			jsonFile.writeFileSync(file, obj, { spaces: 2 })
		catch error
			throw error

#: New Database Object

newDataObj = (args={ initData: false }) ->
	args = {
		initData: false
		...args
	}
	return new Database(
		initData: args.initData
	)

#: Exports

module.exports = newDataObj

#::: End Program :::