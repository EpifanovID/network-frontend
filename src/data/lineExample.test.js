import assert from 'node:assert/strict';
import test from 'node:test';
import { exampleRoute, getExamplePorts, lineExampleEdges, lineExampleNodes, relationKinds } from './lineExample.js';

test('example contains 20 uniquely identified objects and 27 valid, uniquely identified relations', () => {
    const nodes = new Set(lineExampleNodes.map((node) => node.id));
    const edges = new Set(lineExampleEdges.map((edge) => edge.id));
    assert.equal(nodes.size, 20);
    assert.equal(edges.size, 27);
    for (const edge of lineExampleEdges) {
        assert.ok(nodes.has(edge.source) && nodes.has(edge.target));
        assert.ok(relationKinds[edge.data.relation]);
        assert.ok(getExamplePorts(edge.source).some((port) => port.id === edge.sourceHandle));
        assert.ok(getExamplePorts(edge.target).some((port) => port.id === edge.targetHandle));
    }
});

test('declared channel route follows actual physical connections from port 1 to port 4', () => {
    const physical = lineExampleEdges.filter((edge) => edge.data.relation === 2);
    for (let index = 1; index < exampleRoute.length; index += 1) {
        const [a, b] = [exampleRoute[index - 1], exampleRoute[index]];
        assert.ok(physical.some((edge) => edge.source === a && edge.target === b || edge.source === b && edge.target === a), `${a} ↔ ${b}`);
    }
    const channel = lineExampleEdges.filter((edge) => edge.source === 'LS1-019');
    assert.equal(channel.find((edge) => edge.data.relation === 3).target, exampleRoute[0]);
    assert.equal(channel.find((edge) => edge.data.relation === 5).target, exampleRoute.at(-1));
    assert.deepEqual(channel.filter((edge) => edge.data.relation === 4).map((edge) => edge.target), exampleRoute.slice(1, -1));
    assert.equal(channel.find((edge) => edge.data.relation === 6).target, 'LS1-020');
});

test('channel overlay uses separate routing lanes and assumption metadata stays explicit', () => {
    const routes = lineExampleEdges.filter((edge) => Number.isFinite(edge.data.laneY));
    assert.equal(routes.length, 8);
    assert.equal(new Set(routes.map((edge) => edge.data.laneY)).size, routes.length);
    assert.equal(lineExampleNodes.find((node) => node.id === 'LS1-009').data.note.length > 0, true);
    assert.equal(lineExampleEdges.find((edge) => edge.source === 'LS1-018' && edge.target === 'LS1-013').data.assumption, true);
});
