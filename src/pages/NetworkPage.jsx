import {
    ReactFlow,
    Background,
    Controls,
    MiniMap,
} from '@xyflow/react';

import { useState } from 'react';

import NetworkNode from '../components/NetworkNode';
import Passport from '../components/Passport';

import '@xyflow/react/dist/style.css';
import '../App.css';

const initialNodes = [
    {
        id: '1',
        type: 'networkNode',
        position: { x: 100, y: 100 },
        data: {
            label: 'Объект 1',
            type: 'antenna1',
        },
    },
    {
        id: '2',
        type: 'networkNode',
        position: { x: 400, y: 50 },
        data: {
            label: 'Объект 2',
            type: 'antenna2',
        },
    },
    {
        id: '3',
        type: 'networkNode',
        position: { x: 200, y: 400 },
        data: {
            label: 'Объект 3',
            type: 'antenna3',
        },
    },
    {
        id: '4',
        type: 'networkNode',
        position: { x: 700, y: 150 },
        data: {
            label: 'Объект 4',
            type: 'antenna1',
        },
    },
    {
        id: '5',
        type: 'networkNode',
        position: { x: 900, y: 350 },
        data: {
            label: 'Объект 5',
            type: 'antenna2',
        },
    },
    {
        id: '6',
        type: 'networkNode',
        position: { x: 600, y: 400 },
        data: {
            label: 'Объект 6',
            type: 'antenna1',
        },
    },
    {
        id: '7',
        type: 'networkNode',
        position: { x: 0, y: 200 },
        data: {
            label: 'Объект 7',
            type: 'antenna3',
        },
    },
    {
        id: '8',
        type: 'networkNode',
        position: { x: 350, y: 200 },
        data: {
            label: 'Объект 8',
            type: 'antenna1',
        },
    },
    {
        id: '9',
        type: 'networkNode',
        position: { x: 350, y: 600 },
        data: {
            label: 'Объект 9',
            type: 'antenna3',
        },
    },
    {
        id: '10',
        type: 'networkNode',
        position: { x: 50, y: 500 },
        data: {
            label: 'Объект 10',
            type: 'antenna1',
        },
    },
];

function getConnectionHandles(source, target) {
    const dx =
        target.position.x - source.position.x;

    const dy =
        target.position.y - source.position.y;

    if (Math.abs(dx) >= Math.abs(dy)) {
        if (dx >= 0) {
            return {
                sourceHandle: 'right-source',
                targetHandle: 'left-target',
            };
        }

        return {
            sourceHandle: 'left-source',
            targetHandle: 'right-target',
        };
    }

    if (dy >= 0) {
        return {
            sourceHandle: 'bottom-source',
            targetHandle: 'top-target',
        };
    }

    return {
        sourceHandle: 'top-source',
        targetHandle: 'bottom-target',
    };
}

function createEdge(id, sourceId, targetId) {
    const source = initialNodes.find(
        (node) => node.id === sourceId
    );

    const target = initialNodes.find(
        (node) => node.id === targetId
    );

    const handles = getConnectionHandles(
        source,
        target
    );

    return {
        id,
        source: sourceId,
        target: targetId,
        type: 'straight',
        ...handles,
    };
}

const initialEdges = [
    createEdge('1-2', '1', '2'),
    createEdge('1-3', '1', '3'),
    createEdge('2-4', '2', '4'),
    createEdge('3-4', '3', '4'),
    createEdge('5-6', '5', '6'),
    createEdge('5-9', '5', '9'),
    createEdge('6-9', '6', '9'),
    createEdge('7-8', '7', '8'),
];

const connectedHandles = {};

initialEdges.forEach((edge) => {
    if (!connectedHandles[edge.source]) {
        connectedHandles[edge.source] = new Set();
    }

    if (!connectedHandles[edge.target]) {
        connectedHandles[edge.target] = new Set();
    }

    connectedHandles[edge.source].add(
        edge.sourceHandle
    );

    connectedHandles[edge.target].add(
        edge.targetHandle
    );
});

