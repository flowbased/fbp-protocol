var tv4 = require('tv4');
var schemas = require('./schemas');
var format = require('./format');

tv4.addSchema('/shared/', schemas.shared);
tv4.addSchema('/graph/', schemas.graph);
tv4.addSchema('/network/', schemas.network);
tv4.addSchema('/runtime/', schemas.runtime);
tv4.addSchema('/component/', schemas.component);
tv4.addSchema('/trace/', schemas.trace);
format(tv4);

module.exports = tv4;
