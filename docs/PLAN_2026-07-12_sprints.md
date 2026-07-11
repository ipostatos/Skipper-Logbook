# План работ: спринты 2–3 (+хвосты) — Skipper Logbook

Дата: 2026-07-12. Контекст: полный аудит — `docs/AUDIT_2026-07-11.md`,
банк фишек — `UI_IDEAS.md`. Это ТЗ для автономной сессии: выполнять сверху вниз,
после каждого блока — сборка + юнит-тесты, коммит только на зелёных тестах.

## Состояние на старте (ВАЖНО)

**Спринт 1 уже реализован, но НЕ собран и НЕ закоммичен** (кода правился на
Windows, без Xcode). В рабочем дереве:

- новый `SkipperLogbook/Core/Location/FixCoordinator.swift` — фан-аут фиксов
  вне View-слоя (RootView.onChange удалён), троттлинг снапшота виджетов
  (события + ≤1 раз в 10 мин), Live Activity — каждый фикс;
- `AnchorWatchEngine` — тревога повторяется каждые 20 с, `.timeSensitive`
  (entitlement добавлен), нотификация «отбой», журнал 1 запись/экскурсию,
  батч-save сессии;
- `LocationManager` — `onFix`-хук + фильтр `isUsable` (0<hAcc≤100 м, возраст ≤15 с);
- `VoyageRecorder` — кэш последней точки (без пересортировок на фиксе),
  батч-save (10 точек/12 с), в дистанцию только hAcc≤50, восстановление
  engineOn из журнала после перезапуска, хук `onVoyageMetaChange`;
- `LiveActivityController` — `adoptOrphans()`, staleDate 180 с, endActivity
  закрывает всех сирот; виджеты/LA показывают «No recent data»/«NO DATA»;
- +3 юнит-теста в `PersistenceAndRecorderTests`; CHANGELOG заполнен.

### Шаг 0 — валидация спринта 1 (первым делом!)
```bash
xcodegen generate
xcodebuild -project SkipperLogbook.xcodeproj -scheme SkipperLogbook \
  -destination 'platform=iOS Simulator,name=iPhone 16' clean build test
```
Чинить компиляцию/тесты до зелени. Затем коммит:
`fix(core): sprint 1 — safety fan-out, repeating anchor alarm, widget budget, track perf, GPS filter`.

---

## СПРИНТ 2 — «продукт без тупиков» (приоритет: сверху вниз)

### 2.1 SafetyView недостижим → сделать доступным [S]
- `App/AppRouter.swift`: в `enum AppRoute` добавить case `safety`.
- `App/RootView.swift` (`AppRoutesModifier`): `case .safety: SafetyView()`.
- `Features/More/MoreMenuView.swift`: плитка
  `tile("safety.title", "cross.case.fill", Color(hex:"B33A3A"), id:"more.tile.safety") { router.morePathAppend(.safety) }`
  — ключ `safety.title` уже есть в каталоге (EN/RU). Поставить плитку первой в гриде.
- Проверить, что `SafetyView` компилируется в текущем окружении (env: mob,
  anchorWatch, location, router — всё уже инжектится).

### 2.2 «Призрак» экипажа при отмене добавления [S]
`Features/Crew/CrewView.swift:48-58` — `newMember()` делает `context.insert`
внутри ViewBuilder шита. Переделка: sheet показывает `CrewMemberEditView`
в режиме «новый» БЕЗ вставки в контекст; `context.insert` — только по Done.
Проще всего: у `CrewMemberEditView` появляется init(new:) с локальным
@State-полями, а insert+save происходят в его же кнопке Done. Свайп-вниз =
ничего не создано. Повторный показ шита не плодит объекты.

### 2.3 Унификация тумблера двигателя [S]
- Единственный источник: `VoyageRecorder.toggleEngine()` — добавить в него
  установку `propulsion` (логика из `TodayView.toggleEngine` :357-361), убрать
  дублирование из Today; `QuickActionsSheet.swift:66-69` перевести на тот же
  метод. `AppState.engineOn` — синхронизировать из recorder (или удалить поле
  и читать recorder напрямую в чипах Today).

### 2.4 Удаления данных + чистка файлов [M]
1) Утилита удаления голосового файла: при `context.delete(voiceNote)` удалять
   `Documents/VoiceNotes/<file>` (`FileManager.removeItem`, путь — из модели
   VoiceNote). Смотреть `AudioRecorderController.swift:33-42` (формирование пути).
