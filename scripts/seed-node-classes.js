import 'dotenv/config';
import { randomInt, randomUUID } from 'node:crypto';
import process from 'node:process';
import pg from 'pg';

// Demonstration classes, assigned once and stored as ordinary IMC properties.
// Existing nonempty values are preserved on subsequent runs.
if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is required.');
const client = new pg.Client({ connectionString: process.env.DATABASE_URL });

try {
    await client.connect();
    await client.query('BEGIN');
    const { rows: templates } = await client.query(`
        SELECT t.id_sfet AS id, t.id_owner AS owner, t.changed_by AS editor,
               g.id_group AS "groupId"
        FROM imc.sfe_templates t
        JOIN imc.sfe_kinds k ON k.id_sfe_kind = t.id_sfe_kind
        JOIN LATERAL (
            SELECT id_group FROM imc.sfet_properties_groups
            WHERE id_sfet = t.id_sfet
            ORDER BY is_root_group DESC, order_in_list, id_group LIMIT 1
        ) g ON true
        WHERE COALESCE(NULLIF(t.name, ''), k.name) ~* 'узел связи'
        ORDER BY t.id_sfet
    `);
    let assigned = 0;
    for (const template of templates) {
        await client.query(`
            INSERT INTO imc.sfet_properties (
                id_sfet_property, id_owner, changed_by, id_sfet,
                id_sfet_properties_group, name_rus, name_eng, id_val_type
            ) VALUES ($1, $2, $3, $4, $5, 'Класс узла связи', 'Communication node class', 2)
            ON CONFLICT (id_sfet, name_rus) DO NOTHING
        `, [randomUUID(), template.owner, template.editor, template.id, template.groupId]);
        const { rows: definitions } = await client.query(`
            SELECT id_sfet_property AS id, id_val_type, id_pvd
            FROM imc.sfet_properties WHERE id_sfet = $1 AND name_rus = 'Класс узла связи'
        `, [template.id]);
        const definition = definitions[0];
        if (definition.id_val_type !== 2 || definition.id_pvd !== null) {
            throw new Error('An existing class property uses a different value type; no values changed.');
        }
        const { rows: nodes } = await client.query(`
            SELECT id_sfe AS id, id_owner AS owner, changed_by AS editor
            FROM imc.thematic_layers_sfes WHERE id_sfet = $1 ORDER BY id_sfe
        `, [template.id]);
        for (const node of nodes) {
            const result = await client.query(`
                INSERT INTO imc.thematic_layers_sfe_properties (
                    id_sfe_property, id_owner, changed_by, id_sfe, id_sfet_property, val
                ) VALUES ($1, $2, $3, $4, $5, $6)
                ON CONFLICT (id_sfe, id_sfet_property) DO UPDATE SET val = EXCLUDED.val
                WHERE (thematic_layers_sfe_properties.val IS NULL
                    OR btrim(thematic_layers_sfe_properties.val) = '')
                    AND thematic_layers_sfe_properties.val_by_id_pvd_record IS NULL
            `, [randomUUID(), node.owner, node.editor, node.id, definition.id, ['A', 'B', 'C'][randomInt(3)]]);
            assigned += result.rowCount;
        }
    }
    await client.query('COMMIT');
    console.log(`Assigned and saved demonstration classes for ${assigned} communication nodes.`);
} catch (error) {
    await client.query('ROLLBACK').catch(() => {});
    console.error(`Could not assign node classes: ${error.message}`);
    process.exitCode = 1;
} finally {
    await client.end();
}
