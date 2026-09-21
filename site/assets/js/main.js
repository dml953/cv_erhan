/* ═══════════════════════════════════════════════════════════════
   Portfolio — Erhan Dumlu
   Navigation mobile, surlignage de la section courante, envoi du
   formulaire de contact. Aucune bibliothèque externe.
   ═══════════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  /* ── Barre de navigation : ombre portée dès qu'on quitte le hero ── */
  var nav = document.querySelector('.site-nav');
  if (nav) {
    var onScroll = function () {
      nav.classList.toggle('is-scrolled', window.scrollY > 40);
    };
    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();
  }

  /* ── Menu burger (affiché sous 1050px) ──────────────────────── */
  var toggle = document.querySelector('.nav-toggle');
  var links  = document.getElementById('nav-links');

  if (toggle && links) {
    var setMenu = function (open) {
      links.classList.toggle('is-open', open);
      toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
    };

    toggle.addEventListener('click', function () {
      setMenu(toggle.getAttribute('aria-expanded') !== 'true');
    });

    // Un clic sur une entrée referme le panneau.
    links.addEventListener('click', function (e) {
      if (e.target.closest('a')) { setMenu(false); }
    });

    // Échap referme, et on remet le focus sur le bouton.
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && links.classList.contains('is-open')) {
        setMenu(false);
        toggle.focus();
      }
    });

    // Au retour en affichage bureau, le panneau ne doit pas rester ouvert.
    window.addEventListener('resize', function () {
      if (window.innerWidth > 1050) { setMenu(false); }
    });
  }

  /* ── Surlignage de l'entrée de menu correspondant à la section ── */
  var navLinks = Array.prototype.slice.call(
    document.querySelectorAll('#nav-links a[href^="#"]')
  );

  if (navLinks.length && 'IntersectionObserver' in window) {
    var byId = {};
    var sections = [];

    navLinks.forEach(function (link) {
      var id = link.getAttribute('href').slice(1);
      var section = document.getElementById(id);
      if (section) {
        byId[id] = link;
        sections.push(section);
      }
    });

    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) { return; }
        navLinks.forEach(function (l) { l.classList.remove('is-active'); });
        var active = byId[entry.target.id];
        if (active) { active.classList.add('is-active'); }
      });
    }, {
      // La section est « courante » quand elle occupe la bande centrale.
      rootMargin: '-45% 0px -45% 0px',
      threshold: 0
    });

    sections.forEach(function (s) { observer.observe(s); });
  }

  /* ── Formulaire de contact ──────────────────────────────────────
     Envoi en arrière-plan vers contact.php. Si le JS est indisponible
     ou l'envoi échoue, le formulaire reste un POST HTML classique.
     ──────────────────────────────────────────────────────────── */
  var form = document.getElementById('contact-form');

  if (form && window.fetch) {
    var status = document.getElementById('form-status');
    var submit = form.querySelector('button[type="submit"]');

    var say = function (message, ok) {
      if (!status) { return; }
      status.textContent = message;
      status.className = 'form-status ' + (ok ? 'is-ok' : 'is-err');
      status.hidden = false;
    };

    form.addEventListener('submit', function (e) {
      if (!form.checkValidity()) { return; }   // laisse le navigateur signaler
      e.preventDefault();

      var initialLabel = submit ? submit.textContent : '';
      if (submit) { submit.disabled = true; submit.textContent = 'ENVOI…'; }

      fetch(form.action, {
        method: 'POST',
        body: new FormData(form),
        headers: { 'Accept': 'application/json' }
      })
        .then(function (res) {
          return res.json().catch(function () {
            throw new Error('Réponse illisible du serveur.');
          });
        })
        .then(function (data) {
          if (data && data.ok) {
            form.reset();
            say(data.message || 'Message envoyé. Merci !', true);
          } else {
            say((data && data.message) || 'L’envoi a échoué.', false);
          }
        })
        .catch(function () {
          say(
            'Envoi impossible pour le moment. Écrivez-moi directement à ' +
            (form.dataset.fallbackEmail || 'mon adresse e-mail') + '.',
            false
          );
        })
        .then(function () {
          if (submit) { submit.disabled = false; submit.textContent = initialLabel; }
        });
    });
  }

  /* ── Année courante dans le pied de page ────────────────────── */
  var year = document.getElementById('current-year');
  if (year) { year.textContent = new Date().getFullYear(); }
})();
