const fs = require('fs');

const analyzeOutput = fs.readFileSync('analyze_output6.txt', 'utf16le');
const lines = analyzeOutput.split('\n');

const fixes = new Map();

for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (
        line.includes("The expression doesn't evaluate to a function") ||
        line.includes("Extra positional arguments") ||
        line.includes("Too many positional arguments")
    ) {
        const match = line.match(/lib\\[^:]+\.dart:(\d+):(\d+)/);
        if (!match) continue;

        const file = match[0].split(':')[0];
        const lineNum = parseInt(match[1], 10) - 1;

        if (fs.existsSync(file)) {
            const fileLines = fs.readFileSync(file, 'utf8').split('\n');
            const dartLine = fileLines[lineNum];

            // Look specifically for l10n.something( or .of(context).something(
            const methodRegex1 = /l10n\.([a-zA-Z0-9_]+)\s*\(/;
            const methodRegex2 = /\.of\([^)]*\)\.([a-zA-Z0-9_]+)\s*\(/;

            let methodMatch = dartLine.match(methodRegex1);
            if (!methodMatch) methodMatch = dartLine.match(methodRegex2);

            // Fallback if the code spans multiple lines, e.g. "AppLocalizations.of(context)!. \n methodName("
            if (!methodMatch) {
                // try the line itself, ignoring 'of'
                const matches = [...dartLine.matchAll(/\.([a-zA-Z0-9_]+)\s*\(/g)];
                for (const m of matches) {
                    if (m[1] !== 'of' && m[1] !== 'toString' && m[1] !== 'map') {
                        methodMatch = m;
                        break;
                    }
                }
            }

            if (methodMatch) {
                const methodName = methodMatch[1];

                let afterParen = dartLine.substring(dartLine.indexOf(methodMatch[0]) + methodMatch[0].length);
                let pCount = 1;
                let commas = 0;
                let hasArgs = false;
                for (let j = 0; j < afterParen.length; j++) {
                    const char = afterParen[j];
                    if (char === '(') pCount++;
                    else if (char === ')') pCount--;
                    else if (char === ',' && pCount === 1) commas++;
                    else if (char.trim() !== '' && pCount === 1) {
                        hasArgs = true;
                    }
                    if (pCount === 0) break;
                }

                let args = 0;
                if (hasArgs) {
                    args = commas + 1;
                }

                if (args > 0) {
                    fixes.set(methodName, args);
                    console.log(`Fixed ${methodName} with ${args} arg(s) in ${file}`);
                }
            }
        }
    }
}

['app_en.arb', 'app_es.arb'].forEach(filename => {
    const json = JSON.parse(fs.readFileSync(`lib/l10n/${filename}`, 'utf8'));
    let changed = false;

    for (const [methodName, numArgs] of fixes.entries()) {
        if (json[methodName]) {
            let str = json[methodName].split('{')[0].trim();
            let placeholders = {};

            for (let j = 0; j < numArgs; j++) {
                str += ` {arg${j}}`;
                placeholders[`arg${j}`] = { type: "String" };
            }

            json[methodName] = str;
            json[`@${methodName}`] = { placeholders };
            changed = true;
        }
    }

    if (changed) {
        fs.writeFileSync(`lib/l10n/${filename}`, JSON.stringify(json, null, 2));
    }
});
