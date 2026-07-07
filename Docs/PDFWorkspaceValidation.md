# PDF Workspace Validation

This checklist is for changes touching PDF reading, exam attempts, PencilKit answer layers, crop selection, scratch board, export, or grading.

## Automated Checks

- Build the app with the supported simulator SDK:
  `xcodebuild -project PaperClip.xcodeproj -scheme PaperClip -destination 'generic/platform=iOS Simulator' build`
- Run pure Swift regression tests:
  `Tests/run-pure-swift-tests.sh`
- For answer-layer persistence changes, confirm these cases are covered:
  - pending drawings with unchanged pages do not create duplicate writes;
  - changed pending pages update or insert `ExamHandwritingLayer` rows;
  - duplicate handwriting layers load the latest row per page and delete older rows;
  - clearing answers deletes only the active `ExamAttempt` layers;
  - document cascade deletion removes exam attempts, answer layers, grade marks, and generated exam PDFs.

## Manual iPad Validation

- Open a PDF from the subject library and start an exam attempt.
- Confirm the exam attempt enters writing mode by default and the drawing layer is visible.
- Write on multiple pages with Apple Pencil.
- Scroll and pinch-zoom the PDF with touch; confirm writing does not block system PDF scrolling or zooming.
- Exit the exam, reopen it from history, and confirm handwriting restores on the correct pages.
- Switch from one in-progress attempt to another; confirm pending handwriting is saved before the switch.
- Clear answers in one attempt; confirm other attempts for the same source PDF keep their handwriting.
- Submit an exam; confirm pending handwriting is saved before status changes to submitted.
- Reopen the original source PDF outside the exam flow and confirm the source PDF file was not modified.

## UI And Accessibility Checks

- Test portrait, landscape, and a narrow iPad window size.
- Test light mode and dark mode.
- Confirm VoiceOver labels exist for toolbar actions, exam start/exit, clear answers, submit, selection actions, and scratch board controls.
- Confirm system `PKToolPicker` remains the only PencilKit tool picker.
- Confirm sharing still uses `ShareLink`.
- Confirm file import/export paths still use SwiftUI file APIs and `FileDocument` where applicable.

## Native API Guardrails

- Keep PDF rendering and page coordinate conversion in PDFKit.
- Keep handwriting and scratch content in `PKCanvasView`.
- Keep PencilKit tool selection in `PKToolPicker`.
- Do not add custom share sheets, file pickers, navigation bars, alert systems, or PencilKit tool pickers.
- If a custom gesture or control is introduced, document the checked Apple API, why it was insufficient, and the verified accessibility/system-gesture behavior.
