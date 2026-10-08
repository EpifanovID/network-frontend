import { useEffect, useState } from 'react';
import { ReactFlow, Background, Controls, MiniMap } from '@xyflow/react';
import dagre from '@dagrejs/dagre';
import '@xyflow/react/dist/style.css';

import { parseXmlTree } from '../utils/xmlTreeParser';

const NODE_WIDTH = 180;
const NODE_HEIGHT = 60;

const dagreGraph = new dagre.graphlib.Graph();
dagreGraph.setDefaultEdgeLabel(() => ({}));

function buildGraph(tree) {
    const nodes = [];
    const edges = [];

    function addNode(node, parentId = null) {
        nodes.push({
            id: node.id,
            position: { x: 0, y: 0 },
            data: { label: node.name, type: node.type },
            type: 'default',
        });

        if (parentId) {
            edges.push({
                id: `${parentId}-${node.id}`,
                source: parentId,
                target: node.id,
                type: 'smoothstep',
            });
        }

        (node.children || []).forEach((child) => {
            addNode(child, node.id);
        });
    }

    (tree.children || []).forEach((node) => {
        addNode(node);
    });

    return { nodes, edges };
}

function layoutGraph(nodes, edges) {
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

function ObjectTree({ treeNumber }) {
    const [nodes, setNodes] = useState([]);
    const [edges, setEdges] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        async function loadTree() {
            try {
                setLoading(true);
                setError(null);

                if (!treeNumber) {
                    throw new Error('Не задан номер дерева');
                }

                const response = await fetch(
                    `/data/trees/tree-${treeNumber}.xml`
                );

                if (!response.ok) {
                    throw new Error(
                        `Не удалось загрузить XML: ${response.status}`
                    );
                }

                const xmlText = await response.text();
                const tree = parseXmlTree(xmlText);
                const graph = buildGraph(tree);
                const laidOut = layoutGraph(graph.nodes, graph.edges);

                setNodes(laidOut);
                setEdges(graph.edges);
            } catch (e) {
                console.error(e);
                setError(e.message);
            } finally {
                setLoading(false);
            }
        }

        loadTree();
    }, [treeNumber]);

    if (loading) {
        return (
            <div className="object-tree__status">
                Загрузка структуры...
            </div>
        );
    }

    if (error) {
        return (
            <div className="object-tree__status">
                Ошибка: {error}
            </div>
        );
    }

    return (
        <div className="object-tree">
            <ReactFlow
                nodes={nodes}
                edges={edges}
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