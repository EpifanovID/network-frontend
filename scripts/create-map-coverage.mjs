import { writeFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

import dotenv from 'dotenv';
import pg from 'pg';

const radiusKm = 25;
const segmentCount = 48;
const latitudeMetersPerDegree = 110574;
const projectRoot = path.resolve(
    path.dirname(fileURLToPath(import.meta.url)),
    '..'
);
dotenv.config({ path: path.join(projectRoot, '.env') });

if (!process.env.DATABASE_URL) {
    throw new Error('DATABASE_URL is required to build detailed map coverage.');
}

const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
let locations;
try {
    await client.connect();
    const { rows } = await client.query(`
        SELECT longitude AS lng, latitude AS lat
        FROM imc.network_node_locations
        ORDER BY id_sfe
    `);
    locations = rows.map(({ lng, lat }) => ({
        lng: Number(lng),
        lat: Number(lat),
    }));
} finally {
    await client.end();
}

if (!locations.length) {
    throw new Error(
        'No map coordinates are saved in imc.network_node_locations. '
        + 'Assign SFE coordinates in the graph and rerun the map build.'
    );
}

const polygons = locations.map(({ lng, lat }) => {
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
const outputPath = path.resolve(process.argv[2] ?? 'network-map-coverage.geojson');
await writeFile(outputPath, `${JSON.stringify(coverage)}\n`, 'utf8');
console.log(`Created ${outputPath} with ${locations.length} coverage areas (${radiusKm} km radius).`);
