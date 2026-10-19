import { Background, Controls, ReactFlow } from '@xyflow/react';
import dagre from '@dagrejs/dagre';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';

import Toolbar from '../components/Toolbar';
import PhysicalMap from '../components/PhysicalMap';
import NetworkNode from '../components/NetworkNode';
import NetworkNodeContent from '../components/NetworkNodeContent';
import Passport from '../components/Passport';

import '@xyflow/react/dist/style.css';
import '../App.css';

const NODE_WIDTH = 94;
const NODE_HEIGHT = 48;
const FREE_GRAPH_PROJECTION_SCALE = 16;

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

function projectLocation({ lng, lat }) {
    const maxMercatorLatitude = 85.0511287798066;
    const latitude = Math.max(
        -maxMercatorLatitude,
        Math.min(maxMercatorLatitude, lat)
    );
    const sine = Math.sin((latitude * Math.PI) / 180);

    return {
        x: ((lng + 180) / 360) * 256 * FREE_GRAPH_PROJECTION_SCALE,
        y: (
            0.5 - Math.log((1 + sine) / (1 - sine)) / (4 * Math.PI)
        ) * 256 * FREE_GRAPH_PROJECTION_SCALE,
    };
}

function getMedian(values) {
    const ordered = [...values].sort((left, right) => left - right);
    const middle = Math.floor(ordered.length / 2);
    return ordered.length % 2
        ? ordered[middle]
        : (ordered[middle - 1] + ordered[middle]) / 2;
}

function getMedianCenter(points) {
    return {
        x: getMedian(points.map((point) => point.x)),
        y: getMedian(points.map((point) => point.y)),
    };
}

function hasCoordinates(node) {
    return Number.isFinite(node.lng) && Number.isFinite(node.lat);
}

function layoutGraphPositions(objects, edges) {
    const graph = new dagre.graphlib.Graph();
    graph.setDefaultEdgeLabel(() => ({}));
    graph.setGraph({ rankdir: 'TB', nodesep: 40, ranksep: 70 });

    objects.forEach((node) => {
        graph.setNode(node.id, { width: NODE_WIDTH, height: NODE_HEIGHT });
    });
    edges.forEach((edge) => graph.setEdge(edge.source, edge.target));
    dagre.layout(graph);

    return new Map(objects.map((node) => {
        const position = graph.node(node.id);
        return [node.id, {
            x: position.x,
            y: position.y,
        }];
    }));
}

