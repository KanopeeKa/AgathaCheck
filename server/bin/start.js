import '../config/loadEnv.js';
import app from './server.js';

const port = process.env.PORT || 3000;
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
