import { BaseEdge } from '@xyflow/react';

export default function RoutedEdge({ id, sourceX, sourceY, targetX, targetY, data, style, label }) {
    const isRoute = Number.isFinite(data?.laneY);
    const lane = data?.laneY;
    const gutter = data?.gutterX;
    const path = isRoute
        ? `M ${sourceX},${sourceY} V ${lane} H ${targetX} V ${targetY}`
        : `M ${sourceX},${sourceY} H ${gutter} V ${targetY} H ${targetX}`;
    return <BaseEdge id={id} path={path} style={style}
        label={isRoute ? data.routeLabel : label}
        labelX={isRoute ? (sourceX + targetX) / 2 : targetX + 42}
        labelY={isRoute ? lane : targetY - 12}
        labelStyle={{ fill: '#76583d', fontSize: 11, opacity: style?.opacity ?? 1 }}
        labelBgStyle={{ fill: '#fbfaf7', fillOpacity: style?.opacity ?? 1 }}
        labelBgPadding={[6, 3]} labelBgBorderRadius={4} interactionWidth={20} />;
}
