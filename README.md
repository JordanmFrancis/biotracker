# biotracker

An iOS app for people who get bloodwork from more than one provider and want to actually see what's happening over time. Snap a photo of any lab report (Quest, LabCorp, DUTCH, in-house panels), and the app extracts the values, normalizes them against reference ranges, and charts the trends.

## Why I built this

I track my own bloodwork across multiple providers and the data lives in five different PDFs, two patient portals, and a stack of paper. Nothing on the App Store would ingest a photo from an arbitrary lab and give me a clean longitudinal view. So I built it.

## Stack

- Swift 6 · SwiftUI · iOS 26
- SwiftData for local persistence
- Apple Charts framework for visualization
- Vision + a vision-language model for OCR and structured extraction from lab report photos
- XcodeGen (`project.yml`) so the project file stays diffable

## How it works

- Take a photo of any lab report and the app runs OCR + an LLM extraction pass that maps free-form report text into a normalized biomarker schema
- Each reading is stored against a canonical biomarker with its own reference range, so values from different providers line up properly
- Trend views show every biomarker over time with reference-range bands so abnormal moves are obvious at a glance
- Supports protocol tracking (supplements, medications, peptides) and genetic variants alongside the labs, so you can correlate interventions with what your blood is actually doing

## Demo

Private repo — demo available on request.
