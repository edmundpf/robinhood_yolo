var configData, dataDefaults, defaults, editJson, error, fs, getDataPath, jsonFile, overwriteJson, path, updateJson;

fs = require('fs');

path = require('path');

jsonFile = require('jsonfile');

editJson = require('edit-json-file');

dataDefaults = require('../data/dataDefaults.json');

//: Get Data Path
getDataPath = function(filename) {
  return `/node_json_db/${filename}.json`;
};

//: Update JSON File
updateJson = function(filename, obj) {
  var error, file, key, value;
  try {
    file = editJson(getDataPath(filename), {
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
};

//: Overwrite JSON File
overwriteJson = function(filename, obj) {
  var error, file;
  try {
    file = getDataPath(filename);
    return jsonFile.writeFileSync(file, obj, {
      spaces: 2
    });
  } catch (error1) {
    error = error1;
    throw error;
  }
};

//: Init Data Files
configData = defaults = null;

try {
  configData = require('/node_json_db/yolo_config.json');
} catch (error1) {
  error = error1;
  configData = dataDefaults.configData;
  if (!fs.existsSync('/node_json_db')) {
    fs.mkdirSync('/node_json_db');
  }
  overwriteJson('yolo_config', configData);
}

try {
  defaults = require('/node_json_db/yolo_defaults.json');
} catch (error1) {
  error = error1;
  defaults = dataDefaults.defaults;
  if (!fs.existsSync('/node_json_db')) {
    fs.mkdirSync('/node_json_db');
  }
  overwriteJson('yolo_defaults', defaults);
}

//: Exports
module.exports = {
  configData: configData,
  defaults: defaults,
  updateJson: updateJson,
  overwriteJson: overwriteJson
};

//::: End Program :::
