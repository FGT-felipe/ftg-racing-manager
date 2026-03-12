import fs from 'fs';
import path from 'path';

const searchDir = './src';

const replacements = [
  // Backgrounds
  { search: /bg-\[#121212\]/g, replace: 'bg-app-surface' },
  { search: /bg-\[#0A0A0B\]/g, replace: 'bg-app-bg' },
  { search: /bg-zinc-950(?!\/)/g, replace: 'bg-app-bg' },
  { search: /bg-zinc-950\/([0-9]+)/g, replace: 'bg-app-bg/$1' },
  { search: /bg-zinc-900(?!\/)/g, replace: 'bg-app-surface' },
  { search: /bg-zinc-900\/([0-9]+)/g, replace: 'bg-app-surface/$1' },
  { search: /bg-black(?!\/)/g, replace: 'bg-app-bg' }, // Black is almost always bg in this app
  { search: /bg-black\/([0-9]+)/g, replace: 'bg-app-text/$1' }, // opacity black on white? No, app-text is better
  
  // Text
  { search: /text-white(?!\/)/g, replace: 'text-app-text' },
  { search: /text-white\/([0-9]+)/g, replace: 'text-app-text/$1' },
  { search: /text-zinc-400(?!\/)/g, replace: 'text-app-text/60' },
  { search: /text-zinc-500(?!\/)/g, replace: 'text-app-text/40' },
  
  // Borders
  { search: /border-white\/([0-9]+)/g, replace: 'border-app-border' },
  { search: /border-zinc-800/g, replace: 'border-app-border' },
  { search: /border-zinc-900/g, replace: 'border-app-border' },
  { search: /border-app-border/g, replace: 'border-app-border' }, // redundancy check
];

// Special case: text-black on bg-app-primary should be text-app-primary-foreground
const specialCases = [
    { search: /bg-app-primary([^>]*?)text-black/g, replace: 'bg-app-primary$1text-app-primary-foreground' },
    { search: /text-black([^>]*?)bg-app-primary/g, replace: 'text-app-primary-foreground$1bg-app-primary' }
];

function walk(dir) {
  const files = fs.readdirSync(dir);
  files.forEach(file => {
    const filePath = path.join(dir, file);
    const stats = fs.statSync(filePath);
    if (stats.isDirectory()) {
      walk(filePath);
    } else if (file.endsWith('.svelte') || file.endsWith('.ts')) {
      let content = fs.readFileSync(filePath, 'utf8');
      let changed = false;
      
      replacements.forEach(({ search, replace }) => {
        if (search.test(content)) {
          content = content.replace(search, replace);
          changed = true;
        }
      });

      specialCases.forEach(({ search, replace }) => {
        if (search.test(content)) {
          content = content.replace(search, replace);
          changed = true;
        }
      });
      
      if (changed) {
        fs.writeFileSync(filePath, content, 'utf8');
        console.log(`Updated: ${filePath}`);
      }
    }
  });
}

walk(searchDir);
console.log('Done.');
