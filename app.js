var ROLEID = process.env.ROLEID;
var WRAP_SECRET_TOKEN = process.env.WST;
var VAULT_URL = 'http://54.224.180.35:8200';

if (!WRAP_SECRET_TOKEN) {
    console.error('No wrap token');
    process.exit();
}

var options = {
    apiVersion: 'v1',
    endpoint: VAULT_URL,
    token: WRAP_SECRET_TOKEN
};

console.log('Wrapped secret token: ' + WRAP_SECRET_TOKEN);

var vault = require('node-vault')(options);

var secret = '';

vault
    .unwrap()
    .then(result => {
        var secretId = result.data.secret_id;
        console.log('Secret id: ' + result.data.secret_id);

        vault
            .approleLogin({ role_id: ROLEID, secret_id: secretId })
            .then(login_result => {
                var client_token = login_result.auth.client_token;
                console.log('Client token: ' + client_token);
                var client_options = {
                    apiVersion: 'v1',
                    endpoint: VAULT_URL,
                    token: client_token
                };

                var client_vault = require('node-vault')(client_options);

                client_vault
                    .read('secret/secretapp/config')
                    .then(secretData => {
                        console.log(secretData);
                        secret = secretData;
                    });
            });
    })
    .catch(console.error);

var express = require('express');
var app = express();

app.get('/', function(req, res) {
    if (secret === '') {
        res.statusMessage = 'It is a secret';
        res.status(401).end();
    } else {
        res.send(secret);
    }
});

app.get('/secret', function(req, res) {
    res.send(
        'Role id: ' +
            process.env.ROLEID +
            '<br />' +
            'Wrapped secret token: ' +
            process.env.WST
    );
});

app.listen(process.env.PORT || 3000);
module.exports = app;

