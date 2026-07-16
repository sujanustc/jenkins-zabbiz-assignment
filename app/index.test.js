const request = require('supertest');
const { app, server } = require('./index');

afterAll((done) => {
  server.close(done);
});

describe('GET /', () => {
  it('should return 200 OK with success status and welcome message', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toEqual(200);
    expect(res.body.status).toEqual('success');
    expect(res.body.message).toContain('Welcome to the Jenkins CI/CD');
  });
});

describe('GET /health', () => {
  it('should return 200 OK and UP status', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toEqual(200);
    expect(res.body.status).toEqual('UP');
  });
});
