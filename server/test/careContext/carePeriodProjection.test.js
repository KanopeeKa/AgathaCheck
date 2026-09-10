import { corpusCases } from './carePeriodProjectionCorpus.js';

describe('care-period projection corpus', () => {
  it.each(corpusCases.map((c) => [c.id, c]))('case %s', (_id, fixture) => {
    fixture.run();
  });

  expect(corpusCases.length).toBe(30);
});
