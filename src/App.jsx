import {
    BrowserRouter,
    Routes,
    Route,
} from 'react-router-dom';

import NetworkPage from './pages/NetworkPage';
import ObjectPage from './pages/ObjectPage';

function App() {
    return (
        <BrowserRouter>
            <Routes>
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