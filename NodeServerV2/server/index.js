import crypto from 'crypto';
import express from 'express';
import {createServer} from 'http';
import WebSocket from 'ws';
import { StackTowerWeb3 } from './Main.js';

const app = express();
const port = 3000;

const server = createServer(app);
const wss = new WebSocket.Server({ server });

const NewTest = new StackTowerWeb3();

wss.on('connection', function(ws) {
  console.log("client joined.");
  NewTest.setWebSocket(ws);

  ws.on('placeBet', function(data) {
    if (typeof(data) === "string") {
      // client sent a string
      console.log("string received from client -> '" + data + "'");

    } else {
      console.log("binary received from client -> " + Array.from(data).join(", ") + "");
    }
  });

  ws.on('message', function(data) {
    if (typeof(data) === "string") {
      // client sent a string
      console.log("string received from client -> '" + data + "'");

    } else {
      console.log("binary received from client -> " + Array.from(data).join(", ") + "");
    }
  });

  ws.on('close', function() {
    console.log("client left.");
    clearInterval(textInterval);
    clearInterval(binaryInterval);
  });
});

server.listen(port, function() {
  console.log(`Listening on http://localhost:${port}`);
});
