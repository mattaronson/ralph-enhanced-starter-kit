#!/usr/bin/env npx tsx
/**
 * build-content.ts — Markdown-to-HTML Article Builder
 *
 * Converts markdown files to fully SEO-ready static HTML pages using a
 * JSON config file as the single source of truth.
 *
 * Based on the production article builder from TheDecipherist.
 * https://github.com/TheDecipherist/claude-code-mastery
 *
 * FEATURES:
 * - Config-driven: one JSON file controls all articles
 * - Full SEO: Open Graph, Twitter Cards, Schema.org JSON-LD
 * - Sidebar TOC with scroll spy (opt-in per article)
 * - Parent/child article relationships
 * - Category and tag system
 * - published flag — unpublished articles are skipped
 * - Code block syntax highlighting (highlight.js)
 * - Markdown tables, lists, blockquotes, inline formatting
 *
 * USAGE:
 *   npx tsx scripts/build-content.ts                    # Build all published
 *   npx tsx scripts/build-content.ts --id getting-started # Build one article
 *   npx tsx scripts/build-content.ts --list             # List all articles
 *   npx tsx scripts/build-content.ts --dry-run          # Show what would build
 *
 * CONFIG:
 *   Edit scripts/content.config.json to add/modify articles.
 *   Each article needs: id, mdSource, htmlOutput, title, description, url
 */

import fs from 'node:fs';
import path from 'node:path';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface SidebarChild {
  title: string;
  url: string;
  group?: string;
}

interface ArticleConfig {
  id: string;
  published: boolean;
  mdSource: string;
  htmlOutput: string;
  title: string;
  titleHtml?: string;
  subtitle?: string;
  description: string;
  bannerImage?: string;
  bannerAlt?: string;
  url: string;
  datePublished: string;
  category?: string;
  tags?: string[];
  keywords?: string[];
  sidebar?: boolean;
  parent?: { title: string; url: string };
  children?: SidebarChild[];
  childrenLabel?: string;
  tocLevel?: number;
  tocFilter?: string;
  faqSchema?: Array<{ question: string; answer: string }>;
}

interface ContentConfig {
  siteUrl: string;
  siteName: string;
  author: string;
  outputDir: string;
  categories: string[];
  articles: ArticleConfig[];
}

interface CollectedHeading {
  level: number;
  id: string;
  text: string;
}

// ---------------------------------------------------------------------------
// Markdown Processing
// ---------------------------------------------------------------------------

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^\w\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
}

function stripMarkdown(text: string): string {
  return text
    .replace(/\*\*\*(.*?)\*\*\*/g, '$1')
    .replace(/\*\*(.*?)\*\*/g, '$1')
    .replace(/\*(.*?)\*/g, '$1')
    .replace(/`([^`]+)`/g, '$1')
    .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1');
}

function processInlineFormatting(text: string): string {
  let result = text;
  result = result.replace(/\*\*\*(.*?)\*\*\*/g, '<strong><em>$1</em></strong>');
  result = result.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
  result = result.replace(/\*(.*?)\*/g, '<em>$1</em>');
  result = result.replace(/`([^`]+)`/g, '<code>$1</code>');
  result = result.replace(/!\[([^\]]*)\]\(([^)]+)\)/g, '<img src="$2" alt="$1">');
  result = result.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>');
  result = result.replace(/ {2}$/gm, '<br>');
  return result;
}

function processMarkdownTables(html: string): string {
  const lines = html.split('\n');
  const result: string[] = [];
  let inTable = false;
  let tableRows: string[] = [];

  for (const line of lines) {
    const trimmed = line.trim();

    if (trimmed.startsWith('|') && trimmed.endsWith('|')) {
      if (!inTable) {
        inTable = true;
        tableRows = [];
      }
      if (!/^\|[\s\-:|]+\|$/.test(trimmed)) {
        tableRows.push(trimmed);
      }
    } else {
      if (inTable) {
        result.push(convertTableToHtml(tableRows));
        inTable = false;
        tableRows = [];
      }
      result.push(line);
    }
  }

  if (inTable && tableRows.length > 0) {
    result.push(convertTableToHtml(tableRows));
  }

  return result.join('\n');
}

