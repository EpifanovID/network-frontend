import { Background, Controls, ReactFlow } from '@xyflow/react';
import { createRef, useCallback, useEffect, useMemo, useRef, useState } from 'react';

import Toolbar from '../components/Toolbar';
import RoutedEdge from '../components/RoutedEdge';
import HighlightDialog from '../components/HighlightDialog';
import { buildNetworkHighlight, describeHighlightFilters, emptyHighlight, getManualHighlight } from '../utils/networkHighlight';
import { buildExpandableNetwork, getNetworkSelection } from '../utils/fullNetwork';
import PhysicalMap from '../components/PhysicalMap';
import NetworkNode from '../components/NetworkNode';
import { diagramEdgeOptions } from '../components/diagramEdges';
import NetworkNodeContent from '../components/NetworkNodeContent';
import Passport from '../components/Passport';
import { arrangePassports, clampPassportPosition, isPassportDetail, openPassport, passportDetailTitles, passportKey, sidePassportPosition } from '../utils/passports';
import { fetchJson } from '../utils/api';
import { buildMapEdges } from '../utils/mapGraph';
import { loadBoundaryData } from '../utils/mapLayers';

import '@xyflow/react/dist/style.css';
import '../App.css';

function passportDetailCard(item, element, fallbackAnchor) {
    return {
        key: passportKey(item),
        ...item.position,
        width: element.offsetWidth,
        height: element.offsetHeight,
        anchorKey: item.parentKey,
        fallbackAnchor,
        nodeAnchor: fallbackAnchor,
    };
}

function positionPassportWindows(cards, bounds, elements) {
    const visible = [];
    const markers = [];
    for (const card of cards) {
        const anchor = card.nodeAnchor;
        if (anchor && (anchor.x + anchor.width <= bounds.left || anchor.x >= bounds.right
            || anchor.y + anchor.height <= bounds.top || anchor.y >= bounds.bottom)) {
            const targetX = anchor.x + anchor.width / 2;
            const targetY = anchor.y + anchor.height / 2;
            const button = elements.get(card.key).current.querySelector('.passport__offscreen-marker');
            const width = button.offsetWidth;
            const height = button.offsetHeight;
            const marker = { key: card.key, x: targetX - width / 2, y: targetY - height / 2, width, height };
            const point = clampPassportPosition(marker, bounds);
            markers.push({ ...marker, ...point, targetX, targetY });
        } else {
            visible.push(card);
        }
    }

    for (const { key, x, y, height, targetX, targetY } of [...arrangePassports(visible, bounds), ...arrangePassports(markers, bounds)]) {
        const element = elements.get(key).current;
        if (element.dataset.dragging) continue;
        const offscreen = targetX !== undefined;
        element.toggleAttribute('data-offscreen', offscreen);
        if (offscreen) {
            const angle = Math.atan2(targetY - y - height / 2, targetX - x - 18);
            element.style.setProperty('--passport-marker-angle', `${angle}rad`);
        }
        element.style.left = `${x}px`;
        element.style.top = `${y}px`;
    }
}

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

