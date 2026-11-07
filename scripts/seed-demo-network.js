import 'dotenv/config';
import { randomInt, randomUUID } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import process from 'node:process';
import pg from 'pg';
import { containsMapPoint } from '../src/utils/mapFilters.js';

// Pick one city per group to keep the fictional network spread across Russia.
const cityGroups = [
    [['Калининград', 20.51, 54.71], ['Черняховск', 21.81, 54.63]],
    [['Псков', 28.33, 57.81], ['Санкт-Петербург', 30.31, 59.94]],
    [['Петрозаводск', 34.36, 61.79], ['Архангельск', 40.52, 64.54]],
    [['Воронеж', 39.20, 51.66], ['Белгород', 36.59, 50.60]],
    [['Волгоград', 44.52, 48.71], ['Астрахань', 48.04, 46.35]],
    [['Пермь', 56.25, 58.01], ['Ижевск', 53.21, 56.85]],
    [['Омск', 73.37, 54.99], ['Новосибирск', 82.92, 55.03]],
    [['Красноярск', 92.87, 56.01], ['Иркутск', 104.30, 52.29]],
    [['Якутск', 129.73, 62.03], ['Нерюнгри', 124.71, 56.66]],
    [['Хабаровск', 135.07, 48.48], ['Владивосток', 131.89, 43.12]],
];
const connections = [[0, 1], [1, 2], [1, 3], [3, 4], [2, 5], [5, 6], [6, 7], [7, 8], [8, 9], [7, 9]];
const pick = (values) => values[randomInt(values.length)];
const reliability = (minimum) => String(randomInt(minimum, 99999) / 100000);

function propertyValue(name, context) {
    if (name === 'Долгота') return context.lng;
    if (name === 'Широта') return context.lat;
    if (name === 'Класс узла связи') return pick(['A', 'B', 'C']);
    if (name === 'Количество экземпляров компонента') return context.devices;
    if (name.startsWith('Экземпляров с учетом резерва')) return context.devices + 1;
    if (name.startsWith('Пропускная способность')) return pick([100, 1000, 2500, 10000]);
    if (name.startsWith('Среднее время наработки')) return randomInt(120, 481) * 100;
    if (name.startsWith('Надежность')) return reliability(name.includes('без учета резерва') ? 97000 : 99500);
    return undefined;
}

if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is required.');
const client = new pg.Client({ connectionString: process.env.DATABASE_URL });

