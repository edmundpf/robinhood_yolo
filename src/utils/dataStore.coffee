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
		this.configData = dataDefaults.configData
		this.defaults = dataDefaults.defaults
		if args.initData
			this.getDataFiles()

	#: Get Data Files

	getDataFiles: ->
		dataFiles =
			'yolo_config': 'configData'
			'yolo_defaults': 'defaults'
		for file, key of dataFiles
			try
				this[key] = require(this.getDataPath(file))
			catch error
				this.initDatabase()
				this.overwriteJson(
					file,
					this[key]
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