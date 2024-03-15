import { test, expect } from "@playwright/test";

test("search page exists", async ({ page }) => {
  await page.goto("./test/search.html");
});

test("search debug exists", async ({ page }) => {
  await page.goto("./test/search-debug.html");
});

test("manual search debug exists", async ({ page }) => {
  await page.goto(".test/search-manual-debug.html");
});

test("tests are successful", async ({ page }) => {
  await page.goto("./test/search.html");
  const result = page.locator(".complete");
  await result.waitFor();
  const classList = await result.getAttribute("class");
  expect(classList).toContain("success");
});