const nodes = initialNodes.map((node) => ({
    ...node,
    data: {
        ...node.data,
        connectedHandles:
            connectedHandles[node.id] || new Set(),
    },
}));

const nodeTypes = {
    networkNode: NetworkNode,
};

function NetworkPage() {
    const [passport, setPassport] = useState(null);

    const [currentNodes, setCurrentNodes] =
        useState(nodes);

    const [reactFlowInstance, setReactFlowInstance] =
        useState(null);

    const [, setViewport] = useState(null);

    return (
        <div className="app">
            <ReactFlow
                nodes={currentNodes}
                edges={initialEdges}
                nodeTypes={nodeTypes}
                fitView
                nodesDraggable={false}

                onInit={(instance) => {
                    setReactFlowInstance(instance);
                }}

                onViewportChange={(newViewport) => {
                    setViewport(newViewport);

                    requestAnimationFrame(() => {
                        if (
                            !passport ||
                            !reactFlowInstance
                        ) {
                            return;
                        }

                        if (
                            passport.type === 'node'
                        ) {
                            const nodeElement =
                                document.querySelector(
                                    `.react-flow__node[data-id="${passport.nodeId}"]`
                                );

                            if (!nodeElement) {
                                return;
                            }

                            const rect =
                                nodeElement.getBoundingClientRect();

                            setPassport(
                                (currentPassport) => ({
                                    ...currentPassport,
                                    position: {
                                        x:
                                            rect.right +
                                            15,
                                        y: rect.top,
                                    },
                                })
                            );
                        }

                        if (
                            passport.type === 'edge' &&
                            passport.flowPosition
                        ) {
                            const position =
                                reactFlowInstance.flowToScreenPosition(
                                    passport.flowPosition
                                );

                            setPassport(
                                (currentPassport) => ({
                                    ...currentPassport,
                                    position,
                                })
                            );
                        }
                    });
                }}

                onNodesChange={(changes) => {
                    setCurrentNodes(
                        (currentNodes) => {
                            let updatedNodes = [
                                ...currentNodes,
                            ];

                            changes.forEach(
                                (change) => {
                                    if (
                                        change.type ===
                                            'position' &&
                                        change.position
                                    ) {
                                        updatedNodes =
                                            updatedNodes.map(
                                                (node) =>
                                                    node.id ===
                                                    change.id
                                                        ? {
                                                              ...node,
                                                              position:
                                                                  change.position,
                                                          }
                                                        : node
                                            );
                                    }
                                }
                            );

                            return updatedNodes;
                        }
                    );
                }}

                onNodeClick={(_, node) => {
                    const nodeElement =
                        document.querySelector(
                            `.react-flow__node[data-id="${node.id}"]`
                        );

                    if (!nodeElement) {
                        return;
                    }

                    const rect =
                        nodeElement.getBoundingClientRect();

                    setPassport({
                        type: 'node',

                        data: {
                            id: node.id,
                            ...node.data,
                        },

                        nodeId: node.id,

                        position: {
                            x: rect.right + 15,
                            y: rect.top,
                        },
                    });
                }}

                onEdgeClick={(event, edge) => {
                    if (!reactFlowInstance) {
                        return;
                    }

                    const flowPosition =
                        reactFlowInstance.screenToFlowPosition(
                            {
                                x: event.clientX,
                                y: event.clientY,
                            }
                        );

                    setPassport({
                        type: 'edge',
                        data: edge,
                        flowPosition,
                        position: {
                            x: event.clientX,
                            y: event.clientY,
                        },
                    });
                }}

                onPaneClick={() => {
                    setPassport(null);
                }}
            >
                <Background />
                <Controls />
                <MiniMap />
            </ReactFlow>

            {passport && passport.position && (
                <Passport
                    type={passport.type}
                    data={passport.data}
                    position={passport.position}
                />
            )}
        </div>
    );
}

export default NetworkPage;