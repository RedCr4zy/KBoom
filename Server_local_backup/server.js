// server.js
import express from 'express';
import http from 'http';
import cors from 'cors';

import { initWebsocket } from './wsHandler.js';
import { initConsole } from './console.js';

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);

// ✅ Initialisation WebSocket et console
initWebsocket(server);
initConsole();

// écoute sur 0.0.0.0:3000
const PORT = 3000;
const HOST = '0.0.0.0';
server.listen(PORT, HOST, () => {
  console.log(`🚀 Serveur lancé sur http://${HOST}:${PORT}`);
});
