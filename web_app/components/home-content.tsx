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
  const hasPet = pet.name.trim().length > 0;

  return (
    <div className="pageStack">
      <section className="heroCard">
        <div className="heroBadge">Launch MVP</div>
        <h1>{hasPet ? `${pet.name} is ready for try-on` : "PetFit Web Demo"}</h1>
        <p>
          {hasPet
            ? `Open Try-On to preview ${pet.name} in the saved outfit lineup.`
            : "Set up a pet profile, upload a dog photo, and let visitors try outfits directly in the browser."}
        </p>
        <div className="heroActions">
          <Link className="primaryButton" href="/pets">
            Set Up Pet
          </Link>
          <Link className="secondaryButton" href="/try-on">
            Open Try-On
          </Link>
        </div>
      </section>

      <section className="panel">
        <div className="panelHeader">
          <div>
            <h2>Featured Outfit</h2>
            <p>Current launch lineup for demo visitors</p>
          </div>
          <a href={featured.sourceUrl} target="_blank" rel="noreferrer">
            Source
          </a>
        </div>
        <div className="featuredRow">
          <img
            src={featured.thumbnailPath}
            alt={featured.name}
            className="featuredImage"
          />
          <div className="featuredCopy">
            <div className="pill">{featured.badge}</div>
            <h3>{featured.name}</h3>
            <p>{featured.description}</p>
            <p className="muted">
              {featured.platform} • {featured.category} • {featured.material}
            </p>
          </div>
        </div>
      </section>
    </div>
  );
}
