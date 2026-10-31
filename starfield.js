  // Generate lightweight starfield
  const starsContainer = document.getElementById('stars');
  const STAR_COUNT = 60;
  for (let i = 0; i < STAR_COUNT; i++) {
    const s = document.createElement('div');
    s.className = 'star';
    s.style.left = Math.random() * 100 + '%';
    s.style.top = Math.random() * 70 + '%';
    s.style.animationDelay = (Math.random() * 4) + 's';
    s.style.opacity = (0.2 + Math.random() * 0.6).toFixed(2);
    const size = Math.random() < 0.85 ? 1.5 : 2.5;
    s.style.width = size + 'px';
    s.style.height = size + 'px';
    starsContainer.appendChild(s);
  }
