import React, { useEffect, useMemo, useState } from "react"
import Select from "react-select"
import CreatableSelect from "react-select/creatable"
import Flatpickr from "react-flatpickr"
import { FilePond, registerPlugin } from "react-filepond"
import FilePondPluginFileValidateType from "filepond-plugin-file-validate-type"
import FilePondPluginFileValidateSize from "filepond-plugin-file-validate-size"
import "flatpickr/dist/flatpickr.min.css"
import "filepond/dist/filepond.min.css"

registerPlugin(FilePondPluginFileValidateType, FilePondPluginFileValidateSize)

const steps = [
  { key: "details", label: "Details", hint: "Name, category, maker story." },
  { key: "media", label: "Media", hint: "Photos that prove quality and scale." },
  { key: "pricing", label: "Pricing", hint: "Set price, lead time, and inventory." },
  { key: "variants", label: "Variants", hint: "Sizes, colors, and material options." },
  { key: "review", label: "Review", hint: "Check trust signals before publish." }
]

const STORAGE_KEY = "proven_product_wizard_state_v1"

export default function ProductWizard() {
  const [stepIndex, setStepIndex] = useState(0)
  const [furthestStep, setFurthestStep] = useState(0)
  const [attemptedNext, setAttemptedNext] = useState(false)
  const [isHydrated, setIsHydrated] = useState(false)
  const [draft, setDraft] = useState({
    name: "",
    description: "",
    country: null,
    currency: null,
    price: "",
    availableAt: "",
    locations: [],
    files: []
  })
  const currentStep = steps[stepIndex]

  useEffect(() => {
    try {
      const raw = window.localStorage.getItem(STORAGE_KEY)
      if (!raw) return

      const parsed = JSON.parse(raw)
      if (!parsed || typeof parsed !== "object") return

      if (typeof parsed.stepIndex === "number" && parsed.stepIndex >= 0) {
        setStepIndex(Math.min(steps.length - 1, parsed.stepIndex))
      }

      if (typeof parsed.furthestStep === "number" && parsed.furthestStep >= 0) {
        setFurthestStep(Math.min(steps.length - 1, parsed.furthestStep))
      }

      if (parsed.draft && typeof parsed.draft === "object") {
        setDraft((previous) => ({
          ...previous,
          ...parsed.draft,
          files: []
        }))
      }
    } catch (_error) {
      window.localStorage.removeItem(STORAGE_KEY)
    } finally {
      setIsHydrated(true)
    }
  }, [])

  useEffect(() => {
    if (!isHydrated) return

    const serializableDraft = {
      ...draft,
      files: []
    }

    window.localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify({
        stepIndex,
        furthestStep,
        draft: serializableDraft
      })
    )
  }, [draft, furthestStep, isHydrated, stepIndex])

  const countryOptions = useMemo(() => {
    const fallback = ["United States", "Canada", "United Kingdom", "Australia", "Germany", "France", "Japan", "India"]
    const displayNames = typeof Intl !== "undefined" && typeof Intl.DisplayNames === "function" ? new Intl.DisplayNames(["en"], { type: "region" }) : null
    let regionCodes = []
    if (typeof Intl !== "undefined" && typeof Intl.supportedValuesOf === "function") {
      try {
        regionCodes = Intl.supportedValuesOf("region")
      } catch (_error) {
        regionCodes = []
      }
    }
    const countries = (regionCodes.length > 0 ? regionCodes.map((code) => displayNames?.of(code)).filter(Boolean) : fallback).sort((a, b) => a.localeCompare(b))
    return countries.map((name) => ({ value: name, label: name }))
  }, [])

  const currencyOptions = useMemo(() => {
    let codes = ["USD", "EUR", "GBP", "CAD", "AUD", "JPY"]
    if (typeof Intl !== "undefined" && typeof Intl.supportedValuesOf === "function") {
      try {
        codes = Intl.supportedValuesOf("currency")
      } catch (_error) {
        codes = ["USD", "EUR", "GBP", "CAD", "AUD", "JPY"]
      }
    }
    return codes.slice(0, 180).map((code) => ({ value: code, label: code }))
  }, [])

  const locationOptions = useMemo(
    () =>
      ["Los Angeles, CA", "New York, NY", "Austin, TX", "Chicago, IL", "Seattle, WA", "Miami, FL", "Portland, OR", "Denver, CO"].map((value) => ({
        value,
        label: value
      })),
    []
  )

  const validation = useMemo(() => {
    const priceValue = Number.parseFloat(draft.price)
    const availableAtDate = draft.availableAt ? new Date(draft.availableAt) : null
    const isFutureDate = availableAtDate instanceof Date && !Number.isNaN(availableAtDate.getTime()) && availableAtDate.getTime() > Date.now()

    return {
      details: {
        complete: draft.name.trim().length > 1 && draft.country?.value && draft.currency?.value,
        errors: {
          name: draft.name.trim().length > 1 ? "" : "Enter at least 2 characters for product name.",
          country: draft.country?.value ? "" : "Choose a country from the dropdown.",
          currency: draft.currency?.value ? "" : "Choose a 3-letter currency code."
        }
      },
      media: {
        complete: draft.files.length > 0,
        errors: {
          files: draft.files.length > 0 ? "" : "Attach at least one image or video."
        }
      },
      pricing: {
        complete: Number.isFinite(priceValue) && priceValue > 0 && isFutureDate,
        errors: {
          price: Number.isFinite(priceValue) && priceValue > 0 ? "" : "Enter a valid price greater than 0.",
          availableAt: isFutureDate ? "" : "Select a future date and time."
        }
      },
      variants: {
        complete: draft.locations.length > 0,
        errors: {
          locations: draft.locations.length > 0 ? "" : "Add at least one location."
        }
      },
      review: {
        complete: true,
        errors: {}
      }
    }
  }, [draft])

  const progress = useMemo(() => {
    const completedCount = Object.values(validation).filter((step) => step.complete).length
    return Math.round((completedCount / steps.length) * 100)
  }, [validation])

  const canAdvance = () => {
    if (stepIndex === 0) return validation.details.complete
    if (stepIndex === 1) return validation.media.complete
    if (stepIndex === 2) return validation.pricing.complete
    if (stepIndex === 3) return validation.variants.complete
    return true
  }

  const goNext = () => {
    setAttemptedNext(true)
    if (!canAdvance()) return
    setStepIndex((index) => {
      const next = Math.min(steps.length - 1, index + 1)
      setFurthestStep((previous) => Math.max(previous, next))
      return next
    })
    setAttemptedNext(false)
  }

  return (
    <section className="rounded-3xl border border-slate-200 bg-white p-4 shadow-soft">
      <div className="flex items-center justify-between gap-3">
        <h3 className="font-header text-lg font-bold text-slate-900">Product Wizard</h3>
        <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">{progress}% complete</span>
      </div>

      <div className="mt-3 h-2 overflow-hidden rounded-full bg-slate-100" role="progressbar" aria-valuemin={0} aria-valuemax={100} aria-valuenow={progress}>
        <div className="h-full rounded-full bg-accent transition-all duration-300" style={{ width: `${progress}%` }} />
      </div>

      <p className="mt-2 text-xs text-slate-500">
        Step {stepIndex + 1} of {steps.length}: {currentStep.label} - {currentStep.hint}
      </p>

      <div className="mt-4 grid gap-3">
        {stepIndex === 0 ? (
          <>
            <label className="text-sm font-semibold text-slate-700">
              Product name
              <input
                className="input input-bordered mt-1 w-full"
                value={draft.name}
                onChange={(event) => setDraft((prev) => ({ ...prev, name: event.target.value }))}
                placeholder="Example: Curious Clay Earrings"
              />
            </label>
            {attemptedNext && validation.details.errors.name ? <p className="text-xs font-semibold text-rose-600">{validation.details.errors.name}</p> : null}

            <label className="text-sm font-semibold text-slate-700">
              Country
              <Select
                className="mt-1"
                options={countryOptions}
                value={draft.country}
                onChange={(selection) => setDraft((prev) => ({ ...prev, country: selection }))}
                placeholder="Choose country"
                isSearchable
              />
            </label>
            {attemptedNext && validation.details.errors.country ? <p className="text-xs font-semibold text-rose-600">{validation.details.errors.country}</p> : null}

            <label className="text-sm font-semibold text-slate-700">
              Currency
              <Select
                className="mt-1"
                options={currencyOptions}
                value={draft.currency}
                onChange={(selection) => setDraft((prev) => ({ ...prev, currency: selection }))}
                placeholder="Choose currency (USD)"
                isSearchable
              />
            </label>
            {attemptedNext && validation.details.errors.currency ? <p className="text-xs font-semibold text-rose-600">{validation.details.errors.currency}</p> : null}

            <label className="text-sm font-semibold text-slate-700">
              Description
              <textarea
                className="textarea textarea-bordered mt-1 h-20 w-full"
                value={draft.description}
                onChange={(event) => setDraft((prev) => ({ ...prev, description: event.target.value }))}
                placeholder="Share materials, process, and customer use case."
              />
            </label>
          </>
        ) : null}

        {stepIndex === 1 ? (
          <>
            <label className="text-sm font-semibold text-slate-700">
              Upload images/videos
              <div className="mt-1 rounded-2xl border border-slate-200 p-2">
                <FilePond
                  files={draft.files}
                  onupdatefiles={(files) => setDraft((prev) => ({ ...prev, files }))}
                  allowMultiple
                  maxFiles={6}
                  acceptedFileTypes={["image/*", "video/*"]}
                  maxFileSize="50MB"
                  labelIdle='Drag & drop media or <span class="filepond--label-action">Browse</span>'
                  credits={false}
                />
              </div>
            </label>
            {attemptedNext && validation.media.errors.files ? <p className="text-xs font-semibold text-rose-600">{validation.media.errors.files}</p> : null}
          </>
        ) : null}

        {stepIndex === 2 ? (
          <>
            <label className="text-sm font-semibold text-slate-700">
              Price
              <input
                className="input input-bordered mt-1 w-full"
                value={draft.price}
                onChange={(event) => setDraft((prev) => ({ ...prev, price: event.target.value }))}
                placeholder="45"
                inputMode="decimal"
              />
            </label>
            {attemptedNext && validation.pricing.errors.price ? <p className="text-xs font-semibold text-rose-600">{validation.pricing.errors.price}</p> : null}

            <label className="text-sm font-semibold text-slate-700">
              Available date/time
              <Flatpickr
                className="input input-bordered mt-1 w-full"
                value={draft.availableAt}
                options={{ enableTime: true, dateFormat: "Y-m-d H:i", minDate: "today", time_24hr: true }}
                onChange={(selectedDates) =>
                  setDraft((prev) => ({
                    ...prev,
                    availableAt: selectedDates[0] ? selectedDates[0].toISOString() : ""
                  }))
                }
                placeholder="Select date and time"
              />
            </label>
            {attemptedNext && validation.pricing.errors.availableAt ? <p className="text-xs font-semibold text-rose-600">{validation.pricing.errors.availableAt}</p> : null}
          </>
        ) : null}

        {stepIndex === 3 ? (
          <>
            <label className="text-sm font-semibold text-slate-700">
              Locations
              <CreatableSelect
                isMulti
                className="mt-1"
                options={locationOptions}
                value={draft.locations}
                onChange={(selection) => setDraft((prev) => ({ ...prev, locations: selection || [] }))}
                placeholder="Select or type shipping/production locations"
              />
            </label>
            {attemptedNext && validation.variants.errors.locations ? <p className="text-xs font-semibold text-rose-600">{validation.variants.errors.locations}</p> : null}
          </>
        ) : null}

        {stepIndex === 4 ? (
          <div className="rounded-2xl border border-slate-200 p-4">
            <h4 className="text-sm font-bold text-slate-900">Submission checklist</h4>
            <ul className="mt-3 space-y-2 text-sm text-slate-700">
              {steps.map((step, index) => {
                const state = validation[step.key]
                return (
                  <li key={step.key} className="flex items-center justify-between gap-2 rounded-xl border border-slate-200 px-3 py-2">
                    <span>{state.complete ? "Completed" : "Incomplete"} - {step.label}</span>
                    {index < stepIndex ? (
                      <button
                        type="button"
                        className="rounded-full border border-slate-300 px-2 py-1 text-xs font-semibold text-slate-700 hover:border-slate-400"
                        onClick={() => setStepIndex(index)}
                      >
                        Go back
                      </button>
                    ) : null}
                  </li>
                )
              })}
            </ul>
          </div>
        ) : null}
      </div>

      <div className="mt-4 rounded-2xl border border-slate-200 p-3">
        <h4 className="text-xs font-bold uppercase tracking-wide text-slate-700">Step checklist</h4>
        <ul className="mt-2 space-y-2 text-sm">
          {steps.map((step, index) => {
            const state = validation[step.key]
            const canVisit = index <= furthestStep || index <= stepIndex
            return (
              <li key={`summary-${step.key}`} className="flex items-center justify-between gap-2">
                <span className={state.complete ? "font-semibold text-emerald-700" : "text-slate-600"}>
                  {state.complete ? "Completed" : "Incomplete"} - {step.label}
                </span>
                {canVisit ? (
                  <button
                    type="button"
                    className="rounded-full border border-slate-300 px-2 py-1 text-xs font-semibold text-slate-700 hover:border-slate-400"
                    onClick={() => setStepIndex(index)}
                  >
                    Open
                  </button>
                ) : null}
              </li>
            )
          })}
        </ul>
      </div>

      <div className="mt-4 flex items-center justify-between gap-2">
        <button
          className="inline-flex items-center justify-center rounded-full border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-700 transition hover:border-slate-400 disabled:cursor-not-allowed disabled:opacity-50"
          type="button"
          onClick={() => setStepIndex((index) => Math.max(0, index - 1))}
          disabled={stepIndex === 0}
        >
          Back
        </button>

        <button
          className="inline-flex items-center justify-center rounded-full bg-primary px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-700 disabled:cursor-not-allowed disabled:opacity-50"
          type="button"
          onClick={goNext}
          disabled={!canAdvance()}
        >
          {stepIndex === steps.length - 1 ? "Ready to publish" : "Next"}
        </button>
      </div>
    </section>
  )
}
