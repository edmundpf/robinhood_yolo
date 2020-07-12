var Database, dataDefaults, editJson, fs, jsonFile, newDataObj, os, path;

os = require('os');

path = require('path');

fs = require('fs-extra');

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
    this.configData = dataDefaults.configData;
    this.defaults = dataDefaults.defaults;
    this.dataFiles = {
      'yolo_config': 'configData',
      'yolo_defaults': 'defaults'
    };
    if (args.initData) {
      this.getDataFiles();
    }
  }

  //: Get Data Files
  getDataFiles() {
    var error, file, key, ref, results;
    ref = this.dataFiles;
    results = [];
    for (file in ref) {
      key = ref[file];
      try {
        results.push(this[key] = require(this.getDataPath(file)));
      } catch (error1) {
        error = error1;
        this.initDatabase(file);
        results.push(this.overwriteJson(file, this[key]));
      }
    }
    return results;
  }

  //: Create Database Directory
  initDatabase(file) {
    var newHomeDir, newHomeRoot, newPath, oldHomeDir, oldPath;
    oldHomeDir = `${os.homedir()}/node_json_db`;
    newHomeRoot = `${os.homedir()}/.json_config`;
    newHomeDir = `${os.homedir()}/.json_config/robinhood`;
    if (!fs.existsSync(newHomeRoot)) {
      fs.mkdirSync(newHomeRoot);
    }
    if (!fs.existsSync(newHomeDir)) {
      fs.mkdirSync(newHomeDir);
    }
    // Move config files from old to new directory
    if (fs.existsSync(oldHomeDir)) {
      oldPath = this.getOldDataPath(file);
      newPath = this.getDataPath(file);
      if (!fs.existsSync(newPath) && fs.existsSync(oldPath)) {
        fs.copySync(oldPath, this.getDataPath(file));
        return this[this.dataFiles[file]] = require(oldPath);
      }
    }
  }

  //: Get Data Path
  getDataPath(filename) {
    return path.resolve(`${os.homedir()}/.json_config/robinhood/${filename}.json`);
  }

  //: Get Old Data Path
  getOldDataPath(filename) {
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
