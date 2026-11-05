import { Link } from 'react-router-dom';
import { useEffect, useId, useLayoutEffect, useRef, useState } from 'react';
import { fetchJson } from '../utils/api';

const demoNetworks = [
    { name: 'Магистральная сеть', medium: 'Волоконно-оптический кабель', capacity: '10 Гбит/с' },
    { name: 'Транспортная сеть', medium: 'Волоконно-оптический кабель', capacity: '1 Гбит/с' },
    { name: 'Сеть диспетчерской связи', medium: 'Витая пара', capacity: '100 Мбит/с' },
    { name: 'Сеть телеметрии', medium: 'Экранированная витая пара', capacity: '100 Мбит/с' },
    { name: 'Сеть видеонаблюдения', medium: 'Витая пара', capacity: '1 Гбит/с' },
    { name: 'Резервная сеть', medium: 'Волоконно-оптический кабель', capacity: '2,5 Гбит/с' },
];

function NodeProperties({ id, data, onClose }) {
    const [result, setResult] = useState(null);
    const [fullscreen, setFullscreen] = useState(false);

    useEffect(() => {
        const controller = new AbortController();
        fetchJson(`/api/nodes/${encodeURIComponent(data.id)}/properties`, {
            signal: controller.signal,
        }).then(({ properties }) => {
            if (!Array.isArray(properties)) throw new Error('Неверный формат свойств.');
            if (!controller.signal.aborted) setResult({ properties });
        }).catch(() => {
            if (!controller.signal.aborted) setResult({ error: true });
        });
        return () => controller.abort();
    }, [data.id]);

    return (
        <section
            id={id}
            className={`passport__card passport__properties${fullscreen ? ' passport__properties--fullscreen' : ''}`}
            aria-labelledby={`${id}-title`}
        >
            <div className="passport__title passport__properties-header">
                <h2 id={`${id}-title`}>Характеристики узла связи · {data.label}</h2>
                <div className="passport__properties-actions">
                    <button
                        type="button"
                        className="passport__properties-control"
                        aria-label={fullscreen ? 'Вернуть обычный размер' : 'Развернуть на весь экран'}
                        title={fullscreen ? 'Вернуть обычный размер' : 'Развернуть на весь экран'}
                        onClick={() => setFullscreen((expanded) => !expanded)}
                    >
                        <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" aria-hidden="true">
                            <path d={fullscreen ? 'M6 2v4H2m8 8v-4h4M2 10h4v4m8-8h-4V2' : 'M2 6V2h4m4 12h4v-4M6 14H2v-4m8-8h4v4'} />
                        </svg>
                    </button>
                    <button type="button" className="passport__properties-control" aria-label="Закрыть характеристики" onClick={onClose}>
                        ×
                    </button>
                </div>
            </div>
            {!result && <p role="status">Загружаю свойства…</p>}
            {result?.error && <p role="alert">Не удалось загрузить свойства. Закройте карточку и откройте её снова.</p>}
            {result?.properties?.length === 0 && <p>Для этого узла свойства не заданы.</p>}
            {result?.properties?.length > 0 && (
                <dl className="passport__properties-list">
                    {result.properties.map(({ id: propertyId, name, value }) => (
                        <div className="passport__row" key={propertyId}>
                            <dt className="passport__label">{name}</dt>
                            <dd className="passport__value">{value ?? '—'}</dd>
                        </div>
                    ))}
                </dl>
            )}
            <h3 id={`${id}-network`} className="passport__network-title">Сеть</h3>
            <p className="passport__network-caption">Демонстрационные подключения</p>
            <ul className="passport__networks" tabIndex={0} aria-labelledby={`${id}-network`}>
                {Array.from({ length: 36 }, (_, index) => {
                    const { name, medium, capacity } = demoNetworks[index % demoNetworks.length];
                    const number = String(index + 1).padStart(2, '0');
                    return (
                        <li key={number}>
                            <strong>{name} · {number}</strong>
                            <span>{medium} КБ-{number} · {capacity}</span>
                        </li>
                    );
                })}
            </ul>
        </section>
    );
}

