const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const path = require('path');

const app = express();
const PORT = 3000;

// Serve the Vue.js application
app.use(express.static(path.join(__dirname, 'public')));

// Proxy endpoint
app.use('/api', createProxyMiddleware({
  target: 'http://nbchaos2.uksouth.cloudapp.azure.com/',
  changeOrigin: true,
  pathRewrite: {
    '^/api': '', // remove /api prefix when forwarding to the target
  },
}));

app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});
