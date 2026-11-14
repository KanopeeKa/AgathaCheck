import { v4 as uuidv4 } from 'uuid';

import { buildSupportReceiptEmail } from '../../lib/support/outbox/receiptEmail.js';
import {
  buildGithubIssueBody,
  buildGithubIssueLabels,
  buildGithubIssueTitle,
} from '../../lib/support/outbox/issueContent.js';
import {
  refreshSupportGithubRepoGate,
  resetSupportGithubRepoGateCacheForTests,
} from '../../lib/support/outbox/repoGate.js';
import { writeGithubIssueNumber } from '../../lib/support/outbox/rowState.js';
import { fetchGithubRepoPrivacy } from '../../lib/support/outbox/githubApi.js';

jest.mock('../../lib/support/outbox/githubApi.js', () => ({
  ...jest.requireActual('../../lib/support/outbox/githubApi.js'),
  fetchGithubRepoPrivacy: jest.fn(),
}));

describe('support receipt email', () => {
  it('builds EN and FR subjects with reference', () => {
    const ref = 'AT-ABCDEFGH';
    const en = buildSupportReceiptEmail({ locale: 'en', reference: ref });
    const fr = buildSupportReceiptEmail({ locale: 'fr', reference: ref });

    expect(en.subject).toBe(`[${ref}] We received your request`);
    expect(fr.subject).toBe(`[${ref}] Nous avons reçu votre demande`);
    expect(en.text).toContain(ref);
    expect(en.text).not.toContain('user wrote');
    expect(fr.text).toContain(ref);
  });
});

describe('github issue content', () => {
  const ticket = {
    reference: 'AT-ZZZZZZZZ',
    category: 'bug',
    title: 'Crash on save',
    description: 'It breaks',
    expected: 'Save works',
    actual: 'Error',
    steps: '1. Tap save',
    frequency: 'always',
    context: { version: '1.0', platform: 'web' },
  };

  it('titles and labels follow intake rules', () => {
    process.env.APP_ENV = 'uat';
    expect(buildGithubIssueTitle(ticket)).toBe('[AT-ZZZZZZZZ] bug: Crash on save');
    expect(buildGithubIssueLabels(ticket)).toEqual([
      'category:bug',
      'env:uat',
      'source:form',
    ]);
    delete process.env.APP_ENV;
    expect(buildGithubIssueLabels(ticket)).toContain('env:unknown');
  });

  it('fences reporter content and lists allowlisted context', () => {
    const body = buildGithubIssueBody(ticket);
    expect(body).toContain('Reporter submission (untrusted)');
    expect(body).toContain('```');
    expect(body).toContain('It breaks');
    expect(body).toContain('version: 1.0');
    expect(body).not.toContain('reporter_email');
  });
});

describe('github repo gate', () => {
  const mockQuery = jest.fn();
  const pool = { query: mockQuery };

  beforeEach(() => {
    mockQuery.mockReset();
    fetchGithubRepoPrivacy.mockReset();
    resetSupportGithubRepoGateCacheForTests();
    delete process.env.SUPPORT_GITHUB_REPO;
  });

  it('blocks create-issue rows when repo is public', async () => {
    process.env.SUPPORT_GITHUB_REPO = 'AgathaTrack/AgathaTrack';
    fetchGithubRepoPrivacy.mockResolvedValue({ ok: false, reason: 'repo is not private' });
    mockQuery.mockResolvedValue({ rowCount: 2 });

    await refreshSupportGithubRepoGate(pool);

    expect(mockQuery).toHaveBeenCalledWith(
      expect.stringContaining(`status = 'blocked'`),
      ['repo is not private'],
    );
  });

  it('returns blocked rows to pending when repo is private', async () => {
    process.env.SUPPORT_GITHUB_REPO = 'owner/AgathaTrackPrivate';
    fetchGithubRepoPrivacy.mockResolvedValue({ ok: true, private: true });
    mockQuery.mockResolvedValue({ rowCount: 1 });

    await refreshSupportGithubRepoGate(pool);

    expect(mockQuery).toHaveBeenCalledWith(expect.stringContaining(`status = 'pending'`));
  });
});

describe('writeGithubIssueNumber', () => {
  it('queues redact when ticket is gone', async () => {
    const client = {
      query: jest
        .fn()
        .mockResolvedValueOnce({ rowCount: 0 })
        .mockResolvedValueOnce({ rowCount: 1 }),
    };
    const ticketId = uuidv4();
    const exists = await writeGithubIssueNumber(client, ticketId, 42);
    expect(exists).toBe(false);
    expect(client.query).toHaveBeenCalledTimes(2);
    expect(client.query.mock.calls[1][0]).toContain('github_issue_delete');
  });
});
