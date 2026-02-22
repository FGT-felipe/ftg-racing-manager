const fs = require('fs');
const { execSync } = require('child_process');

function mergeArb(filename) {
    try {
        const commits = ['f38f657', 'acb856e', '2c171e7', '1b03d12'];
        let oldStr = '';
        for (const ref of commits) {
            try {
                const str = execSync(`git show ${ref}:lib/l10n/${filename}`, { stdio: 'pipe' }).toString();
                if (str.split('\n').length > 500) {
                    oldStr = str;
                    console.log(`Found good ${filename} at ${ref}`);
                    break;
                }
            } catch (e) { }
        }

        if (!oldStr) return console.log(`Could not find big version for ${filename}`);

        const oldJson = JSON.parse(oldStr);
        const currStr = fs.readFileSync(`lib/l10n/${filename}`, 'utf-8');
        const currJson = JSON.parse(currStr);

        const merged = { ...oldJson, ...currJson };
        fs.writeFileSync(`lib/l10n/${filename}`, JSON.stringify(merged, null, 2));
        console.log(`Successfully merged ${filename}`);
    } catch (e) {
        console.error(`Error merging ${filename}: ${e.message}`);
    }
}

mergeArb('app_en.arb');
mergeArb('app_es.arb');
