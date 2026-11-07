import { Link } from 'react-router-dom';
import { useEffect, useId, useLayoutEffect, useRef, useState } from 'react';
import { fetchJson } from '../utils/api';
import { clampPassportPosition } from '../utils/passports';

const nodeSections = [
    'Все характеристики УС',
    'Сетевые элементы УС',
    'Схема УС',
    'Каналы связи УС',
    'Линии связи УС',
];

function PassportActions({ sections }) {
    const [placeholder, setPlaceholder] = useState('');
    const headingId = useId();
    const arrow = <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" aria-hidden="true"><path d="m9 5 7 7-7 7" /></svg>;
    return <div className="passport__open">
        <h3 id={headingId} className="passport__actions-title">Действия</h3>
        <nav className="passport__menu" aria-labelledby={headingId}>
            {sections.map(({ label, to }) => to
                ? <Link key={label} to={to}><span>{label}</span>{arrow}</Link>
                : <button type="button" key={label} onClick={() => setPlaceholder(label)}><span>{label}</span>{arrow}</button>)}
        </nav>
        <p className="passport__placeholder" role="status">{placeholder ? `${placeholder} — раздел пока не настроен.` : ''}</p>
    </div>;
}

function NodeSummary({ data }) {
    const [identity, setIdentity] = useState(null);

    useEffect(() => {
        const controller = new AbortController();
        fetchJson(`/api/nodes/${encodeURIComponent(data.id)}/properties`, { signal: controller.signal })
            .then(({ properties }) => {
                if (!Array.isArray(properties)) return;
                const callsign = properties.find(({ name }) => /^\s*позывной/i.test(name))?.value;
                const nodeClass = properties.find(({ name }) => /^\s*класс(?:\s|$|\()/i.test(name))?.value;
                if (!controller.signal.aborted) setIdentity({ callsign, nodeClass });
            }).catch(() => {
                // The graph label remains usable when optional identity properties are unavailable.
            });
        return () => controller.abort();
    }, [data.id]);

    const callsign = data.callsign || identity?.callsign || data.label;
    const rawClass = String(data.nodeClass || identity?.nodeClass || '').trim().toUpperCase();
    const nodeClass = /^[ABC]$/.test(rawClass) ? rawClass : '—';

    return <>
        <div className="passport__node-summary">
            <div className="passport__summary-row"><span>Позывной</span><strong>{callsign}</strong></div>
            <div className="passport__summary-row"><span>Класс</span><strong className="passport__class" aria-label={`Класс узла связи: ${nodeClass}`}>{nodeClass}</strong></div>
        </div>
        <PassportActions sections={nodeSections.map((label) => ({ label,
            to: label === 'Схема УС' ? `/objects/${data.id}` : undefined,
        }))} />
    </>;
}

export default function Passport({ type, data, position, elementRef, onClose, onPin, passportId, stackOrder = 0,
    detachedPosition, onMove, onReattach, minimized, onMinimize }) {
    const localRef = useRef(null);
    const dragRef = useRef(null);
    const titleId = useId();
    const isLine = type === 'edge' || data?.isLine || /линия связи/i.test(data?.templateName || data?.type || '');

    useLayoutEffect(() => {
        const element = localRef.current;
        if (!element || !position || minimized) return;
        const toolbar = element.parentElement?.querySelector('.passport-tabs') ?? element.parentElement?.querySelector('.toolbar');
        const keepVisible = () => {
            const toolbarBottom = toolbar?.getBoundingClientRect().bottom ?? 0;
            const top = Math.max(12, Math.min(toolbarBottom + 12, window.innerHeight - 120));
            element.style.setProperty('--passport-available-height', `${Math.max(100, window.innerHeight - top - 12)}px`);
            if (elementRef) return;
            const { width, height } = element.getBoundingClientRect();
            element.style.left = `${Math.max(12, Math.min(position.x, window.innerWidth - width - 12))}px`;
            element.style.top = `${Math.max(top, Math.min(position.y, window.innerHeight - height - 12))}px`;
        };
        keepVisible();
        const observer = new ResizeObserver(keepVisible);
        observer.observe(element);
        if (toolbar) observer.observe(toolbar);
        window.addEventListener('resize', keepVisible);
        return () => { observer.disconnect(); window.removeEventListener('resize', keepVisible); };
    }, [elementRef, position, minimized]);

    if (!data || !position) return null;
    const objectId = type === 'edge' ? data.lineId : data.id;
    const endpointLabel = type === 'edge' ? `${data.sourceLabel || data.source} ↔ ${data.targetLabel || data.target}` : data.endpointLabel;

    const constrain = (point) => {
        const bounds = localRef.current.getBoundingClientRect();
        const parent = localRef.current.parentElement;
        const toolbarBottom = (parent?.querySelector('.passport-tabs') ?? parent?.querySelector('.toolbar'))?.getBoundingClientRect().bottom ?? 0;
        return clampPassportPosition({ ...point, width: bounds.width, height: bounds.height }, {
            left: 12, top: Math.max(12, Math.min(toolbarBottom + 12, window.innerHeight - 120)),
            right: window.innerWidth - 12, bottom: window.innerHeight - 12,
        });
    };
    const finishDrag = (event, cancel = false) => {
        const drag = dragRef.current;
        if (!drag || ('pointerId' in event && event.pointerId !== drag.pointerId)) return;
        dragRef.current = null;
        delete localRef.current.dataset.dragging;
        if (event.currentTarget.hasPointerCapture(drag.pointerId)) event.currentTarget.releasePointerCapture(drag.pointerId);
        if (!drag.moved) return;
        if (cancel) {
            if (drag.originalPosition) onMove(drag.originalPosition);
            else onReattach();
        } else onMove(drag.lastPosition);
    };

    return (
        <section ref={(element) => { localRef.current = element; if (elementRef) elementRef.current = element; }}
            className={`passport${isLine ? ' passport--line' : ' passport--node'}${detachedPosition ? ' passport--detached' : ''}`}
            data-passport-key={passportId}
            hidden={minimized}
            style={{ left: detachedPosition?.x ?? position.x, top: detachedPosition?.y ?? position.y, zIndex: 1000 + stackOrder }} aria-labelledby={titleId}
            onPointerDownCapture={onPin} onFocusCapture={onPin}>
            <button type="button" className="passport__icon-button passport__close" aria-label="Закрыть паспорт" title="Закрыть паспорт · Esc" onClick={onClose}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><path d="m6 6 12 12M18 6 6 18" /></svg>
            </button>
            <button type="button" className="passport__icon-button passport__minimize" aria-label="Свернуть паспорт" title="Свернуть паспорт" onClick={onMinimize}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><path d="M6 12h12" /></svg>
            </button>
            {detachedPosition && <button type="button" className="passport__icon-button passport__reattach"
                aria-label={`Привязать паспорт к ${data.label || 'объекту'}`} title={`Вернуть паспорт к ${data.label || 'объекту'}`}
                onClick={() => {
                    onReattach();
                    requestAnimationFrame(() => localRef.current?.querySelector('.passport__identity')?.focus({ preventScroll: true }));
                }}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" aria-hidden="true"><path d="m9 15 6-6m-5-3 2-2a5 5 0 0 1 7 7l-2 2M7 11l-2 2a5 5 0 0 0 7 7l2-2" /></svg>
            </button>}
            <header className="passport__identity" tabIndex={0}
                aria-label={`Переместить паспорт ${data.label || ''}. Используйте мышь или клавиши со стрелками.`}
                title={detachedPosition ? 'Паспорт откреплён. Перетащите за заголовок; кнопка связи вернёт его к объекту.' : 'Перетащите за заголовок, чтобы открепить паспорт от объекта'}
                onPointerDown={(event) => {
                    if (event.button !== 0) return;
                    event.preventDefault();
                    event.stopPropagation();
                    const bounds = localRef.current.getBoundingClientRect();
                    dragRef.current = { pointerId: event.pointerId, startX: event.clientX, startY: event.clientY,
                        x: bounds.x, y: bounds.y, moved: false, originalPosition: detachedPosition };
                    localRef.current.dataset.dragging = 'true';
                    event.currentTarget.focus({ preventScroll: true });
                    event.currentTarget.setPointerCapture(event.pointerId);
                }}
                onPointerMove={(event) => {
                    const drag = dragRef.current;
                    if (!drag || event.pointerId !== drag.pointerId) return;
                    const dx = event.clientX - drag.startX, dy = event.clientY - drag.startY;
                    if (!drag.moved && dx * dx + dy * dy < 16) return;
                    const point = constrain({ x: drag.x + dx, y: drag.y + dy });
                    localRef.current.style.left = `${point.x}px`;
                    localRef.current.style.top = `${point.y}px`;
                    drag.lastPosition = point;
                    if (!drag.moved) { drag.moved = true; onMove(point); }
                }}
                onPointerUp={finishDrag}
                onPointerCancel={finishDrag}
                onLostPointerCapture={finishDrag}
                onKeyDown={(event) => {
                    if (event.key === 'Escape' && dragRef.current) {
                        event.stopPropagation();
                        event.preventDefault();
                        finishDrag(event, true);
                        return;
                    }
                    const moves = { ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1] };
                    const move = moves[event.key];
                    if (!move) return;
                    event.preventDefault();
                    event.stopPropagation();
                    const bounds = localRef.current.getBoundingClientRect();
                    const step = event.shiftKey ? 40 : 10;
                    onMove(constrain({ x: bounds.x + move[0] * step, y: bounds.y + move[1] * step }));
                }}>
                <h2 id={titleId}>Паспорт {data.label || (isLine ? 'ЛС' : 'УС')}</h2>
                {isLine && <p>Линия связи</p>}
            </header>
            {isLine ? <>
                <div className="passport__line-body">
                    {endpointLabel && <div className="passport__route"><span>Соединяет</span><strong>{endpointLabel}</strong></div>}
                    {data.relationLabel && <p className="passport__muted">{data.relationLabel}</p>}
                    <div className="passport__line-id"><span>ID линии</span><p className="passport__value--id">{objectId || data.id}</p></div>
                </div>
                <PassportActions sections={[{ label: 'Все характеристики ЛС' }, { label: 'КС через ЛС' }]} />
            </> : <NodeSummary key={data.id} data={data} />}
        </section>
    );
}
