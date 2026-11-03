# For Rosa

A colourful Flutter study companion for Grade 10, with a shareable GitHub Pages website and an Android project. The interface uses a course-dashboard layout and topic-based revision, with an independent design and branding.

**Website:** https://joaopedra-amdg.github.io/DLS_app/

## Included

- Seven subjects, named to match the school’s Classroom: Mathematics, Further Studies Mathematics, Physical Science, Life Sciences, Sport Science, English, and RE. LO is excluded.
- 44 uploaded PDFs audited; four exact duplicates combined into one copy each. There are 38 useful unique PDFs and two blank resources recorded as unavailable.
- Papers named by subject, paper, session and year, with matching supplied memos. An unknown year is explicitly labelled.
- Topic packs link to original exam pages, memos and relevant Classroom material. Original diagrams, equations and reading passages stay intact in the PDFs.
- Six further-practice questions and two concept challenges per topic, worked answers, revision notes and at least 15 flashcards per topic. Concept challenges ask learners to predict, explain, evaluate and test misconceptions.
- A searchable Classroom library supports original downloads, PDF viewing copies and clearly labelled school links. A school link requires the relevant Google account and has no offline copy in For Rosa.
- A dedicated Pomodoro screen offers 25-minute focus, 5-minute short breaks and 15-minute long breaks. Timers survive navigation within the app, pause, reset and catch up after a sleeping device resumes.
- Wave amplitude and frequency controls, wavelength/period readouts, graph comparisons, adjustable circuit resistance and normal-distribution spread, and reset/pause controls.
- Search, year/subject/resource filters, bookmarks, revision completion and card-recall ratings.
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
python tools/prepare_web_release.py
```

Serve `build/web` under `/DLS_app/` to match the release base path, or build with `--base-href /` for a root-hosted local preview. The release bundles its own rendering resources rather than relying on a Flutter CDN.

Every push to `main` automatically regenerates and validates the learning library, runs formatting, analysis and learner-flow tests, builds Flutter web, and deploys the public site through `.github/workflows/pages.yml`. The share link stays the same. GitHub Pages uses **GitHub Actions** as its build source. To publish more practice, edit `tools/extra_practice.py` or `tools/curriculum.py`, commit and push to `main`; the workflow includes those content changes automatically. Open or reload the site after deployment to see the updated version. A failed check prevents that update from being published.

## Learning content and sources

Read [docs/SOURCE_AUDIT.md](docs/SOURCE_AUDIT.md) for a complete mapping of all 44 uploads, duplicates, partial memos and missing resources. Notably, no 2024 Chemistry memo was provided: upload 38 is a duplicate Physics memo. Original files are preserved byte-for-byte under `assets/papers/`. The numbered uploads remain locally and are ignored by Git to avoid duplication.

Topic definitions and initial practice are in `tools/curriculum.py`; additional exercises are in `tools/extra_practice.py`; earlier recall cards are preserved from `tools/topic_extensions.py`; concept challenges are in `tools/concept_challenges.py`. English, RE and Classroom study extensions are in `tools/classroom_curriculum.py`. Existing card positions stay unchanged so earlier learner ratings remain meaningful. `assets/content.json` is generated. To rebuild it, install Python `pypdf==6.10.0` and run the following. The builder uses the original numbered uploads when available, or the committed PDFs on a fresh checkout and in GitHub Actions:

```sh
python tools/build_content.py
python tools/validate_content.py
```

Validation checks all input provenance and published file checksums, actual blank PDF content, matching memo subjects/years, reference page bounds, and topic-pack completeness. `--review` additionally prints snippets from locally extracted source pages when those intermediates exist.

Generated learning material is clearly labelled and is separate from official exam content. Topics reflect the supplied papers and are not a guarantee of complete curriculum coverage. Some original memo statements are imprecise or incorrect; the notes explain standard concepts instead of copying those mistakes. The source PDF bytes remain untouched.

## Privacy and persistence

Bookmarks and progress use `shared_preferences` on the learner's device. Clearing browser/site data removes this information. Nothing is uploaded or shared between devices. A PDF needs a successful initial online load before it can be cached. The focus timer runs while For Rosa remains open; closing the app ends it. It is not a background notification service.

Classroom imports require a separate publication decision: public GitHub Pages does not protect downloaded teaching-file copies behind a school login. Account details, passwords, grades, comments and personal submissions must stay out of the repository. Private source collection and review files are kept under ignored `tmp/`. A school link preserves the original provider’s access controls. Importing every posted file has not been completed; the source audit must distinguish verified downloads from school links.

## Project layout

- `lib/app.dart`: dashboard, subject/topic views, search, file library, paper filters and cards.
- `lib/focus_timer.dart`: persistent in-session Pomodoro state and its dedicated screen.
- `lib/pdf_reader_screen.dart` and `web/reader.*`: PDF navigation, downloads and fullscreen reading.
- `lib/models.dart`: catalogue access and local persistence.
- `lib/visuals.dart`: local vector art and animated learning sketches.
- `assets/content.json`: generated learning library.
- `assets/papers/`: descriptively named originals.
- `tools/`: reproducible content validation and icon generation helpers.
- `test/widget_test.dart`: learner journeys, local persistence, narrow layout and visual rendering tests.

The app is independent of Canvas and Save My Exams. Exam PDFs and their embedded third-party source material remain the property of their respective owners. No third-party educational branding or website assets have been copied.

## Install For Rosa

Open the public site in a normal browser and tap **Install For Rosa** at the bottom of the home page. Supporting browsers offer a native install prompt. Otherwise, the app gives Android/Chrome, iPhone/iPad Safari, and desktop instructions. In Safari use Share → Add to Home Screen; in Chrome or Edge use Install app or the browser’s install option.

The web manifest uses the name For Rosa and standalone display mode. The service worker saves the app shell and learning content for offline use after its first successful download. Teaching files are cached on demand. Cache storage depends on the browser; download a separate copy when needed. The PDF reader preserves the study screen and offers Back, Download, page controls, fit-width, zoom and Fullscreen. Browsers without native fullscreen use an expanded reading layout with a Return to app control. Mozilla PDF.js 4.10.38 is bundled locally with its licence in `web/vendor/pdfjs/LICENSE`.

Every push to main regenerates the content, validates sources, runs web and Flutter tests, builds and stamps a new app-shell revision, and deploys GitHub Pages. Existing open pages show a reload notice when a new app-shell version is downloaded. Student bookmarks and card ratings remain stored separately on their device.
