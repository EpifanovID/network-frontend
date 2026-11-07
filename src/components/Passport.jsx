import { Link } from 'react-router-dom';
import { useEffect, useId, useLayoutEffect, useRef, useState } from 'react';
import { fetchJson } from '../utils/api';
import { DEMO_LINE_ID } from '../data/lineExample';
import { clampFloatingWindowPosition, clampPassportPosition, isPassportDetail, passportDetailTitles } from '../utils/passports';

const nodeSections = [
    { type: 'characteristics', label: passportDetailTitles.characteristics },
    { type: 'network-elements', label: passportDetailTitles['network-elements'] },
    { label: 'Схема УС', opensScheme: true },
    { type: 'channels', label: passportDetailTitles.channels },
    { type: 'lines', label: passportDetailTitles.lines },
];

const networkElements = [
    ['П-317С (PDH)', 2],
    ['П-317С (SDH)', 3],
    ['П-317Д (DWDM)', 1],
    ['Маршрутизатор М1', 2],
    ['Коммутатор М3', 1],
    ['Электрическая линия связи', 2],
    ['Волоконно-оптическая линия связи', 3],
    ['Поток STM-4 (внутри УС)', 15],
    ['Поток STM-4 (снаружи УС)', 5],
];

function NodeNetworkElements() {
    return <div className="passport__characteristics">
        <table className="passport__elements">
            <thead><tr><th scope="col">Элемент</th><th scope="col">Количество, шт.</th></tr></thead>
            <tbody>{networkElements.map(([name, count]) => <tr key={name}>
                <th scope="row">{name}</th><td>{count}</td>
            </tr>)}</tbody>
        </table>
        <p>Демонстрационные данные</p>
    </div>;
}

const channelCounts = [
    ['STM-64', 2, 4, 1, 5],
    ['STM-16', 1, 0, 0, 2],
    ['STM-4', 5, 1, 4, 7],
    ['STM-1', 6, 0, 3, 2],
    ['E1', 0, 0, 0, 9],
    ['ОЦК', 0, 0, 0, 25],
];

function NodeChannels() {
    return <div className="passport__characteristics">
        <div className="passport__table-scroll" role="region" aria-label="Количество каналов по интерфейсам" tabIndex={0}>
            <table className="passport__elements passport__grouped-table">
                <colgroup span={1} />
                <colgroup span={4} />
                <thead>
                    <tr><th scope="col" rowSpan={2}>Интерфейс КС</th><th scope="colgroup" colSpan={4}>Количество, шт.</th></tr>
                    <tr>
                        <th scope="col">Внутренних</th>
                        <th scope="col">Исходящих</th>
                        <th scope="col">Входящих</th>
                        <th scope="col">Транзитных</th>
                    </tr>
                </thead>
                <tbody>{channelCounts.map(([name, internal, outgoing, transit, incoming]) => <tr key={name}>
                    <th scope="row">{name}</th>
                    <td>{internal}</td><td>{outgoing}</td><td>{incoming}</td><td>{transit}</td>
                </tr>)}</tbody>
            </table>
        </div>
        <p>Демонстрационные данные</p>
    </div>;
}

const networkLines = [
    { marker: 'ЛС-1-242', kind: 'Электр. ЛС', total: 28, connected: 5, length: '7,4' },
    { marker: 'ЛС-1-543', kind: 'Электр. ЛС', total: 54, connected: 45, length: '2,8' },
    { marker: 'ЛС-4-522', kind: 'ВОЛС', total: 80, connected: 37, length: '5,7' },
    { marker: 'ЛС-21-433', kind: 'ВОЛС', total: 40, connected: 15, length: '0,2' },
];

function NodeLines() {
    return <div className="passport__characteristics">
        <div className="passport__table-scroll" role="region" aria-label="Линии связи узла" tabIndex={0}>
            <table className="passport__elements passport__grouped-table">
                <colgroup span={2} />
                <colgroup span={3} />
                <colgroup span={1} />
                <thead>
                    <tr>
                        <th scope="col" rowSpan={2}>Маркер ЛС</th>
                        <th scope="col" rowSpan={2}>Вид ЛС</th>
                        <th scope="colgroup" colSpan={3}>Жилы или оптоволокна, шт.</th>
                        <th scope="col" rowSpan={2}>Длина, км</th>
                    </tr>
                    <tr>
                        <th scope="col">Всего</th>
                        <th scope="col">Подключено</th>
                        <th scope="col">Свободно</th>
                    </tr>
                </thead>
                <tbody>{networkLines.map(({ marker, kind, total, connected, length }) => <tr key={marker}>
                    <th scope="row">{marker}</th>
                    <td>{kind}</td><td>{total}</td><td>{connected}</td><td>{total - connected}</td><td>{length}</td>
                </tr>)}</tbody>
            </table>
        </div>
        <p>Демонстрационные данные</p>
    </div>;
}

