const express = require('express');
const app = express();
const http = require('http').createServer(app);
const io = require('socket.io')(http);

io.on('connection', (socket) => {
    console.log('A user connected');

    socket.on('player_moved', (data) => {
        // Broadcast to all other players
        socket.broadcast.emit('player_moved', data);
    });

    socket.on('disconnect', () => {
        console.log('A user disconnected');
    });
});

http.listen(8080, () => {
    console.log('WebSocket server running on port 8080');
});