const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const crypto = require('crypto');

const app = express();
const PORT = process.env.PORT || 3000;
const MCP_API_KEY = process.env.MCP_API_KEY;

if (!MCP_API_KEY) {
  console.error('FATAL: MCP_API_KEY environment variable not set');
  process.exit(1);
}

// Trust proxy for accurate IP logging behind reverse proxy
app.set('trust proxy', 1);

// Disable X-Powered-By header
app.disable('x-powered-by');

// Parse and trim CORS origins
const allowedOrigins = process.env.ALLOWED_ORIGINS 
  ? process.env.ALLOWED_ORIGINS.split(',').map(o => o.trim())
  : ['http://localhost:3000'];

const corsOptions = {
  origin: allowedOrigins,
  methods: ['GET', 'POST', 'OPTIONS'],
  credentials: true
};

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100
});

const requireApiKey = (req, res, next) => {
  const key = req.headers['x-api-key'] || '';
  
  // Timing-safe comparison
  try {
    const keyBuffer = Buffer.from(key);
    const apiKeyBuffer = Buffer.from(MCP_API_KEY);
    
    if (keyBuffer.length !== apiKeyBuffer.length || 
        !crypto.timingSafeEqual(keyBuffer, apiKeyBuffer)) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
};

app.use(helmet());
app.use(cors(corsOptions));
app.use(morgan('combined'));
app.use(express.json({ limit: '1mb' }));
app.use(limiter);

app.get('/health', (req, res) => {
  try {
    res.json({ status: 'healthy', service: 'MCP Docker Server' });
  } catch (error) {
    console.error('Error in /health:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/info', requireApiKey, (req, res) => {
  try {
    res.json({
      service: 'MCP Docker Server',
      version: '1.0.0',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error in /api/info:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 404 handler
app.use((req, res, next) => {
  if (!res.headersSent) {
    res.status(404).json({ error: 'Not found' });
  }
});

app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, () => {
  console.log(`MCP Docker Server running on port ${PORT}`);
});
