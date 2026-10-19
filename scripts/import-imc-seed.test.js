import assert from 'node:assert/strict';
import test from 'node:test';

import { parseSeedConfig, parseSeedRecords } from './import-imc-seed.js';

test('reads ordered seed filenames and owner from configuration XML', () => {
    const config = parseSeedConfig(`
        <imc_init_config>
            <general_params>
                <id_user_owner>owner-1</id_user_owner>
                <init_files_list>
                    57__users.xml,
                    1__schemes.xml
                </init_files_list>
            </general_params>
        </imc_init_config>
    `);

    assert.equal(config.ownerSourceId, 'owner-1');
    assert.deepEqual(config.filenames, ['57__users.xml', '1__schemes.xml']);
});

test('parses direct XML records and preserves unresolved relation identifiers', () => {
    const records = parseSeedRecords(`
        <thematic_layers_sfes>
            <thematic_layers_sfe id="1" id_layer="thematic_layers::7" vr_code="Node &amp; link" />
            <thematic_layers_sfe id="2" id_layer="thematic_layers::7" vr_code="Second" />
        </thematic_layers_sfes>
    `, '21__thematic_layers_sfes.xml');

    assert.deepEqual(records, [
        { id: '1', id_layer: 'thematic_layers::7', vr_code: 'Node & link' },
        { id: '2', id_layer: 'thematic_layers::7', vr_code: 'Second' },
    ]);
});

test('rejects malformed XML and records without source identifiers', () => {
    assert.throws(
        () => parseSeedRecords('<data><record></data>', 'broken.xml'),
        /invalid XML/
    );
    assert.throws(
        () => parseSeedRecords('<data><record name="missing" /></data>', 'bad.xml'),
        /no id attribute/
    );
});
