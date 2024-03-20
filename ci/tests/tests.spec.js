import { test, expect } from "@playwright/test";

test("search page exists", async ({ page }) => {
  const response = await page.goto("./test/search.html");
  expect(response.status()).toEqual(200);
});

test("search debug exists", async ({ page }) => {
  const response = await page.goto("./test/search-debug.html");
  expect(response.status()).toEqual(200);
});

test("manual search debug exists", async ({ page }) => {
  const response = await page.goto("./test/search-manual-debug.html");
  expect(response.status()).toEqual(200);
});

test("tests are successful", async ({ page }) => {
  await page.goto("./test/search.html");
  const result = page.locator(".complete");
  await result.waitFor();
  const classList = await result.getAttribute("class");
  expect(classList).toContain("success");
});
