"use client";

import { useEffect, useMemo, useState } from "react";

import { outfitPresets } from "@/lib/outfits";
import type { OutfitPreset, PetProfile, TryOnPreview } from "@/lib/types";

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

function dataUrlToBase64(dataUrl?: string) {
  if (!dataUrl) return null;
  const [, payload] = dataUrl.split(",");
  return payload ?? null;
}

function dataUrlToMimeType(dataUrl?: string) {
  if (!dataUrl) return "image/png";
  const match = dataUrl.match(/^data:(.+);base64,/);
  return match?.[1] ?? "image/png";
}

async function loadOutfitReferenceData(path: string) {
  const response = await fetch(path);
  if (!response.ok) {
    throw new Error(`Outfit reference fetch failed: ${response.status}`);
  }
  const blob = await response.blob();
  const buffer = await blob.arrayBuffer();
  const bytes = new Uint8Array(buffer);
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return {
    base64: btoa(binary),
    mimeType: blob.type || "image/png"
  };
}

export function TryOnExperience() {
  const [pet, setPet] = useState<PetProfile>(emptyPet);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [currentPreview, setCurrentPreview] = useState<TryOnPreview | null>(null);
  const [isGenerating, setIsGenerating] = useState(false);
  const [message, setMessage] = useState<string>(
    "Swipe styles, then tap the button to generate."
  );
  const [cache, setCache] = useState<Record<string, TryOnPreview>>({});

  const preset = outfitPresets[selectedIndex];

  useEffect(() => {
    const raw = window.localStorage.getItem("petfit.web.petProfile");
    if (!raw) return;
    try {
      setPet(JSON.parse(raw) as PetProfile);
    } catch {}
  }, []);

  const sourceImage = useMemo(() => {
    if (currentPreview?.generatedImageBase64) {
      const mime = currentPreview.generatedImageMimeType ?? "image/png";
      return `data:${mime};base64,${currentPreview.generatedImageBase64}`;
    }
    return pet.photoDataUrl;
  }, [currentPreview, pet.photoDataUrl]);

  const cacheKey = `${pet.id}|${preset.id}|${pet.photoDataUrl?.length ?? 0}`;

  async function runTryOn(selectedPreset: OutfitPreset) {
    if (!pet.photoDataUrl) {
      setMessage("Upload a pet photo first from the Pets page.");
      return;
    }

    if (cache[cacheKey]) {
      setCurrentPreview(cache[cacheKey]);
      setMessage(`Loaded cached preview for ${selectedPreset.name}.`);
      return;
    }

    setIsGenerating(true);
    setMessage(`Generating ${selectedPreset.name} with Vertex AI...`);
    try {
      const outfitReference = await loadOutfitReferenceData(
        selectedPreset.thumbnailPath
      );
      const response = await fetch("/api/tryon", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          petId: pet.id,
          petName: pet.name,
          breed: pet.breed,
          weight: pet.weight,
          neckGirth: pet.neckGirth,
          chestGirth: pet.chestGirth,
          backLength: pet.backLength,
          imageBase64: dataUrlToBase64(pet.photoDataUrl),
          imageMimeType: dataUrlToMimeType(pet.photoDataUrl),
          outfitId: selectedPreset.id,
          outfitName: selectedPreset.name,
          category: selectedPreset.category,
          color: selectedPreset.color,
          pattern: selectedPreset.pattern,
          brand: selectedPreset.platform,
          description: selectedPreset.description,
          material: selectedPreset.material,
          sourceUrl: selectedPreset.sourceUrl,
          size: selectedPreset.sizeRange[0] ?? "M",
          outfitReferenceImageBase64: outfitReference.base64,
          outfitReferenceImageMimeType: outfitReference.mimeType
        })
      });

      if (!response.ok) {
        throw new Error(`Try-on failed with ${response.status}`);
      }

      const payload = (await response.json()) as TryOnPreview;
      setCurrentPreview(payload);
      setCache((current) => ({ ...current, [cacheKey]: payload }));
      setMessage(`Generated ${selectedPreset.name}. Next open will be faster.`);
    } catch (error) {
      console.error(error);
      setMessage("Try-on generation failed. Check backend connectivity and retry.");
    } finally {
      setIsGenerating(false);
    }
  }

  return (
    <div className="pageStack">
      <section className="tryonStage">
        <div className="tryonImageWrap">
          {sourceImage ? (
            <img src={sourceImage} alt="Try-on preview" className="tryonImage" />
          ) : (
            <div className="petPlaceholder large">Upload a pet photo first</div>
          )}
          <button className="floatingCircle left" type="button" aria-label="Back">
            ←
          </button>
          <button className="floatingCircle right" type="button" aria-label="Share">
            ↗
          </button>
          <div className="swipeBadge">SWIPE TO SELECT</div>
          <div className="previewMessage">
            <span>✦</span>
            <strong>
              {isGenerating
                ? `Generating ${preset.name} with Vertex AI...`
                : message}
            </strong>
          </div>
          <button className="favoriteFab" type="button" aria-label="Favorite">
            ♡
          </button>
          {isGenerating ? (
            <div className="tryonOverlay">
              <div className="sparkleOrb" />
              <img
                src={preset.thumbnailPath}
                alt={preset.name}
                className="overlayOutfitImage"
              />
              <strong>Fitting {preset.name}</strong>
              <span>Vertex AI is generating the preview.</span>
            </div>
          ) : null}
        </div>
      </section>

      <section className="sectionBlock">
        <div className="sectionTitleRow stacked">
          <div>
            <h1>Swipe Left Or Right</h1>
            <p>Change outfits instantly and preview them on your dog photo.</p>
          </div>
        </div>

        <div className="mobileCarousel">
          {outfitPresets.map((item, index) => {
            const active = index === selectedIndex;
            return (
              <button
                type="button"
                key={item.id}
                className={active ? "styleCard active" : "styleCard"}
                onClick={() => setSelectedIndex(index)}
              >
                <div className="styleCardHeader">
                  <span className="styleBadge">{item.badge}</span>
                  <span className="styleHanger">⟟</span>
                </div>
                <div className="styleCardBody">
                  <img src={item.thumbnailPath} alt={item.name} className="styleThumb" />
                  <div className="styleText">
                    <strong>{item.name}</strong>
                    <p>{item.description}</p>
                  </div>
                </div>
                <div className="styleMeta">
                  <span>{item.platform}</span>
                  <span>{item.category}</span>
                  <span>{item.sizeRange.length} sizes</span>
                </div>
              </button>
            );
          })}
        </div>

        <div className="dotPager">
          {outfitPresets.map((item, index) => (
            <span
              key={item.id}
              className={index === selectedIndex ? "pagerDot active" : "pagerDot"}
            />
          ))}
        </div>

        <button
          className="primaryButton fullButton"
          type="button"
          onClick={() => runTryOn(preset)}
          disabled={isGenerating}
        >
          {isGenerating ? "Generating..." : "✦ Try This Outfit"}
        </button>
      </section>
    </div>
  );
}
