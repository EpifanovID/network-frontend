import { useEffect, useRef, useState } from 'react';

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
    },
    glyphs: `${mapAssetsUrl}/fonts/{fontstack}/{range}.pbf`,
    sprite: `${mapAssetsUrl}/sprites/light`,
    layers: [
        ...layers('protomaps', LIGHT, { lang: 'ru' })
            .filter((layer) => layer.id === 'background'),
        ...overviewLayers,
        ...detailLayers,
    ],
};

function PhysicalMap({ onMapReady }) {
    const containerRef = useRef(null);
    const mapRef = useRef(null);
    const [mapError, setMapError] = useState(null);

    useEffect(() => {
        if (!containerRef.current) return;

        let isCancelled = false;
        let protocolRegistered = false;
        let resizeObserver;
        let map;
        setMapError(null);

        const initializeMap = async () => {
            let missingArchiveName = 'network-areas.pmtiles';
            try {
                for (const archiveUrl of [offlineArchiveUrl, offlineOverviewUrl]) {
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

    return (
        <div className="physical-map-wrapper">
            <div ref={containerRef} className="physical-map" />
            {mapError && (
                <div className="physical-map__offline-error" role="alert">
                    {mapError}
                </div>
            )}
        </div>
    );
}

export default PhysicalMap;