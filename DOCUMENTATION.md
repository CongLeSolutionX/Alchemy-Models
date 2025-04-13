---
created: 2025-04-13 05:31:26
author: Cong Le
version: "1.0"
license(s): MIT, CC BY 4.0
copyright: Copyright (c) 2025 Cong Le. All Rights Reserved.
---



# Alchemy Models - A Diagrammatic Guide
> **Disclaimer:**
>
> This document contains my personal notes on the topic,
> compiled from publicly available documentation and various cited sources.
> The materials are intended for educational purposes, personal study, and reference.
> The content is dual-licensed:
> 1. **MIT License:** Applies to all code implementations (Swift, Mermaid, and other programming languages).
> 2. **Creative Commons Attribution 4.0 International License (CC BY 4.0):** Applies to all non-code content, including text, explanations, diagrams, and illustrations.
---


Here's a documentation focusing on concepts and complexities, illustrated with Mermaid diagrams:

**Code Summary:**

*   **`OpenAIModelsCardView`:** The main SwiftUI view, managing state (models, loading, errors, sorting, search, API key sheet), fetching data via an `APIServiceProtocol`, and displaying the list or error/loading states. It uses `NavigationStack` for navigation to `ModelDetailView`.
*   **`APIServiceProtocol`:** Defines the contract for fetching models, allowing for mock (`MockAPIService`) and live (`LiveAPIService`) implementations.
*   **`MockAPIService`:** Provides hardcoded sample `OpenAIModel` data, simulating network delay.
*   **`LiveAPIService`:** Fetches models from the actual OpenAI `/v1/models` endpoint using `URLSession` and `async/await`. It retrieves the API key from `@AppStorage`. Handles various API errors (`LiveAPIError`).
*   **`APIKeyInputView`:** A sheet view allowing users to enter and save their OpenAI API key to `@AppStorage`.
*   **`OpenAIModel`:** The `Codable`, `Identifiable`, and `Hashable` data structure representing an OpenAI model. It uses `CodingKeys` for custom JSON mapping (`owned_by`) and includes default values for properties not present in the basic `/v1/models` response (`description`, `capabilities`, etc.), ensuring consistency with the mock data structure. An extension provides UI-related computed properties (`profileSymbolName`, `profileBackgroundColor`).
*   **Helper Views:** `ModelCardView` (row item), `ModelDetailView`, `ErrorView`, `WrappingHStack` (for tags/capabilities).
*   **Enums:** `SortOption`, `LiveAPIError`, `MockError`.

**Key Complexities & Concepts Illustrated:**

1.  **Component Interaction & Dependency:** How the main view orchestrates interactions between UI, state, data services, and the API key input mechanism.
2.  **State Management & UI Updates:** The flow of state changes (`isLoading`, `errorMessage`, `allModels`, `useMockData`, `showingApiKeySheet`) and how they drive UI updates.
3.  **Conditional API Service:** The dynamic switching between `MockAPIService` and `LiveAPIService` based on the `useMockData` toggle.
4.  **API Key Handling Logic:** The intricate process of checking for the API key, prompting the user if needed, saving the key, and then triggering the API call.
5.  **Data Loading & Error Propagation:** The `async/await` flow for fetching data, including error catching and updating the UI state accordingly.
6.  **Data Model Flexibility:** How `OpenAIModel` handles data from both mock sources (with extra details) and the live API (with fewer details) using default values and `CodingKeys`.

---

## Mermaid Diagrams:

### 1. High-Level Component Interaction

This diagram shows the main components and their primary relationships.

