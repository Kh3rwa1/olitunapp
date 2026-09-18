// Runtime boot helpers externalized from index.html so they comply with the
// strict `script-src` CSP (no inline scripts). Loaded with `defer`.
(function() {
  'use strict';

  // Remove loading indicator cleanly when Flutter first frame renders
  window.addEventListener('flutter-first-frame', function() {
    var loader = document.getElementById('loading-indicator');
    if (loader) {
      loader.style.opacity = '0';
      setTimeout(function() { loader.remove(); }, 350);
    }
  });

  // Boot diagnostics: surface engine-load failures in the splash note so a
  // failed deploy never looks like an infinite spinner with no explanation.
  // Captures script errors (bootstrap, main.dart.js, CanvasKit) from the start.
  var bootErrors = [];
  function loaderPresent() {
    return !!document.getElementById('loading-indicator');
  }
  function reportBootStall() {
    if (!loaderPresent()) return;
    var notes = document.querySelectorAll('#loading-indicator .loading-note');
    var detail = bootErrors.length
      ? 'Error: ' + bootErrors[bootErrors.length - 1]
      : 'Engine has not signaled first frame yet.';
    for (var i = 0; i < notes.length; i++) {
      notes[i].textContent = 'Taking longer than usual. ' + detail;
    }
    var reloadBtn = document.getElementById('loading-reload-btn');
    if (reloadBtn) reloadBtn.style.display = 'inline-block';
  }
  function recordBootError(message) {
    if (!message) return;
    message = String(message).slice(0, 220);
    if (bootErrors.indexOf(message) === -1) {
      bootErrors.push(message);
      if (bootErrors.length > 3) bootErrors.shift();
    }
    reportBootStall();
  }
  window.addEventListener('error', function(event) {
    var msg = (event && (event.message || (event.error && event.error.message))) ||
      'A script failed to load.';
    var src = '';
    if (event && event.target && event.target !== window && event.target.src) {
      src = ' (' + String(event.target.src).split('/').pop() + ')';
    }
    recordBootError(msg + src);
  }, true);
  window.addEventListener('unhandledrejection', function(event) {
    var reason = event && event.reason;
    var msg = (reason && (reason.message || String(reason))) ||
      'Unhandled promise rejection.';
    recordBootError(msg);
  });

  // Safety fallback: if app takes >8s to boot, show reload button.
  // Offline, the button still works because the shell is cached by sw.js.
  setTimeout(function() {
    var reloadBtn = document.getElementById('loading-reload-btn');
    if (reloadBtn && document.getElementById('loading-indicator')) {
      reloadBtn.style.display = 'inline-block';
      reloadBtn.addEventListener('click', function() {
        window.location.reload();
      });
    }
  }, 8000);

  // Stalled-boot reporter: if the loader is still present, replace the
  // generic note with the captured error (or lack of first frame).
  setTimeout(reportBootStall, 12000);
  setTimeout(reportBootStall, 25000);

  // Live Offline / Online Detection
  function updateOnlineStatus() {
    var indicator = document.getElementById('offline-indicator');
    if (!indicator) return;
    if (navigator.onLine === false) {
      indicator.style.display = 'flex';
    } else {
      indicator.style.display = 'none';
    }
  }
  window.addEventListener('offline', updateOnlineStatus);
  window.addEventListener('online', updateOnlineStatus);
  if (!navigator.onLine) updateOnlineStatus();

  // Service Worker Update Listener
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.addEventListener('controllerchange', function() {
      // Automatically reload when new service worker takes control if requested
    });

    navigator.serviceWorker.ready.then(function(registration) {
      registration.addEventListener('updatefound', function() {
        var newWorker = registration.installing;
        if (!newWorker) return;
        newWorker.addEventListener('statechange', function() {
          if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
            var updateToast = document.getElementById('pwa-update-toast');
            var updateBtn = document.getElementById('pwa-update-btn');
            if (updateToast && updateBtn) {
              updateToast.style.display = 'flex';
              updateBtn.onclick = function() {
                newWorker.postMessage({ action: 'skipWaiting' });
                window.location.reload();
              };
            }
          }
        });
      });
    });
  }
})();
