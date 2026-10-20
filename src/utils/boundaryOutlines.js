function isDatelineSeam(start, end) {
    const epsilon = 1e-7;
    return Math.abs(Math.abs(start[0]) - 180) < epsilon
        && Math.abs(start[0] - end[0]) < epsilon;
}

// A polygon split at +/-180 needs closing edges for its fill. Those edges
// are a file-format seam, not a coastline or administrative boundary.
export function polygonOutlineSegments(geometry) {
    const polygons = geometry.type === 'Polygon'
        ? [geometry.coordinates] : geometry.coordinates;
    const lines = [];
    for (const polygon of polygons) {
        for (const ring of polygon) {
            let line = [];
            for (let index = 1; index < ring.length; index += 1) {
                const start = ring[index - 1];
                const end = ring[index];
                if (isDatelineSeam(start, end)) {
                    if (line.length > 1) lines.push(line);
                    line = [];
                } else {
                    if (!line.length) line.push(start);
                    line.push(end);
                }
            }
            if (line.length > 1) lines.push(line);
        }
    }
    return lines;
}

export function withBoundaryOutlines(collection) {
    const outlines = collection.features
        .filter(({ geometry }) => ['Polygon', 'MultiPolygon'].includes(geometry.type))
        .map((feature) => ({
            type: 'Feature',
            properties: { ...feature.properties, kind: 'outline' },
            geometry: {
                type: 'MultiLineString',
                coordinates: polygonOutlineSegments(feature.geometry),
            },
        }));
    return { ...collection, features: [...collection.features, ...outlines] };
}
