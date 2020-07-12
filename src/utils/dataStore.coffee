os = require 'os'
path = require 'path'
fs = require 'fs-extra'
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
		this.dataFiles =
			'yolo_config': 'configData'
			'yolo_defaults': 'defaults'
		if args.initData
			this.getDataFiles()

	#: Get Data Files

	getDataFiles: ->
		for file, key of this.dataFiles
			try
				this[key] = require(this.getDataPath(file))
			catch error
				this.initDatabase(file)
				this.overwriteJson(
					file,
					this[key]
				)

	#: Create Database Directory

	initDatabase:(file) ->
		oldHomeDir = "#{os.homedir()}/node_json_db"
		newHomeRoot = "#{os.homedir()}/.json_config"
		newHomeDir = "#{os.homedir()}/.json_config/robinhood"
		# Make JSON Config directory
		if !fs.existsSync(newHomeRoot)
			fs.mkdirSync(newHomeRoot)
		# Make Robinhood directory
		if !fs.existsSync(newHomeDir)
			fs.mkdirSync(newHomeDir)
		# Move config files from old to new directory
		if fs.existsSync(oldHomeDir)
			oldPath = this.getOldDataPath(file)
			newPath = this.getDataPath(file)
			if not fs.existsSync(newPath) and fs.existsSync(oldPath)
				fs.copySync(oldPath, this.getDataPath(file))
				this[this.dataFiles[file]] = require(oldPath)

	#: Get Data Path

	getDataPath: (filename) ->
		return path.resolve("#{os.homedir()}/.json_config/robinhood/#{filename}.json")

	#: Get Old Data Path

	getOldDataPath: (filename) ->
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