```mermaid
---
title: "High-Level Component Interaction"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  layout: elk
  look: handDrawn
  theme: dark
---
%%%%%%%% Mermaid version v11.4.1-b.14
%%%%%%%% Toggle theme value to `base` to activate the initilization below for the customized theme version.
%%%%%%%% Available curve styles include the following keywords:
%% basis, bumpX, bumpY, cardinal, catmullRom, linear, monotoneX, monotoneY, natural, step, stepAfter, stepBefore.
%%{
  init: {
    'graph': { 'htmlLabels': false, 'curve': 'linear' },
    'fontFamily': 'Monospace',
    'themeVariables': {
      'primaryColor': '#BEF',
      'primaryTextColor': '#55ff',
      'primaryBorderColor': '#7c2',
      'lineColor': '#F8B229',
      'secondaryColor': '#EE2',
      'tertiaryColor': '#fff',
      'stroke':'#3323',
      'stroke-width': '0.5px'
    }
  }
}%%
graph TD
    subgraph UserInterface["User Interface"]
        direction LR
        MainView[OpenAIModelsCardView]
        DetailView[ModelDetailView]
        CardView[ModelCardView]
        ErrorDisp[ErrorView]
        KeyInput[APIKeyInputView]
        LoadingDisp[ProgressView]
        SearchSort[Search/Sort UI]
    end

    subgraph StateManagement["State Management<br/>(@State, @AppStorage)"]
        ModelsState["allModels:<br/>[OpenAIModel]"]
        LoadingState["isLoading: Bool"]
        ErrorState["errorMessage: String?"]
        SortState["currentSortOrder: SortOption"]
        SearchState["searchText: String"]
        ApiModeState["useMockData: Bool"]
        SheetState["showingApiKeySheet: Bool"]
        ApiKeyStore["@AppStorage('userOpenAIKey')"]
    end

    subgraph Services["API Services"]
        ApiServiceProto["APIServiceProtocol"]
        MockService["MockAPIService"] --> ApiServiceProto
        LiveService["LiveAPIService"] --> ApiServiceProto
    end

    subgraph DataLayer["Data Layer"]
        Model["OpenAIModel"]
        Response["ModelListResponse"]
        Errors["LiveAPIError / MockError"]
        URLSession["URLSession"]
    end

    subgraph External["External Dependencies"]
        OpenAI_API["OpenAI /v1/models API"]
        UserDefaults["UserDefaults<br/>(via @AppStorage)"]
    end

    %% Connections
    MainView -- Manages/Updates --> StateManagement
    StateManagement -- Drives --> UserInterface

    MainView -- Uses --> ApiServiceProto
    MainView -- Presents --> KeyInput
    KeyInput -- Reads/Writes --> ApiKeyStore
    KeyInput -- Updates State --> SheetState
    ApiKeyStore -- Accessed by --> LiveService
    ApiKeyStore -- Read/Write --> UserDefaults

    MainView -- Triggers Load --> LiveService
    MainView -- Triggers Load --> MockService

    LiveService -- Interacts with --> URLSession
    URLSession -- Calls --> OpenAI_API
    LiveService -- Uses --> Model
    LiveService -- Uses --> Response
    LiveService -- Handles/Throws --> Errors

    MockService -- Returns --> Model
    MockService -- Handles/Throws --> Errors

    MainView -- Displays --> CardView
    MainView -- Navigates to --> DetailView
    MainView -- Displays --> ErrorDisp
    MainView -- Displays --> LoadingDisp
    MainView -- Uses --> SearchSort

    CardView -- Displays data from --> Model
    DetailView -- Displays data from --> Model
    ErrorDisp -- Displays --> ErrorState

    LiveService -- Reads --> ApiKeyStore
```

**Explanation:** This diagram illustrates the dependencies between the UI views, state management variables, API services (following the `APIServiceProtocol`), data models/errors, and external systems like the OpenAI API and `UserDefaults`. It highlights how the `OpenAIModelsCardView` acts as the central coordinator.

---

### 2. Data Loading Flow (Happy Path & Mock/Live Switch)

This diagram shows the sequence of events when loading data, triggered by the user or view appearance, including the logic for choosing the API service.

