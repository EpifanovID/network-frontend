import assert from 'node:assert/strict';
import test from 'node:test';
import { buildNetworkHighlight, emptyHighlight } from './networkHighlight.js';

function region(id, west) {
    return {
        properties: { shapeISO: id },
        geometry: { type: 'Polygon', coordinates: [[[west, 0], [west + 5, 0],
            [west + 5, 5], [west, 5], [west, 0]]] },
    };
}

function node(id, lng, nodeClass) {
    return { id, lng, lat: 1, data: { templateName: 'Узел связи', highlightProperties: { Класс: nodeClass } } };
}

test('combines matching nodes with explicitly selected lines and channels', () => {
    const objects = [
        node('west', 1, 'A'), node('east', 11, 'B'), node('remote', 21, 'A'), node('other', 31, 'C'),
        { id: 'line', data: { templateName: 'Линия связи' } },
        { id: 'route', data: { templateName: 'Линия связи' } },
        { id: 'channel', data: { templateName: 'Канал связи', highlightProperties: { Интерфейс: 'STM-4' } } },
    ];
    const relations = [
        { source: 'line', target: 'west' }, { source: 'line', target: 'east' },
        { source: 'route', target: 'channel' },
    ];
    const result = buildNetworkHighlight(objects, relations, { regions: [region('west', 0), region('east', 10)] }, {
        ...emptyHighlight, regions: ['west'], classes: ['A'], betweenRegions: ['east', 'west'], interfaces: ['STM-4'],
    });

    assert.deepEqual(result.nodes, new Set(['west', 'channel']));
    assert.deepEqual(result.lines, new Set(['line', 'route']));
});

test('selecting class A in a district or region excludes other classes, outlying nodes and territorial lines', () => {
    const objects = [node('inside-a', 1, 'A'), node('inside-b', 2, 'B'), node('outside-a', 11, 'A')];
    const relations = [{ id: 'inside-line', source: 'inside-a', target: 'inside-b' }];
    const area = region('east', 0);
    const boundaries = { regions: [area], districts: [{ ...area, properties: { district: 'east' } }] };

    for (const territory of ['districts', 'regions']) {
        const filters = { ...emptyHighlight, [territory]: ['east'] };
        assert.deepEqual(buildNetworkHighlight(objects, relations, boundaries, filters), {
            nodes: new Set(['inside-a', 'inside-b']), lines: new Set(['inside-line']),
        });
        assert.deepEqual(buildNetworkHighlight(objects, relations, boundaries, { ...filters, classes: ['A'] }), {
            nodes: new Set(['inside-a']), lines: new Set(),
        });
    }
    assert.deepEqual(buildNetworkHighlight(objects, relations, boundaries, { ...emptyHighlight, classes: ['A'] }), {
        nodes: new Set(['inside-a', 'outside-a']), lines: new Set(),
    });
});
