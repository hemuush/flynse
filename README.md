<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Flynse - Personal Finance Manager</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Inter', sans-serif;
            background-color: #f8f9fa;
            color: #212529;
        }
        .dark body {
            background-color: #121212;
            color: #e9ecef;
        }
        .container {
            max-width: 900px;
        }
        h1, h2, h3 {
            font-weight: 800;
            letter-spacing: -0.02em;
        }
        h1 { font-size: 2.5rem; }
        h2 { font-size: 1.75rem; margin-top: 2.5rem; border-bottom: 2px solid #e0e0e0; padding-bottom: 0.5rem; margin-bottom: 1.5rem; }
        .dark h2 { border-color: #343a40; }
        h3 { font-size: 1.25rem; margin-top: 2rem; margin-bottom: 1rem; }
        .feature-list li {
            margin-bottom: 1rem;
            display: flex;
            align-items: flex-start;
        }
        .feature-list .icon {
            margin-right: 1rem;
            margin-top: 0.25rem;
            color: #007AFF;
            flex-shrink: 0;
        }
        .dark .feature-list .icon { color: #58A6FF; }
        .tag {
            display: inline-block;
            background-color: #e9ecef;
            color: #495057;
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.875rem;
            font-weight: 500;
            margin: 0.25rem;
        }
        .dark .tag {
            background-color: #343a40;
            color: #ced4da;
        }
        .code-block {
            background-color: #e9ecef;
            border-radius: 0.5rem;
            padding: 1rem;
            font-family: 'Courier New', Courier, monospace;
            white-space: pre-wrap;
            word-wrap: break-word;
            color: #212529;
        }
        .dark .code-block {
            background-color: #212529;
            color: #f8f9fa;
        }
        .project-structure {
            background-color: #e9ecef;
            border-radius: 0.5rem;
            padding: 1.5rem;
            font-family: 'Courier New', Courier, monospace;
            font-size: 0.875rem;
            line-height: 1.5;
            color: #495057;
        }
        .dark .project-structure {
            background-color: #1c1c1e;
            color: #adb5bd;
        }
    </style>
</head>
<body class="dark:bg-gray-900 dark:text-gray-100">
    <div class="container mx-auto p-4 md:p-8">

        <div class="text-center mb-12">
            <img src="https://raw.githubusercontent.com/hemuush/flynse/main/assets/icon/flynse.png" alt="Flynse Icon" class="w-48 h-48 mx-auto mb-4">
            <h1 class="text-5xl font-extrabold text-gray-800 dark:text-white">Flynse</h1>
            <p class="text-xl text-gray-500 dark:text-gray-400 mt-2">Your Modern Personal Finance Manager</p>
        </div>

        <p class="text-lg text-center text-gray-600 dark:text-gray-300 mb-12">
            <strong>Flynse</strong> is a comprehensive, locally-stored personal finance management application built with Flutter. It provides a modern, intuitive interface to help users track their income, expenses, savings, and debts, empowering them to take control of their financial lives.
        </p>

        <!-- Key Features Section -->
        <h2>✨ Key Features</h2>
        <ul class="feature-list list-none p-0">
            <li>
                <span class="icon">📊</span>
                <div>
                    <strong>Interactive Dashboard:</strong> Get a quick overview of your financial status for any selected month or year. Includes a net balance summary, an income vs. expense vs. savings chart, and highlights of your spending habits.
                </div>
            </li>
            <li>
                <span class="icon">💸</span>
                <div>
                    <strong>Transaction Management:</strong> Add, edit, and delete income, expense, and saving transactions. Split a single expense into multiple sub-categories, and view a detailed transaction history with powerful filtering and search capabilities.
                </div>
            </li>
            <li>
                <span class="icon">💰</span>
                <div>
                    <strong>Savings Tracker:</strong> Set and track progress towards your personal savings goals. View your savings growth over time with an interactive chart and see a breakdown of your savings by category (e.g., Bank, Investments).
                </div>
            </li>
            <li>
                <span class="icon">💳</span>
                <div>
                    <strong>Advanced Debt Management:</strong> Track both debts you owe and loans you've given to friends. Calculate and view a full amortization schedule for loans with interest, handle prepayments with options to either <strong>reduce EMI</strong> or <strong>reduce tenure</strong>, and foreclose loans with optional penalty calculations.
                </div>
            </li>
            <li>
                <span class="icon">👥</span>
                <div>
                    <strong>Friend & Social Lending:</strong> Manage a list of friends with custom avatars to easily track money lent or borrowed. The app automatically handles the complex logic of creating, updating, and settling debts between you and your friends. View a complete transaction history with any friend.
                </div>
            </li>
             <li>
                <span class="icon">📈</span>
                <div>
                    <strong>In-Depth Financial Analytics:</strong> Dive deep into your yearly and monthly financial data. Visualize expense breakdowns with dynamic pie charts and analyze spending patterns by category, sub-category, debt, or friend.
                </div>
            </li>
            <li>
                <span class="icon">🗓️</span>
                <div>
                    <strong>Flexible Planning:</strong> Choose your salary cycle (start or end of the month) to accurately plan your finances for the upcoming period, allowing you to select future months for budgeting.
                </div>
            </li>
            <li>
                <span class="icon">⚙️</span>
                <div>
                    <strong>Customization & Settings:</strong> Personalize your profile with a name and avatar. Switch between <strong>Light and Dark themes</strong>, customize dashboard background colors for a unique look, and manage transaction categories and sub-categories.
                </div>
            </li>
            <li>
                <span class="icon">🔒</span>
                <div>
                    <strong>Security & Data Privacy:</strong> All data is stored <strong>locally</strong> on your device. Secure the app with a <strong>PIN lock</strong> and <strong>biometric authentication</strong> (Fingerprint/Face ID). <strong>Backup</strong> your data to a local folder and <strong>Restore</strong> it anytime. Set up <strong>automatic backups</strong> (Daily, Weekly, Monthly) for peace of mind.
                </div>
            </li>
        </ul>

        <!-- Tech Stack Section -->
        <h2>🛠️ Tech Stack & Packages</h2>
        <div class="flex flex-wrap">
            <span class="tag">Flutter</span>
            <span class="tag">Provider</span>
            <span class="tag">sqflite</span>
            <span class="tag">fl_chart</span>
            <span class="tag">google_fonts</span>
            <span class="tag">intl</span>
            <span class="tag">image_picker</span>
            <span class="tag">file_picker</span>
            <span class="tag">permission_handler</span>
            <span class="tag">local_auth</span>
            <span class="tag">flutter_colorpicker</span>
            <span class="tag">smooth_page_indicator</span>
            <span class="tag">uuid</span>
        </div>

        <!-- Getting Started Section -->
        <h2>🚀 Getting Started</h2>
        <h3>Prerequisites</h3>
        <p class="mb-4">You must have Flutter installed on your machine. For instructions, see the <a href="https://docs.flutter.dev/get-started/install" class="text-blue-500 hover:underline">official Flutter documentation</a>.</p>
        
        <h3>Installation</h3>
        <ol class="list-decimal list-inside space-y-2">
            <li><strong>Clone the repository:</strong>
                <div class="code-block mt-2">git clone https://github.com/hemuush/flynse.git</div>
            </li>
            <li><strong>Navigate to the project directory:</strong>
                <div class="code-block mt-2">cd flynse</div>
            </li>
            <li><strong>Install dependencies:</strong>
                <div class="code-block mt-2">flutter pub get</div>
            </li>
            <li><strong>Run the app:</strong>
                <div class="code-block mt-2">flutter run</div>
            </li>
        </ol>

        <!-- Project Structure Section -->
        <h2>📁 Project Structure</h2>
        <div class="project-structure">
            <pre>
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
└── main.dart</pre>
        </div>

        <!-- Contributing Section -->
        <h2>🤝 Contributing</h2>
        <p>Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are <strong>greatly appreciated</strong>.</p>
        <p class="mt-4">If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".</p>
        <ol class="list-decimal list-inside space-y-2 mt-4">
            <li>Fork the Project</li>
            <li>Create your Feature Branch (`git checkout -b feature/AmazingFeature`)</li>
            <li>Commit your Changes (`git commit -m 'Add some AmazingFeature'`)</li>
            <li>Push to the Branch (`git push origin feature/AmazingFeature`)</li>
            <li>Open a Pull Request</li>
        </ol>

        <!-- License Section -->
        <h2>📄 License</h2>
        <p>Distributed under the MIT License. See `LICENSE` for more information.</p>

    </div>
</body>
</html>
