import {
    BrowserRouter,
    Routes,
    Route,
} from 'react-router-dom';

import NetworkPage from './pages/NetworkPage';
import ObjectPage from './pages/ObjectPage';
import LinePage from './pages/LinePage';

function App() {
    return (
        <BrowserRouter>
            <Routes>
                <Route path="/lines/:lineId" element={<LinePage />} />
                <Route
                    path="/"
                    element={<NetworkPage />}
                />

                <Route
                    path="/objects/:objectId"
                    element={<ObjectPage />}
                />
            </Routes>
        </BrowserRouter>
    );
}

export default App;