2) `AudioLogView` — swipeActions «Удалить» на строке заметки (+файл).
3) `LogbookView` — swipeActions удаления LogEvent (только ручные записи?
   решение: удалять любые с confirmationDialog).
4) `VoyageDetailView` — toolbar-меню «Удалить рейс» с confirmationDialog;
   перед delete пройтись по voyage.voiceNotes и удалить их файлы (cascade
   удалит строки, но не файлы!). После удаления — dismiss.
5) `CrewView.swift:99-101` — обернуть удаление в confirmationDialog.
6) `VesselEditView` — добавить Cancel: для нового судна (см. `VesselView`
   :102-107 — createVessel вставляет ДО редактирования) перенести insert на
   Done по образцу 2.2; не оставлять «New Boat» при свайпе.

### 2.5 Пять разделов More без создания записей [M]
`Features/More/ReferenceViews.swift` — добавить в каждый экран toolbar «+» и
простой Form-шит (по образцу `CrewMemberEditView`, вставка по Done — правило 2.2):
- EquipmentListView → EquipmentItem (name, category?, note);
- ServiceNotesView → ServiceNote (date, title, note);
- SeasonLogView → SeasonEntry (поля по модели);
- DeviationView → DeviationEntry (heading, deviation E/W) — «E/W» локализовать
  (`ReferenceViews.swift:192`).
Поля брать строго из существующих @Model-классов (`Shared/Models/ReferenceRecords.swift`) —
ничего в схему не добавлять. `MaintenanceView.swift:43-45` — «+» вместо
`.comingSoon()`: форма MaintenanceItem (title, hours, note...).
Плюс swipe-удаление в каждом списке (единый стиль).

### 2.6 Истинный vs магнитный курс (MOB-стрелка) [S]
- `LocationManager`: хранить отдельно `trueHeadingDegrees: Double?`
  (заполнять только когда `newHeading.trueHeading >= 0`); добавить
  `var trueReferenceHeading: Double { trueHeadingDegrees ?? courseDegrees }`
  (оба — истинные направления; COG всегда истинный).
- `MOBActiveView.swift:74`: `mob.relativeBearing(boatHeading: location.trueReferenceHeading)`.
- В UI пеленга/курса на MOB-экране подписать «°T».
`effectiveHeading` для прочих экранов не трогать (отображение).

### 2.7 Today: спарклайн «to waypoint» врёт [S]
`TodayView.swift:153-154` — кормится `speedSamples.reversed()` (перевёрнутая
скорость вместо дистанции). Минимально честно: убрать reversed-хак и показывать
и в этой карточке скорость (подпись «Speed»), либо построить series остатка
дистанции по точкам трека (если дёшево). Решение на месте, но НЕ оставлять ложь.

Коммит спринта 2 после зелёных тестов:
`fix(ux): sprint 2 — reachable Safety, no ghost inserts, deletions with cleanup, add-forms for More sections, unified engine toggle, true-bearing MOB arrow`.

---

## СПРИНТ 3 — «к релизу» (Store-блокеры)

### 3.1 PrivacyInfo.xcprivacy [S, обязательный]
Создать `SkipperLogbook/PrivacyInfo.xcprivacy` (XcodeGen подхватит как ресурс):
- NSPrivacyAccessedAPITypes:
  - `NSPrivacyAccessedAPICategoryUserDefaults` → reason `CA92.1`;
  - `NSPrivacyAccessedAPICategoryFileTimestamp` → reason `C617.1`.
- NSPrivacyCollectedDataTypes: precise location, collected, not linked, not
  tracking, purpose AppFunctionality (локально в SwiftData; не уходит с устройства —
  но сбор координат декларируем честно).
- NSPrivacyTracking = false.
Аналогичный минимальный файл в `SkipperWidgets/` (UserDefaults через App Group).

### 3.2 Локализация системных промптов [S]
`SkipperLogbook/Resources/InfoPlist.xcstrings` с ключами:
NSLocationWhenInUseUsageDescription, NSLocationAlwaysAndWhenInUseUsageDescription,
NSMicrophoneUsageDescription (+ CFBundleDisplayName при желании) — EN тексты из
Info.plist, RU перевод. В Always-строке упомянуть якорную тревогу (помогает ревью).

### 3.3 Локализация виджетов/LA [M]
- `project.yml` (target SkipperWidgets): добавить в sources
  `SkipperLogbook/Resources/Localizable.xcstrings`, `SWIFT_EMIT_LOC_STRINGS: YES`.
