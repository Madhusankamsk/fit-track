import net from 'net';

const host = process.argv[2] || 'postgres';
const port = Number(process.argv[3] || 5432);
const maxAttempts = Number(process.argv[4] || 90);
const delayMs = Number(process.argv[5] || 2000);

function tryConnect() {
  return new Promise((resolve, reject) => {
    const socket = net.connect(port, host, () => {
      socket.end();
      resolve();
    });
    socket.on('error', reject);
    socket.setTimeout(5000, () => {
      socket.destroy();
      reject(new Error('timeout'));
    });
  });
}

for (let attempt = 1; attempt <= maxAttempts; attempt++) {
  try {
    await tryConnect();
    console.log(`Connected to ${host}:${port}`);
    process.exit(0);
  } catch {
    console.log(`Waiting for ${host}:${port} (${attempt}/${maxAttempts})...`);
    await new Promise((r) => setTimeout(r, delayMs));
  }
}

console.error(`Timed out waiting for ${host}:${port}`);
process.exit(1);
