import { Background, Controls, ReactFlow } from '@xyflow/react';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';

import Toolbar from '../components/Toolbar';
import RoutedEdge from '../components/RoutedEdge';
import { buildFullNetwork, getNetworkSelection } from '../utils/fullNetwork';
import PhysicalMap from '../components/PhysicalMap';
import NetworkNode from '../components/NetworkNode';
import { diagramEdgeOptions } from '../components/diagramEdges';
import NetworkNodeContent from '../components/NetworkNodeContent';
import Passport from '../components/Passport';
import { fetchJson } from '../utils/api';
import { buildMapEdges } from '../utils/mapGraph';

import '@xyflow/react/dist/style.css';
import '../App.css';

function hasCoordinates(node) {
    return Number.isFinite(node.lng) && Number.isFinite(node.lat);
}

function createEdgePassport(edge, position, anchorT = 0.5) {
    return {
        type: 'edge',
        data: {
            id: edge.id,
            lineId: edge.lineId,
            source: edge.source,
            target: edge.target,
            label: edge.label,
            sourceLabel: edge.sourceLabel,
            targetLabel: edge.targetLabel,
            relationLabel: edge.relationLabel,
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
    const hasInitialFitRef = useRef(false);
    const selectedEdge = passport?.type === 'edge'
        ? edges.find((edge) => edge.id === passport.data.id) : null;
    const highlightedNodes = new Set(selectedEdge
        ? [selectedEdge.source, selectedEdge.target]
        : passport?.nodeId ? [passport.nodeId] : []);

    useEffect(() => {
        passportRef.current = passport;
        updateMapRef.current?.();
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
            labelElement: svg.querySelector(`[data-edge-label="${edge.id}"]`),
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
                1.35,
                Math.max(0.7, 2 ** ((map.getZoom() - 5) / 6))
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
            edgeElements.forEach(({ id, source, target, elements, labelElement }) => {
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
                if (labelElement) {
                    labelElement.setAttribute('x', String((sourceX + targetX) / 2));
                    labelElement.setAttribute('y', String((sourceY + targetY) / 2));
                }
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
                hasInitialFitRef.current = true;
            } else {
                const locatedObjects = objectsRef.current.filter(hasCoordinates);
                if (locatedObjects.length && !hasInitialFitRef.current) {
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
                    hasInitialFitRef.current = true;
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
            <svg className="network-map-overlay__edges" aria-label="Линии связи на карте">
                {edges.map((edge) => (
                    <line
                        key={edge.id}
                        className={`network-map-overlay__edge${selectedEdge?.id === edge.id ? ' is-active' : ''}`}
                        style={{ opacity: selectedEdge && selectedEdge.id !== edge.id ? 0.18 : 1 }}
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
                {edges.filter((edge) => edge.label).map((edge) => (
                    <text key={`label:${edge.id}`} data-edge-label={edge.id}
                        className="network-map-overlay__edge-label"
                        style={{ opacity: selectedEdge && selectedEdge.id !== edge.id ? 0.18 : 1 }}
                        onClick={(event) => {
                            event.stopPropagation();
                            onEdgeClick(createEdgePassport(edge, { x: event.clientX + 12, y: event.clientY + 12 }));
                        }}>
                        {edge.label}
                    </text>
                ))}
            </svg>
            {objects.map((node) => (
                <div
                    key={node.id}
                    className={`network-map-overlay__node${highlightedNodes.has(node.id) ? ' is-active' : ''}`}
                    style={{ opacity: selectedEdge && !highlightedNodes.has(node.id) ? 0.4 : 1 }}
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
                    <div className={`network-node${/узел связи/i.test(node.data.templateName || node.data.type || '') ? ' network-node--communication' : ''}`}>
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
const edgeTypes = { routed: RoutedEdge };

function NetworkPage() {
    const [objects, setObjects] = useState([]);
    const [relations, setRelations] = useState([]);
    const [loading, setLoading] = useState(true);
    const [loadError, setLoadError] = useState('');
    const [passport, setPassport] = useState(null);
    const [isMapVisible, setIsMapVisible] = useState(true);
    const [mapLayer, setMapLayer] = useState('base');
    const [mapInstance, setMapInstance] = useState(null);

    const flowInstanceRef = useRef(null);
    const passportElementRef = useRef(null);
    const pendingFocusRef = useRef(null);
    const graph = useMemo(() => buildFullNetwork(objects, relations), [objects, relations]);
    const selection = getNetworkSelection(graph, isMapVisible ? null : passport);
    const hasSelection = selection.edgeIds.size > 0;
    const edges = graph.edges.map((edge) => ({ ...edge,
        style: { opacity: hasSelection && !selection.edgeIds.has(edge.id) ? 0.12 : 1,
            stroke: selection.edgeIds.has(edge.id) ? '#805333' : edge.lineId ? '#96704b' : '#c8b8a4',
            strokeWidth: selection.edgeIds.has(edge.id) ? 3 : edge.lineId ? 1.8 : 1.2 },
        zIndex: selection.edgeIds.has(edge.id) ? 10 : 0,
    }));
    const displayedNodes = graph.nodes.map((node) => ({ ...node,
        style: { opacity: hasSelection && !selection.nodeIds.has(node.id) ? 0.3 : 1 },
        className: selection.nodeIds.has(node.id) ? 'network-node--highlighted' : '',
    }));
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
                const result = await fetchJson('/api/graph', {
                    signal: controller.signal,
                });
                if (!Array.isArray(result.nodes) || !Array.isArray(result.edges)) {
                    throw new TypeError('API вернул данные графа в неверном формате.');
                }
                setObjects(result.nodes);
                setRelations(result.edges);
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

    const handleFitGraph = useCallback(() => {
        flowInstanceRef.current?.fitView({ padding: 0.15, duration: 250 });
    }, []);

    const updateGraphPassport = useCallback(() => {
        const flow = flowInstanceRef.current;
        if (isMapVisible || !flow) return;
        setPassport((current) => {
            if (!current?.flowAnchor) return current;
            const point = flow.flowToScreenPosition(current.flowAnchor);
            const x = point.x + current.anchorOffset.x;
            const y = point.y + current.anchorOffset.y;
            if (current.position.x === x && current.position.y === y) return current;
            return { ...current, position: { x, y } };
        });
    }, [isMapVisible]);

    useEffect(() => {
        if (isMapVisible) return;
        window.addEventListener('resize', updateGraphPassport);
        const observer = new ResizeObserver(updateGraphPassport);
        const container = document.querySelector('.network-flow--interactive');
        if (container) observer.observe(container);
        return () => {
            window.removeEventListener('resize', updateGraphPassport);
            observer.disconnect();
        };
    }, [isMapVisible, updateGraphPassport]);

    const handleCoordinatesChange = useCallback(async ({ id, lng, lat }) => {
        await fetchJson(`/api/nodes/${encodeURIComponent(id)}/location`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ lng, lat }),
        });

        setObjects((current) => current.map((object) => (
            object.id === id
                ? { ...object, lng, lat }
                : object
        )));
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

    const handleBackgroundClick = (event) => {
        if (!(event.target instanceof Element)) return;
        if (event.target.closest(
            '.passport, .network-map-overlay__node, .network-map-overlay__edge, .network-map-overlay__edge-label, '
            + '.network-map-overlay__edge-hit, .react-flow__node, .react-flow__edge, .react-flow__controls'
        )) {
            return;
        }
        setPassport(null);
    };

    const handleMapToggle = () => {
        setPassport(null);
        setIsMapVisible((visible) => !visible);
    };

    const locatedObjects = useMemo(
        () => objects.filter(hasCoordinates),
        [objects]
    );
    const mapEdges = useMemo(
        () => buildMapEdges(objects, relations),
        [objects, relations]
    );
    const unlocatedCount = objects.length - locatedObjects.length;

    return (
        <div className="app" onClickCapture={handleBackgroundClick}>
            <Toolbar
                isMapVisible={isMapVisible}
                onMapToggle={handleMapToggle}
                mapLayer={mapLayer}
                onMapLayerChange={setMapLayer}
            />

            {isMapVisible && (
                <PhysicalMap
                    onMapReady={setMapInstance}
                    mapLayer={mapLayer}
                />
            )}

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
            {!loading && !loadError && unlocatedCount > 0 && isMapVisible && (
                <div className="network-data-notice" role="status">
                    {unlocatedCount} узл. без координат.
                    {isMapVisible
                        ? ' Переключитесь в режим графа без карты, задайте координаты в паспорте узла и сохраните.'
                        : ' Задайте координаты в паспорте узла, чтобы разместить его на карте.'}
                </div>
            )}

            {!isMapVisible && !loading && !loadError && (
                <div className="network-data-notice" role="status">
                    Линии связи → узлы связи → оборудование
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
                    nodes={displayedNodes}
                    edges={edges}
                    nodeTypes={nodeTypes}
                    edgeTypes={edgeTypes}
                    defaultEdgeOptions={diagramEdgeOptions}
                    fitView
                    fitViewOptions={{ padding: 0.2 }}
                    minZoom={0.1}
                    maxZoom={8}
                    onInit={(instance) => {
                        flowInstanceRef.current = instance;
                    }}
                    onMove={updateGraphPassport}
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
                            flowAnchor: flowInstanceRef.current.screenToFlowPosition({ x: rect.right, y: rect.top }),
                            anchorOffset: { x: 15, y: 0 },
                        });
                    }}
                    onEdgeClick={(event, edge) => {
                        setPassport({ ...createEdgePassport(edge, {
                            x: event.clientX + 12,
                            y: event.clientY + 12,
                        }),
                            flowAnchor: flowInstanceRef.current.screenToFlowPosition({ x: event.clientX, y: event.clientY }),
                            anchorOffset: { x: 12, y: 12 },
                        });
                    }}
                    onPaneClick={() => setPassport(null)}
                >
                    <Background color="#ded8ce" gap={24} size={1} />
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
