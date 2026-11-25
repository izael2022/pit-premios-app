import React from "react";
export default function Home({user,onNavigate}) {
 const cards=[
  {id:"missions",icon:"✓",title:"Missões",desc:"Confira as missões disponíveis e conquiste pontos."},
  {id:"invites",icon:"♧",title:"Convide amigos",desc:"Compartilhe seu link e acompanhe indicações."},
  {id:"wallet",icon:"◈",title:"Carteira",desc:"Veja seu saldo e movimentações."},
  {id:"rewards",icon:"✦",title:"Recompensas",desc:"Área de recompensas — próxima etapa de desenvolvimento."},
  {id:"profile",icon:"○",title:"Perfil",desc:"Configurações e segurança da conta — próxima etapa."}
 ];
 return <section className="home-dashboard">
  <div className="home-hero"><div><span className="home-kicker">PIT PRÊMIOS</span><h2>Bem-vindo!</h2><p>Seu espaço para missões, pontos e recompensas.</p><small>{user.email}</small></div><div className="home-hero-mark">P</div></div>
  <div className="home-grid">{cards.map(c=><button type="button" key={c.id} className="home-card" onClick={()=>onNavigate(c.id)}><span className="home-card-icon">{c.icon}</span><strong>{c.title}</strong><p>{c.desc}</p><span className="home-card-link">Acessar →</span></button>)}</div>
 </section>;
}
