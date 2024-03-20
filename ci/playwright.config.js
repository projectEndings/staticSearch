import { defineConfig, devices } from "@playwright/test";

/**
 * @see https://playwright.dev/docs/test-configuration
 */
module.exports = defineConfig({
  testDir: "tests",
  outputDir: "test-results",
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: true,
  retries: 0,
  workers: 1,
  reporter: "list",
  use: {
    screenshot: {
      mode: "on",
      fullPage: true,
    },
    baseURL: "http://127.0.0.1:8080",
  },
  webServer: {
    command: "npx -y http-server ../",
    url: "http://127.0.0.1:8080",
    reuseExistingServer: false,
  },
  /* Configure projects for major browsers */
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
    // {
    //   name: "firefox",
    //   use: { ...devices["Desktop Firefox"] },
    // },

    // {
    //   name: "webkit",
    //   use: { ...devices["Desktop Safari"] },
    // },
  ],
});
