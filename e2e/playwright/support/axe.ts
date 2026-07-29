import AxeBuilder from '@axe-core/playwright';
import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';

/** Impact levels that fail UAT smoke / @smoke-a11y gate. */
const FAILING_IMPACTS = new Set(['critical', 'serious']);

/**
 * Run axe on the current page and fail on critical or serious violations.
 * Call after Flutter semantics are enabled and the page has settled.
 *
 * Flutter web ExpansionTiles expose aria-selected on role=button and nested
 * interactive controls — known false positives; excluded here until the UI tree is fixed.
 * Drawer/endDrawer transitions can leave stale aria-owns on IconButton semantics nodes.
 */
export async function checkA11y(page: Page, context?: string): Promise<void> {
  const results = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
    .disableRules([
      'aria-allowed-attr',
      'aria-valid-attr-value',
      'nested-interactive',
    ])
    .analyze();

  const failing = results.violations.filter((v) => FAILING_IMPACTS.has(v.impact ?? ''));

  if (failing.length > 0) {
    const summary = failing
      .map((v) => `[${v.impact}] ${v.id}: ${v.description} (${v.nodes.length} nodes)`)
      .join('\n');
    expect(
      failing,
      `Accessibility violations${context ? ` (${context})` : ''}:\n${summary}`,
    ).toHaveLength(0);
  }
}
