# Flutter Map Application

A Flutter-based interactive map application using OpenStreetMap, featuring real-time location tracking, location search, and route display with detailed search history. This project integrates various features such as custom markers, route plotting, and satellite view toggle.

## Features

- 📍 **Real-time Location Tracking**: Automatically detects and displays the user’s current location.
- 🔍 **Location Search**: Search for any place using OpenStreetMap's geocoding services.
- 🗺️ **Custom Markers**: Add markers to locations of interest, or plot a route from your current position to a selected destination.
- 🚶 **Route Mapping**: Display walking routes between two points using OpenRouteService.
- 🌍 **Satellite View**: Toggle between standard and satellite views.
- 🧾 **Search & Route History**: View past search results and routes, with the ability to remove entries.
- 📜 **Location History Management**: Automatically save and display the last 10 searches/routes for quick access.

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/flutter-map-app.git
   cd flutter-map-app
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Set up your OpenRouteService API key:

   - Register for a free API key at [OpenRouteService](https://openrouteservice.org/sign-up/).
   - Replace the placeholder API key in `MapScreen.dart`

     ```dart
     final String _orsKey = 'YOUR_API_KEY_HERE';
     ```

4. Run the app:

   ```bash
   flutter run
   ```

## Usage

- **Location Search**: Enter a location in the search bar and tap on the result to see the map zoom in on that location.
- **Route Creation**: Tap anywhere on the map to place a marker and plot a walking route from your current location to that point.
- **View History**: Access previous searches or routes from the history page and tap to revisit them on the map.
  
## Dependencies

- [`flutter_map`](https://pub.dev/packages/flutter_map) for displaying OpenStreetMap tiles and markers.
- [`latlong2`](https://pub.dev/packages/latlong2) for handling geographical coordinates.
- [`location`](https://pub.dev/packages/location) for accessing the user's location.
- [`flutter_speed_dial`](https://pub.dev/packages/flutter_speed_dial) for the floating action menu.
- [`shared_preferences`](https://pub.dev/packages/shared_preferences) for local data storage.

## Contributing

Contributions are welcome! Feel free to submit a pull request or open an issue to report bugs, request new features, or ask questions.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
