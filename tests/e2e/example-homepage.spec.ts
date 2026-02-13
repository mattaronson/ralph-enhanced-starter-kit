/**
 * Example E2E Test — Homepage
 *
 * This is a reference test showing the CORRECT pattern.
 * Every test has explicit success criteria:
 *   ✅ URL verification
 *   ✅ Element visibility
 *   ✅ Content/data verification
 *   ✅ Error state coverage
 *
 * Replace this with real tests for your project.
 */

import { test, expect } from '@playwright/test';

test.describe('Homepage', () => {
  test.describe('happy path', () => {
    test('should load with correct title and navigation', async ({ page }) => {
      await page.goto('/');

      // ✅ URL verification
      await expect(page).toHaveURL('/');

      // ✅ Element visibility — key UI elements present
      await expect(page.locator('h1')).toBeVisible();
      await expect(page.locator('nav')).toBeVisible();

      // ✅ Content verification — correct text displayed
      await expect(page).toHaveTitle(/My Project/);
      await expect(page.locator('h1')).toContainText('Welcome');
    });

    test('should navigate to about page from nav link', async ({ page }) => {
      await page.goto('/');
      await page.click('a[href="/about"]');

      // ✅ URL changed correctly
      await expect(page).toHaveURL('/about');

      // ✅ About page content loaded
      await expect(page.locator('h1')).toContainText('About');
    });
  });

  test.describe('error handling', () => {
    test('should show 404 page for unknown routes', async ({ page }) => {
      const response = await page.goto('/this-page-does-not-exist');

      // ✅ Correct status code
      expect(response?.status()).toBe(404);

      // ✅ Error page visible with helpful message
      await expect(page.locator('h1')).toContainText('Not Found');
      await expect(page.locator('a[href="/"]')).toBeVisible();
    });
  });

  test.describe('responsive behavior', () => {
    test('should show mobile menu on small screens', async ({ page }) => {
      await page.setViewportSize({ width: 375, height: 667 });
      await page.goto('/');

      // ✅ Desktop nav hidden
      await expect(page.locator('nav.desktop-nav')).not.toBeVisible();

      // ✅ Mobile menu button visible
      await expect(page.locator('button.menu-toggle')).toBeVisible();
    });
  });
});
