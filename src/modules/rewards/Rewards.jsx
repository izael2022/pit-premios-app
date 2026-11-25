import React from "react";
import "./rewards.css";
const sections=[
 {icon:"🎡",title:"Roleta de pontos",tag:"Em desenvolvimento",desc:"A roleta será ativada quando as regras e o resgate seguro forem conectados ao servidor.",tone:"wheel"},
 {icon:"🎁",title:"Baús de recompensa",tag:"Em desenvolvimento",desc:"Área preparada para os baús com limite, horário e prêmio validados pelo servidor.",tone:"chest"},
 {icon:"🎟️",title:"Raspadinha",tag:"Em desenvolvimento",desc:"Sistema planejado com resultado controlado e registrado no backend.",tone:"scratch"},
 {icon:"📅",title:"Calendário de recompensas",tag:"Em desenvolvimento",desc:"Confira futuramente as campanhas e recompensas especiais por período.",tone:"calendar"}
];
export default function Rewards(){return <section className="rewards-page"><header className="rewards-intro"><span className="rewards-overline">PIT PRÊMIOS · EXPERIÊNCIAS</span><h2>Central de recompensas</h2><p>Uma área única para acessar futuras experiências e campanhas de pontos.</p></header><div className="rewards-grid">{sections.map((s,i)=><article className="reward-feature" key={s.title}><div className={"reward-art "+s.tone}><span>{s.icon}</span><small>0{i+1}</small></div><div className="reward-feature-body"><span className="reward-status">{s.tag}</span><h3>{s.title}</h3><p>{s.desc}</p></div></article>)}</div><aside className="rewards-safety"><strong>Integridade das recompensas</strong><p>Os prêmios e créditos serão validados pelo servidor. Esta interface não gera nem altera pontos por conta própria.</p></aside></section>}