MLAYA
A Mobile Weather Monitoring and Tourist Destination Recommendation System for Tandag City
MLAYA is a location-based mobile application designed to help residents, tourists, and outdoor enthusiasts monitor weather conditions, discover nearby tourist destinations, and receive recommendations for suitable outdoor activities in Tandag City.
The application combines weather monitoring, interactive maps, tourist-spot discovery, location services, activity recommendations, route guidance, saved destinations, and notifications in one mobile platform.
Overview
Planning an outdoor trip can be difficult when weather information, destination details, maps, and route guidance are spread across different applications.
MLAYA is designed to answer three practical questions:
1. What is the weather like in my current location or destination?
2. What tourist spots can I visit nearby?
3. What outdoor activities are suitable based on current weather conditions?
The system is intended to support more informed and convenient outdoor planning for residents and visitors in Tandag City.
Core Features
Weather Monitoring
- Current weather information
- Temperature and cloud conditions
- Humidity
- Wind speed
- Weather radar access
- Wind forecast
- Interactive weather map
- Map layers and refresh controls
Tourist Destination Discovery
- Search for nearby tourist destinations
- Location-based recommendations
- Destination name and address
- Distance from the user's location
- Attraction category
- Current weather condition at the destination
Outdoor Activity Filters
Users can explore destinations based on activities such as:
- Beach trips
- Hiking
- Camping
- Falls
- Fishing
- Other outdoor activities
Weather-Based Activity Recommendations
MLAYA provides activity recommendations based on available weather conditions.
The recommendation interface may classify activities into categories such as:
- Good For
- Avoid
Examples of activities that may be suggested under favorable conditions include:
- Walking
- Jogging
- Cycling
- Outdoor dining
- Drone flying
- Visiting outdoor tourist destinations
Important: MLAYA recommendations are intended to support user decisions. They do not replace official weather warnings, emergency advisories, or local government safety announcements.

Interactive Map
- Current location display
- Nearby destination exploration
- Zoom controls
- Current-location controls
- Weather layers
- Map refresh
- Location-aware tourism information
Route Guidance
Users can select a destination and access route information to support trip planning, especially for visitors who may not be familiar with the area.
Saved Destinations
Users can save places they want to revisit or include in future travel plans.
Weather Notifications
MLAYA can notify users about relevant outdoor weather conditions for their current location or selected places.
Example:
Good outdoor weather for hiking and outdoor activities near your current location.

User Authentication
- Email and password registration
- Login
- Google Sign-In
- Personalized access to saved destinations and notifications
Target Users
MLAYA is designed for:
- Tourists visiting Tandag City
- Local residents
- Outdoor travelers
- Hikers
- Beachgoers
- Campers
- Fishers
- Visitors looking for nearby attractions
- Users who want weather-aware outdoor planning
Technology Stack
The current project is built primarily with:
- Flutter
- Dart
- Supabase
- Google OAuth
- OpenWeather
- Mapbox
- Geoapify
- Location and mapping services
- Local notification services
Project Structure
A simplified view of the project structure:
lib/
├── core/
│   ├── config/
│   └── services/
│
├── features/
│   ├── auth/
│   ├── community/
│   ├── notifications/
│   ├── outdoor_recommendations/
│   ├── settings/
│   └── weather_map/
│
└── main.dart

assets/
└── images/

docs/
├── supabase_malaya_map_enhancements.sql
└── supabase_storage_setup.md
Getting Started
Prerequisites
Before running MLAYA, install:
- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code
- Git
- An Android emulator or physical Android device
Check your Flutter installation:
flutter doctor
Installation
1. Clone the repository
git clone git@github.com:4LPHACODER/MLAYA.git
2. Open the project
cd MLAYA
3. Install dependencies
flutter pub get
4. Configure environment variables
Create a local .env file based on .env.example.
cp .env.example .env
On Windows PowerShell:
Copy-Item .env.example .env
Add the required API credentials to your local .env file.
Example:
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

OPENWEATHER_API_KEY=your_openweather_api_key

