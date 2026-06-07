import bcrypt from 'bcrypt';
import { PrismaClient } from '@prisma/client';

if (process.env.SEED_ON_STARTUP === 'false') {
  console.log('Seed skipped (SEED_ON_STARTUP=false)');
  process.exit(0);
}

const SEED = {
  username: process.env.SEED_USERNAME || 'runner1',
  email: process.env.SEED_EMAIL || 'runner1@test.com',
  password: process.env.SEED_PASSWORD || 'Securepass1!',
};

const prisma = new PrismaClient();

try {
  const passwordHash = await bcrypt.hash(
    SEED.password,
    parseInt(process.env.BCRYPT_ROUNDS || '12', 10)
  );

  const user = await prisma.user.upsert({
    where: { email: SEED.email },
    update: { passwordHash, username: SEED.username },
    create: { username: SEED.username, email: SEED.email, passwordHash },
    select: { id: true, username: true, email: true },
  });

  console.log('Seed account ready:');
  console.log(`  Email:    ${SEED.email}`);
  console.log(`  Password: ${SEED.password}`);
  console.log(`  User ID:  ${user.id}`);
} finally {
  await prisma.$disconnect();
}
