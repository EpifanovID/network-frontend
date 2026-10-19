CREATE TABLE IF NOT EXISTS imc.network_node_locations (
    id_sfe uuid PRIMARY KEY
        REFERENCES imc.thematic_layers_sfes (id_sfe) ON DELETE CASCADE,
    longitude double precision NOT NULL
        CHECK (longitude >= -180 AND longitude <= 180),
    latitude double precision NOT NULL
        CHECK (latitude >= -90 AND latitude <= 90),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

COMMENT ON TABLE imc.network_node_locations IS
    'Map coordinates maintained by the network frontend for IMC SFE nodes.';
