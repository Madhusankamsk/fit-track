import { updateProfileSchema } from '../validators/auth.schema.js';
import { authenticate } from '../middleware/authenticate.js';

export async function usersRoutes(app, { prisma }) {
  app.get('/api/v1/users/:id', {
    onRequest: [authenticate]
  }, async (request, reply) => {
    const userId = parseInt(request.params.id, 10);
    if (Number.isNaN(userId)) return reply.status(400).send({ error: 'Invalid user ID' });

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        username: true,
        bio: true,
        profilePictureUrl: true,
        createdAt: true,
        activities: {
          where: { isPublic: true },
          orderBy: { createdAt: 'desc' },
          take: 20,
          select: {
            id: true,
            title: true,
            activityType: true,
            distanceMeters: true,
            durationSeconds: true,
            elevationGainMeters: true,
            startTime: true,
            createdAt: true,
            _count: { select: { kudos: true, comments: true } }
          }
        },
        _count: {
          select: { followers: true, following: true, activities: true }
        }
      }
    });

    if (!user) return reply.status(404).send({ error: 'User not found' });
    return reply.send(user);
  });

  app.put('/api/v1/users/me', {
    onRequest: [authenticate]
  }, async (request, reply) => {
    const result = updateProfileSchema.safeParse(request.body);
    if (!result.success) return reply.status(400).send({ error: result.error.flatten() });

    const updated = await prisma.user.update({
      where: { id: request.user.sub },
      data: result.data,
      select: { id: true, username: true, bio: true, profilePictureUrl: true }
    });
    return reply.send(updated);
  });

  app.post('/api/v1/users/:id/follow', {
    onRequest: [authenticate]
  }, async (request, reply) => {
    const followingId = parseInt(request.params.id, 10);
    const followerId = request.user.sub;

    if (followerId === followingId) {
      return reply.status(400).send({ error: 'Cannot follow yourself' });
    }

    await prisma.follow.upsert({
      where: { followerId_followingId: { followerId, followingId } },
      create: { followerId, followingId },
      update: {}
    });

    return reply.status(201).send({ success: true });
  });

  app.delete('/api/v1/users/:id/follow', {
    onRequest: [authenticate]
  }, async (request, reply) => {
    const followingId = parseInt(request.params.id, 10);
    const followerId = request.user.sub;

    await prisma.follow.deleteMany({ where: { followerId, followingId } });
    return reply.send({ success: true });
  });
}
