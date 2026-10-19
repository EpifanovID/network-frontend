import 'dotenv/config';

import { readFile, stat } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { randomUUID } from 'node:crypto';
import { pathToFileURL } from 'node:url';

import { XMLParser, XMLValidator } from 'fast-xml-parser';
import pg from 'pg';

const { Client } = pg;
const parser = new XMLParser({
    ignoreAttributes: false,
    attributeNamePrefix: '@_',
    parseAttributeValue: false,
    parseTagValue: false,
    trimValues: true,
    processEntities: false,
});
const databaseOnlyTables = new Set([
    'dc_kinds',
    'sfet_ls_kinds',
    'sfet_prop_val_types',
    'ict_cnf_param_val_types',
    'icts_calculation_rules_kinds',
    'icts_calculation_rules_allowed_operands',
]);

function getText(value, fieldName) {
    const text = typeof value === 'string' ? value : value?.['#text'];
    if (typeof text !== 'string' || text.trim() === '') {
        throw new Error(`The seed configuration has no value for ${fieldName}.`);
    }
    return text.trim();
}

function decodeXmlEntities(value) {
    return value.replace(/&(#x[\da-f]+|#\d+|amp|lt|gt|quot|apos);/gi, (entity, name) => {
        if (name[0] === '#') {
            const codePoint = name[1].toLowerCase() === 'x'
                ? Number.parseInt(name.slice(2), 16)
                : Number.parseInt(name.slice(1), 10);
            if (
                !Number.isInteger(codePoint)
                || codePoint <= 0
                || codePoint > 0x10ffff
                || (codePoint >= 0xd800 && codePoint <= 0xdfff)
            ) {
                throw new Error(`Invalid XML character reference: ${entity}`);
            }
            return String.fromCodePoint(codePoint);
        }

        return {
            amp: '&',
            lt: '<',
            gt: '>',
            quot: '"',
            apos: "'",
        }[name.toLowerCase()];
    });
}

export function parseSeedConfig(xmlText) {
    const validation = XMLValidator.validate(xmlText, {
        allowBooleanAttributes: false,
    });
    if (validation !== true) {
        throw new Error(`The seed configuration XML is invalid: ${validation.err.msg}`);
    }

    const parsed = parser.parse(xmlText);
    const config = parsed.imc_init_config;
    if (!config?.general_params) {
        throw new Error('The seed configuration has no general_params section.');
    }

    const listText = getText(
        config.general_params.init_files_list,
        'general_params.init_files_list'
    );
    const filenames = listText.split(',').map((name) => name.trim()).filter(Boolean);
    if (!filenames.length || filenames.some((name) => !/^[\w.-]+\.xml$/i.test(name))) {
        throw new Error('The configured seed file list contains an invalid filename.');
    }

    return {
        ownerSourceId: getText(
            config.general_params.id_user_owner,
            'general_params.id_user_owner'
        ),
        filenames,
    };
}

export function parseSeedRecords(xmlText, filename) {
    const validation = XMLValidator.validate(xmlText, {
        allowBooleanAttributes: false,
    });
    if (validation !== true) {
        throw new Error(`${filename} is invalid XML: ${validation.err.msg}`);
    }

    const parsed = parser.parse(xmlText);
    const rootName = Object.keys(parsed).find((key) => !key.startsWith('?'));
    const root = rootName ? parsed[rootName] : null;
    if (!root) return [];
    if (typeof root !== 'object' || Array.isArray(root)) {
        throw new Error(`${filename} has no XML record container.`);
    }

    const records = Object.values(root)
        .flatMap((value) => (Array.isArray(value) ? value : [value]))
        .filter((value) => value && typeof value === 'object' && !Array.isArray(value));

    return records.map((record, index) => {
        const attributes = Object.fromEntries(
            Object.entries(record)
                .filter(([key]) => key.startsWith('@_'))
                .map(([key, value]) => [key.slice(2), decodeXmlEntities(String(value))])
        );
        if (!attributes.id) {
            throw new Error(`${filename} record ${index + 1} has no id attribute.`);
        }
        return attributes;
    });
}

function quoteIdentifier(identifier) {
    if (!/^[a-z_][a-z0-9_]*$/i.test(identifier)) {
        throw new Error(`Unsafe database identifier in seed metadata: ${identifier}`);
    }
    return `"${identifier.replaceAll('"', '""')}"`;
}

