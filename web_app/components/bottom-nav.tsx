"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const items = [
  { href: "/", label: "Home" },
  { href: "/pets", label: "Pets" },
  { href: "/try-on", label: "Try-On" },
  { href: "/profile", label: "Profile" }
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
            {item.label}
          </Link>
        );
      })}
    </nav>
  );
}
