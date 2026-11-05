import { useRef, useState } from 'react';

const mapLayers = [
    { id: 'base', label: 'Только карта' },
    { id: 'districts', label: 'Военные округа' },
    { id: 'regions', label: 'Регионы России' },
];

function TerritoryFilter({ label, allLabel, options, value, onChange, disabled }) {
    const [query, setQuery] = useState('');
    const popupRef = useRef(null);
    const searchRef = useRef(null);
    const search = query.trim().toLocaleLowerCase('ru');
    const findMatches = (text) => options.filter((option) => option.label.toLocaleLowerCase('ru').includes(text));
    const exactMatches = findMatches(search);
    const matches = exactMatches.length === 0 && search.length >= 3
        ? findMatches(search.slice(0, -1))
        : exactMatches;

    return (
        <div className="toolbar__filter">
            <span>{label}</span>
            <details ref={popupRef} onToggle={(event) => {
                if (event.currentTarget.open) searchRef.current?.focus();
                else setQuery('');
            }} onBlur={(event) => {
                if (event.relatedTarget && !event.currentTarget.contains(event.relatedTarget)) {
                    event.currentTarget.open = false;
                }
            }} onKeyDown={(event) => {
                if (event.key === 'Escape') {
                    event.currentTarget.open = false;
                    event.currentTarget.querySelector('summary').focus();
                }
            }}>
                <summary aria-label={label} aria-disabled={disabled} onClick={(event) => {
                    if (disabled) event.preventDefault();
                }}>
                    {options.find((option) => option.value === value)?.label ?? allLabel}
                </summary>
                <div className="toolbar__filter-popup">
                    <input ref={searchRef} type="search" value={query} aria-label={`Поиск: ${label}`}
                        placeholder="Поиск…" onChange={(event) => setQuery(event.target.value)} />
                    <div className="toolbar__filter-results">
                        {matches.map((option) => (
                            <button key={option.value} type="button" aria-pressed={option.value === value}
                                onClick={() => {
                                    onChange(option.value);
                                    popupRef.current.open = false;
                                    popupRef.current.querySelector('summary').focus();
                                }}>
                                {option.label}
                            </button>
                        ))}
                        {matches.length === 0 && <p role="status">Ничего не найдено</p>}
                    </div>
                </div>
            </details>
        </div>
    );
}

function Toolbar({
    isMapVisible,
    onMapVisibilityChange,
    mapLayer,
    onMapLayerChange,
    onRefresh,
    isRefreshing,
    boundaries,
    district,
    region,
    onDistrictChange,
    onRegionChange,
}) {
    const regions = (boundaries?.regions ?? [])
        .filter(({ properties }) => !district || properties.district === district)
        .sort((a, b) => a.properties.name.localeCompare(b.properties.name, 'ru'));

    return (
        <header className="toolbar">
            <div className="toolbar__group" role="group" aria-label="Режим отображения">
                <button type="button" className="toolbar__button" aria-pressed={isMapVisible}
                    onClick={() => onMapVisibilityChange(true)}>Карта</button>
                <button type="button" className="toolbar__button" aria-pressed={!isMapVisible}
                    onClick={() => onMapVisibilityChange(false)}>Схема</button>
            </div>
            {isMapVisible && (
                <div className="toolbar__layers">
                    <span className="toolbar__label">Слои карты</span>
                    <div className="toolbar__group" role="group" aria-label="Слои карты">
                        {mapLayers.map(({ id, label }) => (
                            <button key={id} type="button" className="toolbar__button"
                                aria-pressed={mapLayer === id} onClick={() => onMapLayerChange(id)}>
                                {label}
                            </button>
                        ))}
                    </div>
                </div>
            )}
            <div className="toolbar__filters" role="group" aria-label="Фильтры территории">
                <TerritoryFilter label="Военный округ" allLabel="Все округа" value={district}
                    onChange={onDistrictChange} disabled={!boundaries}
                    options={[
                        { value: '', label: 'Все округа' },
                        ...(boundaries?.districts ?? []).map(({ properties }) => ({
                            value: properties.district, label: properties.district,
                        })),
                    ]} />
                <TerritoryFilter label="Регион" allLabel="Все регионы" value={region}
                    onChange={onRegionChange} disabled={!boundaries}
                    options={[
                        { value: '', label: 'Все регионы' },
                        ...regions.map(({ properties }) => ({ value: properties.shapeISO, label: properties.name })),
                    ]} />
            </div>
            <button
                type="button"
                className="toolbar__button toolbar__refresh"
                onClick={onRefresh}
                disabled={isRefreshing}
                title="Обновить данные"
                aria-label="Обновить данные"
            >
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                    strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                    <path d="M20 4v5h-5M4 20v-5h5M20 9A8 8 0 0 0 6 6M4 15a8 8 0 0 0 14 3" />
                </svg>
            </button>
        </header>
    );
}

export default Toolbar;
