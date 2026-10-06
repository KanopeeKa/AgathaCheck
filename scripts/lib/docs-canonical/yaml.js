'use strict';

const fs = require('fs');
const path = require('path');

function loadYaml(root) {
  try {
    return require('js-yaml');
  } catch {
    try {
      return require(path.join(root, 'server/node_modules/js-yaml'));
    } catch {
      throw new Error('js-yaml is required. Install backend deps: cd server && npm ci');
    }
  }
}

function parseFrontmatter(filePath, root) {
  const text = fs.readFileSync(filePath, 'utf8');
  const match = text.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!match) {
    return { meta: null, body: text };
  }
  const yaml = loadYaml(root);
  let meta;
  try {
    meta = yaml.load(match[1]) || {};
  } catch (error) {
    throw new Error(`invalid YAML frontmatter: ${error.message}`);
  }
  const body = text.slice(match[0].length);
  return { meta, body };
}

module.exports = { loadYaml, parseFrontmatter };