function getArguments(argv) {
    const values = new Map();
    for (let index = 0; index < argv.length; index += 1) {
        const argument = argv[index];
        if (!argument.startsWith('--') || !argv[index + 1] || argv[index + 1].startsWith('--')) {
            throw new Error(`Invalid import argument: ${argument}`);
        }
        values.set(argument.slice(2), argv[index + 1]);
        index += 1;
    }

    const seedDirectory = values.get('seed-dir');
    const configPath = values.get('config');
    if (!seedDirectory) {
        throw new Error(
            'Provide --seed-dir pointing to the extracted init_files folder.'
        );
    }
    return {
        seedDirectory: path.resolve(seedDirectory),
        configPath: configPath
            ? path.resolve(configPath)
            : path.resolve(seedDirectory, '..', 'config', 'imc_init_config.xml'),
    };
}

async function getPrimaryKeyMetadata(client, tableName) {
    const { rows } = await client.query(
        `SELECT column_name, data_type
         FROM information_schema.columns
         WHERE table_schema = 'imc'
           AND table_name = $1
           AND column_name = (
               SELECT attribute.attname
               FROM pg_index AS index
               JOIN pg_attribute AS attribute
                 ON attribute.attrelid = index.indrelid
                AND attribute.attnum = ANY(index.indkey)
               WHERE index.indrelid = format('imc.%I', $1)::regclass
                 AND index.indisprimary
               LIMIT 1
           )`,
        [tableName]
    );
    if (rows.length !== 1) {
        throw new Error(`Could not determine primary key for imc.${tableName}.`);
    }
    return rows[0];
}

async function getColumns(client, tableName) {
    const { rows } = await client.query(
        `SELECT column_name
         FROM information_schema.columns
         WHERE table_schema = 'imc' AND table_name = $1`,
        [tableName]
    );
    return new Set(rows.map((row) => row.column_name));
}

async function createIdMap(client, tableName, primaryKey) {
    const result = await client.query(
        `SELECT ${quoteIdentifier(primaryKey)}::text AS id
         FROM imc.${quoteIdentifier(tableName)}`
    );
    return new Map(result.rows.map(({ id }) => [id, id]));
}

function convertValue(value, sourceIds, filename, recordId, currentRealId) {
    if (value === 'NULL') return null;
    const separator = value.indexOf('::');
    if (separator === -1) return value;

    const tableName = value.slice(0, separator);
    const sourceId = value.slice(separator + 2);
    if (sourceId === '0') return String(currentRealId);
    const resolved = sourceIds.get(tableName)?.get(sourceId);
    if (resolved === undefined) {
        throw new Error(
            `${filename} record ${recordId} refers to missing ${tableName} id ${sourceId}.`
        );
    }
    return resolved;
}

async function readSeedFiles(seedDirectory, config) {
    const files = [];
    for (const filename of config.filenames) {
        const match = filename.match(/^\d+__(\w+)\.xml$/i);
        if (!match) {
            throw new Error(`Cannot determine the table name from ${filename}.`);
        }

        const filePath = path.join(seedDirectory, filename);
        try {
            await stat(filePath);
        } catch (error) {
            if (error.code === 'ENOENT') continue;
            throw error;
        }
        const xmlText = await readFile(filePath, 'utf8');
        const records = parseSeedRecords(xmlText, filename);
        if (records.length) {
            files.push({ filename, tableName: match[1], records });
        }
    }
    if (!files.some(({ tableName }) => tableName === 'users')) {
        throw new Error('The configured seed files contain no users.xml records.');
    }
    return files;
}

