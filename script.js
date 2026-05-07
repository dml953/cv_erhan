// ===== NAVBAR SCROLL =====
const navbar = document.getElementById('navbar');
window.addEventListener('scroll', () => {
    navbar.classList.toggle('scrolled', window.scrollY > 50);
});

// ===== MOBILE NAV TOGGLE =====
const navToggle = document.getElementById('navToggle');
const navLinks = document.querySelector('.nav-links');

navToggle.addEventListener('click', () => {
    navToggle.classList.toggle('open');
    navLinks.classList.toggle('open');
});

navLinks.querySelectorAll('.nav-link').forEach(link => {
    link.addEventListener('click', () => {
        navToggle.classList.remove('open');
        navLinks.classList.remove('open');
    });
});

// ===== ACTIVE NAV LINK ON SCROLL =====
const sections = document.querySelectorAll('section[id]');
const navLinksList = document.querySelectorAll('.nav-link');

function updateActiveNav() {
    const scrollY = window.scrollY + 200;
    sections.forEach(section => {
        const top = section.offsetTop;
        const height = section.offsetHeight;
        const id = section.getAttribute('id');
        if (scrollY >= top && scrollY < top + height) {
            navLinksList.forEach(link => {
                link.classList.remove('active');
                if (link.getAttribute('href') === '#' + id) {
                    link.classList.add('active');
                }
            });
        }
    });
}
window.addEventListener('scroll', updateActiveNav);

// ===== SCROLL ANIMATIONS =====
function initScrollAnimations() {
    const elements = document.querySelectorAll('[data-aos], .value-card, .brasserie-card, .product-card');
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const delay = entry.target.dataset.delay || 0;
                setTimeout(() => {
                    entry.target.classList.add('visible');
                }, delay);
            }
        });
    }, { threshold: 0.15, rootMargin: '0px 0px -50px 0px' });

    elements.forEach(el => observer.observe(el));
}
initScrollAnimations();

// ===== FILTER TABS =====
const filterBtns = document.querySelectorAll('.filter-btn');
const productCards = document.querySelectorAll('.product-card');

filterBtns.forEach(btn => {
    btn.addEventListener('click', () => {
        filterBtns.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');

        const filter = btn.dataset.filter;

        productCards.forEach(card => {
            if (filter === 'all' || card.dataset.category === filter) {
                card.classList.remove('hidden');
                card.style.display = '';
                setTimeout(() => card.classList.add('visible'), 50);
            } else {
                card.classList.add('hidden');
                card.classList.remove('visible');
            }
        });
    });
});

// ===== PRODUCT MODAL =====
const productData = {
    blonde: {
        type: 'Bière',
        title: 'Bière Blonde',
        desc: 'Légère et rafraîchissante, notre bière blonde est un équilibre parfait entre douceur et amertume. Brassée avec des malts pâles sélectionnés et des houblons aromatiques des Hauts-de-France, elle offre des notes subtiles de céréales dorées et une touche florale délicate en fin de bouche.',
        volume: '25 cl',
        degree: '4°',
        aromas: 'Céréales, floral, miel',
        color: '#f4c542'
    },
    brune: {
        type: 'Bière',
        title: 'Bière Brune',
        desc: 'Riche et intense, notre bière brune révèle toute la profondeur des malts torréfiés. Des arômes enveloppants de chocolat noir et de caramel se mêlent à une légère pointe de café, offrant une expérience gustative complexe et satisfaisante.',
        volume: '25 cl',
        degree: '4°',
        aromas: 'Chocolat noir, caramel, café',
        color: '#5a2a0a'
    },
    ipa: {
        type: 'Bière',
        title: 'Indian Pale Ale',
        desc: 'Audacieuse et aromatique, notre IPA est une explosion de saveurs houblonnées. Brassée avec des houblons expressifs soigneusement sélectionnés, elle offre une amertume affirmée mais équilibrée, accompagnée d\'arômes vibrants d\'agrumes et de fruits tropicaux.',
        volume: '25 cl',
        degree: '4°',
        aromas: 'Agrumes, fruits tropicaux, pin',
        color: '#e8a030'
    },
    gin: {
        type: 'Spiritueux',
        title: 'Gin Artisanal',
        desc: 'Élaboré à partir de plantes aromatiques locales et d\'épices minutieusement sélectionnées, notre gin artisanal est une célébration du terroir des Hauts-de-France. Les notes fraîches de genièvre se marient harmonieusement aux zestes d\'agrumes pour une expérience aromatique unique.',
        volume: '80 cl',
        degree: '20°',
        aromas: 'Genièvre, agrumes, épices',
        color: '#5a8c9c'
    },
    whiskey: {
        type: 'Spiritueux',
        title: 'Whiskey',
        desc: 'Distillé avec patience et vieilli en fûts de chêne français, notre whiskey développe un caractère riche et complexe. Des notes chaleureuses de vanille et d\'épices douces se mêlent aux arômes de fruits secs, avec une pointe de tourbe subtile en finale.',
        volume: '80 cl',
        degree: '60°',
        aromas: 'Vanille, épices, tourbe',
        color: '#a05a20'
    }
};

