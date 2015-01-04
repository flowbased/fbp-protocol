var fs = require('fs');
var path = require('path');

exports.getStoredPath = function () {
  var root = process.env.PROJECT_HOME || process.cwd();
  return path.resolve(root, 'fbp-config.json');
};

exports.getStored = function () {
  var storedPath = exports.getStoredPath();
  if (!fs.existsSync(storedPath)) {
    throw new Error('Did not find ' + storedPath + '. Run fpb-init first to configure.');
  }
  return JSON.parse(fs.readFileSync(storedPath));
};

exports.saveStored = function (values) {
  var storedPath = exports.getStoredPath();
  fs.writeFileSync(storedPath, JSON.stringify(values, null, 2), 'utf-8');
};
