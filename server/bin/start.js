import app from './server.js';

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
  console.log(`Database: ${process.env.PGDATABASE || 'agatha_db'} on ${process.env.PGHOST || 'localhost'}:${process.env.PGPORT || 5432}`);
});