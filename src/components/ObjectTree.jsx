import { ReactFlow, Background, Controls, MiniMap } from '@xyflow/react';
import dagre from '@dagrejs/dagre';
import { useMemo } from 'react';
import '@xyflow/react/dist/style.css';

import { buildObjectSubtree } from '../utils/objectTree';

const NODE_WIDTH = 180;
const NODE_HEIGHT = 60;

function layoutGraph(nodes, edges) {
    const dagreGraph = new dagre.graphlib.Graph();
    dagreGraph.setDefaultEdgeLabel(() => ({}));
    dagreGraph.setGraph({ rankdir: 'TB', nodesep: 60, ranksep: 100 });

    nodes.forEach((node) => {
        dagreGraph.setNode(node.id, {
            width: NODE_WIDTH,
            height: NODE_HEIGHT,
        });
    });

    edges.forEach((edge) => {
        dagreGraph.setEdge(edge.source, edge.target);
    });

    dagre.layout(dagreGraph);

    return nodes.map((node) => {
        const position = dagreGraph.node(node.id);
        return {
            ...node,
            position: {
                x: position.x - NODE_WIDTH / 2,
                y: position.y - NODE_HEIGHT / 2,
            },
        };
    });
}

function ObjectTree({ nodes: graphNodes, edges: graphEdges, rootId }) {
    const tree = useMemo(
        () => buildObjectSubtree(graphNodes, graphEdges, rootId),
        [graphNodes, graphEdges, rootId]
    );
    const nodes = useMemo(
        () => layoutGraph(
            tree.nodes.map((node) => ({
                id: node.id,
                position: { x: 0, y: 0 },
                data: {
                    label: node.data.label,
                    type: node.data.type,
                },
                type: 'default',
            })),
            tree.edges
        ),
        [tree]
    );

    if (nodes.length === 1) {
        return (
            <div className="object-tree__status" role="status">
                Для этого узла в базе нет дочерних связей.
            </div>
        );
    }
    if (!nodes.length) {
        return (
            <div className="object-tree__status" role="status">
                Для объекта не найдена структура.
            </div>
        );
    }

    return (
        <div className="object-tree">
            <ReactFlow
                nodes={nodes}
                edges={tree.edges}
                fitView
                nodesDraggable={false}
                nodesConnectable={false}
            >
                <Background />
                <Controls />
                <MiniMap />
            </ReactFlow>
        </div>
    );
}

export default ObjectTree;