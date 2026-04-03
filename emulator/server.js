#!/usr/bin/env node
/**
 * VaultNote Emulator Web Server
 * Provides API for emulator control via browser
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);
const PORT = 8080;

// MIME types
const mimeTypes = {
    '.html': 'text/html',
    '.js': 'text/javascript',
    '.css': 'text/css',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon'
};

// ADB path
const ADB = '/home/blue/sdk/android/platform-tools/adb';
const EMULATOR = '/home/blue/sdk/android/emulator/emulator';

// Execute command with timeout
async function executeCommand(command, timeout = 30000) {
    try {
        const { stdout, stderr } = await execAsync(command, { timeout });
        return {
            success: true,
            output: stdout.trim(),
            error: stderr.trim()
        };
    } catch (error) {
        return {
            success: false,
            output: '',
            error: error.message
        };
    }
}

// API handler
async function handleAPI(req, res) {
    if (req.method === 'POST' && req.url === '/api/execute') {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', async () => {
            try {
                const { command } = JSON.parse(body);
                console.log(`[API] Executing: ${command}`);
                const result = await executeCommand(command);
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify(result));
            } catch (error) {
                res.writeHead(400, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ success: false, error: error.message }));
            }
        });
    } else if (req.method === 'GET' && req.url === '/api/status') {
        const adbResult = await executeCommand(`${ADB} devices`);
        const emuResult = await executeCommand(`${ADB} shell getprop sys.boot_completed 2>/dev/null || echo "0"`);
        const apkResult = await executeCommand(`${ADB} shell pm list packages 2>/dev/null | grep vaultnote || echo ""`);
        
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            adb: adbResult.success && adbResult.output.includes('emulator'),
            emulator: emuResult.success && emuResult.output.trim() === '1',
            apk: apkResult.success && apkResult.output.includes('vaultnote'),
            timestamp: new Date().toISOString()
        }));
    } else {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Not found' }));
    }
}

// Static file handler
async function serveStatic(req, res) {
    let filePath = req.url === '/' ? '/index.html' : req.url;
    filePath = path.join(__dirname, filePath);
    
    const ext = path.extname(filePath).toLowerCase();
    const contentType = mimeTypes[ext] || 'application/octet-stream';
    
    try {
        const content = fs.readFileSync(filePath);
        res.writeHead(200, { 'Content-Type': contentType });
        res.end(content);
    } catch (error) {
        if (error.code === 'ENOENT') {
            res.writeHead(404, { 'Content-Type': 'text/plain' });
            res.end('File not found');
        } else {
            res.writeHead(500, { 'Content-Type': 'text/plain' });
            res.end('Server error');
        }
    }
}

// Main server
const server = http.createServer(async (req, res) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
    
    if (req.url.startsWith('/api/')) {
        await handleAPI(req, res);
    } else {
        await serveStatic(req, res);
    }
});

// Start server
server.listen(PORT, () => {
    console.log(`
╔════════════════════════════════════════════════════════════╗
║         VaultNote Emulator Web Server                      ║
╠════════════════════════════════════════════════════════════╣
║  URL: http://localhost:${PORT}                              ║
║  Status: Running                                           ║
╠════════════════════════════════════════════════════════════╣
║  Features:                                                 ║
║  • Start/Stop emulator                                     ║
║  • Install APK                                             ║
║  • Launch VaultNote app                                    ║
║  • Send key events                                         ║
║  • Real-time status monitoring                             ║
╠════════════════════════════════════════════════════════════╣
║  Commands:                                                 ║
║  • Start Emulator: /home/blue/sdk/android/emulator/...     ║
║  • Install APK: adb install -r app-universal-release.apk   ║
║  • Launch App: adb shell am start -n com.vaultnote...      ║
╚════════════════════════════════════════════════════════════╝
    `);
});

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\nShutting down server...');
    server.close(() => {
        console.log('Server stopped');
        process.exit(0);
    });
});

process.on('SIGTERM', () => {
    console.log('\nReceived SIGTERM, shutting down...');
    server.close(() => {
        process.exit(0);
    });
});