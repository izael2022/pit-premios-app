import React,{useEffect,useState} from "react";
import {createRoot} from "react-dom/client";
import {supabase} from "./lib/supabase.js";
import {modules} from "./modules/modules.js";
import "./styles/global.css";
import Wallet from "./modules/wallet/Wallet.jsx";
import Admin from "./modules/admin/Admin.jsx";
import Missions from "./modules/missions/Missions.jsx";
import Invites from "./modules/invites/Invites.jsx";
import Home from "./modules/home/Home.jsx";
import Profile from "./modules/profile/Profile.jsx";

function Auth({recovery=false}){
 const [mode,setMode]=useState(recovery?"change": "login"),[email,setEmail]=useState(""),[password,setPassword]=useState(""),[busy,setBusy]=useState(false),[msg,setMsg]=useState("");
 const submit=async(e)=>{e.preventDefault();setBusy(true);setMsg("");try{
  let result;
  if(mode==="signup"){const referralId=new URLSearchParams(window.location.search).get("ref");result=await supabase.auth.signUp({email,password,options:{data:{referrer_id:referralId||null}}});}
  else if(mode==="login")result=await supabase.auth.signInWithPassword({email,password});
  else if(mode==="reset")result=await supabase.auth.resetPasswordForEmail(email,{redirectTo:window.location.origin});
  else result=await supabase.auth.updateUser({password});
  if(result?.error)throw result.error;
  setMsg(mode==="signup"?"Cadastro enviado. Confira seu e-mail caso a confirmação esteja habilitada.":mode==="reset"?"Se o e-mail estiver cadastrado, enviaremos um link para redefinir a senha.":mode==="change"?"Senha atualizada com sucesso.":"Login realizado.");
  if(mode==="change"){setMode("login");window.history.replaceState(null,"",window.location.pathname);}
 }catch(err){setMsg(err?.message||"Não foi possível realizar a operação.");}finally{setBusy(false)}};
 const title=mode==="login"?"Entrar":mode==="signup"?"Criar conta":mode==="reset"?"Recuperar senha":"Definir nova senha";
 return <main className="auth-wrap"><section className="auth-card"><div className="brand auth-brand"><div className="mark">P</div><div>PIT <span>PRÊMIOS</span></div></div><h1>{title}</h1><p>{mode==="reset"?"Informe seu e-mail para receber o link.":mode==="change"?"Escolha uma nova senha para sua conta.":"Acesse sua conta ou cadastre-se."}</p><form onSubmit={submit}>{mode!=="change"&&<><label>E-mail</label><input type="email" value={email} onChange={e=>setEmail(e.target.value)} required autoComplete="email"/></>}{mode!=="reset"&&<><label>{mode==="change"?"Nova senha":"Senha"}</label><input type="password" value={password} onChange={e=>setPassword(e.target.value)} required minLength={6} autoComplete={mode==="login"?"current-password":"new-password"}/></>}<button className="primary" disabled={busy}>{busy?"Aguarde…":mode==="login"?"Entrar":mode==="signup"?"Cadastrar":mode==="reset"?"Enviar link":"Atualizar senha"}</button></form>{msg&&<div className="auth-message">{msg}</div>}{mode==="login"&&<button className="switch" onClick={()=>{setMode("reset");setMsg("");setPassword("")}}>Esqueci minha senha</button>}{mode==="reset"&&<button className="switch" onClick={()=>{setMode("login");setMsg("")}}>Voltar ao login</button>}{(mode==="login"||mode==="signup")&&<button className="switch" onClick={()=>{setMode(mode==="login"?"signup":"login");setMsg("")}}>{mode==="login"?"Ainda não tem conta? Cadastre-se":"Já tem conta? Entrar"}</button>}<small>Protegido pelo Supabase Auth.</small></section></main>;
}
function App(){const [session,setSession]=useState(null),[active,setActive]=useState("home"),[loading,setLoading]=useState(true),[admin,setAdmin]=useState(false),[blocked,setBlocked]=useState(false),[recovery,setRecovery]=useState(window.location.hash.includes("type=recovery"));
 useEffect(()=>{let mounted=true;let generation=0;const validate=async(s)=>{const ticket=++generation;if(!s){if(mounted){setAdmin(false);setBlocked(false);}return;}const p=await supabase.from("profiles").select("is_active").eq("id",s.user.id).maybeSingle();if(!mounted||ticket!==generation)return;if(p.error||!p.data||p.data.is_active!==true){setBlocked(true);setAdmin(false);await supabase.auth.signOut();return;}const r=await supabase.rpc("is_app_admin");if(!mounted||ticket!==generation)return;setAdmin(!r.error&&r.data===true);};const init=async()=>{const {data,error}=await supabase.auth.getSession();if(!mounted)return;if(error){setSession(null);setLoading(false);return;}setSession(data.session);await validate(data.session);if(mounted)setLoading(false);};init();const {data:{subscription}}=supabase.auth.onAuthStateChange((event,s)=>{if(event==="PASSWORD_RECOVERY"||window.location.hash.includes("type=recovery"))setRecovery(true);setSession(s);setAdmin(false);if(event!=="PASSWORD_RECOVERY")validate(s);});return()=>{mounted=false;generation++;subscription.unsubscribe();};},[]);
 if(loading)return <main className="auth-wrap"><p>Carregando…</p></main>;
 if(recovery)return <Auth recovery={true}/>;
 if(!session)return <>{blocked&&<div className="auth-message">Este perfil está desativado. Entre em contato com o suporte.</div>}<Auth/></>;
 const selected=active==="admin"?{label:"Administração"}:modules.find(m=>m.id===active)||modules[0];
 return <main className="app"><header className="header"><div className="brand"><div className="mark">P</div><div>PIT <span>PRÊMIOS</span></div></div><div className="account"><span>{session.user.email}</span><button onClick={()=>supabase.auth.signOut()}>Sair</button></div></header><div className="layout"><nav className="nav" aria-label="Navegação">{modules.map(m=><button key={m.id} className={active===m.id?"active":""} onClick={()=>setActive(m.id)}>{m.icon} &nbsp;{m.label}</button>)}{admin&&<button className={active==="admin"?"active":""} onClick={()=>setActive("admin")}>⚙ Administração</button>}</nav><section className="content"><h1>{selected.label}</h1>{active==="home"?<Home user={session.user} onNavigate={setActive}/>:active==="wallet"?<Wallet user={session.user}/>:active==="missions"?<Missions user={session.user}/>:active==="invites"?<Invites user={session.user}/>:active==="admin"?<Admin user={session.user}/>:active==="profile"?<Profile user={session.user}/>:<div className="module"><h2>{selected.label}</h2><p>{selected.description}</p><p>Este módulo será desenvolvido nas próximas etapas.</p></div>}</section></div><footer className="foot">Reconstrução modular · Autenticação · Supabase</footer></main>;
}
createRoot(document.getElementById("root")).render(<React.StrictMode><App/></React.StrictMode>);
