import { useEffect, useRef, useState } from 'react';
import { prepareBasemapLayers, applyBoundaryVisibility, loadBoundaryData } from '../utils/mapLayers';
import { withBoundaryOutlines } from '../utils/boundaryOutlines';

import {
    addProtocol,
    AttributionControl,
    Map,
    NavigationControl,
    removeProtocol,
    setWorkerUrl,
} from 'maplibre-gl';
import { LIGHT, layers } from '@protomaps/basemaps';
import { Protocol } from 'pmtiles';
import workerUrl from 'maplibre-gl/dist/maplibre-gl-worker.mjs?worker&url';
import 'maplibre-gl/dist/maplibre-gl.css';

setWorkerUrl(workerUrl);

const mapAssetsUrl = new URL(
    `${import.meta.env.BASE_URL}maps/`,
    window.location.href
).toString().replace(/\/$/, '');
const offlineArchiveUrl = `${mapAssetsUrl}/network-areas.pmtiles`;
const offlineOverviewUrl = `${mapAssetsUrl}/network-overview.pmtiles`;
const militaryDistrictsUrl = `${mapAssetsUrl}/military-districts.geojson`;
const russiaRegionsUrl = `${mapAssetsUrl}/russia-regions.geojson`;
const detailZoom = 9;
const detailLayers = layers('protomaps', LIGHT, { lang: 'ru' })
    .filter((layer) => (
        layer.id !== 'background'
        && (layer.maxzoom ?? 24) > detailZoom
    ))
    .map((layer) => ({
        ...layer,
        id: `detail-${layer.id}`,
        minzoom: Math.max(layer.minzoom ?? 0, detailZoom),
    }));
const overviewLayers = layers('overview', LIGHT, { lang: 'ru' })
    .filter((layer) => (
        layer.id !== 'background'
        && (layer.minzoom ?? 0) < detailZoom
    ))
    .map((layer) => ({
        ...layer,
        id: `overview-${layer.id}`,
        maxzoom: Math.min(layer.maxzoom ?? 24, detailZoom),
    }));
