import 'dotenv/config';

import express from 'express';
import { access } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath, pathToFileURL } from 'node:url';
import pg from 'pg';

const { Pool } = pg;
const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export function createApp(pool, { staticDirectory } = {}) {
    const app = express();
    app.disable('x-powered-by');
    app.use(express.json({ limit: '16kb' }));

    if (!staticDirectory) app.get('/', (_request, response) => {
        response.json({
            service: 'network-frontend graph API',
            endpoints: {
                health: '/api/health',
                graph: '/api/graph',
                nodeProperties: '/api/nodes/:id/properties',
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
                        location.latitude AS lat,
                        highlight.properties AS "highlightProperties"
                    FROM imc.thematic_layers_sfes AS sfe
                    JOIN imc.thematic_layers AS layer
                        ON layer.id_layer = sfe.id_layer
                    JOIN imc.sfe_templates AS template
                        ON template.id_sfet = sfe.id_sfet
                    JOIN imc.sfe_kinds AS kind
                        ON kind.id_sfe_kind = template.id_sfe_kind
                    LEFT JOIN imc.network_node_locations AS location
                        ON location.id_sfe = sfe.id_sfe
                    LEFT JOIN LATERAL (
                        SELECT jsonb_object_agg(definition.name_rus,
                            CASE WHEN property.id_sfe_property IS NULL
                                THEN COALESCE(default_record.value, definition.dv)
                                ELSE COALESCE(saved_record.value, property.val)
                            END) AS properties
                        FROM imc.sfet_properties AS definition
                        LEFT JOIN imc.thematic_layers_sfe_properties AS property
                            ON property.id_sfe = sfe.id_sfe
                            AND property.id_sfet_property = definition.id_sfet_property
                        LEFT JOIN imc.dc_records AS saved_record ON saved_record.id_record = property.val_by_id_pvd_record
                        LEFT JOIN imc.dc_records AS default_record ON default_record.id_record = definition.dv_by_if_pv_record
                        WHERE definition.id_sfet = sfe.id_sfet
                            AND definition.name_rus ~* '^(класс( |$|[(])|.*интерфейс)'
                    ) AS highlight ON true
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
                    ...(row.highlightProperties && { highlightProperties: row.highlightProperties }),
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

    app.get('/api/nodes/:id/properties', async (request, response, next) => {
        const { id } = request.params;
        if (!uuidPattern.test(id)) {
            response.status(400).json({ error: 'Node id must be a UUID.' });
            return;
        }

        try {
            const { rows } = await pool.query(
                `SELECT definition.id_sfet_property::text AS id,
                        definition.name_rus AS name,
                        CASE WHEN property.id_sfe_property IS NULL
                            THEN COALESCE(default_record.value, definition.dv)
                            ELSE COALESCE(saved_record.value, property.val)
                        END AS value
                 FROM imc.thematic_layers_sfes AS sfe
                 LEFT JOIN imc.sfet_properties AS definition ON definition.id_sfet = sfe.id_sfet
                 LEFT JOIN imc.thematic_layers_sfe_properties AS property
                    ON property.id_sfe = sfe.id_sfe
                    AND property.id_sfet_property = definition.id_sfet_property
                 LEFT JOIN imc.dc_records AS saved_record ON saved_record.id_record = property.val_by_id_pvd_record
                 LEFT JOIN imc.dc_records AS default_record ON default_record.id_record = definition.dv_by_if_pv_record
                 WHERE sfe.id_sfe = $1::uuid
                 ORDER BY definition.name_rus, definition.id_sfet_property`,
                [id]
            );
            if (rows.length === 0) {
                response.status(404).json({ error: 'The requested SFE node was not found.' });
                return;
            }
            response.json({ properties: rows.filter((row) => row.id !== null) });
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

    if (staticDirectory) {
        const directory = path.resolve(staticDirectory);
        app.use('/api', (_request, response) => {
            response.status(404).json({ error: 'API endpoint not found.' });
        });
        app.use(express.static(directory));
        app.get(['/objects/:objectId', '/lines/:lineId'], (_request, response) => {
            response.sendFile(path.join(directory, 'index.html'));
        });
    }

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

    const serveFrontend = process.argv.includes('--serve-frontend');
    const staticDirectory = serveFrontend
        ? fileURLToPath(new URL('../dist/', import.meta.url)) : undefined;
    if (staticDirectory) {
        for (const file of [
            'index.html',
            'maps/network-overview.pmtiles',
            'maps/network-areas.pmtiles',
            'maps/russia-outline.geojson',
            'maps/military-districts.geojson',
            'maps/russia-regions.geojson',
            'maps/sprites/light.json',
            'maps/sprites/light.png',
            'maps/sprites/light@2x.json',
            'maps/sprites/light@2x.png',
            ...['Regular', 'Medium', 'Italic'].map((font) => `maps/fonts/Noto Sans ${font}/0-255.pbf`),
        ]) {
            try {
                await access(path.join(staticDirectory, file));
            } catch {
                throw new Error(`Missing local file: ${file}. Check public/maps and run npm run build.`);
            }
        }
    }
    const port = Number(serveFrontend ? process.env.LOCAL_PORT || 4173 : process.env.API_PORT || 3001);
    const host = serveFrontend ? '127.0.0.1' : process.env.API_HOST || '127.0.0.1';
    if (!Number.isInteger(port) || port < 1 || port > 65535) {
        throw new Error('The server port must be a valid TCP port.');
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

    const server = createApp(pool, { staticDirectory }).listen(port, host, () => {
        console.log(`${serveFrontend ? 'Local application' : 'Graph API'} listening on http://${host}:${port}`);
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
