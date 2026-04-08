# biotracker

An iOS app for people who get bloodwork from more than one provider and want to actually see what's happening over time. Snap a photo of any lab report, and the app extracts the values, normalizes them against reference ranges, and charts the trends.

## Why I built this

I track my own bloodwork across multiple providers and the data lives in five different PDFs, two patient portals, and a stack of paper. Nothing on the App Store would ingest a photo from an arbitrary lab and give me a clean longitudinal view. So I built it.

## Stack

- Swift 6 · SwiftUI · iOS 26
- SwiftData for local persistence (photos kept out of the store via `@Attribute(.externalStorage)`)
- Apple Charts framework for trend visualization
- Anthropic Claude vision API (`claude-sonnet-4-5`) for structured extraction from lab photos
- XcodeGen (`project.yml`) so the project file stays diffable

## How it works

- **Capture** — pick a photo of a lab report from the photo library. The image is JPEG-compressed and sent to Claude with a strict JSON schema prompt; the response is validated against the same `LabResultsImport` type the JSON importer uses.
- **Normalize** — every reading is attached to a canonical `Biomarker` with its own reference range, so values from different labs line up on the same axis.
- **Trend** — biomarker detail views show every reading over time with in-range / out-of-range zone bands and flag-colored points, so abnormal moves are obvious at a glance.
- **Dedup** — re-importing the same draw merges into the existing record instead of duplicating it.
- **Backup** — full JSON export/import of biomarkers and their reading history.

## Tabs

- **Dashboard** — biomarkers grouped by category with quick stats (count, flagged, last draw)
- **Trends** — multi-biomarker chart view
- **Timeline** — every blood draw in reverse chronological order
- **Settings** — import / export, photo capture, API key

## Setup

1. Clone, then run `xcodegen generate` to produce `BioTracker.xcodeproj`.
2. Open in Xcode 16+, build for an iOS 26 simulator or device.
3. To use photo extraction: **Settings → AI Extraction**, paste an Anthropic API key. Stored in `UserDefaults` on-device only.

## Status

Personal project, actively iterating. The photo extraction pipeline is the newest piece — works end-to-end against `claude-sonnet-4-5` but the prompt is still being tuned for less common lab formats.
