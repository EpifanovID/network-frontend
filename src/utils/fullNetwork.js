const isKind = (node, expression) => expression.test(node.data.templateName || node.data.type || '');
const byLabel = (a, b) => a.data.label.localeCompare(b.data.label, 'ru', { numeric: true });

export function buildFullNetwork(objects, relations) {
    const byId = new Map(objects.map((node) => [node.id, node]));
    const roots = objects.filter((node) => isKind(node, /узел связи/i)).sort(byLabel);
    const lines = objects.filter((node) => isKind(node, /линия связи/i)).sort(byLabel);
    const rootIds = new Set(roots.map((node) => node.id));
    const lineIds = new Set(lines.map((node) => node.id));
    const valid = relations.filter((edge) => byId.has(edge.source) && byId.has(edge.target));
    const routed = valid.filter((edge) => lineIds.has(edge.source) || lineIds.has(edge.target)
        || (rootIds.has(edge.source) && rootIds.has(edge.target)));
    const routeName = (edge) => byId.get(lineIds.has(edge.source) ? edge.source : edge.target).data.label;
    routed.sort((a, b) => routeName(a).localeCompare(routeName(b), 'ru', { numeric: true })
        || a.id.localeCompare(b.id));
    const routedIds = new Set(routed.map((edge) => edge.id));
    const rootY = 220 + routed.length * 30;
    const positions = new Map();
    const owners = new Map();
    const depths = new Map();
    roots.forEach((node, index) => {
        positions.set(node.id, { x: index * 440, y: rootY });
        owners.set(node.id, node.id);
        depths.set(node.id, 0);
        const queue = [node.id];
        let row = 0;
        for (let i = 0; i < queue.length; i += 1) {
            for (const edge of valid.filter((edge) => edge.source === queue[i] && !routedIds.has(edge.id))) {
                if (rootIds.has(edge.target) || lineIds.has(edge.target) || owners.has(edge.target)) continue;
                const depth = (depths.get(queue[i]) || 0) + 1;
                owners.set(edge.target, node.id);
                depths.set(edge.target, depth);
                positions.set(edge.target, { x: index * 440 + depth * 24, y: rootY + 180 + row++ * 128 });
                queue.push(edge.target);
            }
        }
    });
    const lineCenter = (roots.length - 1) * 220;
    lines.forEach((node, index) => positions.set(node.id,
        { x: lineCenter + (index - (lines.length - 1) / 2) * 280, y: 0 }));
    let orphanRow = 0;
    objects.filter((node) => !positions.has(node.id)).sort(byLabel).forEach((node) =>
        positions.set(node.id, { x: roots.length * 440, y: rootY + orphanRow++ * 128 }));

    const lineEndpoints = new Map(lines.map((line) => [line.id, new Set()]));
    for (const edge of routed) {
        if (lineIds.has(edge.source) && rootIds.has(edge.target)) lineEndpoints.get(edge.source).add(edge.target);
        if (lineIds.has(edge.target) && rootIds.has(edge.source)) lineEndpoints.get(edge.target).add(edge.source);
    }
    const ports = new Map();
    const portFor = (id, edge, role) => {
        const list = ports.get(id) || [];
        const handleId = `route-${edge.id}-${role}`;
        list.push({ id: handleId, type: role, side: lineIds.has(id) ? 'bottom' : 'top' });
        ports.set(id, list);
        return handleId;
    };
    const routeIndex = new Map(routed.map((edge, index) => [edge.id, index]));
    const edges = valid.map((edge) => {
        const lineId = lineIds.has(edge.source) ? edge.source : lineIds.has(edge.target) ? edge.target : null;
        const isRoute = routedIds.has(edge.id);
        const owner = owners.get(edge.target) || owners.get(edge.source);
        const rootX = positions.get(owner)?.x ?? positions.get(edge.target).x;
        return { ...edge, type: 'routed',
            sourceHandle: isRoute ? portFor(edge.source, edge, 'source') : 'right-source',
            targetHandle: isRoute ? portFor(edge.target, edge, 'target') : 'right-target',
            sourceLabel: byId.get(edge.source).data.label,
            targetLabel: byId.get(edge.target).data.label,
            lineId,
            label: edge.label?.trim().toLocaleLowerCase('ru') === 'состоит из' ? 'имеет' : edge.label,
            data: isRoute
                ? { laneY: 120 + routeIndex.get(edge.id) * 30, routeLabel: `${byId.get(edge.source).data.label} · ${byId.get(edge.target).data.label}` }
                : { gutterX: rootX + 190 + (depths.get(edge.source) || 0) * 16 },
        };
    });
    const nodes = objects.map((node) => ({ id: node.id, type: 'networkNode', position: positions.get(node.id),
        data: { ...node.data, id: node.id, lng: node.lng, lat: node.lat,
            routePorts: ports.get(node.id) || [],
            isLine: lineIds.has(node.id),
            endpointIds: [...(lineEndpoints.get(node.id) || [])],
            endpointLabel: lineIds.has(node.id)
                ? [...lineEndpoints.get(node.id)].map((id) => byId.get(id).data.label).sort().join(' ↔ ') || 'Конечные узлы не указаны'
                : null,
        } }));
    return { nodes, edges };
}

export function getNetworkSelection(graph, passport) {
    const edge = passport?.type === 'edge' ? graph.edges.find((edge) => edge.id === passport.data.id) : null;
    const node = passport?.type === 'node' ? graph.nodes.find((node) => node.id === passport.nodeId) : null;
    const lineId = node?.data.isLine ? node.id : edge?.lineId;
    if (lineId) {
        const related = graph.edges.filter((edge) => edge.lineId === lineId);
        return { nodeIds: new Set([lineId, ...related.flatMap((edge) => [edge.source, edge.target])]),
            edgeIds: new Set(related.map((edge) => edge.id)) };
    }
    return { nodeIds: new Set(edge ? [edge.source, edge.target] : []), edgeIds: new Set(edge ? [edge.id] : []) };
}