function convertTableToHtml(rows: string[]): string {
  if (rows.length === 0) return '';
  let html = '<div class="table-wrapper">\n<table>\n';

  rows.forEach((row, idx) => {
    const cells = row.split('|').slice(1, -1);
    const tag = idx === 0 ? 'th' : 'td';
    html += '<tr>';
    for (const cell of cells) {
      let content = cell.trim();
      content = content.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
      content = content.replace(/\*(.*?)\*/g, '<em>$1</em>');
      html += `<${tag}>${content}</${tag}>`;
    }
    html += '</tr>\n';
  });

  html += '</table>\n</div>';
  return html;
}

function processLists(html: string): string {
  const lines = html.split('\n');
  const result: string[] = [];
  let inList = false;

  for (const line of lines) {
    const match = line.match(/^(\s*)- (.*)$/);
    if (match) {
      const content = processInlineFormatting(match[2]);
      if (!inList) {
        result.push('<ul>');
        inList = true;
      }
      result.push(`<li>${content}</li>`);
    } else {
      if (inList) {
        result.push('</ul>');
        inList = false;
      }
      result.push(line);
    }
  }

  if (inList) result.push('</ul>');
  return result.join('\n');
}

function processOrderedLists(html: string): string {
  const lines = html.split('\n');
  const result: string[] = [];
  let inList = false;

  for (const line of lines) {
    const match = line.match(/^\d+\.\s+(.*)$/);
    if (match) {
      if (!inList) {
        result.push('<ol>');
        inList = true;
      }
      result.push(`<li>${processInlineFormatting(match[1])}</li>`);
    } else {
      if (inList) {
        result.push('</ol>');
        inList = false;
      }
      result.push(line);
    }
  }

  if (inList) result.push('</ol>');
  return result.join('\n');
}

