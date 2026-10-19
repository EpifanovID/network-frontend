import 'dotenv/config';

import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

import pg from 'pg';

const { Client } = pg;
const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const migrationsDirectory = path.join(projectRoot, 'database', 'migrations');
const baseMigrations = new Set([
    '000_uuid_ossp.sql',
    '001_imc_schema.sql',
    '002_imc_triggers.sql',
]);

if (!process.env.DATABASE_URL) {
    throw new Error('DATABASE_URL is required. Set it in .env before migrating.');
}

const client = new Client({ connectionString: process.env.DATABASE_URL });

async function migrate() {
    await client.connect();
    await client.query(`
        CREATE TABLE IF NOT EXISTS public.network_app_migrations (
            filename text PRIMARY KEY,
            applied_at timestamp with time zone NOT NULL DEFAULT now()
        )
    `);

    const filenames = (await readdir(migrationsDirectory))
        .filter((filename) => filename.endsWith('.sql'))
        .sort();
    const existingSchema = process.argv.includes('--existing-schema');

    if (existingSchema) {
        for (const filename of filenames.filter((name) => baseMigrations.has(name))) {
            await client.query(
                `INSERT INTO public.network_app_migrations (filename)
                 VALUES ($1)
                 ON CONFLICT (filename) DO NOTHING`,
                [filename]
            );
            console.log(`Skipping supplied base schema for existing database: ${filename}`);
        }
    }

    for (const filename of filenames) {
        const { rows } = await client.query(
            'SELECT 1 FROM public.network_app_migrations WHERE filename = $1',
            [filename]
        );
        if (rows.length > 0) continue;

        const sql = await readFile(path.join(migrationsDirectory, filename), 'utf8');
        console.log(`Applying ${filename}...`);
        await client.query(sql);
        await client.query(
            'INSERT INTO public.network_app_migrations (filename) VALUES ($1)',
            [filename]
        );
        console.log(`Applied ${filename}.`);
    }
}

try {
    await migrate();
} catch (error) {
    console.error(`Database migration failed: ${error.message}`);
    process.exitCode = 1;
} finally {
    await client.end().catch((error) => {
        console.error(`Could not close the database connection: ${error.message}`);
        process.exitCode = 1;
    });
}
