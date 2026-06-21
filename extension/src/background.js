import {
  buildDashboardResolveUrl,
  loadSettings,
  normalizeInstagramUrl,
} from './shared.js';

const MENU_ID = 'quicksave-save-link';

chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: MENU_ID,
    title: 'Save to QuickSave',
    contexts: ['link'],
    targetUrlPatterns: [
      '*://www.instagram.com/*',
      '*://instagram.com/*',
      '*://instagr.am/*',
    ],
  });
});

chrome.contextMenus.onClicked.addListener(async (info) => {
  if (info.menuItemId !== MENU_ID || !info.linkUrl) return;
  await openDashboardForUrl(info.linkUrl);
});

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (message?.type === 'SAVE_URL') {
    openDashboardForUrl(message.url)
      .then(() => sendResponse({ ok: true }))
      .catch((err) => sendResponse({ ok: false, error: String(err) }));
    return true;
  }
  if (message?.type === 'SAVE_CURRENT_TAB') {
    chrome.tabs.query({ active: true, currentWindow: true }, async (tabs) => {
      const tab = tabs[0];
      if (!tab?.url) {
        sendResponse({ ok: false, error: 'no_tab' });
        return;
      }
      try {
        await openDashboardForUrl(tab.url);
        sendResponse({ ok: true });
      } catch (err) {
        sendResponse({ ok: false, error: String(err) });
      }
    });
    return true;
  }
  return false;
});

/**
 * @param {string} rawUrl
 */
async function openDashboardForUrl(rawUrl) {
  const normalized = normalizeInstagramUrl(rawUrl);
  if (!normalized) {
    throw new Error('invalid_instagram_url');
  }
  const settings = await loadSettings(chrome.storage.sync);
  const target = buildDashboardResolveUrl(normalized, settings.dashboardUrl);
  await chrome.tabs.create({ url: target, active: true });
}
