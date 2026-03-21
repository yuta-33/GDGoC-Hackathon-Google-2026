"use client";

import { ChangeEvent, useEffect, useMemo, useState } from "react";

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

export function PetsForm() {
  const [pet, setPet] = useState<PetProfile>(emptyPet);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    const raw = window.localStorage.getItem("petfit.web.petProfile");
    if (!raw) return;
    try {
      setPet(JSON.parse(raw) as PetProfile);
    } catch {}
  }, []);

  const previewUrl = useMemo(() => pet.photoDataUrl, [pet.photoDataUrl]);

  function update<K extends keyof PetProfile>(key: K, value: PetProfile[K]) {
    setPet((current) => ({ ...current, [key]: value }));
    setSaved(false);
  }

  function onPhotoChange(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      update("photoDataUrl", reader.result as string);
    };
    reader.readAsDataURL(file);
  }

  function saveProfile() {
    window.localStorage.setItem("petfit.web.petProfile", JSON.stringify(pet));
    setSaved(true);
  }

  return (
    <div className="pageStack">
      <section className="profileIntro">
        <span>Step 1 of 2</span>
        <h1>Tell us about your friend</h1>
        <p>Provide accurate info for a perfect AI-powered fit.</p>
      </section>

      <section className="petPhotoCard">
        <div className="petPhotoBadge">
          {previewUrl ? (
            <img src={previewUrl} alt="Pet preview" className="petPhotoBadgeImage" />
          ) : (
            <span>🐾</span>
          )}
        </div>
        <label className="uploadLink">
          Upload Pet Photo
          <input type="file" accept="image/*" hidden onChange={onPhotoChange} />
        </label>
        <span className="supportCopy">
          Works best with one clear dog photo facing the camera.
        </span>
        {saved ? <span className="pill success">Saved locally</span> : null}
      </section>

      <section className="petFormCard">
        <div className="petField">
          <span>Pet Name</span>
          <input
            value={pet.name}
            onChange={(event) => update("name", event.target.value)}
            placeholder="Buddy"
          />
        </div>
        <div className="petField">
          <span>Breed</span>
          <input
            value={pet.breed}
            onChange={(event) => update("breed", event.target.value)}
            placeholder="Jack Russell Terrier"
          />
        </div>
        <div className="weightRow">
          <div className="petField">
            <span>Weight</span>
            <input
              type="number"
              value={pet.weight || ""}
              onChange={(event) => update("weight", Number(event.target.value || 0))}
              placeholder="7.0"
            />
          </div>
          <div className="unitToggle" aria-label="Weight unit">
            <button
              type="button"
              className={pet.weightUnit === "KG" ? "unitButton active" : "unitButton"}
              onClick={() => update("weightUnit", "KG")}
            >
              KG
            </button>
            <button
              type="button"
              className={pet.weightUnit === "LB" ? "unitButton active" : "unitButton"}
              onClick={() => update("weightUnit", "LB")}
            >
              LB
            </button>
          </div>
        </div>
      </section>

      <section className="measurementCard">
        <div className="measurementHeader">
          <div>
            <h2>Measurements</h2>
            <p>Accurate measurements help us find the best fit.</p>
          </div>
          <span className="helpBubble">?</span>
        </div>
        <div className="formGrid">
          <label>
            <span>Neck Girth (cm)</span>
            <input
              type="number"
              value={pet.neckGirth || ""}
              onChange={(event) => update("neckGirth", Number(event.target.value || 0))}
            />
          </label>
          <label>
            <span>Chest Girth (cm)</span>
            <input
              type="number"
              value={pet.chestGirth || ""}
              onChange={(event) => update("chestGirth", Number(event.target.value || 0))}
            />
          </label>
          <label>
            <span>Back Length (cm)</span>
            <input
              type="number"
              value={pet.backLength || ""}
              onChange={(event) => update("backLength", Number(event.target.value || 0))}
            />
          </label>
        </div>
      </section>

      <button className="primaryButton fullButton" type="button" onClick={saveProfile}>
        Save Profile
      </button>
    </div>
  );
}
