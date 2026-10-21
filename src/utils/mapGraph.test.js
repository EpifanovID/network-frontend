import assert from 'node:assert/strict';
import test from 'node:test';

import { buildMapEdges } from './mapGraph.js';

const nodes = [
    {
        id: 'line-1',
        lng: null,
        lat: null,
        data: { label: 'ЛС1', templateName: 'Линия связи МТХХ' },
    },
    {
        id: 'node-1',
        lng: 37.6,
        lat: 55.7,
        data: { label: 'УС1', templateName: 'Узел связи МТХХ' },
    },
    {
        id: 'node-2',
        lng: 30.3,
        lat: 59.9,
        data: { label: 'УС2', templateName: 'Узел связи МТХХ' },
    },
    {
        id: 'unlocated',
        lng: null,
        lat: null,
        data: { label: 'УС3', templateName: 'Узел связи МТХХ' },
    },
];

test('draws a line between located endpoints of a line SFE', () => {
    const edges = buildMapEdges(nodes, [
        { id: 'link-1', source: 'line-1', target: 'node-1', label: 'подключена к' },
        { id: 'link-2', source: 'line-1', target: 'node-2', label: 'подключена к' },
    ]);

    assert.equal(edges.length, 1);
    assert.deepEqual(edges[0], {
        id: 'map-line:line-1:0',
        lineId: 'line-1',
        source: 'node-1',
        target: 'node-2',
        label: 'ЛС1',
        relationLabel: 'подключена к',
        sourceLabel: 'УС1',
        targetLabel: 'УС2',
    });
});

test('does not draw incomplete lines or links to unlocated nodes', () => {
    const edges = buildMapEdges(nodes, [
        { id: 'link-1', source: 'line-1', target: 'node-1', label: 'подключена к' },
        { id: 'link-2', source: 'line-1', target: 'unlocated', label: 'подключена к' },
    ]);

    assert.deepEqual(edges, []);
});

test('preserves a direct edge when both endpoint nodes are located', () => {
    const edge = {
        id: 'direct',
        source: 'node-1',
        target: 'node-2',
        label: 'связаны',
    };

    assert.deepEqual(buildMapEdges(nodes, [edge]), [{
        ...edge,
        sourceLabel: 'УС1',
        targetLabel: 'УС2',
    }]);
});
