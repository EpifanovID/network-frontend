import { writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';

import { initialNodes } from '../src/data/networkData.js';

const radiusKm = 25;
const segmentCount = 48;
const latitudeMetersPerDegree = 110574;
const polygons = initialNodes.map(({ lng, lat }) => {
    const latitudeRadius = (radiusKm * 1000) / latitudeMetersPerDegree;
    const longitudeRadius = latitudeRadius / Math.cos((lat * Math.PI) / 180);
    const ring = Array.from({ length: segmentCount + 1 }, (_, index) => {
        const angle = (index / segmentCount) * 2 * Math.PI;
        return [
            lng + Math.cos(angle) * longitudeRadius,
            lat + Math.sin(angle) * latitudeRadius,
        ];
    });

    ring[segmentCount] = ring[0];
    return [ring];
});

const coverage = {
    type: 'FeatureCollection',
    features: [{
        type: 'Feature',
        properties: {},
        geometry: {
            type: 'MultiPolygon',
            coordinates: polygons,
        },
    }],
};
const outputPath = resolve(process.argv[2] ?? 'network-map-coverage.geojson');
await writeFile(outputPath, `${JSON.stringify(coverage)}\n`, 'utf8');
console.log(`Created ${outputPath} with ${initialNodes.length} coverage areas (${radiusKm} km radius).`);
