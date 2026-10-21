import { Background, BaseEdge, Controls, Handle, MarkerType, Position, ReactFlow, getSmoothStepPath } from '@xyflow/react';
import { useMemo, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { DEMO_LINE_ID, exampleRoute, getExamplePorts, lineExampleEdges, lineExampleNodes, relationKinds } from '../data/lineExample';
import '@xyflow/react/dist/style.css';
import '../App.css';

const positionFor = { top: Position.Top, bottom: Position.Bottom, left: Position.Left, right: Position.Right };

function LineObject({ id, data }) {
    const ports = getExamplePorts(id);
    return (
        <div className={`line-object line-object--${data.tone}`}>
            {ports.map((port) => {
                const sameSide = ports.filter((item) => item.side === port.side);
                const offset = 12 + (sameSide.findIndex((item) => item.id === port.id) + 1) * 76 / (sameSide.length + 1);
                return <Handle key={port.id} id={port.id} type={port.type} position={positionFor[port.side]}
                    style={port.side === 'top' || port.side === 'bottom' ? { left: `${offset}%` } : { top: `${offset}%` }} />;
            })}
            <span className="line-object__kind">{data.kind}</span>
            <strong>{data.label}</strong>
            <span className="line-object__id">{id}</span>
        </div>
    );
}

function LineRelation({ id, sourceX, sourceY, targetX, targetY, sourcePosition, targetPosition, data, style, markerEnd }) {
    const hasLane = Number.isFinite(data.laneY);
    const [smoothPath, labelX, labelY] = getSmoothStepPath({ sourceX, sourceY, targetX, targetY,
        sourcePosition, targetPosition, borderRadius: 10 });
    const approachX = data.approachX ?? targetX;
    const path = hasLane ? `M ${sourceX},${sourceY} V ${data.laneY} H ${approachX} V ${targetY} H ${targetX}` : smoothPath;
    return <BaseEdge id={id} path={path} style={style} markerEnd={markerEnd}
        label={`${id.replace('LS1-', '')} · ${data.label}`}
        labelX={hasLane ? (sourceX + targetX) / 2 : labelX}
        labelY={hasLane ? data.laneY : labelY}
        labelStyle={{ fill: data.color, fontSize: 11, fontWeight: 600, opacity: style?.opacity ?? 1 }}
        labelBgStyle={{ fill: '#fbfaf7', fillOpacity: style?.opacity ?? 1 }}
        labelBgPadding={[6, 3]} labelBgBorderRadius={4} interactionWidth={20} />;
}
const nodeTypes = { lineObject: LineObject };
const edgeTypes = { lineRelation: LineRelation };
const filters = [ ['all', 'Все связи'], ['physical', 'Подключения'], ['channel', 'Маршрут канала'], ['structure', 'Состав оборудования'] ];

export default function LinePage() {
    const { lineId } = useParams();
    const [filter, setFilter] = useState('all');
    const [selected, setSelected] = useState(null);
    const [showRegistry, setShowRegistry] = useState(false);
    const [showDetails, setShowDetails] = useState(false);
    const isDemo = lineId === DEMO_LINE_ID;
    const visibleEdges = useMemo(() => lineExampleEdges.filter((edge) => filter === 'all' || edge.data.group === filter), [filter]);
    const selectedNode = lineExampleNodes.find((node) => node.id === selected);
    const selectedRelation = lineExampleEdges.find((edge) => edge.id === selected);
    const selectedEdges = visibleEdges.filter((edge) => edge.id === selected || edge.source === selected || edge.target === selected);
    const emphasizedIds = new Set(selectedEdges.flatMap((edge) => [edge.source, edge.target]));
    if (selectedNode) emphasizedIds.add(selectedNode.id);
    const nodes = lineExampleNodes.map((node) => ({ ...node,
        style: { opacity: selected && !emphasizedIds.has(node.id) ? 0.35 : 1 },
        data: { ...node.data, tone: node.id === 'LS1-019' ? 'channel' : node.data.kind === 'Узел связи' ? 'root' : 'default' },
        className: node.id === selected ? 'line-object-selected' : '',
    }));
    const edges = visibleEdges.map((edge) => ({ ...edge,
        style: { stroke: edge.data.color, strokeWidth: selectedEdges.includes(edge) ? 2.5 : 1.5,
            strokeDasharray: edge.data.relation === 4 ? '6 4' : undefined,
            opacity: selected && !selectedEdges.includes(edge) ? 0.12 : 1 },
        markerEnd: { type: MarkerType.ArrowClosed, color: edge.data.color, width: 16, height: 16 },
        zIndex: selectedEdges.includes(edge) ? 10 : 0,
    }));

    return (
        <div className="object-page line-page">
            <header className="object-page__header">
                <Link to="/" className="object-page__back">← К сети</Link>
                <div className="object-page__heading">
                    <span className="object-page__eyebrow">СЕТЬ СВЯЗИ / СОСТАВ ЛИНИИ</span>
                    <h1>{isDemo ? 'ЛС1 · УС1 ↔ УС2' : 'Состав линии связи'}</h1>
                    <p>{isDemo ? 'Пример по рисунку · Канал STM-4 · Оптоволокно № 58 · Тракт № 45' : `ID линии: ${lineId}`}</p>
                </div>
                <span className="line-page__badge">{isDemo ? 'Демонстрационный пример' : 'В разработке'}</span>
            </header>
            {!isDemo ? (
                <main className="line-page__empty"><span className="object-page__eyebrow">СОСТАВ ЛИНИИ</span>
                    <h2>Схема пока не заполнена</h2>
                    <p>Демонстрационный состав подготовлен для ЛС1 между УС1 и УС2.</p>
                    <Link className="passport__link" to={`/lines/${DEMO_LINE_ID}`}>Открыть пример ЛС1 →</Link>
                </main>
            ) : (
                <>
                    <div className="line-page__tools">
                        <div className="line-page__filters" role="group" aria-label="Типы связей схемы">
                            {filters.map(([value, label]) => <button key={value} type="button" aria-pressed={filter === value}
                                onClick={() => { setFilter(value); setSelected(null); }}>{label}</button>)}
                        </div>
                        <div className="line-page__filters">
                            <button className="line-page__registry-button" type="button" aria-expanded={showDetails || Boolean(selected)}
                                onClick={() => { setShowDetails(!(showDetails || selected)); setSelected(null); }}>Описание схемы</button>
                            <button className="line-page__registry-button" type="button" aria-expanded={showRegistry}
                                onClick={() => setShowRegistry(!showRegistry)}>Объекты и ID · 20</button>
                        </div>
                    </div>
                    <div className="line-page__legend">
                        {Object.entries(relationKinds).map(([number, kind]) => <span key={number}>
                            <i style={{ background: kind.color }} />{number} · {kind.label}</span>)}
                    </div>
                    <main className="line-page__workspace">
                        <div className="line-page__graph">
                            <ReactFlow nodes={nodes} edges={edges} nodeTypes={nodeTypes} edgeTypes={edgeTypes}
                                fitView fitViewOptions={{ padding: 0.12, maxZoom: 1 }} minZoom={0.2} maxZoom={2}
                                nodesDraggable={false} nodesConnectable={false} aria-label="Схема подключения линии связи ЛС1"
                                onNodeClick={(_, node) => setSelected(node.id)} onEdgeClick={(_, edge) => setSelected(edge.id)}
                                onPaneClick={() => setSelected(null)}>
                                <Background color="#ded8ce" gap={24} size={1} />
                                <Controls showInteractive={false} />
                            </ReactFlow>
                        </div>
                        <aside className={`line-page__details${showDetails || selected ? ' is-open' : ''}`}>
                            <button type="button" className="line-page__details-close" aria-label="Закрыть описание"
                                onClick={() => { setShowDetails(false); setSelected(null); }}>×</button>
                            <span className="object-page__eyebrow">{selected ? 'ВЫБРАННЫЙ ЭЛЕМЕНТ' : 'О СХЕМЕ'}</span>
                            {selectedNode ? <><h2>{selectedNode.data.label}</h2>
                                <code>{selectedNode.id}</code><p>{selectedNode.data.kind} · {selectedNode.data.group}</p>
                                {selectedNode.data.note && <p className="line-page__assumption">{selectedNode.data.note}</p>}
                                <h3>Отношения</h3>
                                {lineExampleEdges.filter((edge) => edge.source === selected || edge.target === selected).map((edge) => (
                                    <p key={edge.id}><code>{edge.id}</code><br />{edge.source} → {edge.data.label} → {edge.target}</p>
                                ))}</> : selectedRelation ? <><h2>{selectedRelation.data.label}</h2><code>{selectedRelation.id}</code>
                                <p>{selectedRelation.source} → {selectedRelation.target}</p>
                                {selectedRelation.data.assumption && <p className="line-page__assumption">Это отношение восстановлено по предположению; требуется уточнение.</p>}
                            </> : <><h2>20 объектов · 27 связей</h2><p>Нажмите на объект или стрелку, чтобы проверить его ID и отношения.</p>
                                <h3>Последовательный маршрут</h3>
                                <ol>{exampleRoute.map((id) => <li key={id}><code>{id}</code><br />{lineExampleNodes.find((node) => node.id === id).data.label}</li>)}</ol>
                            </>}
                        </aside>
                    </main>
                    {showRegistry && <section className="line-page__registry" aria-label="Реестр объектов схемы">
                        <table><thead><tr><th>ID</th><th>Объект</th><th>Группа</th></tr></thead><tbody>
                            {lineExampleNodes.map((node) => <tr key={node.id} onClick={() => setSelected(node.id)}>
                                <td><button type="button" onClick={() => setSelected(node.id)}>{node.id}</button></td>
                                <td>{node.data.label}</td><td>{node.data.group}</td></tr>)}
                        </tbody></table>
                    </section>}
                </>
            )}
        </div>
    );
}
