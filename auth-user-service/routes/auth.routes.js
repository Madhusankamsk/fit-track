import bcrypt from 'bcrypt';
import { registerSchema, loginSchema } from '../validators/auth.schema.js';

export async function authRoutes(app, { prisma }) {
  app.post('/api/v1/auth/register', async (request, reply) => {
    const result = registerSchema.safeParse(request.body);
    if (!result.success) {
      return reply.status(400).send({ error: result.error.flatten() });
    }

    const { username, email, password } = result.data;

    const existing = await prisma.user.findFirst({
      where: { OR: [{ email }, { username }] }
    });
    if (existing) {
      return reply.status(409).send({
        error: existing.email === email ? 'Email already in use' : 'Username taken'
      });
    }

    const passwordHash = await bcrypt.hash(
      password,
      parseInt(process.env.BCRYPT_ROUNDS || '12', 10)
    );
    const user = await prisma.user.create({
      data: { username, email, passwordHash },
      select: { id: true, username: true, email: true, createdAt: true }
    });

    const token = app.jwt.sign(
      { sub: user.id, username: user.username },
      { expiresIn: process.env.JWT_EXPIRES_IN || '15m' }
    );

    return reply.status(201).send({ user, token });
  });

  app.post('/api/v1/auth/login', async (request, reply) => {
    const result = loginSchema.safeParse(request.body);
    if (!result.success) {
      return reply.status(400).send({ error: result.error.flatten() });
    }

    const { email, password } = result.data;

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      return reply.status(401).send({ error: 'Invalid credentials' });
    }

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
      return reply.status(401).send({ error: 'Invalid credentials' });
    }

    const token = app.jwt.sign(
      { sub: user.id, username: user.username },
      { expiresIn: process.env.JWT_EXPIRES_IN || '15m' }
    );

    const refreshToken = app.jwt.sign(
      { sub: user.id, type: 'refresh' },
      { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d' }
    );

    await prisma.user.update({
      where: { id: user.id },
      data: { refreshToken }
    });

    return reply.send({
      token,
      refreshToken,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        profilePictureUrl: user.profilePictureUrl
      }
    });
  });

  app.post('/api/v1/auth/refresh', async (request, reply) => {
    const { refreshToken } = request.body || {};
    if (!refreshToken) {
      return reply.status(400).send({ error: 'Refresh token required' });
    }

    try {
      const decoded = app.jwt.verify(refreshToken);
      const user = await prisma.user.findUnique({ where: { id: decoded.sub } });
      if (!user || user.refreshToken !== refreshToken) {
        return reply.status(401).send({ error: 'Invalid refresh token' });
      }
      const token = app.jwt.sign(
        { sub: user.id, username: user.username },
        { expiresIn: process.env.JWT_EXPIRES_IN || '15m' }
      );
      return reply.send({ token });
    } catch {
      return reply.status(401).send({ error: 'Invalid refresh token' });
    }
  });
}
