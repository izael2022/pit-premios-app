import React from "react";
import { createRoot } from "react-dom/client";
import "./styles/global.css";
function App(){return <main className="shell"><div className="mark">P</div><h1>PIT <span>PRÊMIOS</span></h1><p>Nova plataforma em construção.</p><small>Fundação inicial · Reconstrução do zero</small></main>}
createRoot(document.getElementById("root")).render(<React.StrictMode><App/></React.StrictMode>);
