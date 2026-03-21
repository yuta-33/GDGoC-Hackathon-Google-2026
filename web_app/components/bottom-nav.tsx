"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const items = [
  { href: "/", label: "Home", icon: "⌂" },
  { href: "/shop", label: "Shop", icon: "▣" },
  { href: "/try-on", label: "Try-On", icon: "✦" },
  { href: "/pets", label: "Pets", icon: "🐾" },
  { href: "/profile", label: "Profile", icon: "●" }
];

export function BottomNav() {
  const pathname = usePathname();

  return (
    <nav className="bottomNav">
      {items.map((item) => {
        const active = pathname === item.href;
        return (
          <Link
            key={item.href}
            href={item.href}
            className={active ? "navItem active" : "navItem"}
          >
            <span className="navIcon" aria-hidden="true">
              {item.icon}
            </span>
            <span>{item.label}</span>
          </Link>
        );
      })}
    </nav>
  );
}
