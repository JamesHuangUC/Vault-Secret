var request = require('supertest');
var app = require('../app.js');

describe('GET /', function() {
    it('should respond with secret', function(done) {
        request(app).get('/').expect(200, done);
    });
});

