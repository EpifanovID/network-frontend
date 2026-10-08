import { useEffect, useRef } from 'react';

import {
    AttributionControl,
    Map,
    NavigationControl,
    setWorkerUrl,
} from 'maplibre-gl';
import workerUrl from 'maplibre-gl/dist/maplibre-gl-worker.mjs?worker&url';
import 'maplibre-gl/dist/maplibre-gl.css';

setWorkerUrl(workerUrl);

function PhysicalMap({ onMapReady }) {
    const containerRef = useRef(null);
    const mapRef = useRef(null);

    useEffect(() => {
        if (!containerRef.current) return;

        const map = new Map({
            container: containerRef.current,
            style: 'https://tiles.openfreemap.org/styles/liberty',
            center: [100, 60],
            zoom: 3,
            interactive: true,
            maxZoom: 18,
            attributionControl: false,
        });

        map.addControl(new NavigationControl(), 'top-right');
        map.addControl(new AttributionControl({
            compact: true,
            customAttribution: '© OpenStreetMap contributors © OpenMapTiles © OpenFreeMap',
        }), 'bottom-right');
        mapRef.current = map;
        onMapReady?.(map);

        // Небольшая защита: как только контейнер получил размеры,
        // попросим карту пересчитать viewport.
        const resizeObserver = new ResizeObserver(() => {
            map.resize();
        });
        resizeObserver.observe(containerRef.current);

        return () => {
            resizeObserver.disconnect();
            map.remove();
            mapRef.current = null;
            onMapReady?.(null);
        };
    }, [onMapReady]);

    return (
        <div className="physical-map-wrapper">
            <div ref={containerRef} className="physical-map" />
        </div>
    );
}

export default PhysicalMap;