try {
    await client.connect();
    await client.query('BEGIN');
    await client.query("SELECT pg_advisory_xact_lock(hashtext('network-frontend-demo-network'))");
    const { rows: roots } = await client.query(`
        SELECT id_layer AS layer, id_owner AS owner, changed_by AS editor, id_sfet AS template
        FROM imc.thematic_layers_sfes
        WHERE vr_code = 'УС1' AND id_sfet = 'c09c3cd3-22d9-431d-891a-fbfd6c683848'
    `);
    if (roots.length !== 1) throw new Error('Expected one reference node УС1.');
    const [root] = roots;

    const { rows: links } = await client.query(`
        SELECT DISTINCT source.id_sfet AS source, target.id_sfet AS target,
               edge.id_sfet_linking AS template, edge.id_lmd_record AS meaning, term.value
        FROM imc.thematic_layers_sfe_linkings edge
        JOIN imc.thematic_layers_sfes source ON source.id_sfe = edge.id_sfe
        JOIN imc.thematic_layers_sfes target ON target.id_sfe = edge.id_ls_sfe
        JOIN imc.dc_records term ON term.id_record = edge.id_lmd_record
        WHERE source.id_layer = $1 AND term.value IN ('состоит из', 'подключена к')
    `, [root.layer]);
    const lineLink = links.find((link) => link.target === root.template && link.value === 'подключена к');
    const deviceLink = links.find((link) => link.source === root.template && link.value === 'состоит из');
    const blockLinks = links.filter((link) => link.source === deviceLink?.target && link.value === 'состоит из');
    if (!lineLink || !deviceLink || blockLinks.length < 3) throw new Error('Required IMC link templates are missing.');

    const { rows: definitions } = await client.query(`
        SELECT id_sfet AS template, id_sfet_property AS id, name_rus AS name,
               CASE WHEN id_pvd IS NOT NULL THEN ARRAY(
                   SELECT id_record FROM imc.dc_records WHERE id_dc = p.id_pvd
               ) END AS options
        FROM imc.sfet_properties p
        WHERE id_sfet = ANY($1::uuid[])
    `, [[root.template, lineLink.source, deviceLink.target, ...blockLinks.map(({ target }) => target)]]);

    const { features } = JSON.parse(await readFile(new URL('../public/maps/russia-regions.geojson', import.meta.url), 'utf8'));
    const nodes = [];
    let equipmentCount = 0;
    let propertyCount = 0;
    async function addObject(code, template, context = {}) {
        const id = randomUUID();
        await client.query(`
            INSERT INTO imc.thematic_layers_sfes (id_sfe, id_owner, changed_by, id_layer, id_sfet, vr_code)
            VALUES ($1, $2, $3, $4, $5, $6)
        `, [id, root.owner, root.editor, root.layer, template, code]);
        for (const definition of definitions.filter((entry) => entry.template === template)) {
            const value = propertyValue(definition.name, context);
            const record = definition.options?.length ? pick(definition.options) : null;
            if (value === undefined && record === null) continue;
            await client.query(`
                INSERT INTO imc.thematic_layers_sfe_properties
                    (id_sfe_property, id_owner, changed_by, id_sfe, id_sfet_property, val, val_by_id_pvd_record)
                VALUES ($1, $2, $3, $4, $5, $6, $7)
            `, [randomUUID(), root.owner, root.editor, id, definition.id, value === undefined ? null : String(value), record]);
            propertyCount++;
        }
        return id;
    }

    async function connect(source, target, link) {
        await client.query(`
            INSERT INTO imc.thematic_layers_sfe_linkings
                (id_sfe_linking, id_owner, changed_by, id_sfe, id_sfet_linking, id_lmd_record, id_ls_sfe)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
        `, [randomUUID(), root.owner, root.editor, source, link.template, link.meaning, target]);
    }

    for (const [index, cities] of cityGroups.entries()) {
        const code = `УС${index + 10}`;
        const [city, lng, lat] = pick(cities);
        if (!features.some(({ geometry }) => containsMapPoint(geometry, lng, lat))) {
            throw new Error(`Coordinates for ${city} are outside the map regions.`);
        }
        const devices = randomInt(1, 4);
        const id = await addObject(code, root.template, { lng, lat, devices });
        await client.query('INSERT INTO imc.network_node_locations (id_sfe, longitude, latitude) VALUES ($1, $2, $3)', [id, lng, lat]);
        nodes.push({ code, city, id });

        for (let device = 1; device <= devices; device++) {
            const prefix = `${code}-П317-${device}`;
            const deviceId = await addObject(prefix, deviceLink.target);
            await connect(id, deviceId, deviceLink);
            equipmentCount++;
            const available = [...blockLinks];
            const blockCount = randomInt(3, Math.min(6, available.length) + 1);
            for (let block = 1; block <= blockCount; block++) {
                const [link] = available.splice(randomInt(available.length), 1);
                const blockId = await addObject(`${prefix}-Б${block}`, link.target);
                await connect(deviceId, blockId, link);
                equipmentCount++;
            }
        }
    }

    for (const [index, [first, second]] of connections.entries()) {
        const id = await addObject(`ЛС${index + 10}`, lineLink.source);
        await connect(id, nodes[first].id, lineLink);
        await connect(id, nodes[second].id, lineLink);
    }

    await client.query('COMMIT');
    console.table(nodes);
    console.log(`Saved ${nodes.length} nodes, ${connections.length} lines, ${equipmentCount} equipment objects and ${propertyCount} property values.`);
} catch (error) {
    await client.query('ROLLBACK').catch(() => {});
    console.error(`Could not seed demonstration network: ${error.message}`);
    process.exitCode = 1;
} finally {
    await client.end();
}
