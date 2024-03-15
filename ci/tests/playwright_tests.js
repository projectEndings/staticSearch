import { test, expect } from "@playwright/test";

test("tests are successful", async ({ page }) => {
  await page.goto("./staticSearch/search.html");
  const result = page.locator(".complete");
  await result.waitFor();
  const classList = await result.getAttribute("class");
  expect(classList).toContain("success");
});