MAPBOX_ACCESS_TOKEN=your_mapbox_access_token
MAPBOX_SECRET_ACCESS_TOKEN=your_mapbox_secret_access_token

GEOAPIFY_API_KEY=your_geoapify_api_key

SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
Never commit your real .env file, OAuth secrets, API keys, database credentials, or private access tokens to GitHub.

Your .gitignore should contain:
.env
5. Run the application
flutter run
Supabase Configuration
The repository includes supporting Supabase setup files under the docs/ directory.
Review:
docs/supabase_malaya_map_enhancements.sql
docs/supabase_storage_setup.md
Configure the required database tables, storage buckets, authentication settings, and policies before testing features that depend on Supabase.
Application Flow
A typical MLAYA user flow is:
Create Account / Login
        ↓
Allow Location Access
        ↓
View Weather Map
        ↓
Search Nearby Outdoor Spots
        ↓
Select Destination
        ↓
Review Destination Weather
        ↓
Check Activity Suitability
        ↓
Save Destination or Create Route
        ↓
Receive Weather Notifications
Main Use Case
A resident or tourist planning an outdoor activity can use MLAYA to:
1. Check weather conditions at the current location.
2. Explore nearby destinations.
3. Filter destinations based on preferred outdoor activities.
4. Review weather conditions for a selected destination.
5. View weather-based activity recommendations.
6. Save the destination.
7. Generate a route.
8. Receive relevant weather notifications.
Why MLAYA?
Outdoor tourism is highly affected by weather conditions. A destination may be attractive but unsuitable for a planned visit during heavy rain, strong winds, poor visibility, or other unfavorable conditions.
MLAYA connects weather information with destination discovery so users can make more informed travel decisions without constantly switching between separate weather, map, and tourism applications.
The platform aims to:
- Connect weather information with local tourist destinations
- Improve destination discovery
- Support weather-aware activity planning
- Provide location-based recommendations
- Support route planning
- Promote local attractions in Tandag City
- Help residents and visitors make better-informed outdoor decisions
Safety and Limitations
MLAYA is a decision-support application.
It should not be treated as a replacement for:
- PAGASA weather bulletins
- Official storm warnings
- Emergency alerts
- Local government advisories
- Disaster-response instructions
- On-site safety assessments
Users should always follow official advisories during severe or rapidly changing weather conditions.
Security
Sensitive configuration must be stored locally and excluded from Git.
Do not commit:
.env
API keys
OAuth client secrets
Supabase service-role keys
Private Mapbox tokens
Database credentials
If a secret is accidentally committed, remove it from Git history and rotate or revoke the affected credential.
Development Status
MLAYA is under active development.
Current development areas include:
- Authentication
- Weather-map integration
- Outdoor destination recommendations
- Route services
- Notifications
- User settings
- Community-related functionality
- Supabase integration
- UI and usability improvements
Future Enhancements
Potential future improvements may include:
- Expanded destination coverage
- Improved tourism information
- More configurable weather advisories
- Enhanced notification controls
- Better offline and low-connectivity support
- Additional activity categories
- Destination reviews and community contributions
- Improved recommendation logic
- Administrative destination management
- Analytics for tourism-related usage
Academic / Startup Context
MLAYA is being developed in the context of technology innovation and startup development associated with North Eastern Mindanao State University (NEMSU) and the SULIGAW Technology Business Incubator in Tandag City, Surigao del Sur.
Repository
GitHub:
git@github.com:4LPHACODER/MLAYA.git
Disclaimer
Weather and activity recommendations generated or presented by MLAYA are informational and intended to assist trip planning. Weather conditions can change rapidly. Users remain responsible for checking official weather warnings and assessing actual conditions before participating in outdoor activities.
License
Add the appropriate project license here if the repository will be distributed publicly.
Example:
MIT License
If the project is proprietary, academic-only, or restricted to the development team, replace this section with the applicable usage terms.
Acknowledgment
Developed for the improvement of weather-informed tourism and outdoor trip planning in Tandag City, Surigao del Sur, Philippines.
