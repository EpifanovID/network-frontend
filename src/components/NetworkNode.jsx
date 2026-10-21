import { Handle, Position } from '@xyflow/react';



function NetworkNode({ data }) {
    const isConnectionNode = /узел связи/i.test(data.templateName || data.type || '');
    return (
        <div className={`composition-node network-graph-node${isConnectionNode ? ' composition-node--root' : ''}`}>
            {(data.routePorts || []).map((port, index, ports) => {
                const siblings = ports.filter((item) => item.side === port.side);
                const portIndex = siblings.findIndex((item) => item.id === port.id);
                return <Handle key={index} id={port.id} type={port.type}
                    position={port.side === 'top' ? Position.Top : Position.Bottom}
                    style={{ left: `${15 + (portIndex + 1) * 70 / (siblings.length + 1)}%` }}
                    className="network-graph-node__route-handle" />;
            })}
            {/* Верхняя сторона */}
            <Handle
                type="target"
                position={Position.Top}
                id="top-target"
                className="network-graph-node__handle"
            />

            <Handle
                type="source"
                position={Position.Top}
                id="top-source"
                className="network-graph-node__handle"
            />

            {/* Левая сторона */}
            <Handle
                type="target"
                position={Position.Left}
                id="left-target"
                className="network-graph-node__handle"
            />

            <Handle
                type="source"
                position={Position.Left}
                id="left-source"
                className="network-graph-node__handle"
            />

            <span className="composition-node__category">{isConnectionNode ? 'УЗЕЛ СВЯЗИ' : data.isLine ? 'ЛИНИЯ СВЯЗИ' : 'ОБОРУДОВАНИЕ'}</span>
            <strong className="composition-node__name" title={data.label}>{data.label}</strong>
            <span className="composition-node__type" title={data.endpointLabel || data.templateName || data.type}>{data.endpointLabel || data.templateName || data.type || 'Тип не указан'}</span>

            {/* Правая сторона */}
            <Handle
                type="target"
                position={Position.Right}
                id="right-target"
                className="network-graph-node__handle"
            />

            <Handle
                type="source"
                position={Position.Right}
                id="right-source"
                className="network-graph-node__handle"
            />

            {/* Нижняя сторона */}
            <Handle
                type="target"
                position={Position.Bottom}
                id="bottom-target"
                className="network-graph-node__handle"
            />

            <Handle
                type="source"
                position={Position.Bottom}
                id="bottom-source"
                className="network-graph-node__handle"
            />
        </div>
    );
}


export default NetworkNode;
