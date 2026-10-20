import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const outputPath = path.join(root, 'public', 'maps', 'russia-regions.geojson');
const geoBoundariesRevision = '9469f09592ced973a3448cf66b6100b741b64c0d';
const dataUrl = `https://media.githubusercontent.com/media/wmgeolab/geoBoundaries/${geoBoundariesRevision}/releaseData/gbOpen/RUS/ADM1/geoBoundaries-RUS-ADM1_simplified.geojson`;
const russianNames = {
    'Adygea': 'Республика Адыгея',
    'Altai Krai': 'Алтайский край',
    'Altai Republic': 'Республика Алтай',
    'Amur Oblast': 'Амурская область',
    'Arkhangelsk Oblast': 'Архангельская область',
    'Astrakhan Oblast': 'Астраханская область',
    'Bashkortostan': 'Республика Башкортостан',
    'Belgorod Oblast': 'Белгородская область',
    'Bryansk Oblast': 'Брянская область',
    'Buryatia': 'Республика Бурятия',
    'Chechnya': 'Чеченская Республика',
    'Chelyabinsk Oblast': 'Челябинская область',
    'Chukotka Autonomous Okrug': 'Чукотский автономный округ',
    'Chuvashia': 'Чувашская Республика',
    'Dagestan': 'Республика Дагестан',
    'Ingushetia': 'Республика Ингушетия',
    'Irkutsk Oblast': 'Иркутская область',
    'Ivanovo Oblast': 'Ивановская область',
    'Jewish Autonomous Oblast': 'Еврейская автономная область',
    'Kabardino-Balkaria': 'Кабардино-Балкарская Республика',
    'Kaliningrad': 'Калининградская область',
    'Kalmykia': 'Республика Калмыкия',
    'Kaluga Oblast': 'Калужская область',
    'Kamchatka Krai': 'Камчатский край',
    'Karachay-Cherkessia': 'Карачаево-Черкесская Республика',
    'Karelia': 'Республика Карелия',
    'Kemerovo Oblast': 'Кемеровская область',
    'Khabarovsk Krai': 'Хабаровский край',
    'Khakassia': 'Республика Хакасия',
    'Khanty-Mansiysk Autonomous Okrug – Ugra': 'Ханты-Мансийский автономный округ — Югра',
    'Kirov Oblast': 'Кировская область',
    'Komi Republic': 'Республика Коми',
    'Kostroma Oblast': 'Костромская область',
    'Krasnodar Krai': 'Краснодарский край',
    'Krasnoyarsk Krai': 'Красноярский край',
    'Kurgan Oblast': 'Курганская область',
    'Kursk Oblast': 'Курская область',
    'Leningrad oblast': 'Ленинградская область',
    'Lipetsk Oblast': 'Липецкая область',
    'Magadan Oblast': 'Магаданская область',
    'Mari El': 'Республика Марий Эл',
    'Mordovia': 'Республика Мордовия',
    'Moscow': 'Москва',
    'Moscow Oblast': 'Московская область',
    'Murmansk Oblast': 'Мурманская область',
    'Nenets Autonomous Okrug': 'Ненецкий автономный округ',
    'Nizhny Novgorod Oblast': 'Нижегородская область',
    'North Ossetia–Alania': 'Республика Северная Осетия — Алания',
    'Novgorod Oblast': 'Новгородская область',
    'Novosibirsk Oblast': 'Новосибирская область',
    'Omsk Oblast': 'Омская область',
    'Orenburg Oblast': 'Оренбургская область',
    'Oryol Oblast': 'Орловская область',
    'Penza Oblast': 'Пензенская область',
    'Perm Krai': 'Пермский край',
    'Primorsky Krai': 'Приморский край',
    'Pskov Oblast': 'Псковская область',
    'Republic of Karelia': 'Республика Карелия',
    'Republic of Mordovia': 'Республика Мордовия',
    'Rostov Oblast': 'Ростовская область',
    'Ryazan Oblast': 'Рязанская область',
    'Saint Petersburg': 'Санкт-Петербург',
    'Sakha Republic': 'Республика Саха (Якутия)',
    'Sakhalin Oblast': 'Сахалинская область',
    'Samara Oblast': 'Самарская область',
    'Saratov Oblast': 'Саратовская область',
    'Smolensk Oblast': 'Смоленская область',
    'Stavropol Krai': 'Ставропольский край',
    'Sverdlovsk Oblast': 'Свердловская область',
    'Tambov Oblast': 'Тамбовская область',
    'Tatarstan': 'Республика Татарстан',
    'Tomsk Oblast': 'Томская область',
    'Tula Oblast': 'Тульская область',
    'Tuva': 'Республика Тыва',
    'Tver Oblast': 'Тверская область',
    'Tyumen Oblast': 'Тюменская область',
    'Udmurtia': 'Удмуртская Республика',
    'Ulyanovsk Oblast': 'Ульяновская область',
    'Vladimir Oblast': 'Владимирская область',
    'Volgograd Oblast': 'Волгоградская область',
    'Vologda Oblast': 'Вологодская область',
    'Voronezh Oblast': 'Воронежская область',
    'Yamalo-Nenets Autonomous Okrug': 'Ямало-Ненецкий автономный округ',
    'Yaroslavl Oblast': 'Ярославская область',
    'Zabaykalsky Krai': 'Забайкальский край',
};

const response = await fetch(dataUrl);
if (!response.ok) {
    throw new Error(`Could not download Russian regional boundaries (HTTP ${response.status}).`);
}

const source = await response.json();
if (!Array.isArray(source.features) || source.features.length < 80) {
    throw new Error('The downloaded regional-boundary GeoJSON is incomplete.');
}

const seenNames = new Set();
const features = source.features.map((feature) => {
    const shapeName = feature.properties?.shapeName;
    if (!shapeName || !feature.geometry || seenNames.has(shapeName)) {
        throw new Error(`Missing, invalid, or duplicate regional boundary: ${shapeName}`);
    }
    seenNames.add(shapeName);
    return {
        type: 'Feature',
        properties: {
            name: russianNames[shapeName] ?? shapeName,
            sourceName: shapeName,
            shapeISO: feature.properties.shapeISO,
        },
        geometry: feature.geometry,
    };
});

await mkdir(path.dirname(outputPath), { recursive: true });
await writeFile(outputPath, `${JSON.stringify({
    type: 'FeatureCollection',
    features,
})}\n`, 'utf8');
console.log(`Wrote ${features.length} Russian regional boundaries to ${outputPath}`);
