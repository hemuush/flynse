Flynse
<p align="center">
<img src="https://raw.githubusercontent.com/hemuush/flynse/main/assets/icon/flynse.png" alt="Flynse Icon" width="200"/>
</p>
<p align="center">
<strong>Your Modern Personal Finance Manager</strong>
</p>

<p align="center">
<strong>Flynse</strong> is a comprehensive, locally-stored personal finance management application built with Flutter. It provides a modern, intuitive interface to help users track their income, expenses, savings, and debts, empowering them to take control of their financial lives.
</p>

📸 Screenshots
Dashboard

Debt Management

<img src="https://placehold.co/600x1200/007AFF/FFFFFF?text=Dashboard" alt="Dashboard Screenshot" width="250"/>

<img src="https://placehold.co/600x1200/FF6B6B/FFFFFF?text=Debt+Management" alt="Debt Management Screenshot" width="250"/>

Financial Analytics

Add Transaction

<img src="https://placehold.co/600x1200/34C759/FFFFFF?text=Analytics" alt="Analytics Screenshot" width="250"/>

<img src="https://placehold.co/600x1200/5856D6/FFFFFF?text=Add+Transaction" alt="Add Transaction Screenshot" width="250"/>

<p align="center">
<strong>App Demo</strong><br>
<img src="https://placehold.co/800x450/121212/FFFFFF?text=App+Demo+GIF" alt="App Demo GIF" />
</p>

✨ Key Features
📊 Interactive Dashboard: Get a quick overview of your financial status for any selected month or year. Includes a net balance summary, an income vs. expense vs. savings chart, and highlights of your spending habits.

💸 Transaction Management: Add, edit, and delete income, expense, and saving transactions. Split a single expense into multiple sub-categories, and view a detailed transaction history with powerful filtering and search capabilities.

💰 Savings Tracker: Set and track progress towards your personal savings goals. View your savings growth over time with an interactive chart and see a breakdown of your savings by category (e.g., Bank, Investments).

💳 Advanced Debt Management: Track both debts you owe and loans you've given to friends. Calculate and view a full amortization schedule for loans with interest, handle prepayments with options to either reduce EMI or reduce tenure, and foreclose loans with optional penalty calculations.

👥 Friend & Social Lending: Manage a list of friends with custom avatars to easily track money lent or borrowed. The app automatically handles the complex logic of creating, updating, and settling debts between you and your friends. View a complete transaction history with any friend.

📈 In-Depth Financial Analytics: Dive deep into your yearly and monthly financial data. Visualize expense breakdowns with dynamic pie charts and analyze spending patterns by category, sub-category, debt, or friend.

🗓️ Flexible Planning: Choose your salary cycle (start or end of the month) to accurately plan your finances for the upcoming period, allowing you to select future months for budgeting.

⚙️ Customization & Settings: Personalize your profile with a name and avatar. Switch between Light and Dark themes, customize dashboard background colors for a unique look, and manage transaction categories and sub-categories.

🔒 Security & Data Privacy: All data is stored locally on your device. Secure the app with a PIN lock and biometric authentication (Fingerprint/Face ID). Backup your data to a local folder and Restore it anytime. Set up automatic backups (Daily, Weekly, Monthly) for peace of mind.

🛠️ Tech Stack & Packages
Flutter Provider sqflite fl_chart google_fonts intl image_picker file_picker permission_handler local_auth flutter_colorpicker smooth_page_indicator uuid

🚀 Getting Started
Prerequisites
You must have Flutter installed on your machine. For instructions, see the official Flutter documentation.

Installation
Clone the repository:

git clone https://github.com/hemuush/flynse.git

Navigate to the project directory:

cd flynse

Install dependencies:

flutter pub get

Run the app:

flutter run

📁 Project Structure
lib
├── core
│   ├── data
│   │   ├── repositories
│   │   ├── backup_service.dart
│   │   └── database_helper.dart
│   ├── providers
│   └── routing
│       └── app_router.dart
├── features
│   ├── analytics
│   ├── dashboard
│   ├── debt
│   ├── savings
│   ├── security
│   ├── settings
│   └── transaction
├── shared
│   ├── constants
│   ├── theme
│   ├── utils
│   └── widgets
├── ui
│   ├── home_page.dart
│   ├── onboarding_page.dart
│   └── splash_screen.dart
└── main.dart

🤝 Contributing
Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are greatly appreciated.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".

Fork the Project

Create your Feature Branch (git checkout -b feature/AmazingFeature)

Commit your Changes (git commit -m 'Add some AmazingFeature')

Push to the Branch (git push origin feature/AmazingFeature)

Open a Pull Request

📄 License
Distributed under the MIT License. See LICENSE for more information.