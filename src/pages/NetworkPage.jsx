import { Background, Controls, ReactFlow } from '@xyflow/react';
import dagre from '@dagrejs/dagre';
import { useCallback, useEffect, useRef, useState } from 'react';

import Toolbar from '../components/Toolbar';
import PhysicalMap from '../components/PhysicalMap';
import NetworkNode from '../components/NetworkNode';
import NetworkNodeContent from '../components/NetworkNodeContent';
import Passport from '../components/Passport';
import { initialNodes } from '../data/networkData';

import '@xyflow/react/dist/style.css';
import '../App.css';

const edgePairs = [
    ['1', '2'], ['1', '3'], ['2', '4'], ['3', '4'],
    ['5', '6'], ['5', '9'], ['6', '9'], ['7', '8'],
];

const NODE_WIDTH = 132;
const NODE_HEIGHT = 84;
const OBJECT_LOCATIONS_KEY = 'network-frontend-object-locations';

function readObjectLocations() {
    let storedLocations;
    try {
        storedLocations = localStorage.getItem(OBJECT_LOCATIONS_KEY);
    } catch (error) {
        console.error('Не удалось прочитать координаты объектов.', error);
        return initialNodes;
    }

    if (!storedLocations) return initialNodes;

    try {
        const parsed = JSON.parse(storedLocations);
        if (!Array.isArray(parsed)) {
            throw new TypeError('Сохранённые координаты должны быть массивом.');
        }

        const savedById = new Map(
            parsed
                .filter((item) => (
                    item
                    && typeof item.id === 'string'
                    && Number.isFinite(item.lng)
                    && Number.isFinite(item.lat)
                    && item.lng >= -180
                    && item.lng <= 180
                    && item.lat >= -90
                    && item.lat <= 90
                ))
                .map((item) => [item.id, item])
        );

        return initialNodes.map((node) => {
            const saved = savedById.get(node.id);
            return saved
                ? { ...node, lng: saved.lng, lat: saved.lat }
                : node;
        });
    } catch (error) {
        console.error('Не удалось разобрать сохранённые координаты объектов.', error);
        return initialNodes;
    }
}

function writeObjectLocations(objects) {
    try {
        localStorage.setItem(
            OBJECT_LOCATIONS_KEY,
            JSON.stringify(objects.map(({ id, lng, lat }) => ({ id, lng, lat })))
        );
    } catch (error) {
        console.error('Не удалось сохранить координаты объектов.', error);
    }
}

function getConnectionHandles(source, target) {
    const dx = target.position.x - source.position.x;
    const dy = target.position.y - source.position.y;
    const isHorizontal = Math.abs(dx) / NODE_WIDTH >= Math.abs(dy) / NODE_HEIGHT;

    if (isHorizontal) {
        if (dx >= 0) {
            return { sourceHandle: 'right-source', targetHandle: 'left-target' };
        }
        return { sourceHandle: 'left-source', targetHandle: 'right-target' };
    }
    if (dy >= 0) {
        return { sourceHandle: 'bottom-source', targetHandle: 'top-target' };
    }
    return { sourceHandle: 'top-source', targetHandle: 'bottom-target' };
}

function layoutFreeGraph(nodes, edges) {
    const graph = new dagre.graphlib.Graph();
    graph.setDefaultEdgeLabel(() => ({}));
    graph.setGraph({
        rankdir: 'LR',
        nodesep: 42,
        ranksep: 70,
        marginx: 24,
        marginy: 24,
    });

    nodes.forEach((node) => {
        graph.setNode(node.id, { width: NODE_WIDTH, height: NODE_HEIGHT });
    });
    edges.forEach((edge) => {
        graph.setEdge(edge.source, edge.target);
    });

    dagre.layout(graph);

    return nodes.map((node) => {
        const position = graph.node(node.id);
        return {
            ...node,
            position: { x: position.x, y: position.y },
        };
    });
}