function buildGraph(objects, relations) {
    const allLocated = objects.every(hasCoordinates);
    const laidOutPositions = allLocated
        ? null
        : layoutGraphPositions(objects, relations);
    const nodes = objects.map((node) => {
        const position = allLocated
            ? projectLocation(node)
            : laidOutPositions.get(node.id);
        return {
            id: node.id,
            type: 'networkNode',
            position,
            data: { ...node.data, id: node.id, lng: node.lng, lat: node.lat },
        };
    });

    const byId = Object.fromEntries(nodes.map((node) => [node.id, node]));
    const edges = relations
        .filter((edge) => byId[edge.source] && byId[edge.target])
        .map((edge) => ({
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

function createEdgePassport(edge, position, anchorT = 0.5) {
    return {
        type: 'edge',
        data: {
            id: edge.id,
            source: edge.source,
            target: edge.target,
            label: edge.label,
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
    edges,
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
        const edgeElements = edges.map((edge) => ({
            ...edge,
            elements: [
                svg.querySelector(
                    `.network-map-overlay__edge[data-id="${edge.id}"]`
                ),
                overlay.querySelector(
                    `.network-map-overlay__edge-hit[data-id="${edge.id}"]`
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
                const nodeElement = nodeElements.get(node.id);
                if (!nodeElement) return;
                const { element, width, height } = nodeElement;
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
            edgeElements.forEach(({ id, source, target, elements }) => {
                const sourcePoint = points.get(source);
                const targetPoint = points.get(target);
                if (!sourcePoint || !targetPoint) return;

                const dx = targetPoint.x - sourcePoint.x;
                const dy = targetPoint.y - sourcePoint.y;
                const horizontal =
                    Math.abs(dx) / sourcePoint.width >= Math.abs(dy) / sourcePoint.height;
                const sourceX = sourcePoint.x + (
                    horizontal ? Math.sign(dx) * sourcePoint.width / 2 : 0
                );
                const sourceY = sourcePoint.y + (
                    horizontal ? 0 : Math.sign(dy) * sourcePoint.height / 2
                );
                const targetX = targetPoint.x - (
                    horizontal ? Math.sign(dx) * targetPoint.width / 2 : 0
                );
                const targetY = targetPoint.y - (
                    horizontal ? 0 : Math.sign(dy) * targetPoint.height / 2
                );
                edgeSegments.set(id, {
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
                const locatedObjects = objectsRef.current.filter(hasCoordinates);
                if (locatedObjects.length) {
                    const longitudes = locatedObjects.map((node) => node.lng);
                    const latitudes = locatedObjects.map((node) => node.lat);
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
    }, [edges, map, objects, passportElementRef, pendingFocusRef]);

    return (
        <div ref={overlayRef} className="network-map-overlay">
            <svg className="network-map-overlay__edges" aria-hidden="true">
                {edges.map((edge) => (
                    <line
                        key={edge.id}
                        className="network-map-overlay__edge"
                        data-id={edge.id}
                        onClick={(event) => {
                            event.stopPropagation();
                            onEdgeClick(
                                createEdgePassport(edge, {
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
                {edges.map((edge) => (
                    <line
                        key={edge.id}
                        className="network-map-overlay__edge-hit"
                        data-id={edge.id}
                        onClick={(event) => {
                            event.stopPropagation();
                            onEdgeClick(
                                createEdgePassport(edge, {
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
    const [objects, setObjects] = useState([]);
    const [relations, setRelations] = useState([]);
    const [graphPositions, setGraphPositions] = useState(null);
    const [loading, setLoading] = useState(true);
    const [loadError, setLoadError] = useState('');
    const [passport, setPassport] = useState(null);
    const [isMapVisible, setIsMapVisible] = useState(true);
    const [mapInstance, setMapInstance] = useState(null);

    const flowInstanceRef = useRef(null);
    const passportElementRef = useRef(null);
    const pendingFocusRef = useRef(null);
    const flowSpreadFactorRef = useRef(1);
    const graph = useMemo(
        () => buildGraph(objects, relations),
        [objects, relations]
    );
    const basePositions = useMemo(
        () => new Map(graph.nodes.map((node) => [node.id, node.position])),
        [graph]
    );
    const nodes = useMemo(
        () => graph.nodes.map((node) => ({
            ...node,
            position: graphPositions?.get(node.id) ?? node.position,
        })),
        [graph, graphPositions]
    );
    const edges = graph.edges;
    const handleNodeClick = useCallback((nextPassport) => {
        setPassport(nextPassport);
    }, []);

    const handleEdgeClick = useCallback((nextPassport) => {
        setPassport(nextPassport);
    }, []);

    useEffect(() => {
        const controller = new AbortController();

        async function loadGraph() {
            try {
                const response = await fetch('/api/graph', {
                    signal: controller.signal,
                });
                const result = await response.json();
                if (!response.ok) {
                    throw new Error(result.error || `Ошибка API: ${response.status}`);
                }
                if (!Array.isArray(result.nodes) || !Array.isArray(result.edges)) {
                    throw new TypeError('API вернул данные графа в неверном формате.');
                }
                setObjects(result.nodes);
                setRelations(result.edges);
                setGraphPositions(null);
                setLoadError('');
            } catch (error) {
                if (controller.signal.aborted) return;
                console.error('Не удалось загрузить граф из базы данных.', error);
                setLoadError(error.message || 'Не удалось подключиться к API.');
            } finally {
                if (!controller.signal.aborted) setLoading(false);
            }
        }

        loadGraph();
        return () => controller.abort();
    }, []);

    const handleFlowMove = useCallback((_, viewport) => {
        const flow = document.querySelector('.network-flow--interactive');
        if (flow) {
            const iconScale = String(
                Math.min(2.5, Math.max(1, viewport.zoom)) / viewport.zoom
            );
            if (flow.style.getPropertyValue('--flow-icon-scale') !== iconScale) {
                flow.style.setProperty('--flow-icon-scale', iconScale);
            }
        }

        const spreadFactor = Math.min(
            6,
            1 + Math.max(0, viewport.zoom - 1) * 0.8
        );
        const spreadChanged = (
            Math.abs(spreadFactor - flowSpreadFactorRef.current) >= 0.08
        );
        const entries = [...basePositions.entries()].map(
            ([id, position]) => ({ id, position })
        );
        if (!entries.length) return;
        const center = getMedianCenter(
            entries.map((item) => item.position)
        );

        if (spreadChanged && flow) {
            const bounds = flow.getBoundingClientRect();
            const nextViewport = {
                ...viewport,
                x: bounds.width / 2 - center.x * viewport.zoom,
                y: bounds.height / 2 - center.y * viewport.zoom,
            };
            flowSpreadFactorRef.current = spreadFactor;
            flowInstanceRef.current?.setViewport(nextViewport, { duration: 0 });
        }
        if (!spreadChanged) return;

        setGraphPositions(new Map(entries.map(({ id, position }) => [
            id,
            {
                x: center.x + (position.x - center.x) * spreadFactor,
                y: center.y + (position.y - center.y) * spreadFactor,
            },
        ])));
    }, [basePositions]);

    const handleFitGraph = useCallback(() => {
        flowSpreadFactorRef.current = 1;
        setGraphPositions(null);
        requestAnimationFrame(() => {
            requestAnimationFrame(() => {
                flowInstanceRef.current?.fitView({ padding: 0.2 });
            });
        });
    }, []);

    const handleCoordinatesChange = useCallback(async ({ id, lng, lat }) => {
        const response = await fetch(`/api/nodes/${encodeURIComponent(id)}/location`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ lng, lat }),
        });
        const result = await response.json();
        if (!response.ok) {
            throw new Error(result.error || `Ошибка API: ${response.status}`);
        }

        setObjects((current) => current.map((object) => (
            object.id === id
                ? { ...object, lng, lat }
                : object
        )));
        setGraphPositions(null);
        setPassport((current) => (
            current?.nodeId === id
                ? {
                    ...current,
                    data: { ...current.data, lng, lat },
                }
                : current
        ));
        if (isMapVisible && mapInstance) {
            mapInstance.flyTo({
                center: [lng, lat],
                zoom: 12,
                duration: 1200,
            });
        } else {
            pendingFocusRef.current = [lng, lat];
            setIsMapVisible(true);
        }
    }, [isMapVisible, mapInstance]);

    const handleFocusLocation = useCallback((lng, lat) => {
        if (isMapVisible && mapInstance) {
            mapInstance.flyTo({
                center: [lng, lat],
                zoom: 12,
                duration: 1200,
            });
        } else {
            pendingFocusRef.current = [lng, lat];
            setIsMapVisible(true);
        }
    }, [isMapVisible, mapInstance]);

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
            flowSpreadFactorRef.current = 1;
            setPassport(null);
        } else {
            flowInstanceRef.current?.setViewport({ x: 0, y: 0, zoom: 1 });
        }
        setGraphPositions(null);
        setIsMapVisible((visible) => !visible);
    };

    const locatedObjects = objects.filter(hasCoordinates);
    const locatedIds = new Set(locatedObjects.map((node) => node.id));
    const mapEdges = relations.filter(
        (edge) => locatedIds.has(edge.source) && locatedIds.has(edge.target)
    );
    const unlocatedCount = objects.length - locatedObjects.length;

    return (
        <div className="app">
            <Toolbar
                isMapVisible={isMapVisible}
                onMapToggle={handleMapToggle}
            />

            {isMapVisible && <PhysicalMap onMapReady={setMapInstance} />}

            {loading && (
                <div className="network-data-notice" role="status">
                    Загружаю узлы и связи из базы данных…
                </div>
            )}
            {loadError && (
                <div className="network-data-notice network-data-notice--error" role="alert">
                    Не удалось загрузить граф: {loadError}
                    {' '}Проверьте подключение API и PostgreSQL.
                </div>
            )}
            {!loading && !loadError && objects.length === 0 && (
                <div className="network-data-notice" role="status">
                    В выбранной базе пока нет СФЭ для отображения.
                </div>
            )}
            {!loading && !loadError && unlocatedCount > 0 && (
                <div className="network-data-notice" role="status">
                    {unlocatedCount} узл. без координат.
                    {isMapVisible
                        ? ' Переключитесь в режим графа без карты, задайте координаты в паспорте узла и сохраните.'
                        : ' Задайте координаты в паспорте узла, чтобы разместить его на карте.'}
                </div>
            )}

            {isMapVisible ? (
                <MapGraphOverlay
                    map={mapInstance}
                    objects={locatedObjects}
                    edges={mapEdges}
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
                    fitView
                    fitViewOptions={{ padding: 0.2 }}
                    minZoom={0.1}
                    maxZoom={8}
                    onInit={(instance) => {
                        flowInstanceRef.current = instance;
                        handleFlowMove(null, instance.getViewport());
                    }}
                    onMove={handleFlowMove}
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
                        setPassport(createEdgePassport(edge, {
                            x: event.clientX + 12,
                            y: event.clientY + 12,
                        }));
                    }}
                    onPaneClick={() => setPassport(null)}
                >
                    <Background color="#d6dee8" gap={24} size={1} />
                    <Controls showInteractive={false} showFitView={false}>
                        <button
                            type="button"
                            className="react-flow__controls-button"
                            title="Fit View"
                            aria-label="Fit View"
                            onClick={handleFitGraph}
                        >
                            <svg viewBox="0 0 24 24" aria-hidden="true">
                                <path
                                    d="M8 3H3v5m13-5h5v5M3 16v5h5m13-5v5h-5"
                                    fill="none"
                                    stroke="#40536a"
                                    strokeWidth="2"
                                />
                            </svg>
                        </button>
                    </Controls>
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