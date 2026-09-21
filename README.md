# TestProjectStr — форма регистрации

iOS-приложение с экраном регистрации пользователя. Верстка на UIKit, но построена так,
что переключается на SwiftUI одной строкой конфигурации: обе реализации используют
общую вьюмодель и общую логику.

- **Минимальная версия iOS:** 26.1
- **Swift:** 5 language mode, `default-isolation = MainActor`
- **Зависимости:** нет, только системные фреймворки (UIKit, SwiftUI, Combine, Foundation)

Проект использует синхронизированные группы Xcode (`PBXFileSystemSynchronizedRootGroup`),
поэтому **новые файлы подхватываются автоматически** — редактировать `.pbxproj` вручную не нужно,
достаточно положить файл в папку таргета.

---

## Содержание

1. [Что умеет экран](#что-умеет-экран)
2. [Структура проекта](#структура-проекта)
3. [Как устроена архитектура](#как-устроена-архитектура)
4. [Поток данных при нажатии «Продолжить»](#поток-данных-при-нажатии-продолжить)
5. [DI-контейнер](#di-контейнер)
6. [Заглушка бэкенда](#заглушка-бэкенда)
7. [Работа с ошибками валидации](#работа-с-ошибками-валидации)
8. [Переключение UIKit ↔ SwiftUI](#переключение-uikit--swiftui)
9. [Подключение реального бэкенда](#подключение-реального-бэкенда)
10. [Как расширять приложение](#как-расширять-приложение)
11. [Тестирование](#тестирование)
12. [Отличия от шаблона Xcode](#отличия-от-шаблона-xcode)

---

## Что умеет экран

Сверху — навигационный бар с заголовком «Регистрация». Под ним три поля ввода: логин,
номер телефона и email. Внизу экрана — кнопка «Продолжить», которая поднимается вместе
с клавиатурой.

**Плавающий заголовок.** Пока поле пустое и не в фокусе, название показывается как плейсхолдер
внутри поля. При фокусе (или когда в поле есть текст) название уезжает наверх, над полем,
а плейсхолдер убирается. Место под заголовок зарезервировано всегда, поэтому форма
не «прыгает» при переключении фокуса.

**Отправка.** По нажатию на кнопку уходит запрос в заглушку, которая отвечает через 3 секунды.
Всё это время кнопка заблокирована и показывает индикатор загрузки, поля ввода тоже
заблокированы и притушены. Второй запрос отправить невозможно — блокировка стоит в двух местах:
в UI (кнопка `disabled`) и в вьюмодели (`guard submitTask == nil`), так что даже программный
вызов `submit()` во время запроса ничего не сделает.

**Ошибки.** Приходят с бэкенда отдельно для каждого поля и показываются под ним красным текстом.
Если по одному полю пришло несколько ошибок, они выводятся одной строкой через запятую,
например: `Длина должна быть 11 цифр, Несуществующий номер`. Рамка поля с ошибкой становится красной.

**Сброс ошибок.** Как только пользователь начинает править поле, его ошибка исчезает.
Ошибки соседних полей при этом остаются на месте.

---

## Структура проекта

```
TestProjectStr/
├── App/                                    # Точка входа и composition root
│   ├── AppConfiguration.swift              # Переключатели: UIKit/SwiftUI, stub/HTTP
│   ├── AppCoordinator.swift                # Корневой флоу навигации
│   ├── AppDelegate.swift                   # Владеет CompositionRoot
│   ├── CompositionRoot.swift               # Сборка DI-контейнера из ассамблей
│   ├── SceneDelegate.swift                 # Создаёт окно и запускает координатор
│   └── DI/
│       ├── NetworkAssembly.swift           # Регистрация транспорта
│       └── RegistrationAssembly.swift      # Регистрация зависимостей фичи
│
├── Core/                                   # Переиспользуемая инфраструктура
│   ├── DI/DIContainer.swift                # Контейнер, DIResolver, Assembly, DIScope
│   ├── Navigation/Coordinator.swift        # Протоколы Coordinator и фабрики экрана
│   └── Resources/Strings.swift             # Тексты приложения
│
├── Domain/                                 # Бизнес-правила. Не знает про UI и сеть
│   ├── Entities/
│   │   ├── FormField.swift                 # FormFieldID, FormFieldContentKind, FormField
│   │   ├── Registration.swift              # RegistrationRequest, RegistrationOutcome
│   │   └── ValidationMessage.swift         # ValidationMessage, FieldErrors
│   ├── Repositories/
│   │   └── RegistrationRepository.swift    # Контракты репозитория и схемы формы
│   └── UseCases/
│       └── RegisterUserUseCase.swift       # Сценарий регистрации
│
├── Data/                                   # Реализация контрактов домена
│   ├── DTO/RegistrationDTO.swift           # Транспортные модели запроса и ответа
│   ├── Mappers/RegistrationResponseMapper.swift
│   ├── Network/
│   │   ├── RegistrationRemoteDataSource.swift      # Протокол транспорта
│   │   ├── StubRegistrationRemoteDataSource.swift  # Заглушка на 3 секунды
│   │   └── HTTPRegistrationRemoteDataSource.swift  # Боевой URLSession-клиент
│   └── Repositories/
│       ├── DefaultRegistrationRepository.swift
│       └── StaticRegistrationFormSchemaProvider.swift
│
└── Presentation/
    └── Registration/
        ├── RegistrationViewState.swift         # Состояние экрана, готовое к отрисовке
        ├── RegistrationViewModel.swift         # Логика экрана, без импорта UIKit/SwiftUI
        ├── RegistrationScreenFactories.swift   # Точка подмены верстки
        ├── UIKit/
        │   ├── RegistrationViewController.swift
        │   ├── FormFieldView.swift             # Поле с плавающим заголовком и ошибкой
        │   └── PrimaryButton.swift             # Кнопка с состоянием загрузки
        └── SwiftUI/
            └── RegistrationScreen.swift        # Та же верстка на SwiftUI
```

---

## Как устроена архитектура

Три слоя с зависимостями, направленными строго внутрь: `Presentation → Domain ← Data`.
Домен не импортирует ничего, кроме `Foundation`, и не знает ни про `URLSession`, ни про `UIView`.

### Domain

Здесь живут сущности и контракты.

`FormFieldID` — идентификатор поля. Намеренно **не** `enum`, а обёртка над строкой:

```swift
struct FormFieldID: RawRepresentable, Hashable, Sendable {
    let rawValue: String
}
```

Это ключевое решение для требования «на бэке в любой момент могут добавиться новые ошибки».
Если сервер пришлёт ошибку по полю, о котором приложение ещё не знает, `enum` потерял бы её
при разборе ответа, а строка — нет.

`FormField` описывает поле формы: идентификатор, заголовок и тип содержимого
(`text` / `phone` / `email`). Экран строится из массива таких описаний, а не из захардкоженных
трёх полей — поэтому добавление четвёртого поля не требует правок верстки.

`ValidationMessage` — одна ошибка: машинный `code` и готовый для показа `text`. Приложение
**не переводит коды в тексты** и не хранит их словарь, а показывает то, что прислал сервер.
`FieldErrors` группирует такие сообщения по полям.

`RegistrationRequest` хранит значения в словаре `[FormFieldID: String]`, поэтому новое поле
не меняет сигнатуры домена. `RegistrationOutcome` — результат: либо `.registered(userID:)`,
либо `.rejected(FieldErrors)`. Ошибки валидации — это **не** Swift-ошибка, а нормальный
результат сценария; `throws` остаётся только для сбоев транспорта.

`RegisterUserUseCase` — сценарий регистрации. Единственное, что он делает с данными, —
обрезает пробелы по краям; решение о валидности принимает бэкенд.

### Data

`RegistrationRemoteDataSource` — протокол транспорта с двумя взаимозаменяемыми реализациями
(заглушка и HTTP). `DefaultRegistrationRepository` переводит доменный запрос в DTO, вызывает
транспорт и отдаёт результат маппера. `RegistrationResponseMapper` превращает ответ сервера
в `RegistrationOutcome`, пропуская любые незнакомые коды и имена полей как есть.

`StaticRegistrationFormSchemaProvider` отдаёт схему формы. Сейчас она зашита в код, но раз это
реализация протокола из домена, позже схему можно получать с бэкенда, подменив реализацию
в ассамблее — экран об этом не узнает.

### Presentation

`RegistrationViewState` — полное состояние экрана, уже готовое к отрисовке: значения полей,
тексты ошибок, флаг загрузки. Вся подготовка данных (в том числе склейка нескольких ошибок
через запятую) происходит здесь:

```swift
func errorText(for field: FormFieldID) -> String? {
    guard let messages = errors[field], !messages.isEmpty else { return nil }
    return messages.joined(separator: ", ")
}
```

`RegistrationViewModel` содержит всю логику экрана и **не импортирует ни UIKit, ни SwiftUI** —
только `Combine` и `Foundation`. Состояние публикуется через `@Published private(set) var state`,
а сам класс — `ObservableObject`. Это и есть мост между двумя фреймворками: SwiftUI подписывается
на него штатно через `@ObservedObject`, а UIKit — через Combine:

```swift
viewModel.$state
    .removeDuplicates()
    .receive(on: DispatchQueue.main)
    .sink { [weak self] state in self?.render(state) }
    .store(in: &cancellables)
```

Вьюмодель помечена `@MainActor`, обновление состояния всегда происходит на главном потоке.

Верстка — «глупая»: она раскладывает готовые значения из состояния по вьюхам и ничего
не вычисляет. `FormFieldView` (UIKit) и `FloatingLabelField` (SwiftUI) отвечают только
за анимацию заголовка и цвет рамки — это чисто визуальные состояния, которым незачем
попадать в вьюмодель.

---

## Поток данных при нажатии «Продолжить»

```
RegistrationViewController / RegistrationScreen
        │  submit()
        ▼
RegistrationViewModel            isSubmitting = true, старые ошибки очищены
        │  execute(RegistrationRequest)
        ▼
DefaultRegisterUserUseCase       обрезка пробелов
        │  register(RegistrationRequest)
        ▼
DefaultRegistrationRepository    Domain → RegistrationRequestDTO
        │  register(RegistrationRequestDTO)
        ▼
StubRegistrationRemoteDataSource пауза 3 с, проверки, RegistrationResponseDTO
        │
        ▼
RegistrationResponseMapper       DTO → RegistrationOutcome
        │
        ▼
RegistrationViewModel            раскладывает ошибки по полям, isSubmitting = false
        │  @Published state
        ▼
Верстка                          перерисовка
```

Запрос выполняется в `Task`, ссылка на который хранится в `submitTask`. Он же служит замком
от повторной отправки, а `defer` гарантирует снятие флага загрузки при любом исходе, включая
брошенное исключение.

---

## DI-контейнер

Свой минимальный контейнер в `Core/DI/DIContainer.swift`, без внешних библиотек.

**Регистрация** — по типу (обычно по протоколу), с фабричным замыканием, которому передаётся
резолвер для получения вложенных зависимостей:

```swift
container.register(RegistrationRepository.self, scope: .shared) { resolver in
    DefaultRegistrationRepository(remote: resolver.resolve(RegistrationRemoteDataSource.self))
}
```

**Области видимости** (`DIScope`):

| Scope | Поведение | Где используется |
|---|---|---|
| `.transient` | новый экземпляр на каждый `resolve` | use case |
| `.shared` | один экземпляр на контейнер | транспорт, репозиторий, фабрика экрана |

**Резолв** — `resolve(_:)` падает с понятным сообщением, если зависимость не зарегистрирована
(ошибка конфигурации видна сразу при запуске, а не позже). Есть мягкий вариант
`resolveIfRegistered(_:)`, возвращающий `nil`.

**Ассамблеи.** Зависимости регистрируются не одним списком, а по модулям — каждая фича описывает
свои в собственном `Assembly`. Благодаря этому новая фича не трогает чужой код:

```swift
protocol Assembly {
    func assemble(into container: DIContainer)
}
```

**Composition root.** Единственное место, где собирается всё приложение:

```swift
final class CompositionRoot {
    let container: DIContainer

    init() {
        container = DIContainer(assemblies: [
            NetworkAssembly(),
            RegistrationAssembly()
        ])
    }
}
```

Им владеет `AppDelegate`, `SceneDelegate` берёт его оттуда и передаёт резолвер координатору.
Экраны получают зависимости только через инициализаторы — service locator внутрь фич не протекает.

---

## Заглушка бэкенда

`StubRegistrationRemoteDataSource` имитирует сервер: держит паузу `Task.sleep(for: .seconds(3))`
и возвращает ответ **в том же формате**, что и настоящий бэкенд. Правила проверок живут только
здесь, клиент их не дублирует.

| Поле | Условие | Код | Текст |
|---|---|---|---|
| Логин | пусто | `login_required` | Обязательное поле |
| Логин | меньше 3 символов | `login_too_short` | Минимум 3 символа |
| Логин | входит в список занятых | `login_taken` | Введен существующий логин |
| Телефон | пусто | `phone_required` | Обязательное поле |
| Телефон | цифр не ровно 11 | `phone_length` | Длина должна быть 11 цифр |
| Телефон | не начинается на `79` или `89` | `phone_not_found` | Несуществующий номер |
| Email | пусто | `email_required` | Обязательное поле |
| Email | не проходит регулярку | `email_format` | Неверный формат |

Занятые логины по умолчанию: `admin`, `user`, `test`, `stacy`. Список и задержку можно
переопределить через инициализатор — удобно в тестах, чтобы не ждать три секунды.

Из телефона берутся только цифры, поэтому `+7 (900) 123-45-67` считается корректным номером.
По логину и телефону может прийти сразу несколько ошибок — это и проверяет вывод через запятую.

**Формат ответа:**

```json
{
  "status": "validation_error",
  "errors": [
    { "field": "login", "code": "login_taken",  "message": "Введен существующий логин" },
    { "field": "phone", "code": "phone_length", "message": "Длина должна быть 11 цифр" },
    { "field": "phone", "code": "phone_not_found", "message": "Несуществующий номер" }
  ]
}
```

```json
{ "status": "ok", "userId": "4C0F9F6E-..." }
```

---

## Работа с ошибками валидации

Требование «в любой момент на бэке могут добавиться новые ошибки» закрыто на трёх уровнях.

**Коды не перечисляются.** `ValidationMessage.code` — произвольная строка, а показывается
`message` от сервера. Новая ошибка на бэкенде начинает работать без релиза клиента.
Поле `code` нужно, чтобы позже можно было навесить особое поведение на конкретную ошибку
(например, аналитику или подсветку), не ломая остальные.

**Имена полей не перечисляются.** `FormFieldID` — строка, а не `enum`, поэтому маппер
не отбрасывает незнакомое поле.

**Незнакомые поля не теряются.** Вьюмодель раскладывает пришедшие ошибки на две группы:

```swift
if knownFields.contains(field) {
    errors[field] = texts          // ошибка под своим полем
} else {
    generalErrors.append(contentsOf: texts)   // общий блок под формой
}
```

Если сервер начнёт валидировать поле, которого ещё нет в приложении, пользователь всё равно
увидит текст ошибки — общим блоком под формой, а не молчаливо пустой экран.

**Сброс.** `valueChanged(_:for:)` очищает ошибки только того поля, которое правят,
а общие ошибки (включая сетевую) — при любом вводе. Перед новым запросом `submit()`
очищает всё состояние ошибок целиком.

**Сетевые сбои.** `RegistrationNetworkError` и любые другие исключения не роняют экран:
они превращаются в общее сообщение «Не удалось отправить данные…». `CancellationError`
игнорируется — экран уже закрыт, показывать нечего.

---

## Переключение UIKit ↔ SwiftUI

Обе верстки реализуют один протокол и отдают `UIViewController`; SwiftUI-экран приходит
завёрнутым в `UIHostingController`, поэтому навигация не меняется:

```swift
protocol RegistrationScreenFactory: AnyObject {
    func makeRegistrationScreen(onRegistered: @escaping (String) -> Void) -> UIViewController
}
```

Нужная фабрика выбирается в `RegistrationAssembly` по флагу. Чтобы перейти на SwiftUI,
меняется **одна строка** в `App/AppConfiguration.swift`:

```swift
enum AppConfiguration {
    static let uiFramework: UIFramework = .swiftUI   // было .uiKit
    static let backend: BackendKind = .stub
}
```

Ничего больше править не нужно: вьюмодель, use case, репозиторий, координатор и точка входа
остаются теми же. SwiftUI-экран намеренно не содержит собственного `NavigationStack` —
заголовок ставится через `.navigationTitle`, который прокидывается в `UINavigationController`
хостящего контроллера. Оба варианта проверены в симуляторе и выглядят одинаково.

Такой подход позволяет мигрировать постепенно, экран за экраном, а не всё приложение разом.

---

## Подключение реального бэкенда

`HTTPRegistrationRemoteDataSource` уже написан: `POST {baseURL}/registration` с JSON-телом,
декодирование ответа, статус `422` трактуется как валидационный ответ, а не как сбой.
Переключение — тоже одна строка:

```swift
static let backend: BackendKind = .http(baseURL: URL(string: "https://api.example.com")!)
```

Если формат тела у сервера другой, меняется только `RegistrationRequestDTO`
и `DefaultRegistrationRepository` — домен и презентация не затрагиваются.

---

## Как расширять приложение

**Добавить поле в форму.** Дописать элемент в `StaticRegistrationFormSchemaProvider`
и, при необходимости, константу в `FormFieldID`:

```swift
FormField(id: FormFieldID("promoCode"), title: "Промокод", contentKind: .text)
```

Верстка (обе), отправка значения на сервер и показ ошибок по этому полю заработают сами —
экран строится из схемы в цикле.

**Добавить новый тип клавиатуры.** Новый кейс в `FormFieldContentKind` плюс его маппинг
в двух приватных расширениях: в `FormFieldView.swift` и `RegistrationScreen.swift`.
Компилятор подскажет оба места.

**Добавить экран.** Создать папку в `Presentation`, описать вьюмодель и фабрику экрана,
завести свою `Assembly` и добавить её в список в `CompositionRoot`. Переходы — в координаторе:
сейчас `AppCoordinator` после успешной регистрации вызывает колбэк `onRegistered`, это
и есть готовая точка для следующего шага онбординга.

**Разделить на модули.** Границы слоёв уже совпадают с границами будущих SPM-пакетов:
`Domain` ни от чего не зависит, `Data` и `Presentation` зависят только от него, `App` знает всех.

---

## Тестирование

Отдельного тестового таргета в проекте нет. Архитектура к нему готова: все зависимости
задаются через инициализаторы и описаны протоколами, поэтому мокать можно на любом уровне.

Что стоит покрыть в первую очередь:

- **`RegistrationViewModel`** — с фейковым `RegisterUserUseCase`: блокировка повторной
  отправки, сброс ошибки при вводе, раскладка ошибок по полям, попадание незнакомого поля
  в общий блок, обработка сетевого сбоя.
- **`RegistrationResponseMapper`** — разбор ответа с незнакомым кодом и незнакомым полем.
- **`RegistrationViewState.errorText(for:)`** — склейка нескольких ошибок через запятую.
- **`StubRegistrationRemoteDataSource`** — правила проверок; задержку в тестах задавать
  через инициализатор (`latency: .zero`), чтобы не ждать три секунды.

Добавить таргет: в Xcode `File → New → Target → Unit Testing Bundle`.

---

## Отличия от шаблона Xcode

Из исходного шаблона удалены `Main.storyboard`, сгенерированные `ViewController`,
`AppDelegate`, `SceneDelegate` и неиспользуемая модель Core Data. Соответственно убраны
ключ `UISceneStoryboardFile` из `Info.plist` и настройка сборки
`INFOPLIST_KEY_UIMainStoryboardFile`. Окно и корневой контроллер создаются кодом
в `SceneDelegate`. `LaunchScreen.storyboard` оставлен — он нужен системе.
