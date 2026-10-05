const express = require('express');
const mysql = require('mysql2/promise');
const AWS = require('aws-sdk');

const app = express();
const PORT = 3000;

let dbConfig = null;

// Secrets Manager se DB credentials fetch karo
async function loadSecrets() {
  const client = new AWS.SecretsManager({ region: 'ap-south-1' });
  const data = await client.getSecretValue({ SecretId: 'app/db-credentials' }).promise();
  const secret = JSON.parse(data.SecretString);
  dbConfig = {
    host: secret.host,
    user: secret.username,
    password: secret.password,
    database: secret.dbname,
  };
}

app.get('/api/health', (req, res) => {
  res.json({ message: 'Backend is running fine!' });
});

app.get('/api/db-check', async (req, res) => {
  try {
    const conn = await mysql.createConnection(dbConfig);
    await conn.query('SELECT 1');
    await conn.end();
    res.json({ status: 'connected', message: 'DB connection successful' });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});

async function start() {
  try {
    await loadSecrets();
    console.log('Secrets loaded successfully');
  } catch (err) {
    console.log('Could not load secrets (running without DB for now):', err.message);
  }
  app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
}

start();