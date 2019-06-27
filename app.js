var express = require('express');
 
var app = express();

app.get('/', function (req, res) {
    res.send('Hello World');
});

app.get('/test', function (req, res) {
    res.send('Role id: ' + process.env.ROLEID + '<br/>' + 'Wrapped secret token: ' + process.env.WST);
})
app.listen(process.env.PORT || 3000);
 
module.exports = app;

