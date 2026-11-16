"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";

const links = [
  { href: "/", label: "Overview", icon: "▦" },
  { href: "/inventory", label: "Inventory", icon: "▤" },
  { href: "/suppliers", label: "Suppliers", icon: "♙" },
  { href: "/orders", label: "Purchase orders", icon: "▣" },
  { href: "/risk-notes", label: "Risk intelligence", icon: "◈" },
];
export default function Shell({ children }: { children: React.ReactNode }) {
  const path = usePathname();
  return <div className="min-h-screen lg:flex">
    <aside className="bg-[#101b32] text-white lg:fixed lg:inset-y-0 lg:flex lg:w-64 lg:flex-col">
      <div className="flex items-center gap-3 px-6 py-7"><div className="grid h-10 w-10 place-items-center rounded-xl bg-blue-600 text-xl font-bold">S</div><div><div className="text-lg font-bold">SupplyWatch</div><div className="text-xs text-slate-400">Supply intelligence</div></div></div>
      <div className="px-4 text-xs font-semibold uppercase tracking-widest text-slate-500">Workspace</div>
      <nav className="mt-3 flex gap-1 overflow-x-auto px-3 pb-4 lg:flex-col">{links.map(item => <Link key={item.href} href={item.href} className={`flex shrink-0 items-center gap-3 rounded-lg px-4 py-3 text-sm ${path === item.href ? "bg-blue-600 text-white" : "text-slate-300 hover:bg-slate-800"}`}><span>{item.icon}</span>{item.label}</Link>)}</nav>
      <div className="mt-auto hidden p-5 lg:block"><div className="rounded-xl border border-slate-700 p-4"><div className="text-sm font-semibold">DBMS Mini Project</div><p className="mt-2 text-xs leading-5 text-slate-400">Supplier Performance & Inventory Risk Intelligence System</p></div></div>
    </aside>
    <div className="min-w-0 flex-1 lg:ml-64"><header className="flex items-center justify-between border-b border-slate-200 bg-white px-5 py-4 md:px-8"><div><p className="text-xs text-slate-500">SupplyWatch / Workspace</p><p className="mt-1 font-semibold">Supplier & Inventory Intelligence</p></div><span className="rounded-full bg-blue-50 px-3 py-2 text-xs font-semibold text-blue-700">Development</span></header><main className="p-5 md:p-8">{children}</main></div>
  </div>;
}