function createBottleSVG(product, color) {
    if (product === 'gin') {
        return `<svg viewBox="0 0 200 280" width="160">
            <rect x="65" y="80" width="70" height="160" rx="5" fill="rgba(180,200,230,0.15)" stroke="rgba(200,220,240,0.3)" stroke-width="2"/>
            <rect x="85" y="20" width="30" height="65" rx="4" fill="rgba(180,200,230,0.15)" stroke="rgba(200,220,240,0.3)" stroke-width="1"/>
            <rect x="80" y="16" width="40" height="8" rx="4" fill="${color}"/>
            <rect x="72" y="130" width="56" height="60" rx="4" fill="#1a2a3a" stroke="${color}" stroke-width="1"/>
            <text x="100" y="155" text-anchor="middle" font-size="10" font-weight="bold" fill="#c0d8e8">GIN</text>
            <text x="100" y="170" text-anchor="middle" font-size="5" fill="#8ab0c0">ARTISANAL</text>
        </svg>`;
    }
    if (product === 'whiskey') {
        return `<svg viewBox="0 0 200 280" width="160">
            <rect x="60" y="70" width="80" height="170" rx="6" fill="#2a1a0a" stroke="#5a3a1a" stroke-width="2"/>
            <rect x="82" y="15" width="36" height="60" rx="5" fill="#2a1a0a" stroke="#5a3a1a" stroke-width="1"/>
            <rect x="78" y="12" width="44" height="8" rx="4" fill="${color}"/>
            <rect x="68" y="120" width="64" height="75" rx="4" fill="#f5e6c8" stroke="${color}" stroke-width="1"/>
            <text x="100" y="148" text-anchor="middle" font-size="7" font-weight="bold" fill="#2a1a0a">WHISKEY</text>
            <line x1="76" y1="155" x2="124" y2="155" stroke="${color}" stroke-width="0.5"/>
            <text x="100" y="168" text-anchor="middle" font-size="5" fill="#666">TERROIR & SAVOIRS</text>
        </svg>`;
    }
    const bottleColor = product === 'brune' ? '#1a0a00' : product === 'ipa' ? '#1a4a2a' : '#2a5a1a';
    const label = product === 'brune' ? 'BRUNE' : product === 'ipa' ? 'IPA' : 'BLONDE';
    return `<svg viewBox="0 0 200 280" width="160">
        <rect x="70" y="60" width="60" height="180" rx="8" fill="${bottleColor}" stroke="${color}" stroke-width="1"/>
        <rect x="85" y="10" width="30" height="55" rx="5" fill="${bottleColor}"/>
        <rect x="80" y="8" width="40" height="8" rx="4" fill="${color}"/>
        <rect x="75" y="120" width="50" height="70" rx="5" fill="#f5e6c8" stroke="${color}" stroke-width="1"/>
        <text x="100" y="148" text-anchor="middle" font-size="8" font-weight="bold" fill="${bottleColor}">${label}</text>
        <line x1="82" y1="155" x2="118" y2="155" stroke="${color}" stroke-width="0.5"/>
        <text x="100" y="168" text-anchor="middle" font-size="6" fill="#666">T&S</text>
    </svg>`;
}

function openModal(product) {
    const data = productData[product];
    if (!data) return;

    document.getElementById('modalType').textContent = data.type;
    document.getElementById('modalTitle').textContent = data.title;
    document.getElementById('modalDesc').textContent = data.desc;
    document.getElementById('modalVolume').textContent = data.volume;
    document.getElementById('modalDegree').textContent = data.degree;
    document.getElementById('modalAromas').textContent = data.aromas;
    document.getElementById('modalIllustration').innerHTML = createBottleSVG(product, data.color);
    document.getElementById('productModal').classList.add('active');
    document.body.style.overflow = 'hidden';
}

function closeModal() {
    document.getElementById('productModal').classList.remove('active');
    document.body.style.overflow = '';
}

document.getElementById('productModal').addEventListener('click', (e) => {
    if (e.target === e.currentTarget) closeModal();
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeModal();
});

// ===== CLICKABLE PRODUCT CARDS =====
document.querySelectorAll('.product-card.clickable').forEach(card => {
    card.addEventListener('click', (e) => {
        if (e.target.closest('.product-link')) return;
        const link = card.querySelector('.product-link');
        if (link) link.click();
    });
});

// ===== SMOOTH SCROLL FOR ALL ANCHOR LINKS =====
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            e.preventDefault();
            target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    });
});
