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

export function TryOnExperience() {
  const [pet, setPet] = useState<PetProfile>(emptyPet);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [currentPreview, setCurrentPreview] = useState<TryOnPreview | null>(null);
  const [isGenerating, setIsGenerating] = useState(false);
  const [message, setMessage] = useState<string>(
    "Swipe outfits, then run AI try-on."
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
          outfitName: selectedPreset.name,
          category: selectedPreset.category,
          color: selectedPreset.color,
          pattern: "solid",
          brand: selectedPreset.platform,
          size: selectedPreset.sizeRange[0] ?? "M"
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
      <section className="panel">
        <div className="panelHeader">
          <div>
            <h1>Try-On</h1>
            <p>Web version of the launch try-on flow.</p>
          </div>
          <span className="pill">{selectedIndex + 1}/{outfitPresets.length}</span>
        </div>

        <div className="tryonHero">
          <div className="tryonImageWrap">
            {sourceImage ? (
              <img src={sourceImage} alt="Try-on preview" className="tryonImage" />
            ) : (
              <div className="petPlaceholder large">Upload a pet photo first</div>
            )}
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
          <div className="tryonCopy">
            <span className="pill">{preset.badge}</span>
            <h2>{preset.name}</h2>
            <p>{message}</p>
            <button
              className="primaryButton"
              type="button"
              onClick={() => runTryOn(preset)}
              disabled={isGenerating}
            >
              {isGenerating ? "Generating..." : "Try This Outfit"}
            </button>
          </div>
        </div>
      </section>

      <section className="panel">
        <div className="panelHeader">
          <div>
            <h2>Outfit Lineup</h2>
            <p>Swipe-style selection for hackathon visitors</p>
          </div>
        </div>

        <div className="outfitScroller">
          {outfitPresets.map((item, index) => {
            const active = index === selectedIndex;
            return (
              <button
                type="button"
                key={item.id}
                className={active ? "outfitCard active" : "outfitCard"}
                onClick={() => setSelectedIndex(index)}
              >
                <img src={item.thumbnailPath} alt={item.name} className="outfitThumb" />
                <div className="outfitText">
                  <span className="pill">{item.badge}</span>
                  <strong>{item.name}</strong>
                  <span>{item.platform} • {item.category}</span>
                  <span>{item.material}</span>
                </div>
              </button>
            );
          })}
        </div>
      </section>
    </div>
  );
}
