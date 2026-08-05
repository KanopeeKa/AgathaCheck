import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  isLiveHostingTarget,
  isLiveProdTarget,
  isLiveUatTarget,
} from './hosting';

const PREV_BASE = process.env.E2E_BASE_URL;

test.afterEach(() => {
  if (PREV_BASE === undefined) {
    delete process.env.E2E_BASE_URL;
  } else {
    process.env.E2E_BASE_URL = PREV_BASE;
  }
});

test('isLiveUatTarget matches uat.agathatrack.com only', () => {
  assert.equal(isLiveUatTarget('https://uat.agathatrack.com'), true);
  assert.equal(isLiveUatTarget('https://uat.agathatrack.com/'), true);
  assert.equal(isLiveUatTarget('https://agathatrack.com'), false);
  assert.equal(isLiveUatTarget('https://www.agathatrack.com'), false);
  assert.equal(isLiveUatTarget('http://localhost:3000'), false);
});

test('isLiveProdTarget matches prod hosts but not UAT', () => {
  assert.equal(isLiveProdTarget('https://agathatrack.com'), true);
  assert.equal(isLiveProdTarget('https://www.agathatrack.com'), true);
  assert.equal(isLiveProdTarget('https://uat.agathatrack.com'), false);
  assert.equal(isLiveProdTarget('http://127.0.0.1:3000'), false);
});

test('isLiveHostingTarget matches any *.agathatrack.com', () => {
  assert.equal(isLiveHostingTarget('https://uat.agathatrack.com'), true);
  assert.equal(isLiveHostingTarget('https://agathatrack.com'), true);
  assert.equal(isLiveHostingTarget('https://www.agathatrack.com'), true);
  assert.equal(isLiveHostingTarget('https://preview.agathatrack.com'), true);
  assert.equal(isLiveHostingTarget('http://localhost:3000'), false);
});

test('helpers fall back to E2E_BASE_URL when argument omitted', () => {
  process.env.E2E_BASE_URL = 'https://uat.agathatrack.com';
  assert.equal(isLiveUatTarget(), true);
  assert.equal(isLiveProdTarget(), false);
  assert.equal(isLiveHostingTarget(), true);

  process.env.E2E_BASE_URL = 'https://agathatrack.com';
  assert.equal(isLiveUatTarget(), false);
  assert.equal(isLiveProdTarget(), true);
});

test('empty / invalid candidates are not live hosts', () => {
  delete process.env.E2E_BASE_URL;
  assert.equal(isLiveUatTarget(''), false);
  assert.equal(isLiveProdTarget(undefined), false);
  assert.equal(isLiveHostingTarget('not a url :::'), false);
});
