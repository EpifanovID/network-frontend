import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';
import { LIGHT, layers } from '@protomaps/basemaps';
import { districts } from '../../scripts/map-boundaries.mjs';
import { applyBoundaryVisibility, loadBoundaryData, prepareBasemapLayers } from './mapLayers.js';

test('basemap hides administrative borders and labels while retaining country borders', () => {
    for (const prefix of ['overview', 'detail']) {
        const prepared = prepareBasemapLayers(layers(prefix, LIGHT, { lang: 'ru' })
            .map((layer) => ({ ...layer, id: `${prefix}-${layer.id}` })));
        for (const id of ['boundaries', 'places_region']) {
            assert.equal(prepared.find((layer) => layer.id === `${prefix}-${id}`).layout.visibility, 'none');
        }
        assert.notEqual(prepared.find((layer) => layer.id === `${prefix}-boundaries_country`).layout?.visibility, 'none');
    }
});

test('switching every mode keeps overlays mutually exclusive including return to base', () => {
    const visibility = new Map();
    const map = { setLayoutProperty: (id, property, value) => {
        assert.equal(property, 'visibility');
        visibility.set(id, value);
    } };
    for (const mode of ['base', 'districts', 'regions', 'districts', 'base', 'loading']) {
        applyBoundaryVisibility(map, mode);
        assert.equal([...visibility.values()].filter((value) => value === 'visible').length,
            mode === 'base' ? 1 : mode === 'loading' ? 0 : 5);
        for (const [id, value] of visibility) {
            const expected = id.endsWith('boundaries_country')
                ? mode === 'districts' || mode === 'regions'
                : id === 'russia-outline' ? mode === 'base'
                    : mode === 'districts' ? id.startsWith('military')
                        : mode === 'regions' && id.startsWith('russia-regions');
            assert.equal(value === 'visible', expected, `${mode}: ${id}`);
        }
    }
});

test('country outline is a single dissolved multipolygon without district features', async () => {
    const collection = JSON.parse(await readFile(new URL('../../public/maps/russia-outline.geojson', import.meta.url), 'utf8'));
    assert.equal(collection.features.length, 1);
    const [outline] = collection.features;
    assert.equal(outline.geometry.type, 'MultiPolygon');
    assert.ok(outline.geometry.coordinates.length > 0);
    assert.equal(outline.properties.name, 'Российская Федерация');
});

test('boundary loading rejects missing files, HTML fallback and invalid GeoJSON', async (t) => {
    for (const response of [
        new Response('', { status: 404 }),
        new Response('<html>Vite fallback</html>'),
        Response.json({ type: 'FeatureCollection', features: [] }),
        Response.json({ type: 'FeatureCollection', features: [{ type: 'Feature', geometry: null }] }),
    ]) {
        t.mock.method(globalThis, 'fetch', async () => response);
        await assert.rejects(loadBoundaryData('/missing.geojson'));
        t.mock.restoreAll();
    }
});

test('boundary loader passes abort signal and accepts a valid collection', async (t) => {
    const data = { type: 'FeatureCollection', features: [{ type: 'Feature',
        geometry: { type: 'Point', coordinates: [38, 62] } }] };
    const controller = new AbortController();
    t.mock.method(globalThis, 'fetch', async (_url, { signal }) => {
        assert.equal(signal, controller.signal);
        signal.throwIfAborted();
        return Response.json(data);
    });
    assert.deepEqual(await loadBoundaryData('/boundaries.geojson', controller.signal), data);
    controller.abort();
    await assert.rejects(loadBoundaryData('/boundaries.geojson', controller.signal), { name: 'AbortError' });
});

test('generated regions match district membership exactly with explicit source metadata', async () => {
    const collection = JSON.parse(await readFile(new URL('../../public/maps/russia-regions.geojson', import.meta.url), 'utf8'));
    const expected = districts.flatMap((district) => district.subjects.map(([country, name]) => `${country}:${name}`));
    const actual = collection.features.map(({ properties: p }) => `${p.sourceCountry}:${p.sourceName}`);
    assert.deepEqual(actual.sort(), expected.sort());
    assert.equal(new Set(actual).size, actual.length);
    for (const { properties: p, geometry } of collection.features) {
        assert.equal(p.disputed, p.sourceCountry === 'UKR');
        assert.match(p.name, /[А-Яа-я]/);
        assert.ok(['Polygon', 'MultiPolygon'].includes(geometry.type));
    }
});