function convertMarkdownToHtml(md: string, headings: CollectedHeading[]): string {
  let html = md;

  // Code blocks first (preserve content)
  const codeBlocks: string[] = [];
  html = html.replace(/````(\w*)\n([\s\S]*?)````/g, (_match, lang: string, code: string) => {
    const placeholder = `___CODEBLOCK_${codeBlocks.length}___`;
    codeBlocks.push(`<pre><code class="language-${lang || 'plaintext'}">${escapeHtml(code.trim())}</code></pre>`);
    return placeholder;
  });
  html = html.replace(/```(\w*)\n([\s\S]*?)```/g, (_match, lang: string, code: string) => {
    const placeholder = `___CODEBLOCK_${codeBlocks.length}___`;
    codeBlocks.push(`<pre><code class="language-${lang || 'plaintext'}">${escapeHtml(code.trim())}</code></pre>`);
    return placeholder;
  });

  // Tables
  html = processMarkdownTables(html);

  // Blockquotes
  html = html.replace(/^>\s*(.*)$/gm, '<blockquote><p>$1</p></blockquote>');
  html = html.replace(/<\/blockquote>\n<blockquote>/g, '\n');

  // Headings (collect for sidebar TOC)
  html = html.replace(/^#### (.*)$/gm, (_m, text: string) => {
    const id = slugify(text);
    headings.push({ level: 4, id, text: stripMarkdown(text) });
    return `<h4 id="${id}">${processInlineFormatting(text)}</h4>`;
  });
  html = html.replace(/^### (.*)$/gm, (_m, text: string) => {
    const id = slugify(text);
    headings.push({ level: 3, id, text: stripMarkdown(text) });
    return `<h3 id="${id}">${processInlineFormatting(text)}</h3>`;
  });
  html = html.replace(/^## (.*)$/gm, (_m, text: string) => {
    const id = slugify(text);
    headings.push({ level: 2, id, text: stripMarkdown(text) });
    return `<h2 id="${id}">${processInlineFormatting(text)}</h2>`;
  });
  html = html.replace(/^# (.*)$/gm, (_m, text: string) => {
    const id = slugify(text);
    headings.push({ level: 1, id, text: stripMarkdown(text) });
    return `<h1 id="${id}">${processInlineFormatting(text)}</h1>`;
  });

  // Horizontal rules
  html = html.replace(/^---$/gm, '<hr>');

  // Lists
  html = processLists(html);
  html = processOrderedLists(html);

  // Remaining inline formatting
  html = html.replace(/\*\*\*(.*?)\*\*\*/g, '<strong><em>$1</em></strong>');
  html = html.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
  html = html.replace(/(?<!\*)\*([^*]+)\*(?!\*)/g, '<em>$1</em>');
  html = html.replace(/`([^`]+)`/g, '<code>$1</code>');
  html = html.replace(/!\[([^\]]*)\]\(([^)]+)\)/g, '<img src="$2" alt="$1">');
  html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>');

  // Paragraphs
  const blockTags = /^<(h[1-6]|ul|ol|li|blockquote|pre|div|table|tr|th|td|hr|nav|header|footer|article|section)/i;
  const rawLines = html.split('\n');
  const groups: Array<{ type: string; lines?: string[]; content?: string }> = [];
  let currentGroup: string[] = [];

  for (const line of rawLines) {
    const trimmed = line.trim();
    if (trimmed === '' || blockTags.test(trimmed) || trimmed.startsWith('___CODEBLOCK_')) {
      if (currentGroup.length > 0) {
        groups.push({ type: 'paragraph', lines: currentGroup });
        currentGroup = [];
      }
      if (trimmed !== '') {
        groups.push({ type: 'html', content: trimmed });
      }
    } else if (line.endsWith('  ')) {
      currentGroup.push(trimmed + '<br>');
    } else {
      currentGroup.push(trimmed);
    }
  }
  if (currentGroup.length > 0) {
    groups.push({ type: 'paragraph', lines: currentGroup });
  }

  const result: string[] = [];
  for (const group of groups) {
    if (group.type === 'html') {
      result.push(group.content!);
    } else if (group.type === 'paragraph' && group.lines) {
      result.push(`<p>${group.lines.join('\n')}</p>`);
    }
  }

  html = result.join('\n');

  // Restore code blocks
  codeBlocks.forEach((block, i) => {
    html = html.replace(`___CODEBLOCK_${i}___`, block);
  });

  html = html.replace(/<p><\/p>/g, '');
  html = html.replace(/\n{3,}/g, '\n\n');

  return html;
}

// ---------------------------------------------------------------------------
// SEO & Schema.org
// ---------------------------------------------------------------------------

function generateSchemaJson(article: ArticleConfig, config: ContentConfig): string {
  const schema: Record<string, unknown> = {
    '@context': 'https://schema.org',
    '@type': 'Article',
    headline: article.title,
    description: article.description,
    url: article.url,
    datePublished: article.datePublished,
    dateModified: article.datePublished,
    author: { '@type': 'Person', name: config.author, url: config.siteUrl },
    publisher: { '@type': 'Person', name: config.author },
    keywords: article.keywords ?? [],
    isPartOf: article.parent
      ? { '@type': 'Article', url: `${config.siteUrl}${article.parent.url}` }
      : { '@type': 'WebSite', name: config.siteName, url: config.siteUrl },
  };

  let block = `    <script type="application/ld+json">\n    ${JSON.stringify(schema, null, 4)}\n    </script>`;

  if (article.faqSchema && article.faqSchema.length > 0) {
    const faqSchema = {
      '@context': 'https://schema.org',
      '@type': 'FAQPage',
      mainEntity: article.faqSchema.map((faq) => ({
        '@type': 'Question',
        name: faq.question,
        acceptedAnswer: { '@type': 'Answer', text: faq.answer },
      })),
    };
    block += `\n    <script type="application/ld+json">\n    ${JSON.stringify(faqSchema, null, 4)}\n    </script>`;
  }

  return block;
}

// ---------------------------------------------------------------------------
// Sidebar
// ---------------------------------------------------------------------------

function generateSidebarHtml(article: ArticleConfig, headings: CollectedHeading[]): string {
  if (!article.sidebar) return '';

  const parts: string[] = [];

  if (article.parent) {
    parts.push(`        <a href="${article.parent.url}" class="sidebar-back">${article.parent.title}</a>`);
  }

  const maxLevel = article.tocLevel ?? (article.parent ? 2 : 1);
  let tocHeadings = headings.filter((h) => h.level <= maxLevel);
  if (article.tocFilter) {
    const re = new RegExp(article.tocFilter);
    tocHeadings = tocHeadings.filter((h) => re.test(h.text));
  }

  if (tocHeadings.length > 0) {
    parts.push('        <div class="sidebar-label">CONTENTS</div>');
    parts.push('        <ul class="sidebar-toc">');
    for (const h of tocHeadings) {
      const cls = h.level === 1 ? 'toc-h1' : 'toc-h2';
      parts.push(`            <li><a href="#${h.id}" class="${cls}">${h.text}</a></li>`);
    }
    parts.push('        </ul>');
  }

  if (article.children && article.children.length > 0) {
    const currentPath = '/' + article.htmlOutput.replace(/index\.html$/, '');
    const hasGroups = article.children.some((c) => c.group);

    if (hasGroups) {
      let listOpen = false;
      for (const child of article.children) {
        if (child.group) {
          if (listOpen) parts.push('        </ul>');
          parts.push(`        <div class="sidebar-label">${child.group}</div>`);
          parts.push('        <ul class="sidebar-links">');
          listOpen = true;
        }
        const isCurrent = child.url === currentPath;
        const cls = isCurrent ? ' class="sidebar-current"' : '';
        parts.push(`            <li><a href="${child.url}"${cls}>${child.title}</a></li>`);
      }
      if (listOpen) parts.push('        </ul>');
    } else {
      const label = article.childrenLabel ?? (article.parent ? 'RELATED' : 'DEEP DIVES');
      parts.push(`        <div class="sidebar-label">${label}</div>`);
      parts.push('        <ul class="sidebar-links">');
      for (const child of article.children) {
        const isCurrent = child.url === currentPath;
        const cls = isCurrent ? ' class="sidebar-current"' : '';
        parts.push(`            <li><a href="${child.url}"${cls}>${child.title}</a></li>`);
      }
      parts.push('        </ul>');
    }
  }

  return `    <aside class="article-sidebar" id="articleSidebar">
        <div class="sidebar-inner">