function getEdgeAnchorT(event, line = event.currentTarget) {
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
    passports,
    showPassportHighlights,
    highlight,
    passportElements,
    pendingFocusRef,
}) {
    const overlayRef = useRef(null);
    const passportsRef = useRef([]);
    const objectsRef = useRef(objects);
    const updateMapRef = useRef(null);
    const hasInitialFitRef = useRef(false);
    const selectedKeys = new Set(showPassportHighlights ? passports.map(passportKey) : []);
    for (const item of passports) {
        if (item.routeHighlighted && item.lineKey) selectedKeys.add(item.lineKey);
    }
    const selectedEdges = edges.filter((edge) => highlight?.lines.has(highlight.edgeIdsOnly ? edge.id : edge.lineId ?? edge.id)
        || selectedKeys.has(passportKey({ type: 'edge', data: edge })));
    const selectedEdgeIds = new Set(selectedEdges.map((edge) => edge.id));
    const hasHighlight = Boolean(highlight || selectedEdges.length);
    const highlightedNodes = new Set([
        ...(highlight?.nodes ?? []),
        ...(showPassportHighlights ? passports.filter((item) => item.type === 'node').map((item) => item.nodeId) : []),
        ...selectedEdges.flatMap((edge) => [edge.source, edge.target]),
    ]);

    useEffect(() => {
        passportsRef.current = passports;
        updateMapRef.current?.();
        const observer = new ResizeObserver(() => updateMapRef.current?.());
        passportElements.forEach((ref) => { if (ref.current) observer.observe(ref.current); });
        return () => observer.disconnect();
    }, [passports, passportElements]);

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

            const cards = [];
            for (const activePassport of passportsRef.current) {
                const key = passportKey(activePassport);
                const element = passportElements.get(key)?.current;
                if (!element) continue;
                if (activePassport.detachedPosition || element.dataset.dragging) {
                    const point = element.dataset.dragging ? element.getBoundingClientRect() : activePassport.detachedPosition;
                    cards.push({ key, x: point.x, y: point.y, width: element.offsetWidth, height: element.offsetHeight,
                        fixed: true, detached: Boolean(activePassport.detachedPosition) });
                    continue;
                }
                const isDetail = isPassportDetail(activePassport.type);
                const isLineDetail = Boolean(activePassport.lineKey);
                if ((isDetail && !isLineDetail) || (activePassport.type === 'node' && !activePassport.data.isLine)) {
                    const point = points.get(activePassport.data.id);
                    const anchor = point && {
                        ...point,
                        x: bounds.left + point.x - point.width / 2,
                        y: bounds.top + point.y - point.height / 2,
                    };
                    if (isDetail) {
                        cards.push(passportDetailCard(activePassport, element, anchor));
                    } else {
                        const card = { key, ...activePassport.position, width: element.offsetWidth, height: element.offsetHeight };
                        cards.push(anchor ? { ...card, nodeAnchor: anchor,
                            ...sidePassportPosition(card, anchor, { left: 12, right: bounds.right - 12 }) } : card);
                    }
                    continue;
                }
                let anchorX, anchorY;
                const matchingEdge = edges.find((edge) => passportKey({ type: 'edge', data: edge }) === (activePassport.lineKey ?? key));
                const exactSegment = edgeSegments.get(activePassport.data.id);
                const segment = exactSegment ?? edgeSegments.get(matchingEdge?.id);
                if (segment) {
                    const t = exactSegment ? activePassport.anchorT ?? 0.5 : 0.5;
                    anchorX = segment.x1 + (segment.x2 - segment.x1) * t;
                    anchorY = segment.y1 + (segment.y2 - segment.y1) * t;
                }
                if (isLineDetail) {
                    const anchor = segment && { x: bounds.left + anchorX, y: bounds.top + anchorY, width: 1, height: 1 };
                    cards.push(passportDetailCard(activePassport, element, anchor));
                    continue;
                }
                const width = element.offsetWidth, height = element.offsetHeight;
                if (anchorX == null) {
                    cards.push({ key, width, height, ...activePassport.position });
                    continue;
                }
                cards.push({ key, width, height,
                    x: anchorX + width + 15 > bounds.width - 12 ? anchorX - width - 15 : anchorX + 15,
                    y: bounds.top + anchorY });
            }
            const tabsBottom = overlay.parentElement?.querySelector('.passport-tabs')?.getBoundingClientRect().bottom;
            positionPassportWindows(cards, {
                left: 12, top: (tabsBottom ?? bounds.top) + 12, right: bounds.width - 12, bottom: bounds.bottom - 12,
            }, passportElements);
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
    }, [edges, map, objects, passportElements, pendingFocusRef]);

    return (
        <div ref={overlayRef} className="network-map-overlay">
            <svg className="network-map-overlay__edges" aria-label="Линии связи на карте">
                {edges.map((edge) => (
                    <line
                        key={edge.id}
                        className={`network-map-overlay__edge${selectedEdgeIds.has(edge.id) ? ' is-active' : ''}`}
                        style={{ opacity: hasHighlight && !selectedEdgeIds.has(edge.id) ? 0.18 : 1 }}
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
                        style={{ opacity: hasHighlight && !selectedEdgeIds.has(edge.id) ? 0.18 : 1 }}
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
                    style={{ opacity: hasHighlight && !highlightedNodes.has(node.id) ? 0.4 : 1 }}
                    data-id={node.id}
                    tabIndex={0}
                    role="button"
                    aria-label={`Открыть паспорт ${node.data.label}`}
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
                        tabIndex={0}
                        role="button"
                        aria-label={`Открыть паспорт ${edge.label || 'соединения'}`}
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

const passportHoverDelay = 1000;

function getPassportHoverTarget(target) {
    if (!(target instanceof Element) || target.closest('.passport, .network-composition__toggle')) return null;
    return target.closest(
        '[data-passport-id], .network-map-overlay__node, .network-map-overlay__edge, '
        + '.network-map-overlay__edge-hit, .network-map-overlay__edge-label, '
        + '.react-flow__node, .react-flow__edge'
    );
}

function NetworkPage() {
    const [objects, setObjects] = useState([]);
    const [relations, setRelations] = useState([]);
    const [loading, setLoading] = useState(true);
    const [refreshCount, setRefreshCount] = useState(0);
    const [loadError, setLoadError] = useState('');
    const [passports, setPassports] = useState([]);
    const visiblePassports = useMemo(() => passports.filter((item) => !item.minimized), [passports]);
    const [activePassportId, setActivePassportId] = useState(null);
    const [isMapVisible, setIsMapVisible] = useState(true);
    const [expandedIds, setExpandedIds] = useState(() => new Set());
    const [mapLayer, setMapLayer] = useState('base');
    const [boundaries, setBoundaries] = useState(null);
    const [highlightWindow, setHighlightWindow] = useState(null);
    const [highlightFilters, setHighlightFilters] = useState(emptyHighlight);
    const [highlightDraft, setHighlightDraft] = useState(emptyHighlight);
    const [highlightSection, setHighlightSection] = useState('filters');
    const [manualSelection, setManualSelection] = useState(() => new Set());
    const [manualEditing, setManualEditing] = useState(null);
    const [ctrlPreview, setCtrlPreview] = useState(false);
    const [manualApplied, setManualApplied] = useState(null);
    const highlightOpen = highlightWindow === 'open';
    const manualSelecting = Boolean(manualEditing || (ctrlPreview && !highlightOpen));
    const [boundaryError, setBoundaryError] = useState(false);
    const [mapInstance, setMapInstance] = useState(null);

    const flowInstanceRef = useRef(null);
    const passportElements = useMemo(() => new Map(passports.map((item) => [passportKey(item), createRef()])), [passports]);
    const pendingFocusRef = useRef(null);
    const passportHoverTimerRef = useRef(null);
    const draggedPassportTabRef = useRef(null);
    const [windowTabOrder, setWindowTabOrder] = useState([]);
    const cancelPassportHover = useCallback(() => {
        clearTimeout(passportHoverTimerRef.current);
        passportHoverTimerRef.current = null;
    }, []);
    const showPassport = useCallback((next) => {
        setActivePassportId(passportKey(next));
        setPassports((current) => openPassport(current, next));
    }, []);
    const togglePassport = useCallback((next) => {
        cancelPassportHover();
        const key = passportKey(next);
        setActivePassportId(key);
        setPassports((current) => {
            const existing = current.find((item) => passportKey(item) === key);
            if (!existing) return openPassport(current, { ...next, pinned: true });
            if (existing.minimized) return current.map((item) => item === existing
                ? { ...item, minimized: false, pinned: true } : item);
            if (next.type === 'node' && !next.data.isLine) {
                return current.map((item) => item === existing ? { ...item, minimized: true } : item);
            }
            return current.filter((item) => item !== existing);
        });
    }, [cancelPassportHover]);
    const closePassport = useCallback((key) => {
        cancelPassportHover();
        const activeKey = typeof key === 'string' ? key
            : document.activeElement?.closest('.passport')?.dataset.passportKey
                ?? (visiblePassports.length ? passportKey(visiblePassports[visiblePassports.length - 1]) : null);
        const closing = passports.find((item) => passportKey(item) === activeKey);
        const id = closing?.nodeId ?? closing?.data.id;
        if (id && document.activeElement?.closest('.passport')?.dataset.passportKey === activeKey) {
            document.querySelector(`[data-id="${CSS.escape(id)}"].network-map-overlay__node, [data-id="${CSS.escape(id)}"].network-map-overlay__edge-hit, [data-id="${CSS.escape(id)}"].react-flow__node, [data-id="${CSS.escape(id)}"].react-flow__edge, [data-passport-id="${CSS.escape(id)}"]`)?.focus({ preventScroll: true });
        }
        setPassports((current) => current.filter((item) => passportKey(item) !== activeKey));
    }, [cancelPassportHover, passports, visiblePassports]);
    const pinPassport = useCallback((key) => {
        cancelPassportHover();
        setActivePassportId(key);
        setPassports((current) => {
            const active = current.find((item) => passportKey(item) === key);
            if (!active || active.pinned) return current;
            return current.map((item) => passportKey(item) === key ? { ...item, pinned: true } : item);
        });
    }, [cancelPassportHover]);
    const movePassport = useCallback((key, point) => {
        cancelPassportHover();
        setActivePassportId(key);
        setPassports((current) => current.map((item) => passportKey(item) === key
            ? { ...item, pinned: true, detachedPosition: point } : item));
    }, [cancelPassportHover]);
    const reattachPassport = useCallback((key) => {
        cancelPassportHover();
        setActivePassportId(key);
        setPassports((current) => current.map((item) => {
            if (passportKey(item) !== key) return item;
            if (isPassportDetail(item.type)) return { ...item, pinned: true, detachedPosition: null };
            const source = item.nodeId && document.querySelector(
                `[data-passport-id="${CSS.escape(item.nodeId)}"], .react-flow__node[data-id="${CSS.escape(item.nodeId)}"]`
            );
            const bounds = source?.getBoundingClientRect();
            const flowAnchor = bounds && flowInstanceRef.current
                ? flowInstanceRef.current.screenToFlowPosition({ x: bounds.right, y: bounds.top }) : item.flowAnchor;
            return { ...item, pinned: true, detachedPosition: null, flowAnchor };
        }));
    }, [cancelPassportHover]);
    useEffect(() => {
        const handleEscape = (event) => {
            if (event.key !== 'Escape') return;
            if (manualSelecting) {
                setManualEditing(null);
                setCtrlPreview(false);
            }
            else closePassport();
        };
        window.addEventListener('keydown', handleEscape);
        return () => window.removeEventListener('keydown', handleEscape);
    }, [closePassport, manualSelecting]);
    useEffect(() => {
        let previewTimer;
        const stopPreview = () => {
            clearTimeout(previewTimer);
            setCtrlPreview(false);
        };
        const handleKeyDown = (event) => {
            if (event.key !== 'Control') {
                if (event.ctrlKey) stopPreview();
                return;
            }
            if (event.repeat || event.altKey || event.shiftKey || event.metaKey
                || document.querySelector('dialog[open]')
                || event.target?.closest?.('input, select, textarea, [contenteditable]')) return;
            clearTimeout(previewTimer);
            previewTimer = setTimeout(() => {
                cancelPassportHover();
                setCtrlPreview(true);
            }, 300);
        };
        const handleKeyUp = (event) => {
            if (event.key === 'Control' && !event.ctrlKey) stopPreview();
        };
        window.addEventListener('keydown', handleKeyDown);
        window.addEventListener('keyup', handleKeyUp);
        window.addEventListener('blur', stopPreview);
        return () => {
            clearTimeout(previewTimer);
            window.removeEventListener('keydown', handleKeyDown);
            window.removeEventListener('keyup', handleKeyUp);
            window.removeEventListener('blur', stopPreview);
        };
    }, [cancelPassportHover]);
    useEffect(() => cancelPassportHover, [cancelPassportHover, isMapVisible, objects, expandedIds]);
    const manualView = Boolean(manualSelecting || manualApplied);
    const locatedObjects = useMemo(() => objects.filter(hasCoordinates), [objects]);
    const graph = useMemo(() => buildExpandableNetwork(objects, relations), [objects, relations]);
    const filterHighlight = useMemo(() => buildNetworkHighlight(objects, relations, boundaries, highlightFilters),
        [objects, relations, boundaries, highlightFilters]);
    const allMapEdges = useMemo(() => buildMapEdges(objects, relations), [objects, relations]);
    const manualNodes = manualSelecting ? manualSelection : manualApplied?.nodes;
    const isolateManual = !manualSelecting && manualApplied?.hideOthers;
    const highlight = manualView
        ? (manualNodes && (manualNodes.size > 0 || isolateManual)
            ? getManualHighlight(manualNodes, isolateManual ? allMapEdges : [], isolateManual ? graph.edges : [])
            : null)
        : filterHighlight;
    const hideOthers = Boolean(highlight && (manualView ? isolateManual : highlightFilters.hideOthers));
    const isHighlightedEdge = (edge) => highlight?.lines.has(highlight.edgeIdsOnly ? edge.id : edge.lineId ?? edge.id);
    const toggleComposition = useCallback((id) => {
        setExpandedIds((previous) => {
            const next = new Set(previous);
            if (next.has(id)) next.delete(id);
            else next.add(id);
            return next;
        });
    }, []);
    const openGraphObject = useCallback((id, data, element) => {
        const flow = flowInstanceRef.current;
        if (!flow) return;
        const { right, top } = element.getBoundingClientRect();
        togglePassport({
            type: 'node',
            data: { ...data, id },
            nodeId: id,
            position: { x: right + 15, y: top },
            flowAnchor: flow.screenToFlowPosition({ x: right, y: top }),
            anchorOffset: { x: 15, y: 0 },
        });
    }, [togglePassport]);
    const selection = { nodeIds: new Set(), edgeIds: new Set() };
    if (!isMapVisible) visiblePassports.forEach((item) => {
        if (item.type === 'channel-passport') {
            if (!item.routeHighlighted) return;
            for (const edge of graph.edges) {
                if (passportKey({ type: 'edge', data: edge }) !== item.lineKey) continue;
                selection.edgeIds.add(edge.id);
                selection.nodeIds.add(edge.source);
                selection.nodeIds.add(edge.target);
            }
            if (item.data.lineId) selection.nodeIds.add(item.data.lineId);
            return;
        }
        if (manualView) return;
        const selected = getNetworkSelection(graph, item);
        selected.nodeIds.forEach((id) => selection.nodeIds.add(id));
        selected.edgeIds.forEach((id) => selection.edgeIds.add(id));
        if (item.nodeId) selection.nodeIds.add(item.nodeId);
    });
    const matchedGraphNodes = new Set(highlight?.nodes);
    if (highlight) {
        for (const id of highlight.lines) matchedGraphNodes.add(id);
        for (const edge of graph.edges) {
            if (!isHighlightedEdge(edge)) continue;
            matchedGraphNodes.add(edge.source);
            matchedGraphNodes.add(edge.target);
            selection.edgeIds.add(edge.id);
        }
    }
    const hasSelection = Boolean(highlight || selection.edgeIds.size);
    const edges = graph.edges.map((edge) => ({ ...edge,
        hidden: hideOthers && !isHighlightedEdge(edge),
        ariaLabel: `Открыть паспорт ${edge.label || 'соединения'}`,
        style: { opacity: hasSelection && !selection.edgeIds.has(edge.id) ? 0.12 : 1,
            stroke: selection.edgeIds.has(edge.id) ? '#805333' : edge.lineId ? '#96704b' : '#c8b8a4',
            strokeWidth: selection.edgeIds.has(edge.id) ? 3 : edge.lineId ? 1.8 : 1.2 },
        zIndex: selection.edgeIds.has(edge.id) ? 10 : 0,
    }));
    const displayedNodes = graph.nodes.map((node) => {
        const matchingGroups = new Set();
        const prepareComposition = (items) => items.flatMap((item) => {
            const children = prepareComposition(item.children);
            const matches = highlight.nodes.has(item.id);
            if (children.some((child) => highlight.nodes.has(child.id) || matchingGroups.has(child.id))) {
                matchingGroups.add(item.id);
            }
            return hideOthers && !matches && !matchingGroups.has(item.id) ? [] : [{ ...item, children }];
        });
        const composition = highlight ? prepareComposition(node.data.composition) : node.data.composition;
        if (highlight && composition.some((item) => highlight.nodes.has(item.id) || matchingGroups.has(item.id))) {
            matchingGroups.add(node.id);
        }
        const matches = matchedGraphNodes.has(node.id) || matchingGroups.has(node.id);
        const selected = matches || selection.nodeIds.has(node.id);
        return { ...node,
            hidden: hideOthers && !matches,
            ariaLabel: `Открыть паспорт ${node.data.label}`,
            data: { ...node.data, composition, expandedIds: new Set([...expandedIds, ...matchingGroups]),
                highlightNodes: highlight?.nodes, onToggle: toggleComposition, onOpen: openGraphObject },
            style: { opacity: hasSelection && !selected ? 0.3 : 1 },
            className: selected ? 'network-node--highlighted' : '',
        };
    });
    useEffect(() => {
        const controller = new AbortController();

        async function loadGraph() {
            try {
                const result = await fetchJson('/api/graph', {
                    signal: controller.signal,
                    cache: 'no-store',
                });
                if (controller.signal.aborted) return;
                if (!Array.isArray(result.nodes) || !Array.isArray(result.edges)) {
                    throw new TypeError('API вернул данные графа в неверном формате.');
                }
                setObjects(result.nodes);
                setRelations(result.edges);
                setPassports([]);
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
    }, [refreshCount]);

    const handleRefresh = () => {
        setLoading(true);
        setLoadError('');
        setRefreshCount((count) => count + 1);
    };

    useEffect(() => {
        const controller = new AbortController();
        const mapsUrl = `${import.meta.env.BASE_URL}maps/`;
        Promise.all([
            loadBoundaryData(`${mapsUrl}military-districts.geojson`, controller.signal),
            loadBoundaryData(`${mapsUrl}russia-regions.geojson`, controller.signal),
        ]).then(([districts, regions]) => {
            if (!controller.signal.aborted) {
                setBoundaries({
                    districts: districts.features.filter(({ geometry }) => geometry.type !== 'Point'),
                    regions: regions.features,
                });
            }
        }).catch(() => {
            if (!controller.signal.aborted) setBoundaryError(true);
        });
        return () => controller.abort();
    }, []);

    const handleFitGraph = useCallback(() => {
        flowInstanceRef.current?.fitView({ padding: 0.15, duration: 250 });
    }, []);

    const updateGraphPassport = useCallback(() => {
        const flow = flowInstanceRef.current;
        if (isMapVisible || !flow) return;
        const toolbarBottom = (document.querySelector('.passport-tabs') ?? document.querySelector('.toolbar'))?.getBoundingClientRect().bottom ?? 0;
        const cards = visiblePassports.flatMap((item) => {
            const key = passportKey(item);
            const element = passportElements.get(key)?.current;
            if (!element) return [];
            if (item.detachedPosition || element.dataset.dragging) {
                const point = element.dataset.dragging ? element.getBoundingClientRect() : item.detachedPosition;
                return [{ key, x: point.x, y: point.y, width: element.offsetWidth, height: element.offsetHeight,
                    fixed: true, detached: Boolean(item.detachedPosition) }];
            }
            const isDetail = isPassportDetail(item.type);
            if (isDetail || (item.type === 'node' && !item.data.isLine)) {
                const anchorId = CSS.escape(item.data.lineId ?? item.data.id);
                const node = document.querySelector(`.react-flow__node[data-id="${anchorId}"], [data-passport-id="${anchorId}"]`);
                const anchor = node?.getBoundingClientRect();
                if (isDetail) {
                    if (!item.lineKey || anchor) return [passportDetailCard(item, element, anchor)];
                    const edge = graph.edges.find((candidate) => passportKey({ type: 'edge', data: candidate }) === item.lineKey);
                    const path = edge && document.querySelector(`.react-flow__edge[data-id="${CSS.escape(edge.id)}"] .react-flow__edge-path`);
                    const bounds = path?.getBoundingClientRect();
                    const midpoint = bounds && { x: bounds.x + bounds.width / 2, y: bounds.y + bounds.height / 2, width: 1, height: 1 };
                    return [passportDetailCard(item, element, midpoint)];
                }
                if (anchor) {
                    const card = { key, width: element.offsetWidth, height: element.offsetHeight };
                    return [{ ...card, nodeAnchor: anchor,
                        ...sidePassportPosition(card, anchor, { left: 12, right: window.innerWidth - 12 }) }];
                }
            }
            let point = item.position;
            if (item.flowAnchor) {
                const anchor = flow.flowToScreenPosition(item.flowAnchor);
                point = { x: anchor.x + (item.anchorOffset?.x ?? 0), y: anchor.y + (item.anchorOffset?.y ?? 0) };
            } else if (item.type === 'node') {
                const node = document.querySelector(`.react-flow__node[data-id="${CSS.escape(item.nodeId)}"]`);
                const bounds = node?.getBoundingClientRect();
                if (bounds) point = { x: bounds.right + 15, y: bounds.top };
            } else {
                const edge = graph.edges.find((candidate) => passportKey({ type: 'edge', data: candidate }) === key);
                const path = edge && document.querySelector(`.react-flow__edge[data-id="${CSS.escape(edge.id)}"] .react-flow__edge-path`);
                const bounds = path?.getBoundingClientRect();
                if (bounds) point = { x: bounds.x + bounds.width / 2 + 12, y: bounds.y + 12 };
            }
            return [{ key, ...point, width: element.offsetWidth, height: element.offsetHeight }];
        });
        positionPassportWindows(cards, {
            left: 12, top: toolbarBottom + 12, right: window.innerWidth - 12, bottom: window.innerHeight - 12,
        }, passportElements);
    }, [isMapVisible, visiblePassports, passportElements, graph.edges]);

    useEffect(() => {
        if (isMapVisible) return;
        updateGraphPassport();
        window.addEventListener('resize', updateGraphPassport);
        const observer = new ResizeObserver(updateGraphPassport);
        const container = document.querySelector('.network-flow--interactive');
        if (container) observer.observe(container);
        passportElements.forEach((ref) => { if (ref.current) observer.observe(ref.current); });
        return () => { window.removeEventListener('resize', updateGraphPassport); observer.disconnect(); };
    }, [isMapVisible, updateGraphPassport, passportElements]);

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
        setPassports((current) => current.map((item) => item.nodeId === id
            ? { ...item, data: { ...item.data, lng, lat } } : item));
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

    const closeAllWindows = () => {
        cancelPassportHover();
        setActivePassportId(null);
        setPassports([]);
        setHighlightWindow(null);
        setManualEditing(null);
        setCtrlPreview(false);
    };

    const minimizeAllPassports = () => {
        cancelPassportHover();
        setActivePassportId(null);
        setPassports((current) => current.some((item) => !item.minimized)
            ? current.map((item) => ({ ...item, minimized: true })) : current);
    };

    const restoreAllPassports = () => {
        cancelPassportHover();
        setPassports((current) => current.map((item) => item.minimized
            ? { ...item, minimized: false, pinned: true } : item));
    };

    const minimizePassport = (key) => {
        cancelPassportHover();
        setActivePassportId((current) => current === key ? null : current);
        setPassports((current) => current.map((item) => passportKey(item) === key
            ? { ...item, minimized: true } : item));
        document.querySelector(`[data-passport-tab="${CSS.escape(key)}"]`)?.focus({ preventScroll: true });
    };

    const restorePassport = (key) => {
        cancelPassportHover();
        setActivePassportId(key);
        setPassports((current) => current.map((item) => passportKey(item) === key
            ? { ...item, minimized: false, pinned: true } : item));
    };

    const openPassportDetail = (parent, type, data) => {
        cancelPassportHover();
        const width = Math.min(560, window.innerWidth - 24);
        const position = { x: (window.innerWidth - width) / 2, y: 112 };
        const parentKey = passportKey(parent);
        const next = {
            type,
            data: { ...data, label: `${passportDetailTitles[type]} ${data.marker ?? `№ ${data.number}`}` },
            parentKey,
            lineKey: parent.lineKey ?? (data.marker ? parentKey : undefined),
            position,
            pinned: true,
        };
        const key = passportKey(next);
        setActivePassportId(key);
        setPassports((current) => openPassport(current, next).map((item) => passportKey(item) === key
            ? { ...item, data: next.data, parentKey, lineKey: next.lineKey, minimized: false } : item));
        requestAnimationFrame(() => {
            document.querySelector(`[data-passport-key="${CSS.escape(key)}"] .passport__identity`)?.focus({ preventScroll: true });
        });
    };

    const handleBackgroundClick = (event) => {
        if (!(event.target instanceof Element)) return;
        if ((manualEditing === 'click' || event.ctrlKey)
            && handleManualNode(event, event.target.closest('.network-map-overlay__node, .react-flow__node'))) return;
        if (manualSelecting || !isMapVisible) return;
        if (event.target.closest(
            '.toolbar, .passport-tabs, .manual-selection-panel, .passport, .highlight-dialog, .network-map-overlay__node, .network-map-overlay__edge, .network-map-overlay__edge-label, '
            + '.network-map-overlay__edge-hit, .maplibregl-ctrl, .network-data-notice'
        )) {
            return;
        }
        minimizeAllPassports();
    };

    const handleMapVisibilityChange = (visible) => {
        if (visible === isMapVisible) return;
        cancelPassportHover();
        setIsMapVisible(visible);
    };

    const shownMapEdges = hideOthers ? allMapEdges.filter(isHighlightedEdge) : allMapEdges;
    const shownMapNodeIds = hideOthers ? new Set([...highlight.nodes, ...shownMapEdges.flatMap(({ source, target }) => [source, target])]) : null;
    const shownMapObjects = shownMapNodeIds ? locatedObjects.filter(({ id }) => shownMapNodeIds.has(id)) : locatedObjects;

    const handleManualNode = (event, target) => {
        const id = target?.dataset.id;
        if (!id || event.target.closest('.network-composition__toggle, [data-passport-id]')) return false;
        if (!objects.some((node) => node.id === id && /узел связи/i.test(node.data.templateName || node.data.type || ''))) return false;
        event.preventDefault();
        event.stopPropagation();
        cancelPassportHover();
        setManualSelection((current) => {
            const next = new Set(current);
            if (next.has(id)) next.delete(id);
            else next.add(id);
            return next;
        });
        setHighlightSection('manual');
        setHighlightWindow('minimized');
        setManualEditing((current) => current ?? 'shortcut');
        return true;
    };
    const applyManual = (hideOthers) => {
        if (!manualSelection.size) return;
        setManualApplied({ nodes: manualSelection, hideOthers });
        setManualEditing(null);
        setCtrlPreview(false);
        setHighlightWindow('minimized');
    };
    const clearManual = () => {
        setManualSelection(new Set());
        setManualApplied(null);
    };
    const removeManualNode = (id) => {
        const removeNode = (nodes) => {
            const next = new Set(nodes);
            next.delete(id);
            return next;
        };
        setManualSelection(removeNode);
        setManualApplied((current) => current?.nodes.has(id)
            ? { ...current, nodes: removeNode(current.nodes) }
            : current);
    };
    const closeHighlight = () => {
        setManualEditing(null);
        setHighlightWindow(null);
    };

    const getTargetPassport = (target, clientX, clientY) => {
        const id = target.dataset.passportId ?? target.dataset.id ?? target.dataset.edgeLabel;
        const isEdge = target.matches('.react-flow__edge, .network-map-overlay__edge, '
            + '.network-map-overlay__edge-hit, .network-map-overlay__edge-label');
        let nextPassport;
        if (isEdge) {
            const edge = (isMapVisible ? shownMapEdges : graph.edges).find((item) => item.id === id);
            if (!edge) return;
            nextPassport = createEdgePassport(edge, { x: clientX + 12, y: clientY + 12 },
                target.tagName.toLowerCase() === 'line' ? getEdgeAnchorT({ clientX, clientY }, target) : 0.5);
            if (!isMapVisible) {
                nextPassport.flowAnchor = flowInstanceRef.current.screenToFlowPosition({ x: clientX, y: clientY });
                nextPassport.anchorOffset = { x: 12, y: 12 };
            }
        } else {
            const node = objects.find((item) => item.id === id);
            if (!node) return;
            const displayData = !isMapVisible ? graph.nodes.find((item) => item.id === id)?.data : null;
            const { right, top } = target.getBoundingClientRect();
            nextPassport = {
                type: 'node', nodeId: id,
                data: { ...node.data, ...displayData, id, lng: node.lng, lat: node.lat },
                position: { x: right + 15, y: top },
            };
            if (!isMapVisible) {
                nextPassport.flowAnchor = flowInstanceRef.current.screenToFlowPosition({ x: right, y: top });
                nextPassport.anchorOffset = { x: 15, y: 0 };
            }
        }
        return nextPassport;
    };
    const handlePassportHover = (event) => {
        if (manualEditing === 'click' || event.ctrlKey) return;
        const target = getPassportHoverTarget(event.target);
        if (target === getPassportHoverTarget(event.relatedTarget)) return;
        cancelPassportHover();
        if (!target) return;
        const nextPassport = getTargetPassport(target, event.clientX, event.clientY);
        if (!nextPassport || passports.some((item) => passportKey(item) === passportKey(nextPassport))) return;
        passportHoverTimerRef.current = setTimeout(() => {
            passportHoverTimerRef.current = null;
            showPassport(nextPassport);
        }, passportHoverDelay);
    };

    const tabs = new Map();
    if (highlightWindow) tabs.set('highlight', null);
    for (const item of passports) tabs.set(passportKey(item), item);
    const orderedTabKeys = [
        ...windowTabOrder.filter((key) => tabs.has(key)),
        ...[...tabs.keys()].filter((key) => !windowTabOrder.includes(key)),
    ];
    const moveWindowTab = (source, target) => {
        const sourceIndex = orderedTabKeys.indexOf(source);
        const targetIndex = orderedTabKeys.indexOf(target);
        if (sourceIndex < 0 || targetIndex < 0 || sourceIndex === targetIndex) return;
        const nextOrder = [...orderedTabKeys];
        nextOrder.splice(sourceIndex, 1);
        nextOrder.splice(targetIndex, 0, source);
        setWindowTabOrder(nextOrder);
    };

    return (
        <div className="app" onClickCapture={handleBackgroundClick}
            onMouseOver={handlePassportHover}
            onMouseOut={(event) => {
                if (getPassportHoverTarget(event.target) !== getPassportHoverTarget(event.relatedTarget)) cancelPassportHover();
            }}
            onPointerDownCapture={cancelPassportHover}
            onKeyDownCapture={(event) => {
                const target = getPassportHoverTarget(event.target);
                if (!target || event.target.closest('button, input, a, .passport')) return;
                if (event.key !== 'Enter' && event.key !== ' ') return;
                if ((manualEditing === 'click' || event.ctrlKey) && handleManualNode(event, target)) return;
                event.preventDefault();
                event.stopPropagation();
                cancelPassportHover();
                const bounds = target.getBoundingClientRect();
                const nextPassport = getTargetPassport(target, bounds.x + bounds.width / 2, bounds.y + bounds.height / 2);
                if (nextPassport) {
                    togglePassport(nextPassport);
                    requestAnimationFrame(() => document.querySelector(`[data-passport-key="${CSS.escape(passportKey(nextPassport))}"] .passport__icon-button`)?.focus({ preventScroll: true }));
                }
            }}>
            <Toolbar
                appliedFilter={manualApplied
                    ? `Ручной выбор: ${manualApplied.nodes.size} · ${manualApplied.hideOthers ? 'Только выбранные' : 'Подсветка выбранных'}`
                    : describeHighlightFilters(highlightFilters, boundaries)}
                isMapVisible={isMapVisible}
                onMapVisibilityChange={handleMapVisibilityChange}
                mapLayer={mapLayer}
                onMapLayerChange={setMapLayer}
                onRefresh={handleRefresh}
                onOpenHighlight={() => {
                    if (!highlightWindow) setHighlightDraft(highlightFilters);
                    setHighlightWindow('open');
                }}
                onResetHighlight={() => {
                    setHighlightFilters(emptyHighlight);
                    setHighlightDraft(emptyHighlight);
                    setManualEditing(null);
                    clearManual();
                }}
                isRefreshing={loading}
            />
            {highlightWindow && <HighlightDialog boundaries={boundaries} draft={highlightDraft} onDraftChange={setHighlightDraft}
                open={highlightOpen} onApply={(filters) => {
                    setHighlightFilters(filters);
                    setManualApplied(null);
                    setManualEditing(null);
                }} onReset={() => setHighlightFilters(emptyHighlight)}
                onMinimize={() => setHighlightWindow('minimized')} onClose={closeHighlight}
                section={highlightSection} onSectionChange={setHighlightSection}
                selectedNodes={objects.filter(({ id }) => manualSelection.has(id))} onStartManual={() => {
                    cancelPassportHover();
                    setManualEditing('click');
                    setHighlightWindow('minimized');
                }} onApplyManual={applyManual} onClearManual={clearManual} hasAppliedManual={Boolean(manualApplied)}
                onRemoveManualNode={removeManualNode} />}

            {manualSelecting && <section className="manual-selection-panel" aria-label="Ручной выбор узлов">
                <span role="status">Выбрано узлов: {manualSelection.size}</span>
                <button type="button" disabled={!manualSelection.size}
                    onClick={() => applyManual(false)}>Подсветить выбранные</button>
                <button type="button" disabled={!manualSelection.size}
                    onClick={() => applyManual(true)}>Показать только выбранные</button>
                <button type="button" onClick={() => {
                    setManualEditing(null);
                    setCtrlPreview(false);
                }}>Отмена</button>
            </section>}

            {(passports.length > 0 || highlightWindow) && <div className="passport-tabs" role="group" aria-label="Открытые окна">
                <div className="passport-tabs__list">
                    {orderedTabKeys.map((key) => {
                        const item = tabs.get(key);
                        let label = item ? item.data.label || 'Соединение' : 'Подсветка';
                        if (item?.type === 'node' && !item.data.isLine) label = `Паспорт ${item.data.label || 'УС'}`;
                        const expanded = item ? !item.minimized : highlightOpen;
                        const active = expanded && (!item || key === activePassportId);
                        return <div className={`passport-tabs__item${active ? ' is-active' : ''}${item?.minimized ? ' is-minimized' : ''}`} key={key}
                            onDragOver={(event) => {
                                if (!draggedPassportTabRef.current || draggedPassportTabRef.current === key) return;
                                event.preventDefault();
                                event.dataTransfer.dropEffect = 'move';
                            }}
                            onDrop={(event) => {
                                const sourceKey = draggedPassportTabRef.current;
                                if (!sourceKey) return;
                                event.preventDefault();
                                draggedPassportTabRef.current = null;
                                moveWindowTab(sourceKey, key);
                            }}>
                            <button type="button" className="passport-tabs__restore" data-passport-tab={item ? key : undefined}
                                aria-expanded={expanded} aria-controls={item ? undefined : 'highlight-dialog'}
                                title={item ? `${expanded ? 'Свернуть' : 'Развернуть'} · ${label}` : undefined}
                                draggable={orderedTabKeys.length > 1}
                                onDragStart={(event) => {
                                    cancelPassportHover();
                                    draggedPassportTabRef.current = key;
                                    event.dataTransfer.effectAllowed = 'move';
                                    event.dataTransfer.setData('application/x-passport-tab', key);
                                }}
                                onDragEnd={() => { draggedPassportTabRef.current = null; }}
                                onClick={() => {
                                    if (!item) setHighlightWindow('open');
                                    else if (expanded) minimizePassport(key);
                                    else restorePassport(key);
                                }}>{label}</button>
                            <button type="button" className="passport-tabs__close"
                                aria-label={item ? `Закрыть · ${label}` : 'Закрыть окно подсветки'}
                                onClick={() => item ? closePassport(key) : closeHighlight()}>×</button>
                        </div>;
                    })}
                </div>
                {passports.length > 0 && <>
                <button type="button" className="passport-tabs__bulk-action" onClick={restoreAllPassports}
                    disabled={!passports.some((item) => item.minimized)}>Открыть все</button>
                <button type="button" className="passport-tabs__bulk-action" onClick={minimizeAllPassports}
                    disabled={visiblePassports.length === 0}>Скрыть все</button>
                </>}
                <button type="button" className="passport-tabs__bulk-action" onClick={closeAllWindows}>Закрыть все</button>
            </div>}

            {isMapVisible && (
                <PhysicalMap
                    onMapReady={setMapInstance}
                    mapLayer={mapLayer}
                />
            )}

            {loading && (
                <div className="network-data-notice" role="status">
                    {refreshCount ? 'Обновляю узлы и связи…' : 'Загружаю узлы и связи из базы данных…'}
                </div>
            )}
            {loadError && (
                <div className="network-data-notice network-data-notice--error" role="alert">
                    Не удалось загрузить граф: {loadError}
                    {' '}Проверьте подключение API и PostgreSQL.
                </div>
            )}
            {!loading && !loadError && boundaryError && (
                <div className="network-data-notice network-data-notice--error" role="alert">
                    Не удалось загрузить границы для фильтрации по территории.
                </div>
            )}
            {!loading && !loadError && objects.length === 0 && (
                <div className="network-data-notice" role="status">
                    В выбранной базе пока нет СФЭ для отображения.
                </div>
            )}
            {!isMapVisible && !manualSelecting && !loading && !loadError && !boundaryError && objects.length > 0 && (
                <div className="network-data-notice" role="status">
                    Нажмите «+» у узла или комплекта, чтобы раскрыть его состав.
                </div>
            )}
            {isMapVisible ? (
                <MapGraphOverlay
                    map={mapInstance}
                    objects={shownMapObjects}
                    edges={shownMapEdges}
                    highlight={highlight}
                    onNodeClick={togglePassport}
                    onEdgeClick={togglePassport}
                    passports={visiblePassports}
                    showPassportHighlights={!manualView}
                    passportElements={passportElements}
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
                    nodeOrigin={[0.5, 0]}
                    nodesDraggable={false}
                    nodesConnectable={false}
                    panOnDrag
                    zoomOnScroll
                    zoomOnPinch
                    zoomOnDoubleClick
                    preventScrolling
                    onNodeClick={(event, node) => openGraphObject(node.id, node.data, event.currentTarget)}
                    onEdgeClick={(event, edge) => {
                        togglePassport({ ...createEdgePassport(edge, {
                            x: event.clientX + 12,
                            y: event.clientY + 12,
                        }),
                            flowAnchor: flowInstanceRef.current.screenToFlowPosition({ x: event.clientX, y: event.clientY }),
                            anchorOffset: { x: 12, y: 12 },
                        });
                    }}
                    onPaneClick={manualSelecting ? undefined : minimizeAllPassports}
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

            {passports.map((item, index) => (
                <Passport
                    key={passportKey(item)}
                    passportId={passportKey(item)}
                    stackOrder={passportKey(item) === activePassportId ? passports.length : index}
                    type={item.type}
                    data={item.data}
                    position={item.position}
                    elementRef={passportElements.get(passportKey(item))}
                    onCoordinatesChange={handleCoordinatesChange}
                    onFocusLocation={handleFocusLocation}
                    pinned={item.pinned}
                    minimized={item.minimized}
                    onMinimize={() => minimizePassport(passportKey(item))}
                    detachedPosition={item.detachedPosition}
                    onMove={(point) => movePassport(passportKey(item), point)}
                    onReattach={() => reattachPassport(passportKey(item))}
                    onPin={() => pinPassport(passportKey(item))}
                    onClose={() => closePassport(passportKey(item))}
                    onOpenDetail={(type, data) => openPassportDetail(item, type, data)}
                    routeHighlighted={Boolean(item.routeHighlighted)}
                    onRouteHighlight={(checked) => {
                        const key = passportKey(item);
                        setPassports((current) => current.map((entry) => passportKey(entry) === key
                            ? { ...entry, routeHighlighted: checked } : entry));
                    }}
                />
            ))}
        </div>
    );
}

export default NetworkPage;
