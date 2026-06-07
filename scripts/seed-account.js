import { createRequire } from 'module';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const require = createRequire(import.meta.url);
require(join(root, 'auth-user-service/node_modules/dotenv')).config({ path: join(root, '.env') });
const bcrypt = require(join(root, 'auth-user-service/node_modules/bcrypt'));
const { PrismaClient } = require(join(root, 'node_modules/@prisma/client'));

const SEED = {
  username: 'runner1',
  email: 'runner1@test.com',
  password: 'Securepass1!',
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
