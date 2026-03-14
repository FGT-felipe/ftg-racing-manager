import { error } from '@sveltejs/kit';
import fs from 'fs';
import path from 'path';

export const load = async () => {
    try {
        const docsPath = path.resolve('src/routes/admin/docs');
        const categories = ['human', 'ai'];
        const docsData: Record<string, Record<string, string>> = {
            human: {},
            ai: {}
        };

        for (const cat of categories) {
            const dirPath = path.join(docsPath, cat);
            if (fs.existsSync(dirPath)) {
                const files = fs.readdirSync(dirPath).filter(f => f.endsWith('.md'));
                for (const file of files) {
                    const content = fs.readFileSync(path.join(dirPath, file), 'utf-8');
                    const id = file.replace('.md', '');
                    docsData[cat][id] = content;
                }
            }
        }

        return {
            docsData
        };
    } catch (e: any) {
        console.error('Docs loading failed:', e.message || 'Unknown error');
        throw error(500, 'Could not load documentation files');
    }
};