function buildGraph(map, objects = initialNodes) {
    let nodes = objects.map((n) => {
        const position = map && typeof map.project === 'function'
            ? map.project([n.lng, n.lat])
            : { x: 0, y: 0 };
        return {
            id: n.id,
            type: 'networkNode',
            position: { x: position.x, y: position.y },
            data: { ...n.data, lng: n.lng, lat: n.lat },
        };
    });

    let edges = edgePairs.map(([sId, tId]) => ({
        id: `${sId}-${tId}`,
        source: sId,
        target: tId,
        type: 'straight',
        style: { stroke: '#718096', strokeWidth: 2 },
    }));

    if (!map || typeof map.project !== 'function') {
        nodes = layoutFreeGraph(nodes, edges);
    }

    const byId = Object.fromEntries(nodes.map((node) => [node.id, node]));
    edges = edges.map((edge) => ({
        ...edge,
        ...getConnectionHandles(byId[edge.source], byId[edge.target]),
    }));

    const connected = {};
    edges.forEach((e) => {
        if (!connected[e.source]) connected[e.source] = new Set();
        if (!connected[e.target]) connected[e.target] = new Set();
        connected[e.source].add(e.sourceHandle);
        connected[e.target].add(e.targetHandle);
    });

    const graphNodes = Object.values(byId).map((n) => ({
        ...n,
        data: {
            ...n.data,
            connectedHandles: connected[n.id] || new Set(),
        },
    }));

    return { nodes: graphNodes, edges };
}

function createEdgePassport(source, target, position, anchorT = 0.5) {
    return {
        type: 'edge',
        data: {
            id: `${source}-${target}`,
            source,
            target,
        },
        position,
        anchorT,
    };
}

function getEdgeAnchorT(event) {
    const line = event.currentTarget;
    const svgBounds = line.ownerSVGElement.getBoundingClientRect();
    const x1 = Number(line.getAttribute('x1'));
    const y1 = Number(line.getAttribute('y1'));
    const dx = Number(line.getAttribute('x2')) - x1;
    const dy = Number(line.getAttribute('y2')) - y1;
    const lengthSquared = dx * dx + dy * dy;
    if (!lengthSquared) return 0.5;

    const clickX = event.clientX - svgBounds.left;
    const clickY = event.clientY - svgBounds.top;
    return Math.min(
        1,
        Math.max(0, ((clickX - x1) * dx + (clickY - y1) * dy) / lengthSquared)
    );
}

