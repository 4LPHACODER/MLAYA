import '../../domain/entities/recommended_spot_model.dart';

class ActivityWeatherAdvisor {
  const ActivityWeatherAdvisor();

  ActivitySafetyAdvice evaluate({
    required String activity,
    required SpotWeatherSnapshot weather,
  }) {
    final normalizedActivity = activity.toLowerCase().trim();
    final condition = weather.condition.toLowerCase();
    final isThunder = condition.contains('thunder');
    final isHeavyRain =
        condition.contains('heavy rain') ||
        condition.contains('extreme rain') ||
        condition.contains('drizzle');
    final isRain = condition.contains('rain');
    final hasDangerWind = weather.windSpeed >= 13;
    final hasModerateWind = weather.windSpeed >= 8;
    final tooHot = weather.temperature >= 34;
    final tooCold = weather.temperature <= 14;

    if (normalizedActivity == 'swimming') {
      if (isThunder || isHeavyRain || hasDangerWind) {
        return _avoid(
          'Unsafe water and wind conditions for swimming right now.',
        );
      }
      if (isRain || hasModerateWind) {
        return _caution('Conditions are changing; swim only with extra care.');
      }
      return _good('Calm conditions look suitable for swimming.');
    }

    if (normalizedActivity == 'surfing') {
      if (isThunder || hasDangerWind) {
        return _avoid('Wind and storm risk are too high for safe surfing.');
      }
      if (hasModerateWind) {
        return _good('Wind conditions can be suitable for surfing.');
      }
      return _caution(
        'Low wind may reduce wave quality; check local sea state.',
      );
    }

    if (normalizedActivity == 'camping') {
      if (isThunder || isHeavyRain) {
        return _avoid('Heavy rain or storms make camping unsafe.');
      }
      if (tooHot || tooCold || isRain) {
        return _caution(
          'Camp with extra prep due to temperature or rain risk.',
        );
      }
      return _good('Mild and dry conditions are good for camping.');
    }

    if (normalizedActivity == 'skateboarding') {
      if (isRain || isThunder) {
        return _avoid('Wet surfaces increase slip risk for skateboarding.');
      }
      if (hasDangerWind) {
        return _caution('Strong wind can affect balance and control.');
      }
      return _good('Dry weather is favorable for skateboarding.');
    }

    if (normalizedActivity == 'falls') {
      if (isThunder || isHeavyRain) {
        return _avoid('Heavy rain may increase unsafe water flow near falls.');
      }
      if (isRain) {
        return _caution('Paths near falls may be slippery; be careful.');
      }
      return _good(
        'Clear to light-cloud conditions look suitable for visiting.',
      );
    }

    if (normalizedActivity == 'hiking') {
      if (isThunder || isHeavyRain) {
        return _avoid('Storm and heavy rain conditions are unsafe for hiking.');
      }
      if (tooHot || isRain) {
        return _caution('Heat or rain can increase hiking risk; prepare well.');
      }
      return _good('Conditions look comfortable for hiking.');
    }

    if (isThunder || isHeavyRain) {
      return _avoid('Current weather is risky for most outdoor activities.');
    }
    if (isRain || hasDangerWind) {
      return _caution('Weather is variable; continue with caution.');
    }
    return _good('Weather is generally favorable for outdoor activities.');
  }

  ActivitySafetyAdvice _good(String explanation) {
    return ActivitySafetyAdvice(
      level: WeatherSafetyLevel.good,
      label: 'Good for this activity',
      explanation: explanation,
    );
  }

  ActivitySafetyAdvice _caution(String explanation) {
    return ActivitySafetyAdvice(
      level: WeatherSafetyLevel.caution,
      label: 'Use caution',
      explanation: explanation,
    );
  }

  ActivitySafetyAdvice _avoid(String explanation) {
    return ActivitySafetyAdvice(
      level: WeatherSafetyLevel.avoid,
      label: 'Avoid for now',
      explanation: explanation,
    );
  }
}
