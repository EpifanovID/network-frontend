// Returns 0 outside the ring, 1 inside, and 2 on its boundary.
function locateInRing(lng, lat, ring) {
    let inside = false;
    for (let i = 0, previous = ring.length - 1; i < ring.length; previous = i++) {
        const [x, y] = ring[i];
        const [px, py] = ring[previous];
        if (lng >= Math.min(x, px) && lng <= Math.max(x, px)
            && lat >= Math.min(y, py) && lat <= Math.max(y, py)
            && Math.abs((lng - x) * (py - y) - (lat - y) * (px - x)) < 1e-10) {
            return 2;
        }
        if ((y > lat) !== (py > lat) && lng < x + (px - x) * (lat - y) / (py - y)) {
            inside = !inside;
        }
    }
    return Number(inside);
}

export function containsMapPoint(geometry, lng, lat) {
    const polygons = geometry.type === 'Polygon' ? [geometry.coordinates] : geometry.coordinates;
    return polygons.some(([outline, ...holes]) =>
        locateInRing(lng, lat, outline) > 0
        && holes.every((hole) => locateInRing(lng, lat, hole) !== 1)
    );
}
