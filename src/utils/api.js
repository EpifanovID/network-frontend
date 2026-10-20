export async function readJsonResponse(response) {
    const body = await response.text();
    let result;
    try {
        result = JSON.parse(body);
    } catch {
        if (!body.trim()) {
            throw new Error(
                `API вернул пустой ответ (HTTP ${response.status}). `
                + 'Проверьте, что сервер запущен командой npm run dev:api.'
            );
        }
        throw new Error(
            `API вернул некорректный ответ (HTTP ${response.status}). `
            + 'Проверьте журнал сервера API.'
        );
    }

    if (!response.ok) {
        throw new Error(result.error || `Ошибка API: ${response.status}`);
    }

    return result;
}

export async function fetchJson(url, options) {
    let response;
    try {
        response = await fetch(url, options);
    } catch (error) {
        if (options?.signal?.aborted) throw error;
        throw new Error(
            'Не удалось подключиться к API. Запустите сервер командой npm run dev:api.',
            { cause: error }
        );
    }

    return readJsonResponse(response);
}
