# Simple Node.js development server for testing

FROM node:18-alpine

WORKDIR /app

# Install required tools
RUN apk add --no-cache curl dumb-init

# Create a simple health check endpoint server
RUN cat > server.js << 'EOF'
const http = require('http');

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'OK', message: 'BarberPro Backend is ready!' }));
  } else if (req.url === '/') {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end('<h1>BarberPro Backend API</h1><p>Backend is running in Docker!</p>');
  } else {
    res.writeHead(404);
    res.end('Not Found');
  }
});

const PORT = 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 BarberPro Backend API running on http://localhost:${PORT}`);
  console.log(`📚 Health check: http://localhost:${PORT}/health`);
});
EOF

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start server
CMD ["node", "server.js"]
