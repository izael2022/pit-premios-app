import React,{useEffect,useState} from "react";
import {supabase} from "../../lib/supabase.js";
import "./wallet.css";
export default function Wallet({user}){
 const [points,setPoints]=useState(null),[rows,setRows]=useState([]),[busy,setBusy]=useState(true),[error,setError]=useState("");
 useEffect(()=>{let live=true;async function load(){setBusy(true);setError("");
  try{const p=await supabase.from("profiles").select("points").eq("id",user.id).maybeSingle();if(p.error)throw p.error;
   const t=await supabase.from("point_transactions").select("id,amount,transaction_type,description,created_at").eq("user_id",user.id).order("created_at",{ascending:false}).limit(30);if(t.error)throw t.error;
   if(live){setPoints(Number(p.data?.points||0));setRows(t.data||[])}
  }catch(e){if(live)setError("Carteira ainda não conectada ao banco. As migrations precisam ser aplicadas pelo administrador.");}
  finally{if(live)setBusy(false)}}load();return()=>{live=false}},[user.id]);
 const money=(n)=>"R$ "+(Number(n||0)/1000).toFixed(2).replace(".",",");
 return <div className="wallet-screen"><div className="wallet-card"><span className="wallet-label">Saldo de pontos</span><strong>{busy?"…":points===null?"—":points.toLocaleString("pt-BR")}</strong><span className="wallet-value">{points===null?"":money(points)} estimados</span><small>Conversão: 1.000 pontos = R$ 1,00</small></div>
 <div className="wallet-min"><b>Saques</b><p>Valor mínimo: 10.000 pontos (R$ 10,00). O pedido de saque será habilitado após a validação segura no servidor.</p></div>
 <section className="wallet-history"><h3>Movimentações recentes</h3>{busy?<p>Carregando…</p>:error?<p className="wallet-warning">{error}</p>:rows.length===0?<p>Nenhuma movimentação registrada.</p>:<ul>{rows.map(r=><li key={r.id}><div><b>{r.description||r.transaction_type}</b><small>{new Date(r.created_at).toLocaleString("pt-BR")}</small></div><strong className={Number(r.amount)>=0?"positive":"negative"}>{Number(r.amount)>0?"+":""}{Number(r.amount).toLocaleString("pt-BR")} pts</strong></li>)}</ul>}</section>
 </div>;
}