import { normalizeInstagramUrl } from './shared.js';

const urlEl = document.getElementById('page-url');
const saveBtn = document.getElementById('save-btn');
const statusEl = document.getElementById('status');
const optionsLink = document.getElementById('options-link');

optionsLink.addEventListener('click', (e) => {
  e.preventDefault();
  chrome.runtime.openOptionsPage();
});

async function init() {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  const raw = tab?.url ?? '';
  const normalized = normalizeInstagramUrl(raw);

  if (normalized) {
    urlEl.textContent = normalized;
    saveBtn.disabled = false;
  } else {
    urlEl.textContent = 'Open a public Instagram post, reel, or TV page.';
    saveBtn.disabled = true;
    statusEl.textContent = 'This page cannot be saved.';
    statusEl.classList.add('error');
  }
}

saveBtn.addEventListener('click', () => {
  saveBtn.disabled = true;
  statusEl.textContent = 'Opening QuickSave…';
  statusEl.classList.remove('error');

  chrome.runtime.sendMessage({ type: 'SAVE_CURRENT_TAB' }, (response) => {
    saveBtn.disabled = false;
    if (chrome.runtime.lastError || !response?.ok) {
      statusEl.textContent = 'Could not open QuickSave dashboard.';
      statusEl.classList.add('error');
      return;
    }
    statusEl.textContent = 'Opened in new tab.';
    window.close();
  });
});

init();
