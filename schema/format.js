(function() {
  var moment;

  moment = require('moment');

  module.exports = function(tv4) {
    tv4.addFormat('date-time', function(data) {
      if (!moment(data, moment.ISO_8601).isValid()) {
        return 'Invalid date-time';
      }
    });
    return tv4.addFormat('date', function(data) {
      if (!moment(data, 'YYYY-MM-DD').isValid()) {
        return 'Invalid date';
      }
    });
  };

}).call(this);
