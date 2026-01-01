// Open vignette links in new tabs
// This script runs on page load and adds target="_blank" to article/vignette links

document.addEventListener('DOMContentLoaded', function() {
  // Select links that point to articles (vignettes)
  // Match both navbar links (../articles/*.html) and article index page links (*.html on /articles/ page)
  const articleLinks = document.querySelectorAll('a[href*="articles/"], a[href$="_broadcasting.html"], a[href$="_comprehensive.html"], a[href$="_analysis.html"], a[href$="_programming.html"], a[href$="telemetry.html"]');

  // Also check if we're on the articles index page and match all article links
  const isArticlesPage = window.location.pathname.includes('/articles/');
  if (isArticlesPage) {
    // On articles page, also select links in the main content that end in .html
    const mainContentLinks = document.querySelectorAll('main a[href$=".html"]');
    mainContentLinks.forEach(function(link) {
      // Skip non-article links (reference, index, etc.)
      if (link.href.includes('reference') || link.href.includes('index.html')) return;

      link.setAttribute('target', '_blank');
      link.setAttribute('rel', 'noopener noreferrer');

      if (!link.querySelector('.external-link-icon')) {
        const icon = document.createElement('span');
        icon.className = 'external-link-icon';
        icon.innerHTML = ' ↗';
        icon.style.fontSize = '0.8em';
        icon.style.opacity = '0.6';
        link.appendChild(icon);
      }
    });
    console.log('Articles page links configured to open in new tabs');
  }

  articleLinks.forEach(function(link) {
    // Add target="_blank" and rel="noopener noreferrer" for security
    link.setAttribute('target', '_blank');
    link.setAttribute('rel', 'noopener noreferrer');

    // Add a visual indicator (optional - small icon showing "opens in new tab")
    if (!link.querySelector('.external-link-icon')) {
      const icon = document.createElement('span');
      icon.className = 'external-link-icon';
      icon.innerHTML = ' ↗';
      icon.style.fontSize = '0.8em';
      icon.style.opacity = '0.6';
      link.appendChild(icon);
    }
  });

  console.log('Vignette links configured to open in new tabs:', articleLinks.length);
});
