import { authenticate } from '../middleware/authenticate.js';

export async function socialRoutes(app, { prisma, redis }) {
  app.post('/api/v1/activities/:id/kudos', {
    onRequest: [authenticate]
  }, async (request, reply) => {
    const activityId = parseInt(request.params.id, 10);
    const userId = request.user.sub;

    await prisma.kudo.upsert({
      where: { userId_activityId: { userId, activityId } },
      create: { userId, activityId },
      update: {}
    });

    await redis.del(`activity:${activityId}`);
    return reply.status(201).send({ success: true });
  });

  app.post('/api/v1/activities/:id/comments', {
    onRequest: [authenticate]
  }, async (request, reply) => {
    const activityId = parseInt(request.params.id, 10);
    const userId = request.user.sub;
    const { text } = request.body || {};

    if (!text?.trim()) return reply.status(400).send({ error: 'Comment text required' });

    const comment = await prisma.comment.create({
      data: { userId, activityId, commentText: text.trim() },
      include: { user: { select: { username: true, profilePictureUrl: true } } }
    });

    return reply.status(201).send(comment);
  });
}
