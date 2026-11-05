import { isItemClosed } from '../../item/itemStatus.js';
import { CareCommandError } from '../careCommandError.js';

/** @param {object} entry locked health_entries row */
export function assertItemOpen(entry) {
  if (isItemClosed(entry)) {
    throw new CareCommandError(409, 'care_item_closed', 'This care is closed');
  }
}
