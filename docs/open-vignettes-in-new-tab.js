// Open vignette links in new tabs
// This script runs on page load and adds target="_blank" to article/vignette links

document.addEventListener('DOMContentLoaded', function() {
  // Select all links that point to articles (vignettes)
  const articleLinks = document.querySelectorAll('a[href*="articles/"]');

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