${parts.join('\n')}
        </div>
    </aside>`;
}

// ---------------------------------------------------------------------------
// HTML Page Generation
// ---------------------------------------------------------------------------

function buildArticle(article: ArticleConfig, config: ContentConfig): void {
  const markdown = fs.readFileSync(article.mdSource, 'utf8').replace(/\r\n/g, '\n').replace(/\r/g, '\n');

  const headings: CollectedHeading[] = [];

  // Remove first H1 (shown in header)
  const processedMd = markdown.replace(/^# .*\n+/, '');
  const articleContent = convertMarkdownToHtml(processedMd.trim(), headings);

  const sidebarHtml = generateSidebarHtml(article, headings);
  const hasSidebar = article.sidebar === true;

  const mainSection = hasSidebar
    ? `    <div class="article-layout">
${sidebarHtml}
        <main>
            <article class="article-content">
${articleContent}
            </article>
        </main>
    </div>
    <div class="sidebar-overlay" id="sidebarOverlay"></div>
    <button class="sidebar-toggle" id="sidebarToggle">Contents</button>`
    : `    <main>
        <article class="article-content">
${articleContent}
        </article>
    </main>`;

  const sidebarJs = hasSidebar
    ? `
        // Sidebar scroll spy
        (function() {
            var tocLinks = document.querySelectorAll('.sidebar-toc a');
            var headings = [];
            tocLinks.forEach(function(link) {
                var id = link.getAttribute('href').slice(1);
                var heading = document.getElementById(id);
                if (heading) headings.push({ el: heading, link: link });
            });
            if (headings.length > 0) {
                var observer = new IntersectionObserver(function(entries) {
                    entries.forEach(function(entry) {
                        if (entry.isIntersecting) {
                            tocLinks.forEach(function(l) { l.classList.remove('active'); });
                            var match = headings.find(function(h) { return h.el === entry.target; });
                            if (match) match.link.classList.add('active');
                        }
                    });
                }, { rootMargin: '-80px 0px -70% 0px' });
                headings.forEach(function(h) { observer.observe(h.el); });
            }
            var sidebar = document.getElementById('articleSidebar');
            var overlay = document.getElementById('sidebarOverlay');
            var toggle = document.getElementById('sidebarToggle');
            function openSidebar() { if (sidebar) sidebar.classList.add('open'); if (overlay) overlay.classList.add('open'); }
            function closeSidebar() { if (sidebar) sidebar.classList.remove('open'); if (overlay) overlay.classList.remove('open'); }
            if (toggle) toggle.addEventListener('click', openSidebar);
            if (overlay) overlay.addEventListener('click', closeSidebar);
            tocLinks.forEach(function(link) { link.addEventListener('click', closeSidebar); });
        })();`
    : '';

  const fullHtml = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${article.title} — ${config.siteName}</title>
    <meta name="description" content="${article.description}">
    <meta name="author" content="${config.author}">
    <meta name="robots" content="index, follow">
    <link rel="canonical" href="${article.url}">

    <!-- Open Graph / Facebook -->
    <meta property="og:type" content="article">
    <meta property="og:url" content="${article.url}">
    <meta property="og:title" content="${article.title} — ${config.siteName}">
    <meta property="og:description" content="${article.description}">
    ${article.bannerImage ? `<meta property="og:image" content="${config.siteUrl}${article.bannerImage}">` : ''}
    <meta property="og:site_name" content="${config.siteName}">

    <!-- Twitter -->
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="${article.title} — ${config.siteName}">
    <meta name="twitter:description" content="${article.description}">
    ${article.bannerImage ? `<meta name="twitter:image" content="${config.siteUrl}${article.bannerImage}">` : ''}

    <!-- Schema.org -->
${generateSchemaJson(article, config)}

    <!-- Syntax highlighting -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-dark.min.css">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>

    <!-- Add your CSS here -->
    <link rel="stylesheet" href="/css/global.css">
    <link rel="stylesheet" href="/css/article.css">
</head>
<body>
    <header>
        <h1>${article.titleHtml ?? article.title}</h1>
        ${article.subtitle ? `<p class="subtitle">${article.subtitle}</p>` : ''}
    </header>

    ${article.bannerImage ? `<div class="hero-banner" role="img" aria-label="${article.bannerAlt ?? article.title}" style="background-image: url('${article.bannerImage}')"></div>` : ''}

${mainSection}

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            document.querySelectorAll('pre code').forEach(function(block) {
                hljs.highlightElement(block);
            });
        });
${sidebarJs}
    </script>
</body>
</html>`;

  const outputDir = path.dirname(article.htmlOutput);
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  fs.writeFileSync(article.htmlOutput, fullHtml);
  const sizeKb = (fullHtml.length / 1024).toFixed(1);
  console.log(`  ✓ ${article.id} → ${article.htmlOutput} (${sizeKb} KB, ${headings.length} headings)`);
}

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

