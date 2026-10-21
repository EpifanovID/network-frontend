import { Link } from 'react-router-dom';
import { useLayoutEffect, useRef, useState } from 'react';

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
    const localElementRef = useRef(null);

    useLayoutEffect(() => {
        if (elementRef || !position) return;
        const element = localElementRef.current;
        if (!element) return;
        const keepVisible = () => {
            const { width, height } = element.getBoundingClientRect();
            element.style.left = `${Math.max(12, Math.min(position.x, window.innerWidth - width - 12))}px`;
            element.style.top = `${Math.max(12, Math.min(position.y, window.innerHeight - height - 12))}px`;
        };
        keepVisible();
        window.addEventListener('resize', keepVisible);
        return () => window.removeEventListener('resize', keepVisible);
    }, [elementRef, position, data, coordinateError]);

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
            className="passport"
            style={{
                left: `${position.x}px`,
                top: `${position.y}px`,
            }}
        >
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

                    <Link
                        to={data.isLine || /линия связи/i.test(data.templateName || data.type || '')
                            ? `/lines/${data.id}` : `/objects/${data.id}`}
                        className="passport__link"
                    >
                        {data.isLine || /линия связи/i.test(data.templateName || data.type || '')
                            ? 'Состав линии связи →' : 'Состав узла связи →'}
                    </Link>
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
    );
}

export default Passport;
