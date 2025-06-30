# Flynse - Personal Finance Manager

<p align="center">
  <img src="assets/icon/flynse.png" alt="Flynse Icon" width="200"/>
</p>

**Flynse** is a comprehensive, locally-stored personal finance management application built with Flutter. It provides a modern, intuitive interface to help users track their income, expenses, savings, and debts, empowering them to take control of their financial lives.

## ✨ Key Features

Flynse is packed with features designed to provide a complete financial overview:

* **📊 Interactive Dashboard**: Get a quick overview of your financial status for any selected month or year. Includes a net balance summary, an income vs. expense vs. savings chart, and highlights of your spending habits.
* **💸 Transaction Management**:
    * Add, edit, and delete income, expense, and saving transactions.
    * Split a single expense into multiple sub-categories.
    * View a detailed transaction history with powerful filtering and search capabilities.
* **💰 Savings Tracker**:
    * Set and track progress towards your personal savings goals.
    * View your savings growth over time with an interactive chart.
    * See a breakdown of your savings by category (e.g., Bank, Investments).
* **💳 Advanced Debt Management**:
    * Track both debts you owe and loans you've given to friends.
    * Calculate and view a full amortization schedule for loans with interest.
    * Handle prepayments with options to either **reduce EMI** or **reduce tenure**.
    * Foreclose loans with optional penalty calculations.
* **👥 Friend & Social Lending**:
    * Manage a list of friends to easily track money lent or borrowed.
    * View a complete transaction history with any friend.
* **📈 Financial Analytics**:
    * Dive deep into your yearly and monthly financial data.
    * Visualize expense breakdowns with dynamic pie charts.
    * Analyze spending patterns by category and sub-category.
* **⚙️ Customization & Settings**:
    * Personalize your profile with a name and avatar.
    * Switch between **Light and Dark themes**.
    * Customize dashboard background colors for a unique look.
    * Manage transaction categories and sub-categories.
* **🔒 Security & Data**:
    * All data is stored **locally** on your device.
    * Secure the app with a **PIN lock** and **biometric authentication** (Fingerprint/Face ID).
    * **Backup** your data to a local folder and **Restore** it anytime.
    * Set up **automatic backups** (Daily, Weekly, Monthly).
    * Selectively or completely wipe application data.

---

## 🛠️ Tech Stack & Packages

* **Framework**: [Flutter](https://flutter.dev/)
* **State Management**: [Provider](https://pub.dev/packages/provider)
* **Database**: [sqflite](https://pub.dev/packages/sqflite) - Local SQLite database.
* **Charting**: [fl_chart](https://pub.dev/packages/fl_chart) - For beautiful and interactive charts.
* **Routing**: Centralized `AppRouter`.
* **UI Helpers**:
    * [google_fonts](https://pub.dev/packages/google_fonts)
    * [intl](https://pub.dev/packages/intl) for formatting.
    * [smooth_page_indicator](https://pub.dev/packages/smooth_page_indicator)
* **Utilities**:
    * [image_picker](https://pub.dev/packages/image_picker)
    * [file_picker](https://pub.dev/packages/file_picker)
    * [permission_handler](https://pub.dev/packages/permission_handler)
    * [local_auth](https://pub.dev/packages/local_auth) for biometrics.

---

## 🚀 Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

* You must have Flutter installed on your machine. For instructions, see the [official Flutter documentation](https://docs.flutter.dev/get-started/install).

### Installation

1.  **Clone the repository:**
    ```sh
    git clone [https://github.com/your-username/flynse.git](https://github.com/your-username/flynse.git)
    ```
2.  **Navigate to the project directory:**
    ```sh
    cd flynse
    ```
3.  **Install dependencies:**
    ```sh
    flutter pub get
    ```
4.  **Run the app:**
    ```sh
    flutter run
    ```

---

## 📁 Project Structure

The project is structured following clean architecture principles to ensure scalability and maintainability.

lib
├── core
│   ├── data
│   │   ├── repositories
│   │   ├── backup_service.dart
│   │   └── database_helper.dart
│   ├── providers
│   └── routing
├── features
│   ├── analytics
│   ├── dashboard
│   │   └── widgets
│   ├── debt
│   │   ├── data
│   │   │   ├── models
│   │   │   └── services
│   │   └── ui
│   │       ├── pages
│   │       └── widgets
│   ├── savings
│   │   └── widgets
│   ├── security
│   ├── settings
│   └── transaction
│       └── widgets
├── shared
│   ├── constants
│   ├── theme
│   └── utils
├── ui
└── main.dart
---

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
