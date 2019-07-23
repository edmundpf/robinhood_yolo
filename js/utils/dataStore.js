var Database, dataDefaults, editJson, fs, jsonFile, newDataObj, os, path;

fs = require('fs');

os = require('os');

path = require('path');

jsonFile = require('jsonfile');

editJson = require('edit-json-file');

dataDefaults = require('../data/dataDefaults.json');

Database = class Database {
  //: Constructor
  constructor(args = {
      initData: false
    }) {
    args = {
      initData: false,
      ...args
    };
    if (!args.initData) {
      this.configData = dataDefaults.configData;
      this.defaults = dataDefaults.defaults;
    } else {
      this.getDataFiles();
    }
  }

  //: Get Data Files
  getDataFiles() {
    var error;
    try {
      this.configData = require(this.getDataPath('yolo_config'));
    } catch (error1) {
      error = error1;
      this.initDatabase();
      overwriteJson('yolo_config', this.configData);
    }
    try {
      return this.defaults = require(this.getDataPath('yolo_defaults'));
    } catch (error1) {
      error = error1;
      this.initDatabase();
      return overwriteJson('yolo_defaults', this.defaults);
    }
  }

  //: Create Database Directory
  initDatabase() {
    var homeDir;
    homeDir = `${os.homedir()}/node_json_db`;
    if (!fs.existsSync(homeDir)) {
      return fs.mkdirSync(homeDir);
    }
  }

  //: Get Data Path
  getDataPath(filename) {
    return path.resolve(`${os.homedir()}/node_json_db/${filename}.json`);
  }

  //: Update JSON File
  updateJson(filename, obj) {
    var error, file, key, value;
    try {
      file = editJson(this.getDataPath(filename), {
        autosave: true
      });
      for (key in obj) {
        value = obj[key];
        file.set(key, value);
      }
      return true;
    } catch (error1) {
      error = error1;
      throw error;
    }
  }

  //: Overwrite JSON File
  overwriteJson(filename, obj) {
    var error, file;
    try {
      file = this.getDataPath(filename);
      return jsonFile.writeFileSync(file, obj, {
        spaces: 2
      });
    } catch (error1) {
      error = error1;
      throw error;
    }
  }

};

//: New Database Object
newDataObj = function(args = {
    initData: false
  }) {
  args = {
    initData: false,
    ...args
  };
  return new Database({
    initData: args.initData
  });
};

//: Exports
module.exports = newDataObj;

//::: End Program :::
