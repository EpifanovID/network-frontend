const isKind = (node, expression) => expression.test(node.data.templateName || node.data.type || '');
const byLabel = (a, b) => a.data.label.localeCompare(b.data.label, 'ru', { numeric: true });

export function buildExpandableNetwork(objects, relations) {
    const roots = objects.filter((node) => isKind(node, /узел связи/i)).sort(byLabel);
    const lines = objects.filter((node) => isKind(node, /линия связи/i)).sort(byLabel);
    const rootIds = new Set(roots.map((node) => node.id));
    const endpoints = new Map(lines.map((line) => [line.id, new Set()]));
    const children = new Map(objects.map((node) => [node.id, new Map()]));
    const byId = new Map(objects.map((node) => [node.id, node]));
    const directEdges = [];
    for (const edge of relations) {
        const { source, target } = edge;
        if (endpoints.has(source) && rootIds.has(target)) endpoints.get(source).add(target);
        else if (endpoints.has(target) && rootIds.has(source)) endpoints.get(target).add(source);
        else if (rootIds.has(source) && rootIds.has(target) && source !== target) directEdges.push(edge);
        else if (edge.label?.trim().toLocaleLowerCase('ru') === 'состоит из'
            && byId.has(target) && !rootIds.has(target) && !endpoints.has(target)) {
            children.get(source)?.set(target, byId.get(target));
        }
    }

    function buildComposition(id, ancestors) {
        return [...children.get(id).values()].sort(byLabel)
            .filter((child) => !ancestors.has(child.id))
            .map((child) => ({
                id: child.id,
                data: child.data,
                children: buildComposition(child.id, new Set([...ancestors, child.id])),
            }));
    }

    const junctions = [];
    const connections = [...directEdges];
    for (const line of lines) {
        const ids = [...endpoints.get(line.id)].sort((a, b) => byLabel(byId.get(a), byId.get(b)));
        const connection = { lineId: line.id, label: line.data.label };
        if (ids.length === 2) {
            connections.push({ ...connection, id: `overview:${line.id}`, source: ids[0], target: ids[1] });
        } else {
            junctions.push(line);
            ids.forEach((target) => connections.push({
                ...connection, id: `overview:${line.id}:${target}`, source: line.id, target,
            }));
        }
    }
    const ports = new Map([...roots, ...junctions].map((node) => [node.id, []]));
    function addPort(id, edge, type) {
        const handle = `overview-${edge.id}-${type}`;
        ports.get(id).push({ id: handle, type, side: rootIds.has(id) ? 'top' : 'bottom' });
        return handle;
    }
    const edges = connections.map((edge, index) => ({
        ...edge,
        type: 'routed',
        sourceLabel: byId.get(edge.source).data.label,
        targetLabel: byId.get(edge.target).data.label,
        sourceHandle: addPort(edge.source, edge, 'source'),
        targetHandle: addPort(edge.target, edge, 'target'),
        data: { laneY: 116 + index * 30, routeLabel: edge.label },
    }));
    const nodes = [...roots, ...junctions].map((node, index) => {
        const isLine = endpoints.has(node.id);
        return {
            id: node.id,
            type: 'networkNode',
            position: { x: (isLine ? index - roots.length : index) * 336, y: isLine ? 0 : 136 + edges.length * 30 },
            data: {
                ...node.data, id: node.id, lng: node.lng, lat: node.lat, isLine,
                routePorts: ports.get(node.id),
                composition: isLine ? [] : buildComposition(node.id, new Set([node.id])),
            },
        };
    });
    return { nodes, edges };
}

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
