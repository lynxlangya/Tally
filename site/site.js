/* Tally site — tiny vanilla helpers. No tracking, no dependencies. */
(function () {
  'use strict';

  // ---- theme (persisted, respects system on first visit) ----------------
  var root = document.documentElement;
  var KEY = 'tally-theme';
  function apply(t) {
    root.setAttribute('data-theme', t);
    try { localStorage.setItem(KEY, t); } catch (e) {}
    document.querySelectorAll('[data-theme-icon]').forEach(function (el) {
      el.querySelector('.ic-sun').style.display = t === 'dark' ? 'block' : 'none';
      el.querySelector('.ic-moon').style.display = t === 'dark' ? 'none' : 'block';
    });
  }
  var saved;
  try { saved = localStorage.getItem(KEY); } catch (e) {}
  if (!saved) saved = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  apply(saved);

  document.addEventListener('click', function (e) {
    var t = e.target.closest('[data-theme-toggle]');
    if (t) {
      apply(root.getAttribute('data-theme') === 'dark' ? 'light' : 'dark');
      return;
    }
    var nt = e.target.closest('[data-nav-toggle]');
    if (nt) {
      var links = document.querySelector('.nav-links');
      if (links) links.classList.toggle('open');
      return;
    }
    // close mobile menu when a link is tapped
    if (e.target.closest('.nav-links a')) {
      var l = document.querySelector('.nav-links');
      if (l) l.classList.remove('open');
    }
  });

  // ---- FAQ accordion: animate height, single-open optional -------------
  document.querySelectorAll('.faq-item').forEach(function (item) {
    var q = item.querySelector('.faq-q');
    var a = item.querySelector('.faq-a');
    if (!q || !a) return;
    var inner = a.querySelector('.faq-a-inner');
    a.style.height = '0px';
    a.style.transition = 'height 280ms cubic-bezier(0.16,1,0.3,1)';
    q.addEventListener('click', function (ev) {
      ev.preventDefault();
      var isOpen = item.hasAttribute('open');
      if (isOpen) {
        a.style.height = inner.offsetHeight + 'px';
        requestAnimationFrame(function () { a.style.height = '0px'; });
        a.addEventListener('transitionend', function te() { item.removeAttribute('open'); a.removeEventListener('transitionend', te); });
      } else {
        item.setAttribute('open', '');
        a.style.height = inner.offsetHeight + 'px';
        a.addEventListener('transitionend', function te() { if (item.hasAttribute('open')) a.style.height = 'auto'; a.removeEventListener('transitionend', te); });
      }
    });
  });
  window.addEventListener('resize', function () {
    document.querySelectorAll('.faq-item[open] .faq-a').forEach(function (a) { a.style.height = 'auto'; });
  });

  // ---- footer year ------------------------------------------------------
  document.querySelectorAll('[data-year]').forEach(function (el) { el.textContent = new Date().getFullYear(); });
})();
