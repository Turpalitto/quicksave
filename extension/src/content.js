(function () {
  const BUTTON_ID = 'quicksave-floating-save';

  function currentPageUrl() {
    return window.location.href.split('?')[0];
  }

  function isEligiblePage() {
    const path = window.location.pathname;
    return (
      path.includes('/p/') ||
      path.includes('/reel/') ||
      path.includes('/tv/') ||
      path.includes('/reels/')
    );
  }

  function injectButton() {
    if (!isEligiblePage() || document.getElementById(BUTTON_ID)) return;

    const btn = document.createElement('button');
    btn.id = BUTTON_ID;
    btn.type = 'button';
    btn.title = 'Save to QuickSave';
    btn.setAttribute('aria-label', 'Save to QuickSave');
    btn.textContent = 'QuickSave';

    btn.addEventListener('click', () => {
      btn.disabled = true;
      chrome.runtime.sendMessage(
        { type: 'SAVE_URL', url: currentPageUrl() },
        () => {
          btn.disabled = false;
        },
      );
    });

    document.documentElement.appendChild(btn);
  }

  injectButton();

  const observer = new MutationObserver(() => {
    if (isEligiblePage() && !document.getElementById(BUTTON_ID)) {
      injectButton();
    }
  });
  observer.observe(document.documentElement, { childList: true, subtree: true });
})();
