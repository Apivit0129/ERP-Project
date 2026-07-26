require('dotenv').config();
const prisma = require('./db');

const username = process.argv[2];
if (!username) {
  console.error('Usage: node deleteUser.js <username>');
  process.exit(1);
}

async function run() {
  try {
    const result = await prisma.user.deleteMany({ where: { username } });
    console.log('Deleted count:', result.count);
  } catch (err) {
    console.error('Error deleting user:', err.message || err);
  } finally {
    await prisma.$disconnect();
  }
}

run();
