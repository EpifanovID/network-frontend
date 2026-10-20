import 'dotenv/config';

import process from 'node:process';
import pg from 'pg';

const { Client } = pg;
const baseNodeId = 'd0000000-0000-4000-8000-00000000000';
const nodes = [
    { id: `${baseNodeId}4`, label: 'УС4', lng: 49.1064, lat: 55.7961 },
    { id: `${baseNodeId}5`, label: 'УС5', lng: 50.1002, lat: 53.1959 },
    { id: `${baseNodeId}6`, label: 'УС6', lng: 60.5975, lat: 56.8389 },
    { id: `${baseNodeId}7`, label: 'УС7', lng: 61.4026, lat: 55.1599 },
    { id: `${baseNodeId}8`, label: 'УС8', lng: 39.7015, lat: 47.2357 },
    { id: `${baseNodeId}9`, label: 'УС9', lng: 38.9769, lat: 45.0355 },
];
const nodeTemplateId = 'c09c3cd3-22d9-431d-891a-fbfd6c683848';
const lineTemplateId = '854b74f8-5300-411d-b233-237c7d19a3a8';
const lineLinkTemplateId = '8c2e669b-92ae-48fe-9dcc-6739b4f6874c';
const baseLineId = 'd1000000-0000-4000-8000-00000000000';
const relationIds = [41, 42, 51, 52, 61, 62, 71, 72, 81, 82, 91, 92].map(
    (suffix) => `d2000000-0000-4000-8000-${String(suffix).padStart(12, '0')}`
);
const lines = [
    { id: `${baseLineId}4`, label: 'ЛС4', endpoints: ['УС8', 'УС9'] },
    { id: `${baseLineId}5`, label: 'ЛС5', endpoints: ['УС8', 'УС4'] },
    { id: `${baseLineId}6`, label: 'ЛС6', endpoints: ['УС8', 'УС5'] },
    { id: `${baseLineId}7`, label: 'ЛС7', endpoints: ['УС4', 'УС1'] },
    { id: `${baseLineId}8`, label: 'ЛС8', endpoints: ['УС5', 'УС1'] },
    { id: `${baseLineId}9`, label: 'ЛС9', endpoints: ['УС6', 'УС7'] },
];

if (!process.env.DATABASE_URL) {
    throw new Error('DATABASE_URL is required. Set it in .env before seeding.');
}

const client = new Client({ connectionString: process.env.DATABASE_URL });

