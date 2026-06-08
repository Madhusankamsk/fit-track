import { spawnSync } from 'child_process';

function run(label, command, args) {
  console.log(`=== [auth] ${label} ===`);
  const result = spawnSync(command, args, { stdio: 'inherit', shell: false });
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

run('Waiting for Postgres', 'node', ['scripts/wait-for-tcp.js', 'postgres', '5432']);
run('Running migrations', 'npx', [
  'prisma',
  'migrate',
  'deploy',
  '--schema=./prisma/schema.prisma',
]);

console.log('=== [auth] Running seed (non-fatal) ===');
const seed = spawnSync('node', ['scripts/seed.js'], { stdio: 'inherit', shell: false });
if (seed.status !== 0) {
  console.warn('=== [auth] Seed failed — continuing to start server ===');
}

const port = process.env.AUTH_SERVICE_PORT || '5001';
console.log(`=== [auth] Starting server on port ${port} ===`);
run('Starting server', 'node', ['server.js']);
