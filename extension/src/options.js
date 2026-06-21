import {
  DEFAULT_BACKEND_URL,
  DEFAULT_DASHBOARD_URL,
  loadSettings,
} from './shared.js';

const dashboardInput = document.getElementById('dashboard-url');
const backendModeSelect = document.getElementById('backend-mode');
const backendInput = document.getElementById('backend-url');
const saveBtn = document.getElementById('save');
const statusEl = document.getElementById('status');

async function init() {
  const settings = await loadSettings(chrome.storage.sync);
  dashboardInput.value = settings.dashboardUrl || DEFAULT_DASHBOARD_URL;
  backendModeSelect.value = settings.backendMode || 'hosted';
  backendInput.value = settings.backendUrl || DEFAULT_BACKEND_URL;
}

saveBtn.addEventListener('click', async () => {
  await chrome.storage.sync.set({
    dashboardUrl: dashboardInput.value.trim() || DEFAULT_DASHBOARD_URL,
    backendMode: backendModeSelect.value,
    backendUrl: backendInput.value.trim() || DEFAULT_BACKEND_URL,
  });
  statusEl.textContent = 'Settings saved.';
});

init();
