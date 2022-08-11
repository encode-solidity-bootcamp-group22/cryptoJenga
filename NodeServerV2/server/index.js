import crypto from 'crypto';
import express from 'express';
import {createServer} from 'http';
import WebSocket from 'ws';
import { StackTowerWeb3 } from './Main.js';

const app = express();
const port = process.env.PORT || 3000;

let textInterval = 3000;
let binaryInterval = 3000;

const server = createServer(app);
const wss = new WebSocket.Server({ server });
StackTowerWeb3.wss = wss;
  
const NewTest = new StackTowerWeb3();

wss.on('connection', function(ws) {
  console.log("client joined.");
  NewTest.setWebSocket(wss);

  ws.on('message', function(data) {
  });

  ws.on('close', function() {
    console.log("client left.");
    clearInterval(textInterval);
    clearInterval(binaryInterval);
  });
});

server.listen(port, function() {
  console.log(`Listening on port ${port}`);
});
