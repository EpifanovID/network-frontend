import { BaseEdge, getSmoothStepPath, Position } from '@xyflow/react';

export default function DiagramEdge({ id, sourceX, sourceY, targetX, targetY, sourcePosition,
    targetPosition, markerEnd, style, label, labelStyle, labelBgStyle,
    labelBgPadding, labelBgBorderRadius }) {
    const [path] = getSmoothStepPath({ sourceX, sourceY, targetX, targetY,
        sourcePosition, targetPosition });
    return (
        <BaseEdge
            id={id}
            path={path}
            markerEnd={markerEnd}
            style={style}
            label={label}
            labelX={targetX + (targetPosition === Position.Left ? -54 : targetPosition === Position.Right ? 54 : 0)}
            labelY={targetY + (targetPosition === Position.Bottom ? 26 : targetPosition === Position.Top ? -26 : 0)}
            labelStyle={labelStyle}
            labelBgStyle={labelBgStyle}
            labelBgPadding={labelBgPadding}
            labelBgBorderRadius={labelBgBorderRadius}
        />
    );
}

