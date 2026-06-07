import './load-env.js';
import Fastify from 'fastify';
import fastifyCors from '@fastify/cors';

const app = Fastify({ logger: true });

await app.register(fastifyCors, {
  origin: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
});

const AUTH = `http://127.0.0.1:${process.env.AUTH_SERVICE_PORT || 5001}`;
const INGEST = `http://127.0.0.1:${process.env.INGESTION_API_PORT || 5002}`;
const ANALYTICS = `http://127.0.0.1:${process.env.ANALYTICS_SERVICE_PORT || 5003}`;

function resolveUpstream(method, url) {
  const path = url.split('?')[0];
  if (path.startsWith('/api/v1/auth') || path.startsWith('/api/v1/users')) return AUTH;
  if (path.startsWith('/api/v1/ingest') || path.startsWith('/api/v1/feed')) return INGEST;
  if (path.startsWith('/api/v1/stats') || path.startsWith('/api/v1/segments')) return ANALYTICS;
  if (method === 'POST' && /\/api\/v1\/activities\/\d+\/(kudos|comments)$/.test(path)) return ANALYTICS;
  if (path.startsWith('/api/v1/activities')) return INGEST;
  return null;
}

async function proxyRequest(request, reply) {
  const upstream = resolveUpstream(request.method, request.url);
  if (!upstream) {
    return reply.status(404).send({ error: 'Route not found' });
  }

  const targetUrl = `${upstream}${request.url}`;
  const hopByHop = new Set([
    'host',
    'connection',
    'expect',
    'keep-alive',
    'proxy-authenticate',
    'proxy-authorization',
    'te',
    'trailer',
    'transfer-encoding',
    'upgrade',
  ]);
  const headers = {};
  for (const [key, value] of Object.entries(request.headers)) {
    if (!hopByHop.has(key.toLowerCase())) {
      headers[key] = value;
    }
  }

  const init = {
    method: request.method,
    headers
  };

  if (request.method !== 'GET' && request.method !== 'HEAD' && request.body !== undefined) {
    init.body = typeof request.body === 'string' ? request.body : JSON.stringify(request.body);
    if (!headers['content-type']) {
      headers['content-type'] = 'application/json';
    }
  }

  const response = await fetch(targetUrl, init);
  reply.status(response.status);

  response.headers.forEach((value, key) => {
    if (!['transfer-encoding', 'connection'].includes(key.toLowerCase())) {
      reply.header(key, value);
    }
  });

  if (response.status === 204) {
    return reply.send();
  }

  const text = await response.text();
  try {
    return reply.send(JSON.parse(text));
  } catch {
    return reply.send(text);
  }
}

app.route({
  method: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  url: '/api/v1/*',
  handler: proxyRequest
});

app.get('/health', async () => ({ status: 'ok', service: 'dev-gateway' }));

const port = parseInt(process.env.DEV_GATEWAY_PORT || '8080', 10);
await app.listen({ port, host: '0.0.0.0' });
console.log(`Dev gateway listening on http://localhost:${port}`);
