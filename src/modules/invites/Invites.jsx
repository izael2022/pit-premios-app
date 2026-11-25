import React,{useEffect,useState} from "react";
import {supabase} from "../../lib/supabase.js";
import "./invites.css";
export default function Invites({user}){
 const [rows,setRows]=useState([]),[error,setError]=useState("");
 const referralUrl=window.location.origin+window.location.pathname+"?ref="+encodeURIComponent(user.id);
 useEffect(()=>{let active=true;(async()=>{const r=await supabase.from("referrals").select("id,referred_id,status,created_at,qualified_at,qualification_note").eq("referrer_id",user.id).order("created_at",{ascending:false});if(!active)return;if(r.error)setError(r.error.message);else setRows(r.data||[]);})();return()=>{active=false}},[user.id]);
 return <section className="invite-module"><h2>Convide amigos</h2><p>Compartilhe seu link. A indicação será vinculada automaticamente durante o cadastro do convidado, quando a atribuição estiver habilitada no banco.</p><div className="invite-link"><input readOnly value={referralUrl}/><button onClick={()=>navigator.clipboard.writeText(referralUrl)}>Copiar link</button></div>{error&&<p className="invite-error">{error}</p>}<h3>Minhas indicações</h3>{rows.length===0?<p>Você ainda não possui indicações registradas.</p>:rows.map(x=><article className="invite-row" key={x.id}><div><strong>Indicação #{x.id}</strong><small>{x.referred_id}</small><small>{new Date(x.created_at).toLocaleString("pt-BR")}</small></div><span className={"invite-status "+x.status}>{x.status==="pending"?"Pendente":x.status==="qualified"?"Qualificada":"Rejeitada"}</span></article>)}</section>;
}
