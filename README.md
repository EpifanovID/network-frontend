# React + Vite

This template provides a minimal setup to get React working in Vite with HMR and some ESLint rules.

## PostgreSQL-backed graph

The network graph reads SFE nodes from `imc.thematic_layers_sfes` and direct
SFE-to-SFE links from `imc.thematic_layers_sfe_linkings` (`id_ls_sfe`). Link
targets stored as external catalogue records are not drawn as graph edges.
Node labels come from `vr_code`; the node type and layer are read from the
related IMC records.

Each node passport links to `/objects/:id`, where the selected SFE is shown as
the root of a tree built from its reachable outgoing SFE links. The tree uses
the same database graph data as the network view.

To create the example nodes УС4–УС9 and their sample connections, run
`npm run db:seed-demo-nodes`. The command creates their SFE records, stores
coordinates in `imc.network_node_locations`, and represents each connection
with a line SFE and its two endpoint links in one transaction. It is safe to
rerun and rejects conflicting node or line codes rather than overwriting
existing objects. The graph API then loads the nodes, coordinates, and
connections directly from PostgreSQL.

The source PostgreSQL schema and trigger definitions are in
`database/migrations`. They were copied from the supplied IMC database scripts;
the seed XML files, user records, and logs are intentionally not included.

1. Install PostgreSQL and create an empty database named `imc_db`, or use an
   already populated IMC database.
2. Copy `.env.example` to `.env` and set `DATABASE_URL` to the local database.
   Keep `.env` private; it is excluded from Git.
3. For a new empty database, apply the supplied schema and frontend additions:

   ```powershell
   npm run db:migrate
   ```

   Run this with a database owner account that can create extensions and
   objects as `postgres`. This installs the schema only; it does not import the
   original XML seed data.
4. For an existing database that already has the IMC schema, apply only the
   frontend migration:

   ```powershell
   npm run db:migrate -- --existing-schema
   ```

   This creates the `imc.network_node_locations` table used to store map
   coordinates separately from the supplied schema.
5. If you want to import the original sample data, first back up the database.
   The standard `init_files` set includes user accounts and password hashes.
   Import it into an empty IMC schema, providing the extracted folder and its
   configuration file:

   ```powershell
   npm run db:import -- --seed-dir "C:\path\to\imc_init\init_files" --config "C:\path\to\imc_init\config\imc_init_config.xml"
   ```

   The importer uses parameterized SQL, runs in one transaction, skips database-
   managed dictionaries, and refuses to import if a target table already
   contains records. It does not copy seed data or credentials into this
   repository. Do not run the original initializer; it logs the database
   password and builds SQL through string concatenation.
6. Start the API and Vite in separate terminals:

   ```powershell
   npm run dev:api
   npm run dev
   ```

The API binds to `127.0.0.1` by default and the Vite development server proxies
`/api` requests to it. It returns all SFE nodes and direct SFE links. In
map-free graph mode, nodes without coordinates are laid out automatically.
Select a node, enter longitude and latitude in its passport, and save; the
coordinates are persisted in PostgreSQL. The map displays located nodes only.
The API has no authentication and is intended for local development; do not
expose it to an untrusted network.
The database account in `DATABASE_URL` needs read access to the IMC tables and
`SELECT`, `INSERT`, and `UPDATE` access to `imc.network_node_locations`.

To use the supplied IMC records, configure the API to connect to a database
where those records have already been loaded. The old initialization utility
is not run by this project. It logs database passwords and constructs SQL by
string concatenation, so do not use it with untrusted XML or production
credentials.

## Offline map

The physical map uses two local PMTiles archives: an overview of Russia up to
zoom 8, and detailed coverage within 25 km of every coordinate saved in
`imc.network_node_locations` from zoom 9 onward. Map tiles, style, sprites, and
glyphs are served by the app itself; the map makes no requests to an external
map provider at runtime.

The generated archives are intentionally excluded from Git:
`public/maps/network-overview.pmtiles` and
`public/maps/network-areas.pmtiles`. Generate the detailed archive on Windows:

1. Install Git, Java 21 or newer, and Maven.
   If Java and Maven are extracted under `D:\NetworkMapBuild\tools\jdk` and
   `D:\NetworkMapBuild\tools\maven`, the script detects them automatically;
   they do not need to be added to the system `PATH`.
2. Ensure the build drive will have at least 35 GB free after source downloads.
   The Russia OSM extract itself is about 4 GB; the result archive is clipped
   to the object coverage areas.
3. Run from the project root:

   ```powershell
   .\scripts\build-offline-map.ps1 -BuildRoot D:\NetworkMapBuild
   ```

   This command is for a PowerShell terminal. If using `cmd`, run:

   ```bat
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\build-offline-map.ps1" -BuildRoot "D:\NetworkMapBuild"
   ```