async function importSeed() {
    if (!process.env.DATABASE_URL) {
        throw new Error('DATABASE_URL is required. Set it in .env before importing.');
    }

    const { seedDirectory, configPath } = getArguments(process.argv.slice(2));
    const seedDirectoryInfo = await stat(seedDirectory);
    if (!seedDirectoryInfo.isDirectory()) {
        throw new Error(`Seed directory not found: ${seedDirectory}`);
    }

    const config = parseSeedConfig(await readFile(configPath, 'utf8'));
    const files = await readSeedFiles(seedDirectory, config);
    const client = new Client({ connectionString: process.env.DATABASE_URL });
    const sourceIds = new Map();
    let insertedCount = 0;

    try {
        await client.connect();
        await client.query('BEGIN');
        await client.query(
            "SELECT pg_advisory_xact_lock(hashtext('network-frontend-imc-seed-import'))"
        );

        const migration = await client.query(
            `SELECT 1
             FROM public.network_app_migrations
             WHERE filename = '003_network_node_locations.sql'`
        );
        if (migration.rowCount !== 1) {
            throw new Error(
                'Apply database migrations first with npm run db:migrate -- --existing-schema.'
            );
        }

        for (const tableName of databaseOnlyTables) {
            const primaryKey = await getPrimaryKeyMetadata(client, tableName);
            sourceIds.set(tableName, await createIdMap(client, tableName, primaryKey.column_name));
        }

        const tableNames = [...new Set(
            files
                .filter(({ tableName }) => !databaseOnlyTables.has(tableName))
                .map(({ tableName }) => tableName)
        )];
        for (const tableName of tableNames) {
            await getPrimaryKeyMetadata(client, tableName);
            const countResult = await client.query(
                `SELECT count(*)::int AS count FROM imc.${quoteIdentifier(tableName)}`
            );
            if (countResult.rows[0].count !== 0) {
                throw new Error(
                    `Refusing to import into non-empty imc.${tableName}; no seed data was changed.`
                );
            }
        }

        for (const { filename, tableName, records } of files) {
            if (databaseOnlyTables.has(tableName)) {
                console.log(`Skipping database-managed dictionary ${filename}.`);
                continue;
            }

            const primaryKey = await getPrimaryKeyMetadata(client, tableName);
            const columns = await getColumns(client, tableName);
            const sourceTableIds = new Map();
            sourceIds.set(tableName, sourceTableIds);

            for (const record of records) {
                const sourceId = record.id;
                const realId = primaryKey.data_type === 'uuid'
                    ? randomUUID()
                    : sourceId;
                const suppliedFields = Object.entries(record)
                    .filter(([fieldName]) => fieldName !== 'id')
                    .map(([fieldName, value]) => {
                        if (!columns.has(fieldName)) {
                            throw new Error(
                                `${filename} record ${sourceId} has unknown column ${fieldName}.`
                            );
                        }
                        return [
                            fieldName,
                            convertValue(value, sourceIds, filename, sourceId, realId),
                        ];
                    });
                const fields = new Map([[primaryKey.column_name, realId], ...suppliedFields]);

                if (columns.has('id_owner') && !fields.has('id_owner')) {
                    const ownerId = sourceIds.get('users')?.get(config.ownerSourceId);
                    if (!ownerId) {
                        throw new Error(
                            `Configured owner user ${config.ownerSourceId} is missing from users.xml.`
                        );
                    }
                    fields.set('id_owner', ownerId);
                }
                if (columns.has('changed_by') && !fields.has('changed_by')) {
                    const ownerId = sourceIds.get('users')?.get(config.ownerSourceId);
                    if (!ownerId) {
                        throw new Error(
                            `Configured owner user ${config.ownerSourceId} is missing from users.xml.`
                        );
                    }
                    fields.set('changed_by', ownerId);
                }

                const fieldNames = [...fields.keys()];
                const placeholders = fieldNames.map((_, index) => `$${index + 1}`);
                const query = `INSERT INTO imc.${quoteIdentifier(tableName)} `
                    + `(${fieldNames.map(quoteIdentifier).join(', ')}) `
                    + `VALUES (${placeholders.join(', ')})`;
                await client.query(query, [...fields.values()]);
                sourceTableIds.set(sourceId, String(realId));
                insertedCount += 1;
            }
            console.log(`Staged ${records.length} records from ${filename}.`);
        }

        await client.query('COMMIT');
        console.log(`Imported ${insertedCount} records from ${files.length} seed files.`);
    } catch (error) {
        await client.query('ROLLBACK').catch((rollbackError) => {
            console.error(`Could not roll back the failed import: ${rollbackError.message}`);
        });
        throw error;
    } finally {
        await client.end();
    }
}

if (
    process.argv[1]
    && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href
) {
    try {
        await importSeed();
    } catch (error) {
        console.error(`IMC seed import failed: ${error.message}`);
        process.exitCode = 1;
    }
}
