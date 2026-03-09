const https = require('https');

const url = 'https://firestore.googleapis.com/v1/projects/ftg-racing-manager/databases/(default)/documents/races?pageSize=50&key=YOUR_API_KEY';

https.get(url, (res) => {
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
        try {
            const json = JSON.parse(data);
            console.log('Got', json.documents?.length || 0, 'races.');

            const docs = json.documents || [];
            for (const d of docs) {
                const id = d.name.split('/').pop();
                const fields = d.fields || {};

                const status = fields.status?.stringValue;
                const seasonId = fields.seasonId?.stringValue;
                const eventId = fields.raceEventId?.stringValue;

                // Check for qualyGrid or qualifyingResults
                const hasQG = !!fields.qualyGrid;
                const hasQR = !!fields.qualifyingResults;

                const qgLen = fields.qualyGrid?.arrayValue?.values?.length || 0;
                const qrLen = fields.qualifyingResults?.arrayValue?.values?.length || 0;

                console.log(`Race ID: ${id} | status: ${status} | sId: ${seasonId} | eId: ${eventId} | hasQG: ${hasQG} (len=${qgLen}) | hasQR: ${hasQR} (len=${qrLen})`);

                if (hasQG || hasQR) {
                    console.log(`  Sample object keys:`);
                    const array = fields.qualyGrid || fields.qualifyingResults;
                    const first = array.arrayValue.values[0];
                    if (first && first.mapValue && first.mapValue.fields) {
                        console.log(`    ${Object.keys(first.mapValue.fields).join(', ')}`);
                    }
                }
            }
        } catch (e) {
            console.error(e.message);
        }
    });
}).on('error', (e) => {
    console.error(e);
});
