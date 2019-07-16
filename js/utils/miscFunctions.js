var b64Dec, b64Enc, base64, camelCase, chalk, colorPrint, detPrint, editJson, jsonFile, overwriteJson, p, path, queryStr, roundNum, sortOptions, startCase, titleCase, updateJson, utf8;

path = require('path');

utf8 = require('utf8');

base64 = require('base-64');

chalk = require('chalk');

p = require('print-tools-js');

camelCase = require('lodash/camelCase');

startCase = require('lodash/startCase');

editJson = require('edit-json-file');

jsonFile = require('jsonfile');

//: Base64 Decode
b64Dec = function(text) {
  return base64.decode(utf8.encode(text));
};

//: Base64 Encode
b64Enc = function(text) {
  return base64.encode(utf8.encode(text));
};

//: Round Number
roundNum = function(number, places = 2) {
  return parseFloat(String(number)).toFixed(places);
};

//: Title Case
titleCase = function(text) {
  return startCase(camelCase(text));
};

//: Print Detail
detPrint = function(text) {
  if (typeof text === 'object') {
    console.log(JSON.stringify(text));
    return true;
  } else {
    return console.log(text);
    return true;
  }
};

//: Update JSON File
updateJson = function(filename, obj) {
  var error, file, key, value;
  try {
    file = editJson(path.join(__dirname, filename), {
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
    file = path.join(__dirname, filename);
    return jsonFile.writeFileSync(file, obj, {
      spaces: 2
    });
  } catch (error1) {
    error = error1;
    throw error;
  }
};

//: Sort Options
sortOptions = function(a, b) {
  var aStrike, bStrike;
  aStrike = Number(a.strike_price);
  bStrike = Number(b.strike_price);
  if (aStrike > bStrike) {
    return -1;
  } else if (bStrike > aStrike) {
    return 1;
  } else {
    return 0;
  }
};

//: Query String
queryStr = function(obj) {
  var i, key, objLength, str, value;
  objLength = Object.keys(obj).length;
  str = '';
  i = -1;
  for (key in obj) {
    value = obj[key];
    i++;
    if (i === 0) {
      str += '?';
    }
    str += `${key}=${value}`;
    if (i !== (objLength - 1)) {
      str += '&';
    }
  }
  return str;
};

//: Color Print Dictionary
colorPrint = function(obj, objOrder, args = {
    message: null,
    printSpace: true,
    places: 3
  }) {
  var colMod, colors, i, j, ref, val;
  colors = ['green', 'yellow', 'blue', 'magenta', 'cyan', null, 'gray', 'red'];
  colMod = colors.length;
  if (args.message != null) {
    p.success(args.message);
  }
  for (i = j = 0, ref = objOrder.length; (0 <= ref ? j < ref : j > ref); i = 0 <= ref ? ++j : --j) {
    val = obj[objOrder[i]];
    if (String(val).includes('.') && !isNaN(val)) {
      val = roundNum(val, args.places);
    }
    if (colors[i % colMod] === null) {
      p.bullet(`${titleCase(objOrder[i])}: ${val}`, {
        log: false
      });
    } else {
      p.bullet(chalk`{${colors[i % colMod]} ${titleCase(objOrder[i])}}: ${val}`, {
        log: false
      });
    }
  }
  if (args.printSpace) {
    console.log('');
  }
  return true;
};

//: Exports
module.exports = {
  queryStr: queryStr,
  b64Dec: b64Dec,
  b64Enc: b64Enc,
  colorPrint: colorPrint,
  updateJson: updateJson,
  overwriteJson: overwriteJson,
  detPrint: detPrint,
  roundNum: roundNum,
  sortOptions: sortOptions
};

//::: End Program:::