```mermaid
---
title: "Data Loading Flow (Happy Path & Mock/Live Switch)"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  layout: elk
  look: handDrawn
  theme: dark
---
%%%%%%%% Mermaid version v11.4.1-b.14
%%%%%%%% Toggle theme value to `base` to activate the initilization below for the customized theme version.
%%%%%%%% Available curve styles include the following keywords:
%% basis, bumpX, bumpY, cardinal, catmullRom, linear, monotoneX, monotoneY, natural, step, stepAfter, stepBefore.
%%{
  init: {
    'graph': { 'htmlLabels': false, 'curve': 'linear' },
    'fontFamily': 'Monospace',
    'themeVariables': {
      'primaryColor': '#BEF',
      'primaryTextColor': '#55ff',
      'primaryBorderColor': '#7c2',
      'lineColor': '#F8B229',
      'secondaryColor': '#EE2',
      'tertiaryColor': '#fff',
      'stroke':'#3323',
      'stroke-width': '0.5px'
    }
  }
}%%
graph TD
    A["Trigger Load Models"] --> B{"Is Loading?"}
    B -- Yes --> Z["Exit"]
    B -- No --> C["Set isLoading = true"]
    C --> D{"Use Mock Data?"}
    D -- Yes --> E["Instantiate MockAPIService"]
    D -- No --> F{"API Key Exists in @AppStorage?"}
    F -- Yes --> G["Instantiate LiveAPIService"]
    F -- No --> H["Show API Key Input Sheet"]
    H --> I{"Key Saved?"}
    I -- Yes --> G
    I -- No --> J["Revert to Mock Data, Set isLoading = false"]
    J --> Z

    subgraph Fetch ["Fetch Operation<br/>(async)"]
        direction LR
        E --> K["Call mock.fetchModels()"]
        G --> L["Call live.fetchModels()"]
        K --> M{"Success?"}
        L --> M
        M -- Yes --> N["Decode/Receive Models"]
        M -- No --> O["Catch Error"]
    end

    N -- @MainActor --> P["Update allModels State"]
    N -- @MainActor --> Q["Set errorMessage = nil"]
    O -- @MainActor --> R["Update errorMessage State"]
    O -- @MainActor --> S["Optionally Clear Models"]

    P --> T["Set isLoading = false"]
    Q --> T
    R --> T
    S --> T
    T --> U["Update UI<br/>(List/ErrorView)"]
    U --> Z

    style Fetch fill:#f9f3,stroke:#333,stroke-width:2px

```


**Explanation:** This flowchart details the logic within `attemptLoadModels`, `loadModelsAsyncWithLoadingState`, and `loadModelsAsync`. It shows the checks for `isLoading`, `useMockData`, and the API key's presence (`@AppStorage`). It explicitly shows the path to presenting the `APIKeyInputView` sheet if the live API is selected but the key is missing. The `@MainActor` annotation implies UI updates happen on the main thread after the async fetch completes.

---

### 3. API Key Handling and Live API Trigger Logic

This diagram focuses specifically on the complex interaction triggered by the `Toggle` and the `APIKeyInputView`.

```mermaid
---
title: "API Key Handling and Live API Trigger Logic"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  layout: elk
  look: handDrawn
  theme: dark
---
%%%%%%%% Mermaid version v11.4.1-b.14
%%%%%%%% Toggle theme value to `base` to activate the initilization below for the customized theme version.
%%%%%%%% Available curve styles include the following keywords:
%% basis, bumpX, bumpY, cardinal, catmullRom, linear, monotoneX, monotoneY, natural, step, stepAfter, stepBefore.
%%{
  init: {
    'graph': { 'htmlLabels': false, 'curve': 'linear' },
    'fontFamily': 'Monospace',
    'themeVariables': {
      'primaryColor': '#BEF',
      'primaryTextColor': '#55ff',
      'primaryBorderColor': '#7c2',
      'lineColor': '#F8B229',
      'secondaryColor': '#EE2',
      'tertiaryColor': '#fff',
      'stroke':'#3323',
      'stroke-width': '0.5px'
    }
  }
}%%
graph TD
    A["Toggle 'Use Mock Data' Changed"] --> B{"New Value:<br/>Live API<br/>(false)?"}
    B -- "No<br/>(Using Mock)" --> C["Clear State<br/>(Models, Error)"]
    C --> D["Load Mock Data via loadModelsAsyncWithLoadingState"]
    D --> X["End"]

    B -- "Yes<br/>(Switching to Live)" --> E["Clear State<br/>(Models, Error)"]
    E --> F{"Check if API Key stored in @AppStorage is Empty?"}
    F -- "Yes<br/>(Key is Missing)" --> G["Set showingApiKeySheet = true"]
    G --> H("Present APIKeyInputView Sheet")

    subgraph APIKeyInputView_Interaction
        direction LR
        H --> I{"User Action"}
        I -- Save Tapped --> J{"API Key Input Field Empty?"}
        J -- Yes --> K["Show Validation Error<br/>(isInvalidKeyAttempt=true)"]
        K --> H
        J -- No --> L["Save Key to @AppStorage"]
        L --> M["Call onSave Callback"]
        M --> N["Dismiss Sheet"]

        I -- Cancel Tapped --> O["Call onCancel Callback"]
        O --> P["Dismiss Sheet"]
    end

    N --> Q["Load Live Data via loadModelsAsyncWithLoadingState"]
    P --> R["Revert Toggle:<br/>useMockData = true"]
    R --> X

    F -- "No<br/>(Key Exists)" --> Q

    Q --> X

    style APIKeyInputView_Interaction fill:#e2ff,stroke:#333,stroke-width:1px

```

