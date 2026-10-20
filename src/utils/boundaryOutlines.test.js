import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';
import { polygonOutlineSegments, withBoundaryOutlines } from './boundaryOutlines.js';

test('removes dateline closing edges without joining across the missing edge', () => {
    for (const longitude of [-180, 180]) {
        const ring = [[longitude, 65], [longitude, 69], [longitude - Math.sign(longitude), 68], [longitude, 65]];
        assert.deepEqual(polygonOutlineSegments({ type: 'Polygon', coordinates: [ring] }),
            [[ring[1], ring[2], ring[3]]]);
    }
});

test('retains real coastline segments crossing or near the dateline and polygon holes', () => {
    const ring = [[179.9, 65], [180, 66], [179.9, 67], [179.9, 65]];
    const hole = [[179.92, 65.5], [179.95, 65.5], [179.94, 65.6], [179.92, 65.5]];
    assert.deepEqual(polygonOutlineSegments({ type: 'Polygon', coordinates: [ring, hole] }), [ring, hole]);
});

test('all three map datasets produce outlines without dateline seams and preserve fills', async () => {
    for (const name of ['military-districts', 'russia-regions', 'russia-outline']) {
        const original = JSON.parse(await readFile(new URL(`../../public/maps/${name}.geojson`, import.meta.url), 'utf8'));
        const snapshot = structuredClone(original);
        const result = withBoundaryOutlines(original);
        assert.deepEqual(original, snapshot, 'original geometry must stay unchanged');
        assert.deepEqual(result.features.slice(0, original.features.length), original.features);
        const outlines = result.features.slice(original.features.length);
        assert.ok(outlines.length > 0);
        for (const feature of outlines) {
            assert.equal(feature.geometry.type, 'MultiLineString');
            for (const line of feature.geometry.coordinates) {
                assert.ok(line.length >= 2);
                for (let i = 1; i < line.length; i += 1) {
                    const [a, b] = [line[i - 1], line[i]];
                    assert.ok(!(Math.abs(a[0]) === 180 && a[0] === b[0]), `${name}: dateline seam`);
                    assert.ok(Math.abs(a[0] - b[0]) <= 180, `${name}: cross-world segment`);
                }
            }
        }
    }
});