- Добавить в каталог ключи (EN+RU): Speed, Course, ETA, To WP, Logged,
  Remaining, Fuel, Recording, REC, «No recent data», NO DATA, «No voyage»,
  Active Voyage (+description виджетов, Maintenance/Streak строки из
  `SecondaryWidgets.swift`). В коде виджетов `Text("...")` уже
  LocalizedStringKey — строки подхватятся; литералы в `String` (если есть) —
  через `String(localized:)`.
- ETA: `ActiveVoyageWidget.etaString` и `VoyageLiveActivity.etaString` →
  `Date(timeIntervalSince1970: epoch).formatted(date: .omitted, time: .shortened)`
  (уважает 12/24 ч).

### 3.4 UIBackgroundModes: audio [S, решение принято]
В `SkipperLogbook/Info.plist` к `location` добавить `audio` — голосовая заметка
не должна обрываться блокировкой экрана. Проверить, что AVAudioSession
конфигурируется `.playAndRecord` перед записью (AudioRecorderController).

### 3.5 Миграции схемы + отказ от fatalError [M]
`Core/Persistence/PersistenceController.swift`:
- Ввести `enum SchemaV1: VersionedSchema` (все 11 моделей) +
  `SkipperMigrationPlan: SchemaMigrationPlan` (stages: []); контейнер строить
  через `ModelContainer(for:migrationPlan:configurations:)`.
- Вместо `fatalError`: при падении загрузки переместить store-файлы в
  `Application Support/CorruptedStore-<дата>/` и создать чистый контейнер
  (лог + однократный алерт при старте: «данные не удалось прочитать, бэкап
  сохранён»). Данные не стирать молча.

### 3.6 CI-фиксы [S]
`.github/workflows/ci.yml`:
- `brew install xcodegen xcbeautify` (шаг install) — иначе pipefail роняет пайп
  и `||`-фоллбек гоняет тесты ВТОРОЙ раз;
- убрать `|| swiftlint` (строгий линт должен уметь падать) — но сперва
  прогнать `swiftlint --strict` локально и починить/задокументировать warnings;
- `.gitignore`: добавить `*.xcresult`;
- (опционально) закешировать brew/DerivedData.
`preview.yml` не трогать (работает), sed-хак objectVersion оставить.

### 3.7 P2-локализация UI [S]
- Ключи `chip.on/off/up/down/add` (EN: ON/OFF/UP/DOWN/Add; RU: ВКЛ/ВЫКЛ/УБРАН/
  СТОИТ/Добавить — по смыслу чипов Today) + `StatusChip.swift:73-88` перевести
  на `String(localized:)`.
- A11y-лейблы: «Man overboard» ×3 (`TodayView:280`, `MapView:168`,
  `SafetyView:157`) → `String(localized: "mob.title")`; `CustomTabBar:70` →
  `action.quick_actions_title`; `Badges:16` → новый ключ `badge.beta_a11y`.
- `MapView.swift:132-137` — accessibilityLabel на кнопки слоёв/центра/waypoint
  (новые ключи a11y.map_layers / a11y.map_recenter / a11y.map_add_waypoint).
- `StatisticsView.swift:74` «kn max» → ключ.
- Док-ссылки: `yonyz/XcodeGen` → `yonaskolb/XcodeGen` в README.md:94,
  SETUP.md:3, CONTRIBUTING.md:4.

Коммит: `chore(store): privacy manifest, localized permissions & widgets, schema versioning, CI fixes`.

---

## Бэклог (НЕ в этих спринтах — не трогать без запроса)
P2-перф (Avatar-кэш, DateFormatter-статики, WaveformView ForEach, orderedTrack
в видах, упрощение полилинии карты), выбор рейса в Statistics, NewVoyage
координаты по имени, AudioLog одиночный плеер, CSV BOM (+правка теста), GPX
extensions, Xcode 15/16 в доках, git-диета design-PNG, фишки из `UI_IDEAS.md`.

## Правила выполнения
1. Порядок строго: шаг 0 → 2.1…2.7 → 3.1…3.7. Блок = сборка + тесты + коммит.
2. Схему SwiftData НЕ менять (только 3.5 оборачивает существующую в V1).
3. Новые строки — сразу в каталог EN+RU (каталог обязан остаться 100%).
4. Ничего не «Coming soon»-ить обратно; честность UI сохраняем.
5. Если тест падает из-за нового поведения — сначала понять, потом править тест.
6. Пуш — после каждого зелёного коммита (CI добьёт валидацию).