**Explanation:** This flowchart details the steps initiated when the `useMockData` toggle changes, particularly when switching *to* the Live API. It shows the check for the stored key, the presentation of the `APIKeyInputView`, the actions within that view (Save/Cancel), and the subsequent triggering of the live data load or reverting the toggle if canceled.

---

### 4. State Management Cycle in `OpenAIModelsCardView`

This diagram illustrates the primary states of the main view and the transitions between them.

```mermaid
---
title: "State Management Cycle in `OpenAIModelsCardView`"
config:
  theme: dark
---
%%%%%%%% Mermaid version v11.4.1-b.14
%%%%%%%% Available curve styles include the following keywords:
%% basis, bumpX, bumpY, cardinal, catmullRom, linear, monotoneX, monotoneY, natural, step, stepAfter, stepBefore.
%%{
  init: {
    'stateDiagram-v2': { 'htmlLabels': false},
    'fontFamily': 'verdana',
    'themeVariables': {
      'primaryColor': '#B528',
      'primaryTextColor': '#2cf',
      'primaryBorderColor': '#7C33',
      'lineColor': '#F8B229',
      'secondaryColor': '#0610',
      'tertiaryColor': '#fff'
    }
  }
}%%
stateDiagram-v2
    direction LR
    [*] --> Idle : App Starts / View Appeared

    Idle --> Loading : .task / Refresh / Toggle Change (if key exists or mock)
    Idle --> PromptingForKey : Toggle Change (Live, no key) / Attempt Load (Live, no key)

    Loading --> DisplayingData : Load Success (Models received)
    Loading --> DisplayingError : Load Failure (Error received)

    DisplayingData --> Loading : Refresh / Toggle Change
    DisplayingData : User Filters/Sorts/Searches
    DisplayingData : Navigates to Detail View

    DisplayingError --> Loading : Retry Tapped / Refresh / Toggle Change
    DisplayingError: Shows ErrorView

    PromptingForKey --> Loading : Key Saved in Sheet
    PromptingForKey --> Idle : Cancelled Sheet (Reverts Toggle to Mock)

    Loading : Shows ProgressView
    DisplayingData : Shows List / ContentUnavailable
```

**Explanation:** This state diagram shows the lifecycle of the `OpenAIModelsCardView`. It starts `Idle`, moves to `Loading` when data fetch begins, then transitions to either `DisplayingData` or `DisplayingError`. It also shows the `PromptingForKey` state, entered when the live API is needed but the key is missing, and how it transitions back based on user action in the sheet. Actions like filtering/sorting happen within the `DisplayingData` state.

---

### 5. `LiveAPIService` Error Handling Flow

This diagram shows how errors are handled within the `LiveAPIService`.

```mermaid
---
title: "`LiveAPIService` Error Handling Flow"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  layout: elk
  look: handDrawn
  theme: dark
---
%%%%%%%% Mermaid version v11.4.1-b.14
%%%%%%%% Toggle theme value to `base` to activate the initilization below for the customized theme version.
%%%%%%%% Available curve styles include the following keywords:
%% basis, bumpX, bumpY, cardinal, catmullRom, linear, monotoneX, monotoneY, natural, step, stepAfter, stepBefore.
%%{
  init: {
    'graph': { 'htmlLabels': false, 'curve': 'linear' },
    'fontFamily': 'Monospace',
    'themeVariables': {
      'primaryColor': '#BEF',
      'primaryTextColor': '#55ff',
      'primaryBorderColor': '#7c2',
      'lineColor': '#F8B229',
      'secondaryColor': '#EE2',
      'tertiaryColor': '#fff',
      'stroke':'#3323',
      'stroke-width': '0.5px'
    }
  }
}%%
graph TD
    A["fetchModels() called"] --> B{"Check API Key"}
    B -- "Key Missing/Empty" --> C["Throw LiveAPIError.missingAPIKey"]
    B -- Key Present --> D["Build URLRequest"]
    D --> E["URLSession.shared.data(for: request)"]

    subgraph URLSessionTryCatch["try await URLSession..."]
        direction TB
        E --> F{"Error During Network Request?"}
        F -- Yes --> G["Catch Error"]
        G --> H["Throw LiveAPIError.networkError(error)"]

        F -- No --> I["Received<br/>(data, response)"]
        I --> J{"Response is HTTPURLResponse?"}
        J -- No --> K["Throw LiveAPIError.requestFailed(statusCode: 0)"]
        J -- Yes --> L("httpResponse")
        L --> M{"Status Code 401<br/>(Unauthorized)?"}
        M -- Yes --> N["Throw LiveAPIError.missingAPIKey<br/>(Invalid Key)"]
        M -- No --> O{"Status Code 200-299?"}
        O -- No --> P["Throw LiveAPIError.requestFailed(statusCode)"]
        O -- Yes --> Q["Try Decoding Response"]
    end

     subgraph JSONDecodeTryCatch["try decoder.decode..."]
         direction TB
         Q --> R{"Error During Decoding?"}
         R -- Yes --> S["Catch Error"]
         S --> T["Throw LiveAPIError.decodingError(error)"]
         R -- No --> U["Return Decoded<br/>[OpenAIModel]"]
     end

     C --> Z["Propagate Error to Caller<br/>(View)"]
     H --> Z
     K --> Z
     N --> Z
     P --> Z
     T --> Z
     U --> Y["Return Result to Caller<br/>(View)"]

    style URLSessionTryCatch fill:#fee2,stroke:#333,stroke-width:1px
    style JSONDecodeTryCatch fill:#e6ff,stroke:#333,stroke-width:1px
```

