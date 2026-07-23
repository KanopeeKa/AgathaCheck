'use strict';

const fs = require('fs');

function parseFlags(argv) {
  const flags = {};
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (!arg.startsWith('--')) continue;
    const key = arg.slice(2);
    const next = argv[i + 1];
    if (next && !next.startsWith('--')) {
      flags[key] = next;
      i += 1;
    } else {
      flags[key] = true;
    }
  }
  return flags;
}

function readBody(flags) {
  if (flags.body) return flags.body;
  if (flags['body-file']) return fs.readFileSync(flags['body-file'], 'utf8');
  return null;
}

module.exports = {
  parseFlags,
  readBody,
};