const characteristicGroups = [
    { title: 'Текущие технические характеристики', power: '12 кВт', capacity: '10 000 Мбит/с' },
    { title: 'Плановые характеристики на 2030 год', power: '18 кВт', capacity: '25 000 Мбит/с' },
];

function NodeCharacteristics({ number, callsign }) {
    return <div className="passport__characteristics">
        <section>
            <h3>Паспортные данные</h3>
            <dl>
                <dt>Позывной</dt><dd>{callsign}</dd>
                <dt>Номер УС</dt><dd>{number}</dd>
            </dl>
        </section>
        {characteristicGroups.map(({ title, power, capacity }) => <section key={title}>
            <h3>{title}</h3>
            <dl>
                <dt>Потребляемая мощность</dt><dd>{power}</dd>
                <dt>Пропускная способность</dt><dd>{capacity}</dd>
            </dl>
        </section>)}
        <p>Демонстрационные данные</p>
    </div>;
}

function LineCharacteristics({ marker }) {
    const example = networkLines.find((line) => line.marker === marker) ?? networkLines[3];
    return <div className="passport__characteristics">
        <section>
            <h3>Паспортные данные</h3>
            <dl>
                <dt>Инвентарный номер</dt><dd>{marker}</dd>
                <dt>Год ввода в эксплуатацию</dt><dd>2025</dd>
            </dl>
        </section>
        <section>
            <h3>Технические характеристики</h3>
            <dl>
                <dt>{example.kind === 'ВОЛС' ? 'Оптоволокна, шт.' : 'Жилы, шт.'}</dt><dd>{example.total}</dd>
                <dt>Длина, км</dt><dd>{example.length}</dd>
            </dl>
        </section>
        <p>Демонстрационные данные</p>
    </div>;
}

const lineChannels = [
    { marker: 'КС-2-318', interfaceName: 'STM-16', source: 'Мальта', target: 'Дельфин' },
    { marker: 'КС-3-544', interfaceName: 'STM-4', source: 'Кордон', target: 'Купель' },
    { marker: 'КС-24-517', interfaceName: 'STM-1', source: 'Мальта', target: 'Геракл' },
];

function LineChannels({ id, marker, onOpenDetail }) {
    return <div className="passport__characteristics">
        <div className="passport__table-scroll" role="region" aria-label="Каналы связи через линию" tabIndex={0}>
            <table className="passport__elements passport__grouped-table">
                <thead><tr>
                    <th scope="col">Маркер КС</th>
                    <th scope="col">Интерфейс КС</th>
                    <th scope="col">Исходящий для КС</th>
                    <th scope="col">Входящий для КС</th>
                </tr></thead>
                <tbody>{lineChannels.map((channel) => <tr key={channel.marker}>
                    <th scope="row"><button type="button" className="passport__channel-link"
                        aria-label={`Открыть паспорт ${channel.marker}`}
                        onClick={() => onOpenDetail('channel-passport', {
                            ...channel, id: `${id}:${channel.marker}`, lineId: id, lineMarker: marker,
                        })}>{channel.marker}</button></th>
                    <td>{channel.interfaceName}</td><td>{channel.source}</td><td>{channel.target}</td>
                </tr>)}</tbody>
            </table>
        </div>
        <p>Демонстрационные данные</p>
    </div>;
}

