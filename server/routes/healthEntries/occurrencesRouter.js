export {
  handleCommand,
  loadEntry,
  loadOccurrence,
  logOccurrenceAction,
} from './occurrenceHttpBridge.js';

import { registerOccurrenceCommandRoutes } from './occurrenceCommandRouter.js';
import { registerOccurrenceListRoutes } from './occurrenceListRouter.js';

/** Occurrence HTTP routes; command bridge and list wire live in sibling modules. */
export function registerOccurrenceRoutes(router, pool) {
  registerOccurrenceListRoutes(router, pool);
  registerOccurrenceCommandRoutes(router, pool);
}
