import { test, expect } from '@playwright/test';
import { password, username, displayName } from './utils/demo-user';

/**
 * Regression guard for the auth-hydration race that flashed the sign-in UI on reload.
 *
 * Root cause (fixed in index.js / auth.context.js): initial auth state was
 * hardcoded `false` and only corrected by a post-mount effect. On the unprotected
 * home route the Header renders immediately from that state, so on reload it
 * painted its unauthenticated "Sign In" variant first, then flipped to the
 * authenticated account menu once user.tokens().get() resolved. That flip is the
 * flash. It was intermittent because it only showed when the token read lost the
 * race with first paint.
 *
 * The home page always *settles* into the authenticated view (even with the bug),
 * so asserting the final DOM proves nothing. We instead sample the DOM every
 * animation frame during hydration and record whether the "Sign In" link was ever
 * visible. A MutationObserver was tried first but never fired for React 18's async
 * root render; the rAF sampler reliably catches the transient frame. addInitScript
 * re-installs the sampler on every navigation, including reloads.
 *
 * Verified to FAIL on the pre-fix code (the sampler catches the flash on a
 * fraction of reloads) and PASS on the fix. Because the bug is a race that only
 * shows on some reloads, the loop count is set well above the observed cadence so
 * a regression is caught reliably rather than flakily.
 */

const RELOAD_COUNT = 20;

test('React - authenticated home page reloads without a sign-in flash', async ({ page }) => {
  // Sample every animation frame whether a visible "Sign In" link exists, and
  // latch the first time one is seen. Reinstalled on every navigation because
  // addInitScript runs before page scripts on each document.
  await page.addInitScript(() => {
    window.__signInFlashed = false;

    const sample = () => {
      const anchors = Array.from(document.querySelectorAll('a'));
      const hasSignIn = anchors.some((anchor) => anchor.textContent.trim() === 'Sign In');
      if (hasSignIn) {
        window.__signInFlashed = true;
      }
      requestAnimationFrame(sample);
    };
    requestAnimationFrame(sample);
  });

  // Log in via the embedded login modal (mirrors modal-login.spec.js). This lands
  // back on the home route showing the authenticated welcome message.
  await page.goto('https://localhost:8443/');
  await page.getByRole('link', { name: 'Sign In', exact: true }).click();

  await page.getByLabel('Username').fill(username);
  await page.getByLabel('Password').fill(password);
  await page.getByLabel('Password').press('Enter');

  await expect(page.getByText(`Welcome back, ${displayName}!`)).toBeVisible();

  for (let reloadIndex = 0; reloadIndex < RELOAD_COUNT; reloadIndex++) {
    // Clear the latch, then reload. The init script re-arms the sampler for the
    // fresh document before the app's own scripts run.
    await page.evaluate(() => {
      window.__signInFlashed = false;
    });
    await page.reload();

    // Wait for hydration to settle into the authenticated home view.
    await expect(page.getByText(`Welcome back, ${displayName}!`)).toBeVisible();

    // The unauthenticated "Sign In" link must never have been visible during
    // this reload's hydration, not even for a single frame.
    const flashed = await page.evaluate(() => window.__signInFlashed);
    expect(flashed, `Reload #${reloadIndex + 1} flashed the sign-in link`).toBe(false);
  }
});
