// Loaded only by the migration subprocess in migration083.integration.test.js.
const instant = new Date(process.env.CARE_MIGRATION_TEST_CLOCK);
if (Number.isNaN(instant.getTime())) throw new Error('Invalid CARE_MIGRATION_TEST_CLOCK');

const NativeDate = Date;
globalThis.Date = class FixedMigrationDate extends NativeDate {
  constructor(...args) {
    super(...(args.length ? args : [instant.getTime()]));
  }

  static now() {
    return instant.getTime();
  }
};