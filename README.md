# DLS Study Club

A colourful Flutter study companion for Grade 10, with a shareable GitHub Pages website and an Android project. The interface uses a course-dashboard layout and topic-based revision, with an independent design and branding.

**Website:** https://joaopedra-amdg.github.io/DLS_app/

## Included

- Five subjects: Maths, AP Maths, Physical Science (Physics and Chemistry), Life Science, and Sports Science.
- 44 uploaded PDFs audited; four exact duplicates combined into one copy each. There are 38 useful unique PDFs and two blank resources recorded as unavailable.
- Papers named by subject, paper, session and year, with matching supplied memos. An unknown year is explicitly labelled.
- 46 editorial topic packs linking directly to original question pages and matching memo pages where available. Original diagrams, equations and reading passages stay intact in the PDFs.
- 92 newly authored practice questions with worked answers, 138 short revision sections, 230 flashcards, animated concept sketches and interactive graph controls.
- Search, year/subject/resource filters, bookmarks, revision completion, card-recall ratings and a 25-minute focus timer.
- Responsive phone, tablet and desktop layouts; reduced-motion support for lesson animations.
- Device-local progress. No learner accounts, backend, tracking or cross-device synchronization.

## Run

Use Flutter **3.29.1** (Dart 3.7), the version used by CI, or a compatible newer SDK.

```sh
flutter pub get
flutter run -d chrome
```

The Android project can be opened in Android Studio or run with `flutter run -d <device-id>`. Android PDF buttons open the published HTTPS PDFs in the device's browser; notes, practice and flashcards are bundled with the app. An APK and store signing are not required to use the website.

## Verify and build

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release --base-href /DLS_app/ --no-web-resources-cdn
```

Serve `build/web` under `/DLS_app/` to match the release base path, or build with `--base-href /` for a root-hosted local preview. The release bundles its own rendering resources rather than relying on a Flutter CDN.

Every push to `main` runs formatting, analysis and learner-flow tests before the Pages deployment in `.github/workflows/pages.yml`. GitHub Pages must use **GitHub Actions** as its build source.

## Learning content and sources

Read [docs/SOURCE_AUDIT.md](docs/SOURCE_AUDIT.md) for a complete mapping of all 44 uploads, duplicates, partial memos and missing resources. Notably, no 2024 Chemistry memo was provided: upload 38 is a duplicate Physics memo. Original files are preserved byte-for-byte under `assets/papers/`. The numbered uploads remain locally and are ignored by Git to avoid duplication.

Topic definitions, notes and generated practice are in `tools/curriculum.py`; `assets/content.json` is the generated app catalogue. To rebuild it, place the original `1.pdf` through `44.pdf` in the project root, install Python `pypdf`, and run:

```sh
python tools/build_content.py
python tools/validate_content.py
```

Validation checks all input provenance and published file checksums, actual blank PDF content, matching memo subjects/years, reference page bounds, and topic-pack completeness. `--review` additionally prints snippets from locally extracted source pages when those intermediates exist.

Generated learning material is clearly labelled and is separate from official exam content. Topics reflect the supplied papers and are not a guarantee of complete curriculum coverage. Some original memo statements are imprecise or incorrect; the notes explain standard concepts instead of copying those mistakes. The source PDF bytes remain untouched.

## Privacy and persistence

Bookmarks and progress use `shared_preferences` on the learner's device. Clearing browser/site data removes this information. Nothing is uploaded or shared between devices. PDF access requires a connection. The focus timer runs while its page remains open and is not a background notification service.

## Project layout

- `lib/app.dart`: dashboard, subject/topic views, search, paper filters, cards and timer.
- `lib/models.dart`: catalogue access and local persistence.
- `lib/visuals.dart`: local vector art and animated learning sketches.
- `assets/content.json`: generated learning library.
- `assets/papers/`: descriptively named originals.
- `tools/`: reproducible content validation and icon generation helpers.
- `test/widget_test.dart`: learner journeys, local persistence, narrow layout and visual rendering tests.

The app is independent of Canvas and Save My Exams. Exam PDFs and their embedded third-party source material remain the property of their respective owners. No third-party educational branding or website assets have been copied.
