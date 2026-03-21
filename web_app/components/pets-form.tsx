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
      <section className="panel">
        <div className="panelHeader">
          <div>
            <h1>Pet Profile</h1>
            <p>Save one dog profile locally for the web demo.</p>
          </div>
          {saved ? <span className="pill success">Saved</span> : null}
        </div>

        <div className="photoUploader">
          {previewUrl ? (
            <img src={previewUrl} alt="Pet preview" className="petPreview" />
          ) : (
            <div className="petPlaceholder">Add a dog photo</div>
          )}
          <label className="secondaryButton uploadButton">
            Upload Photo
            <input type="file" accept="image/*" hidden onChange={onPhotoChange} />
          </label>
        </div>

        <div className="formGrid">
          <label>
            <span>Pet Name</span>
            <input
              value={pet.name}
              onChange={(event) => update("name", event.target.value)}
              placeholder="Milo"
            />
          </label>
          <label>
            <span>Breed</span>
            <input
              value={pet.breed}
              onChange={(event) => update("breed", event.target.value)}
              placeholder="Jack Russell Terrier"
            />
          </label>
          <label>
            <span>Weight (kg)</span>
            <input
              type="number"
              value={pet.weight || ""}
              onChange={(event) =>
                update("weight", Number(event.target.value || 0))
              }
            />
          </label>
          <label>
            <span>Neck Girth (cm)</span>
            <input
              type="number"
              value={pet.neckGirth || ""}
              onChange={(event) =>
                update("neckGirth", Number(event.target.value || 0))
              }
            />
          </label>
          <label>
            <span>Chest Girth (cm)</span>
            <input
              type="number"
              value={pet.chestGirth || ""}
              onChange={(event) =>
                update("chestGirth", Number(event.target.value || 0))
              }
            />
          </label>
          <label>
            <span>Back Length (cm)</span>
            <input
              type="number"
              value={pet.backLength || ""}
              onChange={(event) =>
                update("backLength", Number(event.target.value || 0))
              }
            />
          </label>
        </div>

        <button className="primaryButton" type="button" onClick={saveProfile}>
          Save Profile
        </button>
      </section>
    </div>
  );
}
