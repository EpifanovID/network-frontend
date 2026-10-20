import { readFile, writeFile } from 'node:fs/promises';
import polygonClipping from 'polygon-clipping';

const sourceUrl = new URL('../public/maps/military-districts.geojson', import.meta.url);
const outputUrl = new URL('../public/maps/russia-outline.geojson', import.meta.url);
const collection = JSON.parse(await readFile(sourceUrl, 'utf8'));
const districts = collection.features.filter((feature) => feature.properties.kind === 'district');
if (districts.length !== 5) throw new Error('Expected five military district polygons');
const coordinates = polygonClipping.union(...districts.map(({ geometry }) => (
    geometry.type === 'Polygon' ? [geometry.coordinates] : geometry.coordinates
)));
await writeFile(outputUrl, `${JSON.stringify({
    type: 'FeatureCollection',
    boundaryConvention: 'Same territorial composition as military-districts.geojson and russia-regions.geojson, including disputed territories; not lines of control.',
    features: [{
        type: 'Feature',
        properties: { name: 'Российская Федерация' },
        geometry: { type: 'MultiPolygon', coordinates },
    }],
})}\n`);
console.log('Wrote country outline without internal district or regional borders.');