The script creates the coverage polygons locally from the PostgreSQL object coordinates,
downloads the Protomaps basemap builder and current Geofabrik Russia OSM
extract, builds zoom levels through 15, and copies the clipped archive into
`public/maps`. Completed downloads in the build cache are reused on restart.
Do not start another build while one is running; the script now detects an
active builder and exits with a clear message instead of trying to replace its
open JAR.
The largest input files are removed after they have been read to leave more
space for tile generation; if generation later fails, those inputs may need
to be downloaded again. The map archive is not included in source control;
repeat this step on each machine that needs the offline map. The app must be
served over HTTP (for example, with `npm run dev`), not opened as a `file://`
URL.

To generate the country and regional overview archive, run the same script
with `-OverviewOnly`. It builds the unclipped Russia source through zoom 8
and writes `public/maps/network-overview.pmtiles`; this overview supplies
regional context outside the detailed object areas.

   ```powershell
   .\scripts\build-offline-map.ps1 -BuildRoot D:\NetworkMapBuild -OverviewOnly
   ```

   ```bat
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\build-offline-map.ps1" -BuildRoot "D:\NetworkMapBuild" -OverviewOnly
   ```

Use the map control in the upper-left corner to choose a basemap, military
district boundaries, or Russian regional boundaries. To regenerate the local
regional GeoJSON from the pinned geoBoundaries ADM1 dataset, run
`npm run build:russia-regions`.

In "Только карта" mode, only the Russian country outline is shown; other
country borders are hidden. This outline is dissolved from the five district
polygons, using the same territorial convention as the other overlays.
Regenerate it with `npm run build:russia-outline` after rebuilding districts.
In district and region modes, basemap country borders remain visible.
Polygon fills retain their closed rings, but visible outlines are separate
line features with technical closing edges at +/-180 degrees removed. This
prevents a false vertical border through Chukotka and Wrangel Island in all
three modes without altering the underlying territorial polygons.
Built-in administrative boundaries and regional labels are hidden
to avoid duplicate lines and labels. Only the selected overlay is downloaded;
an unavailable or invalid GeoJSON displays an overlay error while the basemap
and graph remain usable. Switch away and back to retry loading.

Both generators share the administrative membership in
`scripts/map-boundaries.mjs`. The regional layer contains 89 features, including
the six disputed territories included in the existing district layer's Russian
administrative assignment. These six use UKR source geometries and carry
`sourceCountry: "UKR"` and `disputed: true`. The assignment is a map convention,
not a statement of international recognition or current territorial control.
The four oblast outlines show full administrative extents, not front lines.

To avoid downloading a large optional popularity-ranking table, the build uses
default POI zoom rules rather than QRank prominence. This does not remove OSM
roads, places, or POI features from the map.

Map data is based on OpenStreetMap and is distributed under the ODbL. Keep the
visible map attribution and see [map asset notices](./public/maps/ATTRIBUTION.md)
before redistributing the generated archive.

If either local archive is missing or unavailable, the map displays an
explicit setup message. Assign coordinates to nodes first, then regenerate the
detailed archive so offline coverage includes their locations.

The map also displays the five military-district boundaries and labels. The
outlines dissolve federal-subject boundaries according to Presidential Decree
No. 141 of February 26, 2024. Regenerate the local GeoJSON layer with
`npm run build:military-districts`; this downloads pinned geoBoundaries ADM1
data derived from OpenStreetMap (2017 boundary snapshot). The Southern District
includes Crimea, Sevastopol, Donetsk, Luhansk, Kherson, and Zaporizhzhia under
the Russian administrative assignment. The four Ukrainian oblast outlines
follow their full administrative extents, not current lines of control.
See [map asset notices](./public/maps/ATTRIBUTION.md).

## Running the app

Install dependencies with `npm install`, configure PostgreSQL as described
above, then run `npm run dev:api` and `npm run dev` in separate terminals.

Currently, two official plugins are available:

- [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react) uses [Oxc](https://oxc.rs)
- [@vitejs/plugin-react-swc](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react-swc) uses [SWC](https://swc.rs/)

## React Compiler

The React Compiler is not enabled on this template because of its impact on dev & build performances. To add it, see [this documentation](https://react.dev/learn/react-compiler/installation).

## Expanding the ESLint configuration

If you are developing a production application, we recommend using TypeScript with type-aware lint rules enabled. Check out the [TS template](https://github.com/vitejs/vite/tree/main/packages/create-vite/template-react-ts) for information on how to integrate TypeScript and [`typescript-eslint`](https://typescript-eslint.io) in your project.
