function hasCoordinates(node) {
    return Number.isFinite(node.lng) && Number.isFinite(node.lat);
}

export function buildMapEdges(objects, relations) {
    const objectsById = new Map(objects.map((node) => [node.id, node]));
    const locatedIds = new Set(
        objects.filter(hasCoordinates).map((node) => node.id)
    );
    const linksByLineId = new Map();
    const mapEdges = [];

    relations.forEach((edge) => {
        const source = objectsById.get(edge.source);
        if (source?.data?.templateName?.toLowerCase().includes('линия связи')) {
            const links = linksByLineId.get(source.id) ?? [];
            links.push(edge);
            linksByLineId.set(source.id, links);
            return;
        }

        if (locatedIds.has(edge.source) && locatedIds.has(edge.target)) {
            mapEdges.push({
                ...edge,
                sourceLabel: objectsById.get(edge.source)?.data.label,
                targetLabel: objectsById.get(edge.target)?.data.label,
            });
        }
    });

    linksByLineId.forEach((links, lineId) => {
        const line = objectsById.get(lineId);
        const endpoints = [...new Set(
            links
                .map((edge) => edge.target)
                .filter((targetId) => locatedIds.has(targetId))
        )];

        if (endpoints.length < 2) return;

        const [sourceId, ...targetIds] = endpoints;
        targetIds.forEach((targetId, index) => {
            mapEdges.push({
                id: `map-line:${lineId}:${index}`,
                source: sourceId,
                target: targetId,
                label: line.data?.label ?? line.label,
                relationLabel: links[0].label,
                sourceLabel: objectsById.get(sourceId)?.data?.label,
                targetLabel: objectsById.get(targetId)?.data?.label,
            });
        });
    });

    return mapEdges;
}
