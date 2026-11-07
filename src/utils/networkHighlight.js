import { containsMapPoint } from './mapFilters.js';

export const highlightInterfaces = ['STM-16', 'STM-4', 'STM-1', 'E1', 'ОЦК', 'ТЧ-У'];

export const emptyHighlight = {
    regions: [], districts: [], classes: [], interfaces: [],
    betweenRegions: ['', ''], betweenDistricts: ['', ''], hideOthers: false,
};

export function getManualHighlight(nodes, mapEdges, graphEdges) {
    const lines = new Set();
    const junctions = new Map();
    for (const edge of [...mapEdges, ...graphEdges]) {
        if (nodes.has(edge.source) && nodes.has(edge.target)) lines.add(edge.id);
    }
    for (const edge of graphEdges) {
        if (!edge.lineId || ![edge.source, edge.target].includes(edge.lineId)) continue;
        const endpoint = edge.source === edge.lineId ? edge.target : edge.source;
        if (!nodes.has(endpoint)) continue;
        const branches = junctions.get(edge.lineId) ?? [];
        branches.push(edge.id);
        junctions.set(edge.lineId, branches);
    }
    for (const branches of junctions.values()) {
        if (branches.length >= 2) branches.forEach((id) => lines.add(id));
    }
    return { nodes, lines, edgeIdsOnly: true };
}

function isPair([first, second]) {
    return Boolean(first && second && first !== second);
}

export function hasHighlightCriteria(filters) {
    return Boolean(filters.regions.length || filters.districts.length || filters.classes.length
        || filters.interfaces.length || isPair(filters.betweenRegions) || isPair(filters.betweenDistricts));
}

export function describeHighlightFilters(filters, boundaries) {
    if (!hasHighlightCriteria(filters)) return 'Без фильтра';

    const regionNames = new Map(boundaries?.regions.map(({ properties }) => [properties.shapeISO, properties.name]));
    const regionName = (id) => regionNames.get(id) ?? id;
    const parts = [];
    if (filters.regions.length) parts.push(filters.regions.map(regionName).join(', '));
    if (filters.districts.length) parts.push(filters.districts.join(', '));
    if (filters.classes.length) parts.push(`Класс узлов: ${filters.classes.join(', ')}`);
    if (isPair(filters.betweenRegions)) parts.push(`Линии: ${filters.betweenRegions.map(regionName).join(' ↔ ')}`);
    if (isPair(filters.betweenDistricts)) parts.push(`Линии: ${filters.betweenDistricts.join(' ↔ ')}`);
    if (filters.interfaces.length) parts.push(`Интерфейсы: ${filters.interfaces.join(', ')}`);
    if (filters.hideOthers) parts.push('Скрыто остальное');
    return parts.join(' · ');
}

export function buildNetworkHighlight(objects, relations, boundaries, filters) {
    if (!hasHighlightCriteria(filters)) return null;

    const nodes = new Set();
    const lines = new Set();
    const hasTerritoryFilter = filters.regions.length > 0 || filters.districts.length > 0;
    const hasClassFilter = filters.classes.length > 0;
    const regions = new Map((boundaries?.regions ?? []).map((feature) => [feature.properties.shapeISO, feature.geometry]));
    const districts = new Map((boundaries?.districts ?? []).map((feature) => [feature.properties.district, feature.geometry]));
    const byId = new Map(objects.map((object) => [object.id, object]));
    const adjacent = new Map(objects.map(({ id }) => [id, []]));
    for (const { source, target } of relations) {
        adjacent.get(source)?.push(target);
        adjacent.get(target)?.push(source);
    }
    const kind = ({ data }) => data.templateName || data.type || '';
    const inTerritory = (node, geometry) => geometry && Number.isFinite(node?.lng)
        && Number.isFinite(node.lat) && containsMapPoint(geometry, node.lng, node.lat);
    const inSelectedTerritory = (node) => filters.regions.some((id) => inTerritory(node, regions.get(id)))
        || filters.districts.some((id) => inTerritory(node, districts.get(id)));
    const matchesPair = (ends, pair, areas) => isPair(pair) && ends.some((first) =>
        inTerritory(first, areas.get(pair[0])) && ends.some((second) =>
            second !== first && inTerritory(second, areas.get(pair[1]))));

    const territorialNodes = new Set();
    for (const object of objects) {
        const { id, data } = object;
        const properties = Object.entries(data.highlightProperties ?? {});
        if (/узел связи/i.test(kind(object))) {
            if (inSelectedTerritory(object)) territorialNodes.add(id);
            const nodeClass = data.nodeClass || properties.find(([name]) => /^класс(?:\s|$|\()/i.test(name))?.[1];
            const matchesClass = filters.classes.includes(String(nodeClass ?? '').trim().toUpperCase());
            if ((hasTerritoryFilter || hasClassFilter)
                && (!hasTerritoryFilter || territorialNodes.has(id))
                && (!hasClassFilter || matchesClass)) {
                nodes.add(id);
            }
        }
        if (filters.interfaces.length && /канал связи/i.test(kind(object))) {
            const values = [data.label, ...properties.filter(([name]) => /интерфейс/i.test(name)).map(([, value]) => value)];
            const interfaces = values.flatMap((value) => String(value ?? '').toUpperCase()
                .match(/STM[-– ]?(?:16|4|1)(?!\d)|Е1|E1|ОЦК|ТЧ[-– ]?У/g) ?? [])
                .map((value) => value.replace(/^STM[-– ]?/, 'STM-').replace(/^ТЧ[-– ]?/, 'ТЧ-').replace('Е1', 'E1'));
            if (interfaces.some((value) => filters.interfaces.includes(value))) {
                nodes.add(id);
                for (const relatedId of adjacent.get(id)) {
                    const related = byId.get(relatedId);
                    if (related && /линия связи/i.test(kind(related))) lines.add(relatedId);
                }
            }
        }
    }

    const matchesLine = (ends) => (!hasClassFilter && ends.length > 1 && ends.every(({ id }) => territorialNodes.has(id)))
        || matchesPair(ends, filters.betweenRegions, regions) || matchesPair(ends, filters.betweenDistricts, districts);
    for (const object of objects) {
        if (!/линия связи/i.test(kind(object))) continue;
        const ends = [...new Set(adjacent.get(object.id))].map((id) => byId.get(id))
            .filter((node) => node && /узел связи/i.test(kind(node)));
        if (matchesLine(ends)) lines.add(object.id);
    }
    for (const { id, source, target } of relations) {
        const ends = [byId.get(source), byId.get(target)];
        if (ends.every((node) => node && /узел связи/i.test(kind(node))) && matchesLine(ends)) lines.add(id);
    }
    return { nodes, lines };
}
