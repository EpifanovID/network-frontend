function Toolbar({
    isMapVisible,
    onMapToggle,
    mapLayer,
    onMapLayerChange,
}) {
    return (
        <div className="toolbar">
            <button
                className={`toolbar__button ${
                    isMapVisible
                        ? 'toolbar__button--active'
                        : ''
                }`}
                onClick={onMapToggle}
                title={isMapVisible ? 'Скрыть карту' : 'Показать карту'}
                aria-label={isMapVisible ? 'Скрыть карту' : 'Показать карту'}
                aria-pressed={isMapVisible}
            >
                <span className="toolbar__icon">
                    🗺
                </span>
            </button>
            <label className="toolbar__layer-control">
                <span className="toolbar__layer-label">Слои карты</span>
                <select
                    className="toolbar__layer-select"
                    value={mapLayer}
                    onChange={(event) => onMapLayerChange(event.target.value)}
                    disabled={!isMapVisible}
                    aria-label="Выбрать отображение карты"
                >
                    <option value="base">Только карта</option>
                    <option value="districts">Военные округа</option>
                    <option value="regions">Регионы России</option>
                </select>
            </label>
        </div>
    );
}

export default Toolbar;