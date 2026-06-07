import { describe, it, expect } from 'vitest';

const BASE = process.env.TEST_AUTH_URL || 'http://localhost:5001';

describe('POST /api/v1/auth/register', () => {
  it('should return 400 for invalid email', async () => {
    const res = await fetch(`${BASE}/api/v1/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: 'test',
        email: 'not-an-email',
        password: 'password123'
      })
    });
    expect(res.status).toBe(400);
  });

  it('should return 201 and token for valid registration', async () => {
    const unique = Date.now();
    const res = await fetch(`${BASE}/api/v1/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: `testuser${unique}`,
        email: `test${unique}@test.com`,
        password: 'Securepass1!'
      })
    });
    expect(res.status).toBe(201);
    const body = await res.json();
    expect(body.token).toBeDefined();
    expect(body.user).toBeDefined();
  });
});

describe('POST /api/v1/auth/login', () => {
  it('should return 401 for invalid credentials', async () => {
    const res = await fetch(`${BASE}/api/v1/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'nonexistent@test.com',
        password: 'wrongpassword'
      })
    });
    expect(res.status).toBe(401);
  });
});
