# ✨ Alchemy Models: OpenAI Model Explorer ✨
Alchemy Models: OpenAI Model Explorer

----

[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS-blue)](https://developer.apple.com/swift/)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-orange)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](https://opensource.org/licenses/MIT)


---
Copyright (c) 2025 Cong Le. All Rights Reserved.

---

**A sleek SwiftUI app for browsing OpenAI models, showcasing robust API integration, dynamic data handling, and modern Swift concurrency.**




Ever wanted a quick way to see the latest models available from OpenAI, right from your device? Alchemy Models provides a clean interface to do just that. More importantly, this project serves as a practical example of several key iOS development techniques, especially useful for anyone learning SwiftUI, API integration, or managing different data sources.

You can seamlessly switch between reliable **mock data** (great for UI development and offline use) and **live data** fetched directly from the OpenAI API.

---

## Screenshots/Demo

*(Imagine adding screenshots/GIFs here to visually showcase the app)*

| List View (Mock/Live)        | Detail View                   | API Key Input                 | Error State                   |
| :--------------------------- | :---------------------------- | :---------------------------- | :---------------------------- |
| `[Screenshot Placeholder 1]` | `[Screenshot Placeholder 2]`  | `[Screenshot Placeholder 3]`  | `[Screenshot Placeholder 4]`  |
| *Browsing models with search*| *Detailed info & actions*     | *Sheet for entering API key* | *Handling API fetch errors*   |

---

## Key Features

*   **Browse OpenAI Models:** View a list of available models.
*   **Mock & Live Data:** Toggle between predefined mock data and real-time data from the OpenAI API.
*   **Search & Sort:** Easily find models by ID or sort them by ID or creation date.
*   **Detailed View:** Tap a model to see more information like owner, creation date, and (if available in mock data) capabilities, description, etc.
*   **API Key Management:** Securely prompts for and stores your OpenAI API key using `@AppStorage` when fetching live data.
*   **Modern SwiftUI Interface:** Built entirely with SwiftUI, leveraging `NavigationStack`, `@State`, `@AppStorage`, and `async/await`.
*   **Robust Error Handling:** Clearly displays errors encountered during API requests.
*   **Clean Architecture:** Utilizes a protocol (`APIServiceProtocol`) for fetching data, making it testable and flexible.

-----

## Techniques Showcased (Technical Deep Dive) 🧪

This project isn't just about the end result; it's a sandbox for demonstrating useful patterns:

1.  **`APIServiceProtocol` for Flexibility:**
    *   Defines a clear contract (`fetchModels()`) for how data is loaded.
    *   Allows easy swapping between `MockAPIService` and `LiveAPIService`.
    *   Great for testing: You can inject the mock service during UI tests or previews.
    *   Promotes separation of concerns: The view doesn't need to know the *details* of how data is fetched.

2.  **Mock vs. Live Data Toggle:**
    *   Uses a simple `@State var useMockData: Bool` and a `Toggle` control.
    *   The `currentApiService` computed property dynamically returns the correct service instance based on the toggle's state.
    *   `onChange(of: useMockData)` observer handles clearing state and triggering data reloads when the source changes, including managing the API key prompt logic.

3.  **`async/await` for Modern Concurrency:**
    *   Data fetching (`fetchModels()`) is an `async throws` function.
    *   SwiftUI's `.task` and `.refreshable` modifiers integrate seamlessly with `async/await` for initial loading and pull-to-refresh.
    *   Loading states (`isLoading`) are managed around asynchronous calls to provide user feedback (`ProgressView`).
    *   Error handling uses `do-catch` blocks to manage exceptions from the async tasks.

4.  **Clear Error Handling Strategy:**
    *   Custom error enums (`LiveAPIError`, `MockError`) conform to `LocalizedError` for user-friendly messages.
    *   The `LiveAPIService` catches specific network and decoding errors, wrapping them in `LiveAPIError` cases.
    *   The main view catches these errors, updates the `errorMessage` state variable, and conditionally displays a dedicated `ErrorView` with a retry action.

5.  **Practical API Key Handling (`@AppStorage` & Sheet):**
    *   Demonstrates prompting the user for sensitive data (like an API key) only when needed (switching to Live API without a key).
    *   Uses `@AppStorage` for simple local storage of the API key.
        *   **Note:** For production apps, `Keychain` is strongly recommended for storing sensitive data more securely. `@AppStorage` (UserDefaults) is less secure.
    *   A dedicated `APIKeyInputView` sheet provides a focused UI for key entry and basic validation.
    *   Callbacks (`onSave`, `onCancel`) decouple the sheet logic from the main view.

6.  **Resilient `Codable` Data Modeling:**
    *   The `OpenAIModel` struct uses default values (e.g., `description = "No description available."`).
    *   `CodingKeys` selectively includes properties expected from the live API (`id`, `object`, `created`, `owned_by`).
    *   This makes the *same* model struct work seamlessly with both detailed mock data (where `description`, etc., are provided directly) and the live API data (where those fields might be missing, falling back to the defaults).

7.  **Reusable SwiftUI Components:**
    *   `ModelCardView`: A well-defined view for displaying a single model in the list.
    *   `ModelDetailView`: A dedicated view for showing all details.
    *   `WrappingHStack`: A custom layout container useful for displaying tags or capabilities that wrap to the next line.
    *   `ErrorView`: A generic view for displaying error messages with a retry button.

8.  **UI Polish:**
    *   `.searchable` modifier for easy filtering.
    *   `Menu` with a `Picker` for sorting options.
    *   Dynamic profile images/colors based on the model owner (`profileSymbolName`, `profileBackgroundColor` in `OpenAIModel` extension).
    *   Use of materials (`.regularMaterial`), padding, and shadows for a modern look.

----

## How to Use

1.  Clone or download the repository.
2.  Open the `.xcodeproj` file in Xcode.
3.  Run the app on a simulator or device.
    *   By default, it uses **Mock Data**. No API key is needed.
4.  **To use Live Data:**
    *   Tap the toggle at the bottom toolbar to switch to "Using Live API".
    *   If you haven't entered an API key before, a sheet will appear prompting you to enter your OpenAI API key.
    *   Enter your valid key (starting with `sk-...`) and tap "Save".
    *   The app will then attempt to fetch live models from OpenAI.
    *   Your key is saved locally using `@AppStorage` for future sessions.

-----

## Getting Started (for Developers)

```bash
# Clone the repository
git clone https://github.com/your-username/alchemy-models.git # Replace with your actual repo URL

# Open the project in Xcode
cd alchemy-models
open AlchemyModels.xcodeproj # Or your project file name
```

Build and run! Explore the code, especially:

*   `OpenAIModelsCardView.swift`: The main view controller logic.
*   `APIService*.swift`: The `LiveAPIService` and `MockAPIService` implementations.
*   `APIKeyInputView.swift`: The sheet for key handling.
*   `OpenAIModel.swift`: The data model and its extensions/Codable setup.

----

## Future Ideas & Contributing

This is a foundational example. Potential improvements could include:

*   **Keychain Integration:** Store the API key securely in the Keychain.
*   **More Model Details:** Fetch individual model details from the `/v1/models/{model_id}` endpoint if needed.
*   **Pagination:** Handle large numbers of models if the API supports it.
*   **Filtering Options:** Add more sophisticated filtering beyond just search.
*   **UI Enhancements:** Animations, custom transitions.
*   **Testing:** Adding Unit and UI tests.

Feel free to fork the repository, experiment, and suggest improvements via Pull Requests!


---

## ❤️ Contributing

Found a bug or have an improvement? Feel free to open an issue or submit a pull request! Contributions are welcome.

---

## 📜 License

- **MIT License:**  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) - Full text in [LICENSE](LICENSE) file.
- **Creative Commons Attribution 4.0 International:** [![License: CC BY 4.0](https://licensebuttons.net/l/by/4.0/88x31.png)](LICENSE-CC-BY) - Legal details in [LICENSE-CC-BY](LICENSE-CC-BY) and at [Creative Commons official site](http://creativecommons.org/licenses/by/4.0/).

---

[Back to Top](#top)

