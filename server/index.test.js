import assert from 'node:assert/strict';
import { mkdtemp, mkdir, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { after, before, test } from 'node:test';

import { createApp } from './index.js';

const sourceId = '10325016-e49f-45c1-bc49-ddce3fa476ae';

test('local server serves frontend routes, map byte ranges, and API on the same origin', async () => {
    const directory = await mkdtemp(path.join(os.tmpdir(), 'network-local-test-'));
    let localServer;
    try {
        await mkdir(path.join(directory, 'maps'));
        await writeFile(path.join(directory, 'index.html'), '<html>local application</html>');
        await writeFile(path.join(directory, 'maps', 'example.pmtiles'), '0123456789');
        localServer = createApp(pool, { staticDirectory: directory }).listen(0, '127.0.0.1');
        await new Promise((resolve) => localServer.once('listening', resolve));
        const origin = `http://127.0.0.1:${localServer.address().port}`;
        for (const route of ['/', `/objects/${sourceId}`, `/lines/${linkId}`]) {
            const response = await fetch(`${origin}${route}`);
            assert.equal(response.status, 200);
            assert.match(response.headers.get('content-type'), /text\/html/);
            assert.equal(await response.text(), '<html>local application</html>');
        }
        const head = await fetch(`${origin}/maps/example.pmtiles`, { method: 'HEAD' });
        assert.equal(head.status, 200);
        assert.equal(head.headers.get('content-length'), '10');
        const range = await fetch(`${origin}/maps/example.pmtiles`, { headers: { Range: 'bytes=2-5' } });
        assert.equal(range.status, 206);
        assert.equal(range.headers.get('content-range'), 'bytes 2-5/10');
        assert.equal(await range.text(), '2345');
        const graph = await fetch(`${origin}/api/graph`);
        assert.equal((await graph.json()).nodes[0].id, sourceId);
        const missingApi = await fetch(`${origin}/api/missing`);
        assert.equal(missingApi.status, 404);
        assert.equal((await missingApi.json()).error, 'API endpoint not found.');
        const missingMap = await fetch(`${origin}/maps/missing.pmtiles`);
        assert.equal(missingMap.status, 404);
        assert.doesNotMatch(await missingMap.text(), /local application/);
        assert.equal((await fetch(`${origin}/.env`)).status, 404);
    } finally {
        if (localServer) await new Promise((resolve) => localServer.close(resolve));
        await rm(directory, { recursive: true, force: true });
    }
});
const targetId = '20325016-e49f-45c1-bc49-ddce3fa476ae';
const linkId = '30325016-e49f-45c1-bc49-ddce3fa476ae';
const queries = [];
let server;
let baseUrl;

const pool = {
    async query(sql, values = []) {
        queries.push({ sql, values });
        if (sql.includes('INSERT INTO imc.network_node_locations')) {
            return {
                rows: [{
                    id: values[0],
                    lng: values[1],
                    lat: values[2],
                }],
            };
        }
        if (sql.includes('FROM imc.thematic_layers_sfe_linkings')) {
            return {
                rows: [{
                    id: linkId,
                    source: sourceId,
                    target: targetId,
                    label: 'Связь',
                }],
            };
        }
        return {
            rows: [
                {
                    id: sourceId,
                    lng: null,
                    lat: null,
                    label: 'Узел 1',
                    type: 'Узел связи',
                    templateName: 'Узел связи',
                    layerId: '40325016-e49f-45c1-bc49-ddce3fa476ae',
                    layerName: 'Срез',
                },
                {
                    id: targetId,
                    lng: 37.62,
                    lat: 55.75,
                    label: 'Узел 2',
                    type: 'Узел связи',
                    templateName: 'Узел связи',
                    layerId: '40325016-e49f-45c1-bc49-ddce3fa476ae',
                    layerName: 'Срез',
                },
            ],
        };
    },
};

before(async () => {
    server = createApp(pool).listen(0, '127.0.0.1');
    await new Promise((resolve) => server.once('listening', resolve));
    baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
    await new Promise((resolve, reject) => {
        server.close((error) => (error ? reject(error) : resolve()));
    });
});

test('returns graph nodes, direct links, and unlocated count', async () => {
    const response = await fetch(`${baseUrl}/api/graph`);
    const graph = await response.json();

    assert.equal(response.status, 200);
    assert.equal(graph.nodes.length, 2);
    assert.equal(graph.nodes[0].id, sourceId);
    assert.equal(graph.nodes[0].lng, null);
    assert.equal(graph.nodes[1].data.label, 'Узел 2');
    assert.equal(graph.edges[0].source, sourceId);
    assert.equal(graph.edges[0].target, targetId);
    assert.equal(graph.unlocatedCount, 1);
});

test('documents API endpoints at the root URL', async () => {
    const response = await fetch(`${baseUrl}/`);
    const info = await response.json();

    assert.equal(response.status, 200);
    assert.equal(info.endpoints.health, '/api/health');
    assert.match(info.frontend, /npm run dev/);
});

test('rejects invalid layer identifiers without querying the database', async () => {
    const queryCount = queries.length;
    const response = await fetch(`${baseUrl}/api/graph?layerId=not-a-uuid`);

    assert.equal(response.status, 400);
    assert.equal(queries.length, queryCount);
});

test('validates and persists map coordinates with parameterized SQL', async () => {
    const invalidResponse = await fetch(`${baseUrl}/api/nodes/${sourceId}/location`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ lng: 181, lat: 55 }),
    });
    assert.equal(invalidResponse.status, 400);

    const response = await fetch(`${baseUrl}/api/nodes/${sourceId}/location`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ lng: 37.62, lat: 55.75 }),
    });
    const saved = await response.json();
    const query = queries.at(-1);

    assert.equal(response.status, 200);
    assert.deepEqual(saved, { id: sourceId, lng: 37.62, lat: 55.75 });
    assert.deepEqual(query.values, [sourceId, 37.62, 55.75]);
    assert.match(query.sql, /WHERE id_sfe = \$1::uuid/);
});