function Passport({
    type,
    data,
    position,
    elementRef,
    onCoordinatesChange,
    onFocusLocation,
}) {
    const [longitude, setLongitude] = useState(() => String(data?.lng ?? ''));
    const [latitude, setLatitude] = useState(() => String(data?.lat ?? ''));
    const [coordinateError, setCoordinateError] = useState('');
    const [savingCoordinates, setSavingCoordinates] = useState(false);
    const [showProperties, setShowProperties] = useState(false);
    const propertiesId = useId();
    const propertiesButtonRef = useRef(null);
    const localElementRef = useRef(null);
    const isLine = data?.isLine || /линия связи/i.test(data?.templateName || data?.type || '');
    const hasProperties = type === 'node' && !isLine && /узел связи/i.test(data?.templateName || data?.type || '');

    useLayoutEffect(() => {
        if (elementRef || !position) return;
        const element = localElementRef.current;
        if (!element) return;
        const keepVisible = () => {
            const { width, height } = element.getBoundingClientRect();
            const toolbarBottom = element.parentElement?.querySelector('.toolbar')?.getBoundingClientRect().bottom ?? 0;
            element.style.left = `${Math.max(12, Math.min(position.x, window.innerWidth - width - 12))}px`;
            element.style.top = `${Math.max(toolbarBottom + 12, Math.min(position.y, window.innerHeight - height - 12))}px`;
        };
        keepVisible();
        const observer = new ResizeObserver(keepVisible);
        observer.observe(element);
        window.addEventListener('resize', keepVisible);
        return () => {
            observer.disconnect();
            window.removeEventListener('resize', keepVisible);
        };
    }, [elementRef, position]);

    if (!data || !position) {
        return null;
    }

    const handleCoordinatesSubmit = async (event) => {
        event.preventDefault();
        const lng = Number(longitude);
        const lat = Number(latitude);
        if (
            longitude.trim() === ''
            || latitude.trim() === ''
            || !Number.isFinite(lng)
            || !Number.isFinite(lat)
            || lng < -180
            || lng > 180
            || lat < -90
            || lat > 90
        ) {
            setCoordinateError('Введите долготу от −180 до 180 и широту от −90 до 90.');
            return;
        }

        setCoordinateError('');
        setSavingCoordinates(true);
        try {
            await onCoordinatesChange?.({ id: data.id, lng, lat });
            setLongitude(String(lng));
            setLatitude(String(lat));
        } catch (error) {
            setCoordinateError(error.message || 'Не удалось сохранить координаты.');
        } finally {
            setSavingCoordinates(false);
        }
    };

    return (
        <div
            ref={elementRef || localElementRef}
            className={`passport${type === 'node' ? ' passport--object' : ''}${showProperties ? ' passport--expanded' : ''}`}
            style={{
                left: `${position.x}px`,
                top: `${position.y}px`,
            }}
        >
            <div className="passport__card passport__summary">
                {type === 'node' && (
                    <>
                        <div className="passport__title">
                            Паспорт объекта
                            <span className="passport__subtitle">{data.label}</span>
                        </div>
                        {data.endpointLabel && (
                            <div className="passport__row">
                                <span className="passport__label">Соединяет:</span>
                                <span className="passport__value">{data.endpointLabel}</span>
                            </div>
                        )}

                        <div className="passport__row">
                            <span className="passport__label">
                                Наименование:
                            </span>

                            <span className="passport__value">
                                {data.label}
                            </span>
                        </div>

                        <div className="passport__row">
                            <span className="passport__label">
                                ID:
                            </span>

                            <span className="passport__value passport__value--id">
                                {data.id}
                            </span>
                        </div>

                        <div className="passport__row">
                            <span className="passport__label">
                                Тип:
                            </span>

                            <span className="passport__value">
                                {data.type || '—'}
                            </span>
                        </div>
                        <div className="passport__row">
                            <span className="passport__label">
                                Шаблон:
                            </span>
                            <span className="passport__value">
                                {data.templateName || '—'}
                            </span>
                        </div>
                        <div className="passport__row">
                            <span className="passport__label">
                                Тематический срез:
                            </span>
                            <span className="passport__value">
                                {data.layerName || '—'}
                            </span>
                        </div>

                        <form
                            className="passport__coordinates"
                            onSubmit={handleCoordinatesSubmit}
                        >
                            <span className="passport__section-title">Координаты на карте</span>
                            <label className="passport__coordinate-field">
                                <span>Долгота</span>
                                <input
                                    type="number"
                                    min="-180"
                                    max="180"
                                    step="any"
                                    value={longitude}
                                    onChange={(event) => setLongitude(event.target.value)}
                                    required
                                />
                            </label>
                            <label className="passport__coordinate-field">
                                <span>Широта</span>
                                <input
                                    type="number"
                                    min="-90"
                                    max="90"
                                    step="any"
                                    value={latitude}
                                    onChange={(event) => setLatitude(event.target.value)}
                                    required
                                />
                            </label>
                            {coordinateError && (
                                <div className="passport__coordinate-error" role="alert">
                                    {coordinateError}
                                </div>
                            )}
                            <button
                                className="passport__action"
                                type="submit"
                                disabled={savingCoordinates}
                            >
                                {savingCoordinates ? 'Сохраняю…' : 'Сохранить и показать на карте'}
                            </button>
                            {Number.isFinite(data.lng) && Number.isFinite(data.lat) && (
                                <button
                                    className="passport__action passport__action--secondary"
                                    type="button"
                                    onClick={() => onFocusLocation?.(data.lng, data.lat)}
                                >
                                    Показать текущее место
                                </button>
                            )}
                        </form>

                        <div className="passport__footer">
                            <Link to={isLine ? `/lines/${data.id}` : `/objects/${data.id}`} className="passport__link">
                                {isLine ? 'Состав линии связи →' : 'Состав узла связи →'}
                            </Link>
                            {hasProperties && (
                                <button
                                    ref={propertiesButtonRef}
                                    type="button"
                                    className="passport__action passport__action--secondary"
                                    aria-expanded={showProperties}
                                    aria-controls={showProperties ? propertiesId : undefined}
                                    onClick={() => setShowProperties((visible) => !visible)}
                                >
                                    Все свойства
                                </button>
                            )}
                        </div>
                    </>
                )}

                {type === 'edge' && (
                    <>
                        <div className="passport__title">
                            Паспорт соединения
                            <span className="passport__subtitle">
                                {data.sourceLabel || data.source} ↔ {data.targetLabel || data.target}
                            </span>
                        </div>

                        <div className="passport__row">
                            <span className="passport__label">
                                ID:
                            </span>

                            <span className="passport__value passport__value--id">
                                {data.lineId || data.id}
                            </span>
                        </div>

                        <div className="passport__row">
                            <span className="passport__label">
                                Источник:
                            </span>

                            <span className="passport__value">
                                {data.sourceLabel || data.source}
                            </span>
                        </div>

                        <div className="passport__row">
                            <span className="passport__label">
                                Приёмник:
                            </span>

                            <span className="passport__value">
                                {data.targetLabel || data.target}
                            </span>
                        </div>
                        {data.label && (
                            <div className="passport__row">
                                <span className="passport__label">Связь:</span>
                                <span className="passport__value">{data.label}</span>
                            </div>
                        )}
                        {data.relationLabel && (
                            <div className="passport__row">
                                <span className="passport__label">Отношение:</span>
                                <span className="passport__value">{data.relationLabel}</span>
                            </div>
                        )}
                        {data.lineId && <Link to={`/lines/${data.lineId}`} className="passport__link">Состав линии связи →</Link>}
                    </>
                )}
            </div>
            {hasProperties && showProperties && (
                <NodeProperties
                    id={propertiesId}
                    data={data}
                    onClose={() => {
                        setShowProperties(false);
                        propertiesButtonRef.current?.focus();
                    }}
                />
            )}
        </div>
    );
}

export default Passport;
