import type { ReactNode } from "react";

import { BottomNav } from "@/components/bottom-nav";

export function SiteShell({ children }: { children: ReactNode }) {
  return (
    <div className="appFrame">
      <div className="siteShell">
        <main className="siteMain">{children}</main>
        <BottomNav />
      </div>
    </div>
  );
}