function main(): void {
  const args = process.argv.slice(2);
  const configPath = path.resolve(__dirname, 'content.config.json');

  if (!fs.existsSync(configPath)) {
    console.error(`Config not found: ${configPath}`);
    console.error('Create scripts/content.config.json first.');
    process.exit(1);
  }

  const config: ContentConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const published = config.articles.filter((a) => a.published);

  // --list
  if (args.includes('--list')) {
    console.log(`\n  ${config.articles.length} articles (${published.length} published):\n`);
    for (const a of config.articles) {
      const status = a.published ? '✓' : '○';
      console.log(`    ${status} ${a.id.padEnd(35)} ${a.category ?? ''}`);
    }
    console.log('');
    return;
  }

  // --dry-run
  if (args.includes('--dry-run')) {
    console.log(`\n  Would build ${published.length} articles:\n`);
    for (const a of published) {
      console.log(`    ${a.mdSource} → ${a.htmlOutput}`);
    }
    console.log('');
    return;
  }

  // --id <article-id>
  const idIdx = args.indexOf('--id');
  if (idIdx !== -1) {
    const targetId = args[idIdx + 1];
    const article = config.articles.find((a) => a.id === targetId);
    if (!article) {
      console.error(`Article not found: ${targetId}`);
      console.error('Run with --list to see available articles.');
      process.exit(1);
    }
    console.log(`\n  Building: ${article.id}\n`);
    buildArticle(article, config);
    console.log('\n  Done.\n');
    return;
  }

  // Default: build all published
  if (published.length === 0) {
    console.log('\n  No published articles to build.\n');
    return;
  }

  console.log(`\n  Building ${published.length} published article(s)...\n`);
  for (const article of published) {
    buildArticle(article, config);
  }
  console.log(`\n  Done. ${published.length} articles built.\n`);
}

main();