function MapGraphOverlay({
    map,
    objects,
    onNodeClick,
    onEdgeClick,
    passport,
    passportElementRef,
    pendingFocusRef,
}) {
    const overlayRef = useRef(null);
    const passportRef = useRef(null);
    const objectsRef = useRef(objects);
    const updateMapRef = useRef(null);

    useEffect(() => {
        passportRef.current = passport;
    }, [passport]);

    useEffect(() => {
        objectsRef.current = objects;
        updateMapRef.current?.();
    }, [objects]);

    useEffect(() => {
        const overlay = overlayRef.current;
        if (!overlay || !map) return;

        const svg = overlay.querySelector('svg');
        let currentViewBox = '';
        const nodeElements = new Map(objectsRef.current.map((node) => {
            const element = overlay.querySelector(
                `.network-map-overlay__node[data-id="${node.id}"]`
            );
            return [node.id, {
                element,
                image: element?.querySelector('img'),
                width: element?.offsetWidth ?? 0,
                height: element?.offsetHeight ?? 0,
            }];
        }));
        const edgeElements = edgePairs.map(([sourceId, targetId]) => ({
            sourceId,
            targetId,
            elements: [
                svg.querySelector(
                    `.network-map-overlay__edge[data-id="${sourceId}-${targetId}"]`
                ),
                overlay.querySelector(
                    `.network-map-overlay__edge-hit[data-id="${sourceId}-${targetId}"]`
                ),
            ],
        }));
        let currentNodeScale = null;
        const update = () => {
            const bounds = overlay.getBoundingClientRect();
            if (!bounds.width || !bounds.height) return;

            const nextViewBox = `0 0 ${bounds.width} ${bounds.height}`;
            if (nextViewBox !== currentViewBox) {
                svg.setAttribute('viewBox', nextViewBox);
                currentViewBox = nextViewBox;
            }
            const nodeScale = Math.min(
                2.5,
                Math.max(0.5, 2 ** ((map.getZoom() - 3) / 2))
            );
            if (nodeScale !== currentNodeScale) {
                nodeElements.forEach(({ element }) => {
                    element?.querySelector('.network-node')?.style.setProperty(
                        '--node-scale',
                        nodeScale
                    );
                });
                currentNodeScale = nodeScale;
            }
            const points = new Map();

            objectsRef.current.forEach((node) => {
                const { element, width, height } = nodeElements.get(node.id);
                if (!element) return;
                const point = map.project([node.lng, node.lat]);
                element.style.transform =
                    `translate3d(${point.x}px, ${point.y}px, 0) translate(-50%, -50%)`;
                points.set(node.id, {
                    x: point.x,
                    y: point.y,
                    width: width * nodeScale,
                    height: height * nodeScale,
                });
            });

            const edgeSegments = new Map();
            edgeElements.forEach(({ sourceId, targetId, elements }) => {
                const source = points.get(sourceId);
                const target = points.get(targetId);
                if (!source || !target) return;

                const dx = target.x - source.x;
                const dy = target.y - source.y;
                const horizontal =
                    Math.abs(dx) / source.width >= Math.abs(dy) / source.height;
                const sourceX = source.x + (
                    horizontal ? Math.sign(dx) * source.width / 2 : 0
                );
                const sourceY = source.y + (
                    horizontal ? 0 : Math.sign(dy) * source.height / 2
                );
                const targetX = target.x - (
                    horizontal ? Math.sign(dx) * target.width / 2 : 0
                );
                const targetY = target.y - (
                    horizontal ? 0 : Math.sign(dy) * target.height / 2
                );
                edgeSegments.set(`${sourceId}-${targetId}`, {
                    x1: sourceX,
                    y1: sourceY,
                    x2: targetX,
                    y2: targetY,
                });

                elements.forEach((element) => {
                    if (!element) return;
                    element.setAttribute('x1', String(sourceX));
                    element.setAttribute('y1', String(sourceY));
                    element.setAttribute('x2', String(targetX));
                    element.setAttribute('y2', String(targetY));
                });
            });

            const activePassport = passportRef.current;
            const passportElement = passportElementRef.current;
            if (!activePassport || !passportElement) return;

            let anchorX;
            let anchorY;
            if (activePassport.type === 'node') {
                const point = points.get(activePassport.nodeId);
                if (!point) return;
                anchorX = point.x + point.width / 2;
                anchorY = point.y - point.height / 2;
            } else {
                const segment = edgeSegments.get(activePassport.data.id);
                if (!segment) return;
                const t = activePassport.anchorT ?? 0.5;
                anchorX = segment.x1 + (segment.x2 - segment.x1) * t;
                anchorY = segment.y1 + (segment.y2 - segment.y1) * t;
            }

            const passportWidth = passportElement.offsetWidth;
            const passportHeight = passportElement.offsetHeight;
            const right = anchorX + 15;
            const left = right + passportWidth > bounds.width - 12
                ? anchorX - passportWidth - 15
                : right;
            const top = Math.min(
                Math.max(12, anchorY),
                bounds.height - passportHeight - 12
            );
            passportElement.style.left = `${Math.max(12, left)}px`;
            passportElement.style.top = `${Math.max(12, top)}px`;
        };
        updateMapRef.current = update;

        const fitMap = () => {
            map.resize();
            if (pendingFocusRef.current) {
                map.flyTo({
                    center: pendingFocusRef.current,
                    zoom: 12,
                    duration: 1200,
                });
                pendingFocusRef.current = null;
            } else {
                const longitudes = objectsRef.current.map((node) => node.lng);
                const latitudes = objectsRef.current.map((node) => node.lat);
                map.fitBounds(
                    [
                        [Math.min(...longitudes), Math.min(...latitudes)],
                        [Math.max(...longitudes), Math.max(...latitudes)],
                    ],
                    {
                        padding: { top: 130, bottom: 110, left: 130, right: 130 },
                        maxZoom: 6,
                        duration: 0,
                    }
                );
            }
            update();
        };

        map.on('render', update);
        map.on('load', fitMap);
        if (map.isStyleLoaded()) fitMap();

        return () => {
            map.off('render', update);
            map.off('load', fitMap);
            updateMapRef.current = null;
        };
    }, [map, passportElementRef, pendingFocusRef]);

    return (
        <div ref={overlayRef} className="network-map-overlay">
            <svg className="network-map-overlay__edges" aria-hidden="true">
                {edgePairs.map(([source, target]) => (
                    <line
                        key={`${source}-${target}`}
                        className="network-map-overlay__edge"
                        data-id={`${source}-${target}`}
                        onClick={(event) => {
                            event.stopPropagation();
                            onEdgeClick(
                                createEdgePassport(source, target, {
                                    x: event.clientX + 12,
                                    y: event.clientY + 12,
                                }, getEdgeAnchorT(event))
                            );
                        }}
                    />
                ))}
            </svg>
            {objects.map((node) => (
                <div
                    key={node.id}
                    className="network-map-overlay__node"
                    data-id={node.id}
                    onClick={(event) => {
                        event.stopPropagation();
                        const rect = event.currentTarget.getBoundingClientRect();
                        onNodeClick({
                            type: 'node',
                            data: {
                                id: node.id,
                                ...node.data,
                                lng: node.lng,
                                lat: node.lat,
                            },
                            nodeId: node.id,
                            position: { x: rect.right + 15, y: rect.top },
                        });
                    }}
                >
                    <div className="network-node">
                        <NetworkNodeContent data={node.data} />
                    </div>
                </div>
            ))}
            <svg
                className="network-map-overlay__edge-hit-area"
                aria-label="Связи между объектами"
            >
                {edgePairs.map(([source, target]) => (
                    <line
                        key={`${source}-${target}`}
                        className="network-map-overlay__edge-hit"
                        data-id={`${source}-${target}`}
                        onClick={(event) => {
                            event.stopPropagation();
                            onEdgeClick(
                                createEdgePassport(source, target, {
                                    x: event.clientX + 12,
                                    y: event.clientY + 12,
                                }, getEdgeAnchorT(event))
                            );
                        }}
                    />
                ))}
            </svg>
        </div>
    );
}

