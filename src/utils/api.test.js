import assert from 'node:assert/strict';
import test from 'node:test';

import { readJsonResponse } from './api.js';

test('returns parsed JSON for a successful response', async () => {
    const result = await readJsonResponse(new Response(
        JSON.stringify({ nodes: [], edges: [] }),
        { headers: { 'Content-Type': 'application/json' } }
    ));
    assert.deepEqual(result, { nodes: [], edges: [] });
});

test('reports an empty API response with a server-start hint', async () => {
    await assert.rejects(
        readJsonResponse(new Response('', { status: 502 })),
        /API вернул пустой ответ.*npm run dev:api/i
    );
});

test('reports non-JSON responses without leaking an opaque parse error', async () => {
    await assert.rejects(
        readJsonResponse(new Response('<html>proxy error</html>', { status: 502 })),
        /API вернул некорректный ответ \(HTTP 502\)/
    );
});
