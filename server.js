require('dotenv').config();

const http = require('http');

const PORT = process.env.PORT || 3000;

const APIKEY   = process.env.APIkey   || 'NOT SET';
const PASSWORD = process.env.password || 'NOT SET';

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok' }));
    return;
  }

  if (req.url === '/secrets') {

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      message : 'Secrets loaded from Infisical via fetch-infisical-env.sh',
      env     : process.env.APP_ENV || 'dev',
      keys    : {
        APIkey   : APIKEY   !== 'NOT SET' ? 'loaded' : 'missing',
        password : PASSWORD !== 'NOT SET' ? 'loaded' : 'missing',
      }
    }, null, 2));
    return;
  }

  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({
    app    : 'Test Workflow App',
    env    : process.env.APP_ENV || 'dev',
    gitSha : process.env.GIT_SHA || 'local',
    routes : ['/health', '/secrets']
  }, null, 2));
});

server.listen(PORT, () => {
  console.log(`────────────────────────────────────────`);
  console.log(`  Server running on port ${PORT}`);
  console.log(`  ENV        : ${process.env.APP_ENV || 'dev'}`);
  console.log(`  APIkey     : ${APIKEY   !== 'NOT SET' ? 'loaded' : 'missing'}`);
  console.log(`  password   : ${PASSWORD !== 'NOT SET' ? 'loaded' : 'missing'}`);
  console.log(`────────────────────────────────────────`);
});

