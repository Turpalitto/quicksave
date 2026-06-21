const LOGIN_WALL_MARKERS = [
  '"Login required"',
  'This account is private',
  'accounts/login',
  'Page Not Found',
  '"login_required"',
  'loginForm',
  'login_page',
];

function classifyHttpStatus(status) {
  if (status === 404) return 'not_found';
  if (status === 401 || status === 403) return 'private';
  if (status === 429) return 'rate_limited';
  if (status >= 400) return 'resolver_failed';
  return 'resolver_failed';
}

function isNetworkError(err) {
  if (!err) return false;
  if (err.code === 'ECONNABORTED' || err.code === 'ETIMEDOUT') return true;
  return !err.response;
}

function isLoginWall(html, hasPlayableMedia) {
  if (!html) return false;
  if (hasPlayableMedia) return false;
  return LOGIN_WALL_MARKERS.some((m) => html.includes(m));
}

module.exports = {
  LOGIN_WALL_MARKERS,
  classifyHttpStatus,
  isNetworkError,
  isLoginWall,
};