const boundaryLayers = {
    base: { source: 'russiaOutline', url: `${mapAssetsUrl}/russia-outline.geojson`, name: 'Граница Российской Федерации' },
    districts: { source: 'militaryDistricts', url: militaryDistrictsUrl, name: 'Военные округа' },
    regions: { source: 'russiaRegions', url: russiaRegionsUrl, name: 'Регионы России' },
};
const emptyCollection = { type: 'FeatureCollection', features: [] };
const offlineStyle = {
    version: 8,
    sources: {
        overview: {
            type: 'vector',
            url: `pmtiles://${offlineOverviewUrl}`,
            attribution: '© OpenStreetMap contributors · Protomaps',
        },
        protomaps: {
            type: 'vector',
            url: `pmtiles://${offlineArchiveUrl}`,
            attribution: '© OpenStreetMap contributors · Protomaps',
        },
        militaryDistricts: {
            type: 'geojson',
            data: emptyCollection,
            attribution: 'Границы военных округов по субъектам: Указ Президента РФ № 141 от 26.02.2024',
        },
        russiaRegions: {
            type: 'geojson',
            data: emptyCollection,
            attribution: 'Регионы: geoBoundaries ADM1, OpenStreetMap, ODbL; спорные территории — по составу слоя округов, не линии контроля',
        },
        russiaOutline: {
            type: 'geojson',
            data: emptyCollection,
            attribution: 'Граница РФ: geoBoundaries, ODbL; состав как в слое округов, включая спорные территории; не линии контроля',
        },
    },
    glyphs: `${mapAssetsUrl}/fonts/{fontstack}/{range}.pbf`,
    sprite: `${mapAssetsUrl}/sprites/light`,
    layers: [
        ...layers('protomaps', LIGHT, { lang: 'ru' })
            .filter((layer) => layer.id === 'background'),
        ...prepareBasemapLayers(overviewLayers),
        ...prepareBasemapLayers(detailLayers),
        {
            id: 'russia-outline',
            type: 'line',
            source: 'russiaOutline',
            filter: ['==', ['get', 'kind'], 'outline'],
            layout: { visibility: 'none' },
            paint: {
                'line-color': '#805333',
                'line-width': ['interpolate', ['linear'], ['zoom'], 2, 1, 7, 1.8, 12, 2.5],
                'line-opacity': 0.9,
            },
        },
        {
            id: 'military-districts-fill',
            type: 'fill',
            source: 'militaryDistricts',
            filter: ['==', ['get', 'kind'], 'district'],
            minzoom: 2,
            layout: { visibility: 'none' },
            paint: {
                'fill-color': [
                    'match',
                    ['get', 'district'],
                    'Ленинградский военный округ', '#a67c52',
                    'Московский военный округ', '#94633f',
                    'Южный военный округ', '#bd946c',
                    'Центральный военный округ', '#ad8968',
                    'Восточный военный округ', '#8c6b50',
                    '#a67c52',
                ],
                'fill-opacity': 0.07,
                'fill-antialias': false,
            },
        },
        {
            id: 'military-districts-outline',
            type: 'line',
            source: 'militaryDistricts',
            filter: ['==', ['get', 'kind'], 'outline'],
            minzoom: 2,
            layout: { visibility: 'none' },
            paint: {
                'line-color': '#805333',
                'line-width': ['interpolate', ['linear'], ['zoom'], 2, 1.2, 7, 2.4],
                'line-dasharray': [2, 1],
                'line-opacity': 0.9,
            },
        },
        {
            id: 'military-districts-labels',
            type: 'symbol',
            source: 'militaryDistricts',
            filter: ['==', ['get', 'kind'], 'label'],
            minzoom: 3,
            layout: {
                visibility: 'none',
                'text-field': ['get', 'district'],
                'text-font': ['Noto Sans Regular'],
                'text-size': ['interpolate', ['linear'], ['zoom'], 3, 10, 7, 13],
                'text-max-width': 10,
                'text-allow-overlap': false,
                'text-ignore-placement': false,
            },
            paint: {
                'text-color': '#5c3b24',
                'text-halo-color': '#ffffff',
                'text-halo-width': 1.5,
            },
        },
        {
            id: 'russia-regions-fill',
            type: 'fill',
            source: 'russiaRegions',
            filter: ['==', ['geometry-type'], 'Polygon'],
            minzoom: 2,
            layout: { visibility: 'none' },
            paint: {
                'fill-color': '#a67c52',
                'fill-opacity': 0.035,
                'fill-antialias': false,
            },
        },
        {
            id: 'russia-regions-outline',
            type: 'line',
            source: 'russiaRegions',
            filter: ['==', ['get', 'kind'], 'outline'],
            minzoom: 2,
            layout: { visibility: 'none' },
            paint: {
                'line-color': '#805333',
                'line-width': ['interpolate', ['linear'], ['zoom'], 2, 0.6, 7, 1.5, 12, 2],
                'line-opacity': 0.8,
            },
        },
        {
            id: 'russia-regions-labels',
            type: 'symbol',
            source: 'russiaRegions',
            filter: ['==', ['geometry-type'], 'Polygon'],
            minzoom: 3,
            layout: {
                visibility: 'none',
                'text-field': ['get', 'name'],
                'text-font': ['Noto Sans Regular'],
                'text-size': ['interpolate', ['linear'], ['zoom'], 3, 9, 7, 12],
                'text-max-width': 9,
                'text-allow-overlap': false,
                'text-ignore-placement': false,
            },
            paint: {
                'text-color': '#5c3b24',
                'text-halo-color': '#ffffff',
                'text-halo-width': 1.5,
            },
        },
    ],
};