const nodeTypes = { networkNode: NetworkNode };

function NetworkPage() {
    const [objects, setObjects] = useState(readObjectLocations);
    const [nodes, setNodes] = useState([]);
    const [edges, setEdges] = useState([]);
    const [passport, setPassport] = useState(null);
    const [isMapVisible, setIsMapVisible] = useState(true);
    const [mapInstance, setMapInstance] = useState(null);

    const flowInstanceRef = useRef(null);
    const passportElementRef = useRef(null);
    const pendingFocusRef = useRef(null);
    const handleNodeClick = useCallback((nextPassport) => {
        setPassport(nextPassport);
    }, []);

    const handleEdgeClick = useCallback((nextPassport) => {
        setPassport(nextPassport);
    }, []);

    const handleCoordinatesChange = useCallback(({ id, lng, lat }) => {
        setObjects((current) => current.map((object) => (
            object.id === String(id)
                ? { ...object, lng, lat }
                : object
        )));
        setPassport((current) => (
            current?.nodeId === String(id)
                ? {
                    ...current,
                    data: { ...current.data, lng, lat },
                }
                : current
        ));
        if (mapInstance) {
            mapInstance.flyTo({
                center: [lng, lat],
                zoom: 12,
                duration: 1200,
            });
        } else {
            pendingFocusRef.current = [lng, lat];
            setIsMapVisible(true);
        }
    }, [mapInstance]);

    const handleFocusLocation = useCallback((lng, lat) => {
        if (mapInstance) {
            mapInstance.flyTo({
                center: [lng, lat],
                zoom: 12,
                duration: 1200,
            });
        } else {
            pendingFocusRef.current = [lng, lat];
            setIsMapVisible(true);
        }
    }, [mapInstance]);

    useEffect(() => {
        writeObjectLocations(objects);
    }, [objects]);

    useEffect(() => {
        const dismissPassport = (event) => {
            if (!(event.target instanceof Element)) return;
            if (event.target.closest(
                '.passport, .network-map-overlay__node, .network-map-overlay__edge, '
                + '.react-flow__node, .react-flow__edge'
            )) {
                return;
            }
            setPassport(null);
        };

        document.addEventListener('click', dismissPassport);
        return () => document.removeEventListener('click', dismissPassport);
    }, []);

    const handleMapToggle = () => {
        if (isMapVisible) {
            const { nodes: nextNodes, edges: nextEdges } = buildGraph(null, objects);
            setNodes(nextNodes);
            setEdges(nextEdges);
            setPassport(null);
        } else {
            flowInstanceRef.current?.setViewport({ x: 0, y: 0, zoom: 1 });
        }
        setIsMapVisible((visible) => !visible);
    };

    useEffect(() => {
        if (!isMapVisible) {
            flowInstanceRef.current?.fitView({ padding: 0.2 });
        }
    }, [isMapVisible]);

    return (
        <div className="app">
            <Toolbar
                isMapVisible={isMapVisible}
                onMapToggle={handleMapToggle}
            />

            {isMapVisible && <PhysicalMap onMapReady={setMapInstance} />}

            {isMapVisible ? (
                <MapGraphOverlay
                    map={mapInstance}
                    objects={objects}
                    onNodeClick={handleNodeClick}
                    onEdgeClick={handleEdgeClick}
                    passport={passport}
                    passportElementRef={passportElementRef}
                    pendingFocusRef={pendingFocusRef}
                />
            ) : (
                <ReactFlow
                    className="network-flow--interactive"
                    nodes={nodes}
                    edges={edges}
                    nodeTypes={nodeTypes}
                    fitView={false}
                    onInit={(instance) => {
                        flowInstanceRef.current = instance;
                    }}
                    nodeOrigin={[0.5, 0.5]}
                    nodesDraggable={false}
                    nodesConnectable={false}
                    panOnDrag
                    zoomOnScroll
                    zoomOnPinch
                    zoomOnDoubleClick
                    preventScrolling
                    onNodeClick={(_, node) => {
                        const el = document.querySelector(
                            `.react-flow__node[data-id="${node.id}"]`
                        );
                        if (!el) return;
                        const rect = el.getBoundingClientRect();
                        setPassport({
                            type: 'node',
                            data: { id: node.id, ...node.data },
                            nodeId: node.id,
                            position: { x: rect.right + 15, y: rect.top },
                        });
                    }}
                    onEdgeClick={(event, edge) => {
                        setPassport(createEdgePassport(
                            edge.source,
                            edge.target,
                            {
                                x: event.clientX + 12,
                                y: event.clientY + 12,
                            }
                        ));
                    }}
                    onPaneClick={() => setPassport(null)}
                >
                    <Background color="#d6dee8" gap={24} size={1} />
                    <Controls showInteractive={false} />
                </ReactFlow>
            )}

            {passport && passport.position && (
                <Passport
                    key={passport.nodeId ?? passport.data.id}
                    type={passport.type}
                    data={passport.data}
                    position={passport.position}
                    elementRef={isMapVisible ? passportElementRef : undefined}
                    onCoordinatesChange={handleCoordinatesChange}
                    onFocusLocation={handleFocusLocation}
                />
            )}
        </div>
    );
}

export default NetworkPage;