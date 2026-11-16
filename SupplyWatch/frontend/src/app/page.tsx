"use client";
import { useEffect, useState } from "react";
import Shell from "@/components/Shell";
import PageTitle from "@/components/PageTitle";
import { apiGet } from "@/lib/api";

type Dashboard = {
 metrics: { total_suppliers:number; active_suppliers:number; total_products:number; total_units:number; inventory_value:number; open_orders:number };
 risk: { risk_level:string; count:number }[];
 supplierPerformance: { supplier_name:string; on_time_percentage:number|null; late_deliveries:number; open_orders:number }[];
 recentOrders: { order_number:string; supplier_name:string; expected_date:string; order_status:string; days_past_expected:number; order_value:number }[];
};
const money = (n:number) => new Intl.NumberFormat("en-IN",{style:"currency",currency:"INR",maximumFractionDigits:0}).format(n || 0);
export default function Dashboard() {
 const [data,setData] = useState<Dashboard|null>(null); const [error,setError] = useState("");
 useEffect(()=>{ apiGet<Dashboard>("/dashboard").then(setData).catch(e=>setError(e.message)); },[]);
 const m=data?.metrics;
 const cards=[["Suppliers",m?.total_suppliers ?? "—",`${m?.active_suppliers ?? "—"} active`,"♙"],["Products",m?.total_products ?? "—","Active product records","▣"],["Inventory units",m?.total_units ?? "—","Units currently in stock","▤"],["Inventory value",m?money(m.inventory_value):"—","Based on product unit prices","₹"]];
 return <Shell><PageTitle title="Dashboard overview" subtitle="Monitor supplier reliability, stock health and purchasing activity."/>
 {error && <div className="mb-5 rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-800">Backend connection unavailable. Start the API and configure MySQL to load live project data. <span className="block text-xs mt-1">{error}</span></div>}
 <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">{cards.map(([label,value,sub,icon])=><div key={label} className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"><div className="flex justify-between text-sm text-slate-500"><span>{label}</span><span className="text-xl">{icon}</span></div><div className="mt-4 text-3xl font-bold">{value}</div><div className="mt-2 text-xs text-slate-500">{sub}</div></div>)}</div>
 <div className="mt-6 grid gap-6 xl:grid-cols-2">
 <section className="rounded-xl border border-slate-200 bg-white p-5"><h2 className="font-bold">Inventory risk overview</h2><p className="mb-5 mt-1 text-sm text-slate-500">Live classifications from v_inventory_risk</p><div className="space-y-4">{(data?.risk||[]).map(r=><div key={r.risk_level} className="flex items-center justify-between rounded-lg bg-slate-50 p-4"><span className="text-sm font-medium">{r.risk_level}</span><span className="text-xl font-bold">{r.count}</span></div>)}{!data?.risk.length&&<p className="text-sm text-slate-400">Waiting for database data.</p>}</div></section>
 <section className="rounded-xl border border-slate-200 bg-white p-5"><h2 className="font-bold">Supplier performance</h2><p className="mb-5 mt-1 text-sm text-slate-500">On-time delivery metrics calculated from recorded deliveries</p><div className="space-y-5">{(data?.supplierPerformance||[]).map(s=><div key={s.supplier_name}><div className="mb-2 flex justify-between gap-3 text-sm"><span className="font-medium">{s.supplier_name}</span><b>{s.on_time_percentage===null?"N/A":`${s.on_time_percentage}%`}</b></div><div className="h-2 rounded-full bg-slate-100"><div className="h-2 rounded-full bg-blue-600" style={{width:`${s.on_time_percentage||0}%`}}/></div><p className="mt-1 text-xs text-slate-400">{s.late_deliveries} late deliveries · {s.open_orders} open orders</p></div>)}{!data?.supplierPerformance.length&&<p className="text-sm text-slate-400">Waiting for database data.</p>}</div></section>
 </div>
 <section className="mt-6 rounded-xl border border-slate-200 bg-white p-5"><h2 className="font-bold">Open purchase orders</h2><p className="mb-4 mt-1 text-sm text-slate-500">Orders that are placed or partially received</p><div className="overflow-x-auto"><table className="w-full min-w-[650px] text-left text-sm"><thead className="border-b text-xs uppercase text-slate-400"><tr><th className="pb-3">Order</th><th className="pb-3">Supplier</th><th className="pb-3">Expected</th><th className="pb-3">Status</th><th className="pb-3 text-right">Value</th></tr></thead><tbody>{(data?.recentOrders||[]).map(o=><tr key={o.order_number} className="border-b border-slate-100"><td className="py-4 font-semibold">{o.order_number}</td><td>{o.supplier_name}</td><td>{new Date(o.expected_date).toLocaleDateString("en-IN")}</td><td><span className="rounded-full bg-blue-50 px-2 py-1 text-xs text-blue-700">{o.order_status}</span></td><td className="text-right">{money(o.order_value)}</td></tr>)}</tbody></table>{!data?.recentOrders.length&&<p className="py-6 text-sm text-slate-400">No open orders returned yet.</p>}</div></section>
 </Shell>;
}
