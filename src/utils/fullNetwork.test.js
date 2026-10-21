import assert from 'node:assert/strict';
import test from 'node:test';
import { buildFullNetwork, getNetworkSelection } from './fullNetwork.js';

const node = (id, templateName) => ({ id, data: { label: id, templateName } });
const objects = [node('УС1', 'Узел связи'), node('УС2', 'Узел связи'),
    node('ЛС1', 'Линия связи'), node('ЛС2', 'Линия связи'), node('П1', 'Прибор'), node('Б1', 'Блок'), node('Одинокий', 'Прибор')];
const relations = [{ id: 'l1-a', source: 'ЛС1', target: 'УС1' }, { id: 'l1-b', source: 'ЛС1', target: 'УС2' },
    { id: 'l2-a', source: 'ЛС2', target: 'УС1' }, { id: 'l2-b', source: 'УС2', target: 'ЛС2' },
    { id: 'has-p', source: 'УС1', target: 'П1', label: 'состоит из' },
    { id: 'has-b', source: 'П1', target: 'Б1', label: 'состоит из' }];

test('full layout preserves all objects and relations with equipment below its node', () => {
    const before = structuredClone({ objects, relations });
    const graph = buildFullNetwork(objects, relations);
    assert.equal(graph.nodes.length, objects.length);
    assert.equal(graph.edges.length, relations.length);
    const nodes = new Map(graph.nodes.map((node) => [node.id, node]));
    assert.ok(nodes.get('ЛС1').position.y < nodes.get('УС1').position.y);
    assert.ok(nodes.get('П1').position.y > nodes.get('УС1').position.y);
    assert.ok(nodes.get('Б1').position.y > nodes.get('П1').position.y);
    assert.equal(nodes.get('ЛС1').data.endpointLabel, 'УС1 ↔ УС2');
    assert.deepEqual({ objects, relations }, before);
});

test('every line segment uses its own lane and endpoint port, including reversed links', () => {
    const graph = buildFullNetwork(objects, relations);
    const routed = graph.edges.filter((edge) => edge.lineId);
    assert.equal(new Set(routed.map((edge) => edge.data.laneY)).size, 4);
    for (const edge of routed) {
        assert.ok(graph.nodes.find((node) => node.id === edge.source).data.routePorts.some((port) => port.id === edge.sourceHandle));
        assert.ok(graph.nodes.find((node) => node.id === edge.target).data.routePorts.some((port) => port.id === edge.targetHandle));
    }
    const ports = graph.nodes.find((node) => node.id === 'УС1').data.routePorts;
    assert.equal(new Set(ports.map((port) => port.id)).size, ports.length);
});

test('selecting a line card or either segment highlights its entire route and both nodes', () => {
    const graph = buildFullNetwork(objects, relations);
    for (const passport of [{ type: 'node', nodeId: 'ЛС1' }, { type: 'edge', data: { id: 'l1-a' } }, { type: 'edge', data: { id: 'l1-b' } }]) {
        const selection = getNetworkSelection(graph, passport);
        assert.deepEqual([...selection.edgeIds].sort(), ['l1-a', 'l1-b']);
        assert.deepEqual([...selection.nodeIds].sort(), ['ЛС1', 'УС1', 'УС2'].sort());
    }
    assert.equal(getNetworkSelection(graph, null).edgeIds.size, 0);
});

test('cycles, incomplete lines and missing endpoints do not drop valid objects or hang layout', () => {
    const graph = buildFullNetwork(objects, [...relations, { id: 'cycle', source: 'Б1', target: 'П1' },
        { id: 'missing', source: 'ЛС1', target: 'missing' }]);
    assert.equal(graph.nodes.length, objects.length);
    assert.equal(graph.edges.length, relations.length + 1);
    assert.deepEqual(buildFullNetwork([], []), { nodes: [], edges: [] });
});
