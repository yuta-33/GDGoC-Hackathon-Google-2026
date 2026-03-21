import { SiteShell } from "@/components/site-shell";

export default function ShopPage() {
  return (
    <SiteShell>
      <div className="pageStack">
        <section className="sectionBlock">
          <div className="sectionTitleRow stacked">
            <div>
              <h1>Shop</h1>
              <p>Commerce browsing is staged after the hackathon demo.</p>
            </div>
            <span className="pill">Coming Soon</span>
          </div>
          <div className="comingSoonBox">
            <h2>Try-On is live first.</h2>
            <p>
              The web build prioritizes pet onboarding and AI outfit previews.
              Catalog browsing and checkout will be connected later.
            </p>
          </div>
        </section>
      </div>
    </SiteShell>
  );
}
