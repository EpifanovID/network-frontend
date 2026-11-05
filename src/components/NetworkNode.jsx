import { Handle, Position } from '@xyflow/react';

function CompositionToggle({ id, label, expanded, onToggle }) {
    return (
        <button
            type="button"
            className="network-composition__toggle nodrag nopan"
            aria-label={`${expanded ? 'Свернуть' : 'Развернуть'} состав ${label}`}
            aria-expanded={expanded}
            onClick={(event) => {
                event.stopPropagation();
                onToggle(id);
            }}
        >
            {expanded ? '−' : '+'}
        </button>
    );
}

function CompositionList({ items, expandedIds, onToggle, onOpen }) {
    return (
        <ul className="network-composition__list">
            {items.map(({ id, data, children }) => {
                const expanded = expandedIds.has(id);
                return (
                    <li key={id}>
                        <div className="network-composition__item">
                            <button type="button" className="network-composition__name nodrag nopan"
                                onClick={(event) => {
                                    event.stopPropagation();
                                    onOpen(id, data, event.currentTarget);
                                }}>
                                <strong>{data.label}</strong>
                                <span>{data.templateName || data.type}</span>
                            </button>
                            {children.length > 0 && (
                                <CompositionToggle id={id} label={data.label} expanded={expanded} onToggle={onToggle} />
                            )}
                        </div>
                        {expanded && <CompositionList items={children} expandedIds={expandedIds}
                            onToggle={onToggle} onOpen={onOpen} />}
                    </li>
                );
            })}
        </ul>
    );
}

export default function NetworkNode({ data }) {
    const expanded = data.expandedIds.has(data.id);
    return (
        <div className="network-graph-node network-composition">
            {data.routePorts.map((port, index, ports) => (
                <Handle key={port.id} id={port.id} type={port.type}
                    position={port.side === 'top' ? Position.Top : Position.Bottom}
                    style={{ left: `${15 + (index + 1) * 70 / (ports.length + 1)}%` }}
                    className="network-graph-node__route-handle" />
            ))}
            <div className={`composition-node network-composition__header${data.isLine ? '' : ' composition-node--root'}`}>
                <span className="composition-node__category">{data.isLine ? 'ЛИНИЯ СВЯЗИ' : 'УЗЕЛ СВЯЗИ'}</span>
                <strong className="composition-node__name" title={data.label}>{data.label}</strong>
                <span className="composition-node__type">{data.templateName || data.type}</span>
                {data.composition.length > 0 && <CompositionToggle id={data.id} label={data.label}
                    expanded={expanded} onToggle={data.onToggle} />}
            </div>
            {expanded && data.composition.length > 0 && (
                <CompositionList items={data.composition} expandedIds={data.expandedIds}
                    onToggle={data.onToggle} onOpen={data.onOpen} />
            )}
        </div>
    );
}
