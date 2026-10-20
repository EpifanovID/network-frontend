import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import polygonClipping from 'polygon-clipping';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const outputPath = path.join(root, 'public', 'maps', 'military-districts.geojson');
import { boundaryDataUrls, districts } from './map-boundaries.mjs';

async function loadBoundaries(countryCode) {
    const response = await fetch(boundaryDataUrls[countryCode]);
    if (!response.ok) {
        throw new Error(`Could not download ${countryCode} administrative boundaries (HTTP ${response.status}).`);
    }
    const collection = await response.json();
    if (!Array.isArray(collection.features)) {
        throw new Error(`Invalid ${countryCode} administrative-boundary GeoJSON.`);
    }
    return collection.features;
}

const boundaryFeatures = {
    RUS: await loadBoundaries('RUS'),
    UKR: await loadBoundaries('UKR'),
};
const indexedFeatures = new Map();
for (const [countryCode, features] of Object.entries(boundaryFeatures)) {
    for (const feature of features) {
        const key = `${countryCode}:${feature.properties?.shapeName}`;
        if (!feature.geometry || indexedFeatures.has(key)) {
            throw new Error(`Missing or duplicate administrative boundary: ${key}`);
        }
        indexedFeatures.set(key, feature);
    }
}

const usedSubjects = new Set();
const outputFeatures = [];
for (const district of districts) {
    const geometries = district.subjects.map(([countryCode, subjectName]) => {
        const key = `${countryCode}:${subjectName}`;
        const feature = indexedFeatures.get(key);
        if (!feature) {
            throw new Error(`Boundary data does not contain ${key}.`);
        }
        if (usedSubjects.has(key)) {
            throw new Error(`Administrative unit assigned to more than one district: ${key}`);
        }
        usedSubjects.add(key);
        return feature.geometry.type === 'Polygon'
            ? [feature.geometry.coordinates]
            : feature.geometry.coordinates;
    });

    outputFeatures.push({
        type: 'Feature',
        properties: { kind: 'district', district: district.name },
        geometry: {
            type: 'MultiPolygon',
            coordinates: polygonClipping.union(...geometries),
        },
    });
    outputFeatures.push({
        type: 'Feature',
        properties: { kind: 'label', district: district.name },
        geometry: { type: 'Point', coordinates: district.anchor },
    });
}

const unassignedSubjects = [...indexedFeatures.keys()]
    .filter((key) => key.startsWith('RUS:') && !usedSubjects.has(key));
if (unassignedSubjects.length) {
    throw new Error(`Administrative units are not assigned to a district: ${unassignedSubjects.join(', ')}`);
}

await mkdir(path.dirname(outputPath), { recursive: true });
await writeFile(outputPath, `${JSON.stringify({
    type: 'FeatureCollection',
    features: outputFeatures,
})}\n`);
console.log(`Wrote five military district boundaries to ${outputPath}`);
