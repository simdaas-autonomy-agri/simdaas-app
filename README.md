# Simdaas

A comprehensive Flutter application for agricultural management and precision farming. Simdaas enables farmers and operators to manage plots, schedule jobs, monitor equipment, and track data in real-time.

## Features

- **Authentication**: Secure user login and role-based access (Admin, Technician, Operator)
- **Plot Mapping**: Create and manage agricultural plots with polygon boundaries, area calculations, and visual previews
- **Job Planning**: Schedule and manage spraying jobs with product mixes, timing, and status tracking
- **Equipment Management**: Track tractors, sprayers, and control units with linked plots and real-time status
- **Data Monitoring**: Real-time monitoring of ongoing jobs with sensor data and analytics
- **Dashboard Views**: Multiple dashboards for different user roles with quick access to key metrics
- **QR Code Integration**: Quick equipment setup and data entry via QR codes

## Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Mapping**: LatLong2 for geographic coordinates
- **UI Components**: Material Design with custom widgets
- **Architecture**: Clean Architecture with domain/data/presentation layers

## Prerequisites

- Flutter SDK (3.x or later)
- Dart SDK (3.x or later)
- Android Studio or VS Code with Flutter extensions
- Firebase project with Auth and Firestore enabled
- Git for version control

## Installation

1. **Clone the repository**:

   ```bash
   git clone https://github.com/simdaas-autonomy-agri/simdaas-app
   cd simdaas
   ```

2. **Install dependencies**:

   ```bash
   flutter pub get
   ```

3. **Add the API URL**:

    in lib/core/config.dart

4. **Run the app**:

   ```bash
   flutter run
   ```

## Project Structure

```text
lib/
├── core/                    # Core utilities and services
│   ├── errors/             # Error handling
│   ├── services/           # API, Auth, and other services
│   ├── theme/              # App theming
│   └── widgets/            # Shared UI components
├── features/               # Feature modules
│   ├── auth/               # Authentication
│   ├── plot_mapping/       # Plot creation and management
│   ├── job_planner/        # Job scheduling and management
│   ├── equipments/         # Equipment tracking
│   ├── data_monitoring/    # Real-time data monitoring
│   └── home/               # Dashboard screens
├── temp_features/          # Temporary/development features
└── main.dart               # App entry point
```

## Usage

### For Developers

1. **Development Setup**:
   - Use `flutter analyze` to check code quality
   - Run tests with `flutter test`

2. **Key Providers**:
   - `authServiceProvider`: User authentication
   - `plotsListProvider`: Plot data
   - `controlUnitsProvider`: Equipment status
   - `jobsListProvider`: Job management

3. **Current Development Focus**:
   - **Temp Dashboard**: Developer-focused dashboard showing control unit statuses with plot name resolution
   - **Equipment Linking**: Control units now link to default plots (`linkedPlotId`)
   - **UI Improvements**: Fixed overflow issues in plot details screen, enhanced form field locking for QR-prefilled data

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow Flutter's effective Dart guidelines
- Use Riverpod for state management
- Maintain clean architecture separation
- Run `flutter analyze` before committing

## Testing

Run the test suite:

```bash
flutter test
```

For integration tests:

```bash
flutter test integration_test/
```

## Deployment

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

## License

This project is proprietary. See LICENSE file for details.

## Support

For questions or issues:

- Create an issue in the repository
- Contact the development team

---

Built with ❤️ using Flutter
