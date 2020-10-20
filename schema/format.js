const moment = require('moment');

module.exports = function (tv4) {
  tv4.addFormat('date-time', (data) => {
    if (!moment(data, moment.ISO_8601).isValid()) {
      return 'Invalid date-time';
    }
    return null;
  });

  tv4.addFormat('date', (data) => {
    if (!moment(data, 'YYYY-MM-DD').isValid()) {
      return 'Invalid date';
    }
    return null;
  });
};
