// Administrative borders and names come from our overlays.
export function prepareBasemapLayers(layers) {
    return layers.map((layer) => (
        /^(overview|detail)-(boundaries|places_region)$/.test(layer.id)
            ? { ...layer, layout: { ...layer.layout, visibility: 'none' } }
            : layer
    ));
}

export function applyBoundaryVisibility(map, mode) {
    for (const prefix of ['overview', 'detail']) {
        map.setLayoutProperty(`${prefix}-boundaries_country`, 'visibility',
            mode === 'districts' || mode === 'regions' ? 'visible' : 'none');
    }
    map.setLayoutProperty('russia-outline', 'visibility', mode === 'base' ? 'visible' : 'none');
    for (const [key, prefix] of [
        ['districts', 'military-districts'],
        ['regions', 'russia-regions'],
    ]) {
        for (const suffix of ['fill', 'outline', 'labels']) {
            map.setLayoutProperty(`${prefix}-${suffix}`, 'visibility',
                mode === key ? 'visible' : 'none');
        }
    }
}

export async function loadBoundaryData(url, signal) {
    const response = await fetch(url, { signal });
    if (!response.ok) throw new Error(`Boundary request failed: HTTP ${response.status}`);
    const data = await response.json();
    if (data.type !== 'FeatureCollection' || !Array.isArray(data.features)
        || data.features.length === 0
        || data.features.some((feature) => feature.type !== 'Feature' || !feature.geometry
            || !['Polygon', 'MultiPolygon', 'Point'].includes(feature.geometry.type)
            || !Array.isArray(feature.geometry.coordinates))) {
        throw new Error('Invalid boundary GeoJSON');
    }
    return data;
}