function PhysicalMap({ onMapReady, mapLayer }) {
    const containerRef = useRef(null);
    const mapRef = useRef(null);
    const [mapStyleLoaded, setMapStyleLoaded] = useState(false);
    const [mapError, setMapError] = useState(null);
    const [layerError, setLayerError] = useState(null);

    useEffect(() => {
        if (!containerRef.current) return;

        let isCancelled = false;
        let protocolRegistered = false;
        let resizeObserver;
        let map;
        setMapError(null);
        setMapStyleLoaded(false);

        const initializeMap = async () => {
            let missingArchiveName = 'network-areas.pmtiles';
            try {
                for (const archiveUrl of [
                    offlineArchiveUrl,
                    offlineOverviewUrl,
                    militaryDistrictsUrl,
                    russiaRegionsUrl,
                ]) {
                    missingArchiveName = new URL(archiveUrl).pathname.split('/').pop();
                    const response = await fetch(archiveUrl, { method: 'HEAD' });
                    const contentType = response.headers.get('content-type') || '';
                    if (!response.ok || contentType.includes('text/html')) {
                        throw new Error(
                            `Offline map archive is unavailable (HTTP ${response.status}): ${archiveUrl}`
                        );
                    }
                }
            } catch (error) {
                if (!isCancelled) {
                    console.error('Не удалось загрузить локальный архив карты.', error);
                    setMapError(missingArchiveName === 'network-overview.pmtiles'
                        ? 'Не найден архив network-overview.pmtiles — обзорная карта регионов. '
                            + 'Создайте его командой из корня проекта:\n'
                            + 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File '
                            + '".\\scripts\\build-offline-map.ps1" '
                            + '-BuildRoot "D:\\NetworkMapBuild" -OverviewOnly'
                        : `Не найден архив ${missingArchiveName}. `
                            + 'См. команды сборки офлайн-карты в README.md.');
                }
                return;
            }
            if (isCancelled) return;

            try {
                const protocol = new Protocol();
                addProtocol('pmtiles', protocol.tile);
                protocolRegistered = true;
                map = new Map({
                    container: containerRef.current,
                    style: offlineStyle,
                    center: [100, 60],
                    zoom: 3,
                    interactive: true,
                    maxZoom: 18,
                    attributionControl: false,
                });
                map.once('style.load', () => setMapStyleLoaded(true));
                if (map.isStyleLoaded()) setMapStyleLoaded(true);

                map.addControl(new NavigationControl(), 'top-right');
                map.addControl(new AttributionControl({
                    compact: true,
                    customAttribution: '© OpenStreetMap contributors · Protomaps',
                }), 'bottom-right');
                mapRef.current = map;
                onMapReady?.(map);
                resizeObserver = new ResizeObserver(() => map.resize());
                resizeObserver.observe(containerRef.current);
                map.on('error', (event) => {
                    console.error('Ошибка загрузки офлайн-слоёв карты.', event.error);
                });
            } catch (error) {
                map?.remove();
                if (protocolRegistered) removeProtocol('pmtiles');
                protocolRegistered = false;
                console.error('Не удалось запустить локальную карту.', error);
                setMapError('Не удалось запустить локальную карту. См. консоль браузера.');
            }
        };

        initializeMap();

        return () => {
            isCancelled = true;
            resizeObserver?.disconnect();
            map?.remove();
            if (protocolRegistered) removeProtocol('pmtiles');
            mapRef.current = null;
            onMapReady?.(null);
        };
    }, [onMapReady]);

    useEffect(() => {
        const map = mapRef.current;
        if (!map || !mapStyleLoaded) return;

        const controller = new AbortController();
        applyBoundaryVisibility(map, 'loading');
        const selected = boundaryLayers[mapLayer];
        if (selected) {
            loadBoundaryData(selected.url, controller.signal)
                .then((data) => {
                    if (controller.signal.aborted) return;
                    map.getSource(selected.source).setData(withBoundaryOutlines(data));
                    setLayerError(null);
                    applyBoundaryVisibility(map, mapLayer);
                })
                .catch((error) => {
                    if (controller.signal.aborted) return;
                    console.error('Не удалось загрузить выбранный слой.', error);
                    setLayerError({ mode: mapLayer, message: `Слой «${selected.name}» недоступен. Можно выбрать другой слой или повторить выбор.` });
                });
        }
        return () => controller.abort();
    }, [mapLayer, mapStyleLoaded]);

    return (
        <div className="physical-map-wrapper">
            <div ref={containerRef} className="physical-map" />
            {(mapError || (layerError?.mode === mapLayer && layerError)) && (
                <div className="physical-map__offline-error" role="alert">
                    {mapError || layerError?.message}
                </div>
            )}
        </div>
    );
}

export default PhysicalMap;
