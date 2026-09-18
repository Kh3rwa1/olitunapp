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

  // --- Custom offline-first service worker (web/sw.js) ---
  // Flutter's flutter_service_worker.js is a deprecated stub that unregisters
  // itself, so offline only works once this worker controls the scope.
  // Registration is delayed until window load so the first paint (splash) is
  // never blocked on tablets / low-end iPhones.
  function showUpdateToast(registration) {
    var updateToast = document.getElementById('pwa-update-toast');
    var updateBtn = document.getElementById('pwa-update-btn');
    if (!updateToast || !updateBtn) return;
    if (updateToast.style.display === 'flex') return;
    updateToast.style.display = 'flex';
    updateBtn.onclick = function() {
      var worker = registration.waiting || registration.installing;
      if (worker) {
        try {
          worker.postMessage({ action: 'skipWaiting' });
        } catch (_) { /* older iOS: fall through to reload */ }
      }
      // Give skipWaiting a beat, then reload into the fresh shell.
      setTimeout(function() { window.location.reload(); }, 400);
    };
  }

  function trackUpdates(registration) {
    if (!registration) return;
    registration.addEventListener('updatefound', function() {
      var newWorker = registration.installing;
      if (!newWorker) return;
      newWorker.addEventListener('statechange', function() {
        if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
          showUpdateToast(registration);
        }
      });
    });
    // Handle the case where an update was installed while the page was closed.
    if (registration.waiting && navigator.serviceWorker.controller) {
      showUpdateToast(registration);
    }
  }

  function registerOfflineWorker() {
    if (!('serviceWorker' in navigator)) return;
    // file:// and some in-app webviews have no SW support scope — skip quietly.
    var isHttp = /^https?:$/.test(window.location.protocol);
    if (!isHttp) return;

    // Clean up any legacy Flutter stub so it can never evict our worker.
    // The stub unregisters itself on activate, but an already-installed copy
    // from an older deploy may still be registered under this scope.
    try {
      navigator.serviceWorker.getRegistrations().then(function(regs) {
        regs.forEach(function(r) {
          var script = (r.active && r.active.scriptURL) || '';
          if (script.indexOf('flutter_service_worker.js') !== -1) {
            r.unregister().catch(function() {});
          }
        });
      }).catch(function() {});
    } catch (_) {}

    window.addEventListener('load', function() {
      navigator.serviceWorker.register('sw.js', { scope: './' }).then(
        function(registration) {
          trackUpdates(registration);
          // Check for updates when the PWA returns to foreground — keeps
          // tablets that stay suspended for days from going stale.
          document.addEventListener('visibilitychange', function() {
            if (document.visibilityState === 'visible') {
              registration.update().catch(function() {});
            }
          });
        },
        function(err) {
          // Offline-first is best-effort: the app still boots online.
          if (window.console && console.warn) {
            console.warn('Olitun offline worker registration failed:', err);
          }
        },
      );

      // Reload once when the fresh worker takes control (standard UX).
      var reloaded = false;
      navigator.serviceWorker.addEventListener('controllerchange', function() {
        if (reloaded) return;
        reloaded = true;
        // Only auto-reload if the update toast isn't already asking the user.
        var toast = document.getElementById('pwa-update-toast');
        if (!toast || toast.style.display !== 'flex') {
          window.location.reload();
        }
      });
    });
  }

  registerOfflineWorker();
})();
