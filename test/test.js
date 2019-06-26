var request = require('supertest');
var app = require('../app.js');

describe('GET /', function() {
    it('should respond with Hello World', function(done) {
        request(app).get('/').expect('Hello World', done);
    });
});

