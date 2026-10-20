export function buildObjectSubtree(nodes, edges, rootId) {
    const nodesById = new Map(nodes.map((node) => [node.id, node]));
    const root = nodesById.get(rootId);
    if (!root) return { nodes: [], edges: [] };

    const outgoingEdges = new Map();
    edges.forEach((edge) => {
        const outgoing = outgoingEdges.get(edge.source) ?? [];
        outgoing.push(edge);
        outgoingEdges.set(edge.source, outgoing);
    });

    const visited = new Set([rootId]);
    const queue = [rootId];
    const treeNodes = [root];
    const treeEdges = [];

    while (queue.length) {
        const sourceId = queue.shift();
        (outgoingEdges.get(sourceId) ?? []).forEach((edge) => {
            const target = nodesById.get(edge.target);
            if (!target || visited.has(target.id)) return;

            visited.add(target.id);
            queue.push(target.id);
            treeNodes.push(target);
            treeEdges.push({
                id: edge.id,
                source: sourceId,
                target: target.id,
                type: 'smoothstep',
                label: edge.label,
            });
        });
    }

    return { nodes: treeNodes, edges: treeEdges };
}