function ChannelPassport({ source, target, lineMarker, routeHighlighted, onRouteHighlight }) {
    const lines = ['ЛС-5-829', 'ЛС-15-603', 'ЛС-92-124'];
    if (!lines.includes(lineMarker)) lines[1] = lineMarker;
    const nodes = [source, 'Зори-12', 'Горки-3', target];
    return <div className="passport__characteristics">
        <section>
            <h3>Паспортные данные</h3>
            <dl>
                <dt>УС исходящий для КС</dt><dd>{source}</dd>
                <dt>УС входящий для КС</dt><dd>{target}</dd>
                <dt>Проходит через УС и ЛС:</dt><dd></dd>
            </dl>
            <table className="passport__elements passport__grouped-table passport__route-table">
                <thead><tr>
                    <th scope="col" aria-label="Узел начала участка">УС</th>
                    <th scope="col" aria-label="Линия связи">ЛС</th>
                    <th scope="col" aria-label="Узел конца участка">УС</th>
                </tr></thead>
                <tbody>{lines.map((line, index) => <tr key={line}>
                    <td>{nodes[index]}</td><td>{line}</td><td>{nodes[index + 1]}</td>
                </tr>)}</tbody>
            </table>
        </section>
        <label className="passport__route-highlight">
            <input type="checkbox" checked={routeHighlighted} onChange={(event) => onRouteHighlight(event.target.checked)} />
            Подсветить
        </label>
        <p>Демонстрационные данные</p>
    </div>;
}

const passportDetailContents = {
    characteristics: NodeCharacteristics,
    'network-elements': NodeNetworkElements,
    channels: NodeChannels,
    lines: NodeLines,
    'line-characteristics': LineCharacteristics,
    'line-channels': LineChannels,
    'channel-passport': ChannelPassport,
};

function PassportActions({ sections }) {
    const [placeholder, setPlaceholder] = useState('');
    const headingId = useId();
    const arrow = <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" aria-hidden="true"><path d="m9 5 7 7-7 7" /></svg>;
    return <div className="passport__open">
        <h3 id={headingId} className="passport__actions-title">Действия</h3>
        <nav className="passport__menu" aria-labelledby={headingId}>
            {sections.map(({ label, to, onClick }) => to
                ? <Link key={label} to={to}><span>{label}</span>{arrow}</Link>
                : <button type="button" key={label} onClick={onClick ?? (() => setPlaceholder(label))}><span>{label}</span>{arrow}</button>)}
        </nav>
        <p className="passport__placeholder" role="status">{placeholder ? `${placeholder} — раздел пока не настроен.` : ''}</p>
    </div>;
}

function NodeSummary({ data, onOpenNodeDetail }) {
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
        <PassportActions sections={nodeSections.map(({ label, type, opensScheme }) => ({
            label,
            to: opensScheme ? `/objects/${data.id}` : undefined,
            onClick: type ? () => onOpenNodeDetail(type, {
                id: data.id,
                number: /^(?:УС\s*№?\s*)?(\d+)$/iu.exec(data.label ?? '')?.[1] ?? '203',
                callsign: data.callsign || identity?.callsign || 'Рубеж',
            }) : undefined,
        }))} />
    </>;
}

