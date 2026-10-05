import '../config/loadEnv.js';
import app from './server.js';
import { verifyPgDateParser } from '../lib/db/createPool.js';
import { kickCleanupJobs, startCleanupJobsRunner } from '../lib/jobs/cleanupJobsRunner.js';

export { kickCleanupJobs };

const port = process.env.PORT || 3000;

async function startServer() {
  try {
    await verifyPgDateParser(app.locals.pool);
  } catch (err) {
    console.error('PG DATE startup check failed:', err.message);
    process.exit(1);
  }
  const cleanupRunner = startCleanupJobsRunner(app.locals.pool);

  const server = app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
    console.log(`Database: ${process.env.PGDATABASE || 'agatha_db'} on ${process.env.PGHOST || 'localhost'}:${process.env.PGPORT || 5432}`);
  });

  // Graceful shutdown: stop accepting connections and close the DB pool so
  // in-flight queries can finish and Passenger/containers can restart cleanly.
  let shuttingDown = false;
  async function shutdown(signal) {
    if (shuttingDown) return;
    shuttingDown = true;
    console.log(`Received ${signal}, shutting down gracefully...`);
    cleanupRunner.stop();
    server.close(async () => {
      try {
        await app.locals.pool?.end();
      } catch (err) {
        console.error('Error closing DB pool:', err.message);
      }
      process.exit(0);
    });
    // Failsafe: force-exit if connections don't drain in time.
    setTimeout(() => process.exit(0), 10000).unref();
  }

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

startServer().catch((err) => {
  console.error(err);
  process.exit(1);
});