async function seedDemoNodes() {
    await client.connect();
    await client.query('BEGIN');

    const { rows: rootRows } = await client.query(
        `SELECT id_layer::text AS "layerId",
                id_owner::text AS "ownerId",
                changed_by::text AS "changedBy"
         FROM imc.thematic_layers_sfes
         WHERE id_sfet = $1::uuid AND vr_code = $2`,
        [nodeTemplateId, 'УС1']
    );
    if (rootRows.length !== 1) {
        throw new Error(
            `Expected one УС1 node for template ${nodeTemplateId}; found ${rootRows.length}.`
        );
    }
    const [root] = rootRows;
    const labels = [...nodes, ...lines].map((node) => node.label);
    const ids = [...nodes, ...lines].map((node) => node.id);
    const { rows: conflicts } = await client.query(
        `SELECT id_sfe::text AS id, id_sfet::text AS "templateId", vr_code AS label
         FROM imc.thematic_layers_sfes
         WHERE id_layer = $1::uuid
           AND (vr_code = ANY($2::text[]) OR id_sfe = ANY($3::uuid[]))`,
        [root.layerId, labels, ids]
    );
    for (const existing of conflicts) {
        const expected = [...nodes, ...lines].find(
            (node) => node.label === existing.label || node.id === existing.id
        );
        if (
            !expected
            || expected.id !== existing.id
            || existing.templateId !== (
                nodes.includes(expected) ? nodeTemplateId : lineTemplateId
            )
        ) {
            throw new Error(
                `${existing.label} or node ID ${existing.id} already belongs to another database object.`
            );
        }
    }

    const { rows: lineTemplateRows } = await client.query(
        `SELECT id_sfet_linking::text AS "linkTemplateId",
                id_lmd::text AS "catalogId",
                id_ls_sfet::text AS "targetTemplateId"
         FROM imc.sfet_linkings
         WHERE id_sfet = $1::uuid`,
        [lineTemplateId]
    );
    if (
        lineTemplateRows.length !== 1
        || lineTemplateRows[0].linkTemplateId !== lineLinkTemplateId
        || lineTemplateRows[0].targetTemplateId !== nodeTemplateId
    ) {
        throw new Error('The configured line-to-node relationship template is not valid.');
    }

    const { rows: semanticRows } = await client.query(
        `SELECT record.id_record::text AS id
         FROM imc.dc_records AS record
         WHERE record.id_dc = $1::uuid
           AND record.value = $2`,
        [lineTemplateRows[0].catalogId, 'подключена к']
    );
    if (semanticRows.length !== 1) {
        throw new Error(
            `Expected one "подключена к" semantic record; found ${semanticRows.length}.`
        );
    }

    const { rows: endpointRows } = await client.query(
        `SELECT id_sfe::text AS id, vr_code AS label
         FROM imc.thematic_layers_sfes
         WHERE id_layer = $1::uuid
           AND vr_code = ANY($2::text[])
           AND id_sfet = $3::uuid`,
        [root.layerId, [...new Set(lines.flatMap((line) => line.endpoints))], nodeTemplateId]
    );
    const endpointsByLabel = new Map(
        endpointRows.map((endpoint) => [endpoint.label, endpoint.id])
    );
    for (const line of lines) {
        for (const endpoint of line.endpoints) {
            if (!endpointsByLabel.has(endpoint)) {
                throw new Error(`Required endpoint ${endpoint} is missing from the layer.`);
            }
        }
    }

    for (const node of nodes) {
        await client.query(
            `INSERT INTO imc.thematic_layers_sfes (
                id_sfe, id_owner, changed_by, id_layer, id_sfet, vr_code
             ) VALUES ($1::uuid, $2::uuid, $3::uuid, $4::uuid, $5::uuid, $6)
             ON CONFLICT (id_sfe) DO NOTHING`,
            [node.id, root.ownerId, root.changedBy, root.layerId, nodeTemplateId, node.label]
        );
        await client.query(
            `INSERT INTO imc.network_node_locations (id_sfe, longitude, latitude)
             VALUES ($1::uuid, $2, $3)
             ON CONFLICT (id_sfe) DO NOTHING`,
            [node.id, node.lng, node.lat]
        );
    }

    for (const line of lines) {
        await client.query(
            `INSERT INTO imc.thematic_layers_sfes (
                id_sfe, id_owner, changed_by, id_layer, id_sfet, vr_code
             ) VALUES ($1::uuid, $2::uuid, $3::uuid, $4::uuid, $5::uuid, $6)
             ON CONFLICT (id_sfe) DO NOTHING`,
            [line.id, root.ownerId, root.changedBy, root.layerId, lineTemplateId, line.label]
        );
        for (let index = 0; index < line.endpoints.length; index += 1) {
            const relationId = relationIds[
                (lines.indexOf(line) * 2) + index
            ];
            await client.query(
                `INSERT INTO imc.thematic_layers_sfe_linkings (
                    id_sfe_linking, id_owner, changed_by, id_sfe,
                    id_sfet_linking, id_lmd_record, id_ls_sfe
                 ) VALUES ($1::uuid, $2::uuid, $3::uuid, $4::uuid, $5::uuid, $6::uuid, $7::uuid)
                 ON CONFLICT (id_sfe_linking) DO NOTHING`,
                [
                    relationId,
                    root.ownerId,
                    root.changedBy,
                    line.id,
                    lineLinkTemplateId,
                    semanticRows[0].id,
                    endpointsByLabel.get(line.endpoints[index]),
                ]
            );
        }
    }

    await client.query('COMMIT');
    console.log(
        `Ensured ${nodes.length} nodes, ${lines.length} lines, `
        + `${relationIds.length} line relations, and coordinates in PostgreSQL.`
    );
}

try {
    await seedDemoNodes();
} catch (error) {
    await client.query('ROLLBACK').catch((rollbackError) => {
        console.error(`Could not roll back demo node seed: ${rollbackError.message}`);
    });
    console.error(`Could not seed demo nodes: ${error.message}`);
    process.exitCode = 1;
} finally {
    await client.end().catch((error) => {
        console.error(`Could not close the database connection: ${error.message}`);
        process.exitCode = 1;
    });
}
