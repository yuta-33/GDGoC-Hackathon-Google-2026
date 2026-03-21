"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

import { outfitPresets } from "@/lib/outfits";
import type { PetProfile } from "@/lib/types";

const emptyPet: PetProfile = {
  id: "1",
  name: "",
  breed: "",
  weight: 0,
  weightUnit: "KG",
  neckGirth: 0,
  chestGirth: 0,
  backLength: 0
};

export function HomeContent() {
  const [pet, setPet] = useState<PetProfile>(emptyPet);

  useEffect(() => {
    const raw = window.localStorage.getItem("petfit.web.petProfile");
    if (!raw) return;
    try {
      setPet(JSON.parse(raw) as PetProfile);
    } catch {}
  }, []);

  const featured = outfitPresets[0];
  const trending = outfitPresets.slice(0, 2);
  const hasPet = pet.name.trim().length > 0;

  return (
    <div className="pageStack">
      <section className="topGreeting">
        <div className="avatarBubble">🐕</div>
        <div className="greetingText">
          <span>Good morning</span>
          <strong>{hasPet ? `${pet.name} & family` : "Buddy & Sarah"}</strong>
        </div>
        <div className="topActions">
          <button className="iconButton" type="button" aria-label="Notifications">
            🔔
          </button>
          <button className="iconButton" type="button" aria-label="Filters">
            ☰
          </button>
        </div>
      </section>

      <section className="searchRow">
        <div className="searchField">⌕ Search luxury pet fashion</div>
        <button className="searchFilterButton" type="button" aria-label="Filter">
          ☰
        </button>
      </section>

      <section className="matchCard">
        <div className="matchCopy">
          <div className="matchBadge">AI MATCH 98%</div>
          <h1>{featured.name}</h1>
          <p>
            {hasPet
              ? `Tailored for ${pet.name}'s frame and coat`
              : "Tailored for your saved pet profile"}
          </p>
          <Link className="darkButton" href="/try-on">
            View Fit
          </Link>
        </div>
        <img
          src={hasPet && pet.photoDataUrl ? pet.photoDataUrl : featured.thumbnailPath}
          alt={hasPet ? pet.name : featured.name}
          className="matchImage"
        />
      </section>

      <section className="sectionBlock">
        <div className="sectionTitleRow">
          <h2>Trending Brands</h2>
          <Link href="/shop">View all</Link>
        </div>
        <div className="brandRow">
          <div className="brandChip">
            <div className="brandCircle blush">🐾</div>
            <span>Pawsace</span>
          </div>
          <div className="brandChip">
            <div className="brandCircle cocoa">🎩</div>
            <span>Barkberry</span>
          </div>
          <div className="brandChip">
            <div className="brandCircle cream">👑</div>
            <span>Pupreme</span>
          </div>
          <div className="brandChip">
            <div className="brandCircle charcoal">💎</div>
            <span>Tiffany &amp; Co</span>
          </div>
        </div>
      </section>

      <section className="sectionBlock">
        <div className="sectionTitleRow">
          <h2>Trending Outfits</h2>
          <div className="togglePills">
            <span className="togglePill active">✓ Newest</span>
            <span className="togglePill">Popular</span>
          </div>
        </div>
        <div className="trendGrid">
          {trending.map((item) => (
            <Link key={item.id} href="/try-on" className="trendCard">
              <img src={item.thumbnailPath} alt={item.name} className="trendImage" />
              <div className="trendOverlay">
                <strong>{item.name}</strong>
                <span>{item.platform}</span>
              </div>
            </Link>
          ))}
        </div>
      </section>
    </div>
  );
}
