// flutter_web_auth_2 callback handler. Externalized from auth.html so it
// complies with the strict `script-src` CSP (no inline scripts).
(function() {
  'use strict';

  var message = {
    'flutter-web-auth-2': window.location.href
  };

  if (window.opener) {
    window.opener.postMessage(message, window.location.origin);
    window.close();
  } else if (window.parent && window.parent !== window) {
    window.parent.postMessage(message, window.location.origin);
  } else {
    localStorage.setItem('flutter-web-auth-2', window.location.href);
    window.close();
  }
})();
