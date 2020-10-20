const fs = require('fs');
const path = require('path');

exports.getStoredPath = function getStoredPath() {
  const root = process.env.PROJECT_HOME || process.cwd();
  return path.resolve(root, 'fbp-config.json');
};

exports.getStored = function getStored() {
  const storedPath = exports.getStoredPath();
  if (!fs.existsSync(storedPath)) {
    throw new Error(`Did not find ${storedPath}. Run fpb-init first to configure.`);
  }
  return JSON.parse(fs.readFileSync(storedPath));
};

exports.saveStored = function saveStored(values) {
  const storedPath = exports.getStoredPath();
  fs.writeFileSync(storedPath, JSON.stringify(values, null, 2), 'utf-8');
};
