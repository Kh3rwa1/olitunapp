import puppeteer from 'puppeteer';
(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  
  page.on('console', msg => console.log('PAGE LOG:', msg.text()));
  page.on('pageerror', error => console.log('PAGE ERROR:', error.message));
  page.on('requestfinished', req => console.log('FINISHED:', req.url()));
  page.on('requestfailed', req => console.log('FAILED:', req.url()));

  await page.goto('https://olitunapp.appwrite.network/', { waitUntil: 'networkidle0' });
  await new Promise(r => setTimeout(r, 8000));
  
  await browser.close();
})();
