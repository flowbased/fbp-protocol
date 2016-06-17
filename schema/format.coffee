moment = require 'moment'

module.exports = (tv4) ->
  tv4.addFormat 'date-time', (data) ->
    unless moment(data, moment.ISO_8601).isValid()
      return 'Invalid date-time'

  tv4.addFormat 'date', (data) ->
    unless moment(data, 'YYYY-MM-DD').isValid()
      return 'Invalid date'
