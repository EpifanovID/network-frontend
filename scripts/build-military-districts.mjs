import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import polygonClipping from 'polygon-clipping';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const outputPath = path.join(root, 'public', 'maps', 'military-districts.geojson');
const geoBoundariesRevision = '9469f09592ced973a3448cf66b6100b741b64c0d';
const boundaryDataUrls = {
    RUS: `https://media.githubusercontent.com/media/wmgeolab/geoBoundaries/${geoBoundariesRevision}/releaseData/gbOpen/RUS/ADM1/geoBoundaries-RUS-ADM1_simplified.geojson`,
    UKR: `https://media.githubusercontent.com/media/wmgeolab/geoBoundaries/${geoBoundariesRevision}/releaseData/gbOpen/UKR/ADM1/geoBoundaries-UKR-ADM1_simplified.geojson`,
};

const districts = [
    {
        name: 'Ленинградский военный округ',
        anchor: [38, 62],
        subjects: [
            ['RUS', 'Republic of Karelia'],
            ['RUS', 'Komi Republic'],
            ['RUS', 'Arkhangelsk Oblast'],
            ['RUS', 'Nenets Autonomous Okrug'],
            ['RUS', 'Vologda Oblast'],
            ['RUS', 'Kaliningrad'],
            ['RUS', 'Leningrad oblast'],
            ['RUS', 'Murmansk Oblast'],
            ['RUS', 'Novgorod Oblast'],
            ['RUS', 'Pskov Oblast'],
            ['RUS', 'Saint Petersburg'],
        ],
    },
    {
        name: 'Московский военный округ',
        anchor: [38, 54],
        subjects: [
            ['RUS', 'Belgorod Oblast'],
            ['RUS', 'Bryansk Oblast'],
            ['RUS', 'Vladimir Oblast'],
            ['RUS', 'Voronezh Oblast'],
            ['RUS', 'Ivanovo Oblast'],
            ['RUS', 'Kaluga Oblast'],
            ['RUS', 'Kostroma Oblast'],
            ['RUS', 'Kursk Oblast'],
            ['RUS', 'Lipetsk Oblast'],
            ['RUS', 'Moscow'],
            ['RUS', 'Moscow Oblast'],
            ['RUS', 'Oryol Oblast'],
            ['RUS', 'Ryazan Oblast'],
            ['RUS', 'Smolensk Oblast'],
            ['RUS', 'Tambov Oblast'],
            ['RUS', 'Tver Oblast'],
            ['RUS', 'Tula Oblast'],
            ['RUS', 'Yaroslavl Oblast'],
        ],
    },
    {
        name: 'Южный военный округ',
        anchor: [44, 46],
        subjects: [
            ['RUS', 'Adygea'],
            ['RUS', 'Astrakhan Oblast'],
            ['RUS', 'Chechnya'],
            ['RUS', 'Dagestan'],
            ['RUS', 'Ingushetia'],
            ['RUS', 'Kabardino-Balkaria'],
            ['RUS', 'Kalmykia'],
            ['RUS', 'Karachay-Cherkessia'],
            ['RUS', 'Krasnodar Krai'],
            ['RUS', 'North Ossetia–Alania'],
            ['RUS', 'Rostov Oblast'],
            ['RUS', 'Stavropol Krai'],
            ['RUS', 'Volgograd Oblast'],
            ['UKR', 'Autonomous Republic of Crimea'],
            ['UKR', 'Sevastopol'],
            ['UKR', 'Donetsk Oblast'],
            ['UKR', 'Luhansk Oblast'],
            ['UKR', 'Kherson Oblast'],
            ['UKR', 'Zaporizhia Oblast'],
        ],
    },
    {
        name: 'Центральный военный округ',
        anchor: [70, 55],
        subjects: [
            ['RUS', 'Altai Krai'],
            ['RUS', 'Altai Republic'],
            ['RUS', 'Bashkortostan'],
            ['RUS', 'Chelyabinsk Oblast'],
            ['RUS', 'Chuvashia'],
            ['RUS', 'Irkutsk Oblast'],
            ['RUS', 'Kemerovo Oblast'],
            ['RUS', 'Khakassia'],
            ['RUS', 'Khanty-Mansiysk Autonomous Okrug – Ugra'],
            ['RUS', 'Kirov Oblast'],
            ['RUS', 'Krasnoyarsk Krai'],
            ['RUS', 'Kurgan Oblast'],
            ['RUS', 'Mari El'],
            ['RUS', 'Republic of Mordovia'],
            ['RUS', 'Nizhny Novgorod Oblast'],
            ['RUS', 'Yamalo-Nenets Autonomous Okrug'],
            ['RUS', 'Novosibirsk Oblast'],
            ['RUS', 'Omsk Oblast'],
            ['RUS', 'Orenburg Oblast'],
            ['RUS', 'Penza Oblast'],
            ['RUS', 'Perm Krai'],
            ['RUS', 'Samara Oblast'],
            ['RUS', 'Saratov Oblast'],
            ['RUS', 'Sverdlovsk Oblast'],
            ['RUS', 'Tatarstan'],
            ['RUS', 'Tomsk Oblast'],
            ['RUS', 'Tuva'],
            ['RUS', 'Tyumen Oblast'],
            ['RUS', 'Udmurtia'],
            ['RUS', 'Ulyanovsk Oblast'],
        ],
    },
    {
        name: 'Восточный военный округ',
        anchor: [132, 56],
        subjects: [
            ['RUS', 'Amur Oblast'],
            ['RUS', 'Buryatia'],
            ['RUS', 'Chukotka Autonomous Okrug'],
            ['RUS', 'Jewish Autonomous Oblast'],
            ['RUS', 'Kamchatka Krai'],
            ['RUS', 'Khabarovsk Krai'],
            ['RUS', 'Magadan Oblast'],
            ['RUS', 'Primorsky Krai'],
            ['RUS', 'Sakha Republic'],
            ['RUS', 'Sakhalin Oblast'],
            ['RUS', 'Zabaykalsky Krai'],
        ],
    },
];

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
