import assert from 'node:assert/strict';
import test from 'node:test';

import { buildObjectSubtree } from './objectTree.js';

const nodes = [
    { id: 'root', data: { label: 'Корень' } },
    { id: 'child', data: { label: 'Потомок' } },
    { id: 'grandchild', data: { label: 'Вложенный потомок' } },
    { id: 'unrelated', data: { label: 'Несвязанный узел' } },
];

test('builds a directed subtree rooted at the selected object', () => {
    const tree = buildObjectSubtree(nodes, [
        { id: 'root-child', source: 'root', target: 'child', label: 'содержит' },
        { id: 'child-grandchild', source: 'child', target: 'grandchild', label: 'содержит' },
        { id: 'unrelated-link', source: 'unrelated', target: 'root' },
    ], 'root');

    assert.deepEqual(tree.nodes.map((node) => node.id), [
        'root',
        'child',
        'grandchild',
    ]);
    assert.deepEqual(tree.edges.map(({ source, target }) => [source, target]), [
        ['root', 'child'],
        ['child', 'grandchild'],
    ]);
});

test('does not duplicate nodes when relations contain cycles or multiple parents', () => {
    const tree = buildObjectSubtree(nodes, [
        { id: 'root-child', source: 'root', target: 'child' },
        { id: 'root-grandchild', source: 'root', target: 'grandchild' },
        { id: 'child-grandchild', source: 'child', target: 'grandchild' },
        { id: 'child-root', source: 'child', target: 'root' },
    ], 'root');

    assert.deepEqual(tree.nodes.map((node) => node.id), [
        'root',
        'child',
        'grandchild',
    ]);
    assert.equal(tree.edges.length, 2);
});

test('returns empty hierarchy when the selected root is missing', () => {
    assert.deepEqual(buildObjectSubtree(nodes, [], 'missing'), {
        nodes: [],
        edges: [],
    });
});
