import { Link } from 'react-router-dom';
import { useState } from 'react';

function Passport({
    type,
    data,
    position,
    elementRef,
    onCoordinatesChange,
    onFocusLocation,
}) {
    const [longitude, setLongitude] = useState(data?.lng ?? '');
    const [latitude, setLatitude] = useState(data?.lat ?? '');
    const [coordinateError, setCoordinateError] = useState('');
    const [savingCoordinates, setSavingCoordinates] = useState(false);

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
            setLongitude(lng);
            setLatitude(lat);
        } catch (error) {
            setCoordinateError(error.message || 'Не удалось сохранить координаты.');
        } finally {
            setSavingCoordinates(false);
        }
    };

    return (
        <div
            ref={elementRef}
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
                    </div>

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

                        <span className="passport__value">
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

                    {data.treeNumber && (
                        <Link
                            to={`/objects/${data.id}`}
                            className="passport__link"
                        >
                            Открыть структуру объекта →
                        </Link>
                    )}
                </>
            )}

            {type === 'edge' && (
                <>
                    <div className="passport__title">
                        Паспорт соединения
                    </div>

                    <div className="passport__row">
                        <span className="passport__label">
                            ID:
                        </span>

                        <span className="passport__value">
                            {data.id}
                        </span>
                    </div>

                    <div className="passport__row">
                        <span className="passport__label">
                            Источник:
                        </span>

                        <span className="passport__value">
                            {data.source}
                        </span>
                    </div>

                    <div className="passport__row">
                        <span className="passport__label">
                            Приёмник:
                        </span>

                        <span className="passport__value">
                            {data.target}
                        </span>
                    </div>
                    {data.label && (
                        <div className="passport__row">
                            <span className="passport__label">Связь:</span>
                            <span className="passport__value">{data.label}</span>
                        </div>
                    )}
                </>
            )}
        </div>
    );
}

export default Passport;