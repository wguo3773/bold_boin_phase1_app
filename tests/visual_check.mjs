import { chromium } from "playwright";

const browser = await chromium.launch({
  headless: true,
  executablePath: "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
});
const page = await browser.newPage({ viewport: { width: 1440, height: 1000 }, deviceScaleFactor: 1 });
const errors = [];
page.on("console", (message) => {
  if (message.type() === "error") errors.push(message.text());
});
page.on("pageerror", (error) => errors.push(error.message));

await page.goto("http://127.0.0.1:3876", { waitUntil: "networkidle" });
await page.screenshot({ path: "results/app_run_simulation.png", fullPage: true });

await page.getByRole("button", { name: /Run comparison/ }).click();
await page.getByText(/Complete: 500 simulated trials per scenario/).waitFor({ timeout: 30000 });
await page.screenshot({ path: "results/app_after_run.png", fullPage: true });

await page.getByRole("tab", { name: "How to use" }).click();
await page.getByRole("heading", { name: "Beginner click guide" }).waitFor();
await page.screenshot({ path: "results/app_how_to_use.png", fullPage: true });

const desktopOverflow = await page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth);
if (desktopOverflow) throw new Error("Desktop layout has horizontal overflow.");

const mobile = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1 });
await mobile.goto("http://127.0.0.1:3876", { waitUntil: "networkidle" });
await mobile.screenshot({ path: "results/app_mobile.png", fullPage: true });
const mobileOverflow = await mobile.evaluate(() => document.documentElement.scrollWidth > window.innerWidth);
if (mobileOverflow) throw new Error("Mobile layout has horizontal overflow.");

const actionableErrors = errors.filter((message) => !message.includes("404"));
if (actionableErrors.length) {
  throw new Error(`Browser errors:\n${actionableErrors.join("\n")}`);
}

console.log("Visual and interaction checks passed.");
await browser.close();
