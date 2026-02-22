const fs = require('fs');

['app_en.arb', 'app_es.arb'].forEach(filename => {
    const fileContent = fs.readFileSync(`lib/l10n/${filename}`, 'utf8');
    let json = JSON.parse(fileContent);

    // Remove corrupted keys
    const newJson = {};
    for (const k in json) {
        if (k.indexOf('\x00') === -1 && k.indexOf('\r') === -1) {
            newJson[k] = json[k];
        }
    }

    // Read missing keys with utf16le
    const missingBuf = fs.readFileSync('missing_keys.txt');
    const missingKeys = missingBuf.toString('utf16le').split('\n').map(l => l.trim()).filter(Boolean);

    let added = 0;
    for (const k of missingKeys) {
        if (!newJson[k]) {
            let readable = k.replace(/([A-Z])/g, ' $1').trim();
            readable = readable.charAt(0).toUpperCase() + readable.slice(1);
            newJson[k] = readable;
            added++;
        }
    }

    fs.writeFileSync(`lib/l10n/${filename}`, JSON.stringify(newJson, null, 2));
    console.log(`Cleaned up and added ${added} valid keys to ${filename}`);
});