**Explanation:** This flowchart breaks down the error handling within `LiveAPIService.fetchModels`. It shows the initial API key check, the `try/catch` block around the `URLSession` call (handling network errors and non-2xx status codes, specifically 401), and the nested `try/catch` block for JSON decoding. Each potential failure point maps to a specific `LiveAPIError` case, which is then thrown and eventually caught by the `OpenAIModelsCardView` to update the `errorMessage` state.

---

### 6. `OpenAIModel` Structure & Codable Handling

This diagram illustrates the structure of the data model and how `Codable` interacts with it, especially regarding default values.

```mermaid
---
title: "`OpenAIModel` Structure & Codable Handling"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  layout: elk
  look: handDrawn
  theme: dark
---
%%%%%%%% Mermaid version v11.4.1-b.14
%%{
  init: {
    'classDiagram': { 'htmlLabels': false},
    'fontFamily': 'Monospace',
    'themeVariables': {
      'primaryColor': '#B28',
      'primaryTextColor': '#F8B229',
      'primaryBorderColor': '#7C33',
      'secondaryColor': '#0615'
    }
  }
}%%
classDiagram
    direction LR
    class OpenAIModel {
        +String id
        +String object
        +Int created
        +String ownedBy
        +String description = "No description available."
        +[String] capabilities = ["general"]
        +String contextWindow = "N/A"
        +[String] typicalUseCases = ["Various tasks"]
        +Date createdDate (computed)
        +String profileSymbolName (computed)
        +Color profileBackgroundColor (computed)
        +hash(into: Hasher)
        +static ==(lhs, rhs) bool
    }

    class CodingKeys {
        <<enumeration>>
        case id
        case object
        case created
        case ownedBy = "owned_by"
        -- Not Included --
        description
        capabilities
        contextWindow
        typicalUseCases
    }

    class ModelListResponse {
        + [OpenAIModel] data
    }

    OpenAIModel ..> CodingKeys : Uses for JSON Mapping
    ModelListResponse --> OpenAIModel : Contains array of
```

**Explanation:** This class diagram shows the properties of the `OpenAIModel`. Critically, it highlights which properties are included in the `CodingKeys` enum (and thus actively mapped during JSON decoding) and which are not. Because `description`, `capabilities`, `contextWindow`, and `typicalUseCases` are *not* in `CodingKeys`, Swift's `Codable` synthesis ignores them when decoding JSON from the `/v1/models` endpoint. If the JSON doesn't provide these keys, the properties retain their default initialized values. This design allows the struct to be used consistently with both the detailed mock data and the less detailed live API data. The diagram also shows the simple `ModelListResponse` wrapper used for decoding the overall API response.




---
**Licenses:**

- **MIT License:**  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) - Full text in [LICENSE](LICENSE) file.
- **Creative Commons Attribution 4.0 International:** [![License: CC BY 4.0](https://licensebuttons.net/l/by/4.0/88x31.png)](LICENSE-CC-BY) - Legal details in [LICENSE-CC-BY](LICENSE-CC-BY) and at [Creative Commons official site](http://creativecommons.org/licenses/by/4.0/).

---