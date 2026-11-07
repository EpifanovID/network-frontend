import { useEffect, useId, useRef, useState } from 'react';

function MainMenu({ isMapVisible, mapLayer, onApply, onOpenHighlight, onResetHighlight, showCalculations = false }) {
    const [showMapSettings, setShowMapSettings] = useState(false);
    const [draftMapVisible, setDraftMapVisible] = useState(isMapVisible);
    const [draftLayer, setDraftLayer] = useState(mapLayer);
    const [notice, setNotice] = useState('');
    return (
        <nav className="main-menu" aria-label="Главное меню">
            <h2>Меню</h2>
            <button type="button" className="main-menu__item" aria-expanded={showMapSettings}
                onClick={() => setShowMapSettings((value) => !value)}>
                <span>Карта</span>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" aria-hidden="true"><path d={showMapSettings ? 'm5 15 7-7 7 7' : 'm5 9 7 7 7-7'} /></svg>
            </button>
            {showMapSettings && <form className="main-menu__map" onSubmit={(event) => {
                event.preventDefault();
                onApply(draftMapVisible, draftLayer);
            }}>
                <fieldset>
                    <legend>Отображение карты</legend>
                    <label><input type="checkbox" checked={draftMapVisible} onChange={(event) => setDraftMapVisible(event.target.checked)} />Показать карту</label>
                    <label><input type="checkbox" checked={draftLayer === 'regions'} disabled={!draftMapVisible}
                        onChange={(event) => setDraftLayer(event.target.checked ? 'regions' : 'base')} />Показать регионы</label>
                    <label><input type="checkbox" checked={draftLayer === 'districts'} disabled={!draftMapVisible}
                        onChange={(event) => setDraftLayer(event.target.checked ? 'districts' : 'base')} />Показать округа</label>
                </fieldset>
                <button type="submit" className="main-menu__apply">Применить</button>
            </form>}
            <button type="button" className="main-menu__item" onClick={onOpenHighlight}>Подсветить</button>
            <button type="button" className="main-menu__item" onClick={() => { onResetHighlight(); setNotice('Подсветка сброшена.'); }}>Сбросить подсветку</button>
            {showCalculations && <button type="button" className="main-menu__item" onClick={() => setNotice('Расчёты — раздел пока не настроен.')}>Расчёты</button>}
            <p className="main-menu__notice" role="status">{notice}</p>
        </nav>
    );
}

function Toolbar({
    isMapVisible,
    onMapVisibilityChange,
    mapLayer,
    onMapLayerChange,
    onRefresh,
    isRefreshing,
    onOpenHighlight,
    onResetHighlight,
}) {
    const [menuOpen, setMenuOpen] = useState(false);
    const menuRef = useRef(null);
    const menuButtonRef = useRef(null);
    const menuId = useId();
    useEffect(() => {
        if (!menuOpen) return;
        const closeOutside = (event) => {
            if (!menuRef.current?.contains(event.target)) setMenuOpen(false);
        };
        const closeOnEscape = (event) => {
            if (event.key === 'Escape') {
                event.stopPropagation();
                setMenuOpen(false);
                menuButtonRef.current?.focus();
            }
        };
        document.addEventListener('pointerdown', closeOutside);
        document.addEventListener('keydown', closeOnEscape);
        return () => {
            document.removeEventListener('pointerdown', closeOutside);
            document.removeEventListener('keydown', closeOnEscape);
        };
    }, [menuOpen]);

    return (
        <header className="toolbar">
            <div className="toolbar__menu-container" ref={menuRef}>
            <button
                type="button"
                className="toolbar__button toolbar__menu"
                aria-label="Меню"
                title="Меню"
                ref={menuButtonRef}
                aria-expanded={menuOpen}
                aria-controls={menuOpen ? menuId : undefined}
                onClick={() => setMenuOpen((value) => !value)}
            >
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                    strokeWidth="1.8" strokeLinecap="round" aria-hidden="true">
                    <path d="M4 6h16M4 12h16M4 18h16" />
                </svg>
            </button>
            {menuOpen && <div id={menuId}><MainMenu
                isMapVisible={isMapVisible} mapLayer={mapLayer} onResetHighlight={onResetHighlight}
                onOpenHighlight={() => {
                    setMenuOpen(false);
                    menuButtonRef.current?.focus();
                    onOpenHighlight();
                }}
                onApply={(visible, layer) => {
                    onMapLayerChange(layer);
                    onMapVisibilityChange(visible);
                    setMenuOpen(false);
                    menuButtonRef.current?.focus();
                }}
            /></div>}
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
