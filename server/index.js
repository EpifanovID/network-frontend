import 'dotenv/config';

import express from 'express';
import path from 'node:path';
import process from 'node:process';
import { pathToFileURL } from 'node:url';
import pg from 'pg';

const { Pool } = pg;
const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export function createApp(pool) {
    const app = express();
    app.disable('x-powered-by');
    app.use(express.json({ limit: '16kb' }));

    app.get('/', (_request, response) => {
        response.json({
            service: 'network-frontend graph API',
            endpoints: {
                health: '/api/health',
                graph: '/api/graph',
                updateNodeLocation: 'PUT /api/nodes/:id/location',
            },
            frontend: 'Start the Vite app separately with npm run dev.',
        });
    });

    app.get('/api/health', async (_request, response, next) => {
        try {
            await pool.query('SELECT 1');
            response.json({ status: 'ok', database: 'connected' });
        } catch (error) {
            next(error);
        }
    });

    app.get('/api/graph', async (request, response, next) => {
        const { layerId } = request.query;
        if (layerId !== undefined && (
            typeof layerId !== 'string' || !uuidPattern.test(layerId)
        )) {
            response.status(400).json({ error: 'layerId must be a UUID.' });
            return;
        }

        try {
            const values = [layerId ?? null];
            const [nodeResult, edgeResult] = await Promise.all([
                pool.query(
                    `SELECT
                        sfe.id_sfe::text AS id,
                        sfe.vr_code AS label,
                        sfe.id_layer::text AS "layerId",
                        layer.name AS "layerName",
                        kind.name AS "type",
                        template.name AS "templateName",
                        location.longitude AS lng,
                        location.latitude AS lat
                    FROM imc.thematic_layers_sfes AS sfe
                    JOIN imc.thematic_layers AS layer
                        ON layer.id_layer = sfe.id_layer
                    JOIN imc.sfe_templates AS template
                        ON template.id_sfet = sfe.id_sfet
                    JOIN imc.sfe_kinds AS kind
                        ON kind.id_sfe_kind = template.id_sfe_kind
                    LEFT JOIN imc.network_node_locations AS location
                        ON location.id_sfe = sfe.id_sfe
                    WHERE ($1::uuid IS NULL OR sfe.id_layer = $1::uuid)
                    ORDER BY layer.name, sfe.vr_code, sfe.id_sfe`,
                    values
                ),
                pool.query(
                    `SELECT
                        linking.id_sfe_linking::text AS id,
                        linking.id_sfe::text AS source,
                        linking.id_ls_sfe::text AS target,
                        record.value AS label
                    FROM imc.thematic_layers_sfe_linkings AS linking
                    JOIN imc.thematic_layers_sfes AS source_sfe
                        ON source_sfe.id_sfe = linking.id_sfe
                    JOIN imc.thematic_layers_sfes AS target_sfe
                        ON target_sfe.id_sfe = linking.id_ls_sfe
                    LEFT JOIN imc.dc_records AS record
                        ON record.id_record = linking.id_lmd_record
                    WHERE linking.id_ls_sfe IS NOT NULL
                        AND ($1::uuid IS NULL OR (
                            source_sfe.id_layer = $1::uuid
                            AND target_sfe.id_layer = $1::uuid
                        ))
                    ORDER BY linking.id_sfe_linking`,
                    values
                ),
            ]);

            const nodes = nodeResult.rows.map((row) => ({
                id: row.id,
                lng: row.lng === null ? null : Number(row.lng),
                lat: row.lat === null ? null : Number(row.lat),
                data: {
                    label: row.label || row.templateName || row.id,
                    type: row.type,
                    templateName: row.templateName,
                    layerId: row.layerId,
                    layerName: row.layerName,
                },
            }));
            const edges = edgeResult.rows.map((row) => ({
                id: row.id,
                source: row.source,
                target: row.target,
                label: row.label,
                type: 'straight',
                style: { stroke: '#718096', strokeWidth: 2 },
            }));

            response.json({
                nodes,
                edges,
                unlocatedCount: nodes.filter((node) => node.lng === null || node.lat === null).length,
            });
        } catch (error) {
            next(error);
        }
    });

    app.put('/api/nodes/:id/location', async (request, response, next) => {
        const { id } = request.params;
        const { lng, lat } = request.body ?? {};

        if (!uuidPattern.test(id)) {
            response.status(400).json({ error: 'Node id must be a UUID.' });
            return;
        }
        if (
            typeof lng !== 'number'
            || !Number.isFinite(lng)
            || lng < -180
            || lng > 180
            || typeof lat !== 'number'
            || !Number.isFinite(lat)
            || lat < -90
            || lat > 90
        ) {
            response.status(400).json({
                error: 'lng and lat must be finite numbers within geographic bounds.',
            });
            return;
        }

        try {
            const { rows } = await pool.query(
                `INSERT INTO imc.network_node_locations (id_sfe, longitude, latitude)
                 SELECT id_sfe, $2, $3
                 FROM imc.thematic_layers_sfes
                 WHERE id_sfe = $1::uuid
                 ON CONFLICT (id_sfe) DO UPDATE
                     SET longitude = EXCLUDED.longitude,
                         latitude = EXCLUDED.latitude,
                         updated_at = now()
                 RETURNING id_sfe::text AS id, longitude AS lng, latitude AS lat`,
                [id, lng, lat]
            );
            if (rows.length === 0) {
                response.status(404).json({ error: 'The requested SFE node was not found.' });
                return;
            }
            response.json(rows[0]);
        } catch (error) {
            next(error);
        }
    });

    app.use((error, _request, response, _next) => {
        void _next;
        console.error(`API request failed: ${error.message}`);
        response.status(500).json({ error: 'Database request failed.' });
    });

    return app;
}

async function startServer() {
    if (!process.env.DATABASE_URL) {
        throw new Error('DATABASE_URL is required. Set it in .env before starting the API.');
    }

    const port = Number(process.env.API_PORT || 3001);
    const host = process.env.API_HOST || '127.0.0.1';
    if (!Number.isInteger(port) || port < 1 || port > 65535) {
        throw new Error('API_PORT must be a valid TCP port.');
    }

    const pool = new Pool({ connectionString: process.env.DATABASE_URL });
    try {
        await pool.query('SELECT 1');
    } catch (error) {
        console.error(`Database connection failed: ${error.message}`);
        await pool.end();
        process.exitCode = 1;
        return;
    }

    const server = createApp(pool).listen(port, host, () => {
        console.log(`Graph API listening on http://${host}:${port}`);
    });

    const closeServer = () => {
        server.close(async () => {
            await pool.end();
        });
    };
    process.once('SIGINT', closeServer);
    process.once('SIGTERM', closeServer);
}

if (
    process.argv[1]
    && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href
) {
    await startServer();
}