export default function Passport({ type, data, position, elementRef, onClose, onPin, passportId, stackOrder = 0,
    detachedPosition, onMove, onReattach, minimized, onMinimize, onOpenDetail, routeHighlighted, onRouteHighlight }) {
    const localRef = useRef(null);
    const dragRef = useRef(null);
    const titleId = useId();
    const isDetail = isPassportDetail(type);
    const DetailContent = passportDetailContents[type];
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
            const clamp = detachedPosition ? clampFloatingWindowPosition : clampPassportPosition;
            const point = clamp({ ...(detachedPosition ?? position), width, height }, {
                left: 12, top, right: window.innerWidth - 12, bottom: window.innerHeight - 12,
            });
            element.style.left = `${point.x}px`;
            element.style.top = `${point.y}px`;
        };
        keepVisible();
        const observer = new ResizeObserver(keepVisible);
        observer.observe(element);
        if (toolbar) observer.observe(toolbar);
        window.addEventListener('resize', keepVisible);
        return () => { observer.disconnect(); window.removeEventListener('resize', keepVisible); };
    }, [elementRef, position, minimized, detachedPosition]);

    if (!data || !position) return null;
    const objectId = type === 'edge' ? data.lineId : data.id;
    const endpointLabel = type === 'edge' ? `${data.sourceLabel || data.source} ↔ ${data.targetLabel || data.target}` : data.endpointLabel;

    const constrain = (point) => {
        const bounds = localRef.current.getBoundingClientRect();
        const parent = localRef.current.parentElement;
        const toolbarBottom = (parent?.querySelector('.passport-tabs') ?? parent?.querySelector('.toolbar'))?.getBoundingClientRect().bottom ?? 0;
        return clampFloatingWindowPosition({ ...point, width: bounds.width }, {
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

    const markerLabel = isDetail ? data.label : `Паспорт ${data.label || (isLine ? 'ЛС' : 'УС')}`;

    return (
        <section ref={(element) => { localRef.current = element; if (elementRef) elementRef.current = element; }}
            className={`passport${isLine ? ' passport--line' : ' passport--node'}${detachedPosition ? ' passport--detached' : ''}${isDetail ? ' passport--detail' : ''}`}
            data-passport-key={passportId}
            hidden={minimized}
            style={{ left: detachedPosition?.x ?? position.x, top: detachedPosition?.y ?? position.y, zIndex: 1000 + stackOrder }} aria-labelledby={titleId}
            onPointerDownCapture={onPin} onFocusCapture={onPin}>
            <button type="button" className="passport__offscreen-marker"
                aria-label={`Вернуть окно «${markerLabel}» на экран`} title={`Вернуть окно «${markerLabel}» на экран`}
                onClick={() => {
                    onMove(constrain({ x: (window.innerWidth - localRef.current.offsetWidth) / 2, y: 112 }));
                    requestAnimationFrame(() => localRef.current?.querySelector('.passport__identity')?.focus({ preventScroll: true }));
                }}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><path d="M4 12h15m-6-6 6 6-6 6" /></svg>
                <span>{markerLabel}</span>
            </button>
            <button type="button" className="passport__icon-button passport__close" aria-label="Закрыть паспорт" title="Закрыть паспорт · Esc" onClick={onClose}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><path d="m6 6 12 12M18 6 6 18" /></svg>
            </button>
            <button type="button" className="passport__icon-button passport__minimize" aria-label="Свернуть паспорт" title="Свернуть паспорт" onClick={onMinimize}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><path d="M6 12h12" /></svg>
            </button>
            {detachedPosition && <button type="button" className="passport__icon-button passport__reattach"
                aria-label={isDetail ? 'Привязать окно к паспорту или объекту' : `Привязать паспорт к ${data.label || 'объекту'}`}
                title={isDetail ? 'Вернуть окно к паспорту или объекту' : `Вернуть паспорт к ${data.label || 'объекту'}`}
                onClick={() => {
                    onReattach();
                    requestAnimationFrame(() => localRef.current?.querySelector('.passport__identity')?.focus({ preventScroll: true }));
                }}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" aria-hidden="true"><path d="m9 15 6-6m-5-3 2-2a5 5 0 0 1 7 7l-2 2M7 11l-2 2a5 5 0 0 0 7 7l2-2" /></svg>
            </button>}
            <header className="passport__identity" tabIndex={0}
                aria-label={`Переместить паспорт ${data.label || ''}. Используйте мышь или клавиши со стрелками.`}
                title={isDetail ? 'Перетащите окно за заголовок' : detachedPosition ? 'Паспорт откреплён. Перетащите за заголовок; кнопка связи вернёт его к объекту.' : 'Перетащите за заголовок, чтобы открепить паспорт от объекта'}
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
                    if (!drag.moved) {
                        drag.moved = true;
                        onMove(point);
                    }
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
                <h2 id={titleId}>{isDetail ? passportDetailTitles[type] : `Паспорт ${data.label || (isLine ? 'ЛС' : 'УС')}`}</h2>
                {isDetail && <p>{type === 'channel-passport' ? data.marker
                    : data.marker ? `Линия связи ${data.marker}` : `Узел связи № ${data.number}`}</p>}
                {isLine && <p>Линия связи</p>}
            </header>
            {isDetail ? <DetailContent {...data} onOpenDetail={onOpenDetail}
                routeHighlighted={routeHighlighted} onRouteHighlight={onRouteHighlight} /> : isLine ? <>
                <div className="passport__line-body">
                    {endpointLabel && <div className="passport__route"><span>Соединяет</span><strong>{endpointLabel}</strong></div>}
                    {data.relationLabel && <p className="passport__muted">{data.relationLabel}</p>}
                    <div className="passport__line-id"><span>ID линии</span><p className="passport__value--id">{objectId || data.id}</p></div>
                </div>
                <PassportActions sections={[
                    ...['line-characteristics', 'line-channels'].map((detailType) => ({
                        label: passportDetailTitles[detailType],
                        onClick: () => onOpenDetail(detailType, {
                            id: objectId || data.id,
                            marker: data.label || objectId || data.id,
                        }),
                    })),
                    ...(objectId === DEMO_LINE_ID ? [{ label: 'Состав линии связи', to: `/lines/${DEMO_LINE_ID}` }] : []),
                ]} />
            </> : <NodeSummary key={data.id} data={data} onOpenNodeDetail={onOpenDetail} />}
        </section>
    );
}
