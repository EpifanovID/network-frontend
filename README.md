# React + Vite

This template provides a minimal setup to get React working in Vite with HMR and some ESLint rules.

## Offline map

The physical map uses two local PMTiles archives: an overview of Russia up to
zoom 8, and detailed coverage within 25 km of each object in
`src/data/networkData.js` from zoom 9 onward. Map tiles, style, sprites, and
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

The script creates the coverage polygons locally from the object coordinates,
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

To avoid downloading a large optional popularity-ranking table, the build uses
default POI zoom rules rather than QRank prominence. This does not remove OSM
roads, places, or POI features from the map.

Map data is based on OpenStreetMap and is distributed under the ODbL. Keep the
visible map attribution and see [map asset notices](./public/maps/ATTRIBUTION.md)
before redistributing the generated archive.

If either local archive is missing or unavailable, the map displays an
explicit setup message. Adding or moving objects requires regenerating the
detailed archive so the offline coverage matches their coordinates.

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

Install dependencies with `npm install`, then run `npm run dev`.

Currently, two official plugins are available:

- [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react) uses [Oxc](https://oxc.rs)
- [@vitejs/plugin-react-swc](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react-swc) uses [SWC](https://swc.rs/)

## React Compiler

The React Compiler is not enabled on this template because of its impact on dev & build performances. To add it, see [this documentation](https://react.dev/learn/react-compiler/installation).

## Expanding the ESLint configuration

If you are developing a production application, we recommend using TypeScript with type-aware lint rules enabled. Check out the [TS template](https://github.com/vitejs/vite/tree/main/packages/create-vite/template-react-ts) for information on how to integrate TypeScript and [`typescript-eslint`](https://typescript-eslint.io) in your project.
