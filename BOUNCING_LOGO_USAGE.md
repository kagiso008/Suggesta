# Bouncing Logo Loading Animation

The `BouncingLogo` widget provides an engaging loading animation that can be used throughout the app (except on the splash screen where it's already implemented).

## Widget Location
`lib/shared/widgets/bouncing_logo.dart`

## Basic Usage

```dart
import '../../shared/widgets/bouncing_logo.dart';

// Simple bouncing logo
BouncingLogo(
  imagePath: 'assets/images/app_logo.png',
  width: 80,
  height: 80,
)

// With custom bounce parameters
BouncingLogo(
  imagePath: 'assets/images/app_logo.png',
  width: 100,
  height: 100,
  bounceDuration: const Duration(milliseconds: 600),
  bounceHeight: 0.3,
  showShadow: true,
  shadowColor: Colors.black.withOpacity(0.2),
  shadowBlurRadius: 15,
)
```

## Using as a Loading Indicator

### Example 1: Full-screen loading
```dart
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BouncingLogo(
              imagePath: 'assets/images/app_logo.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 24),
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
```

### Example 2: Inline loading within a widget
```dart
Widget build(BuildContext context) {
  return Column(
    children: [
      // Your content here
      if (isLoading)
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              BouncingLogo(
                imagePath: 'assets/images/app_logo.png',
                width: 60,
                height: 60,
                bounceDuration: const Duration(milliseconds: 500),
              ),
              const SizedBox(height: 12),
              Text(
                'Fetching data...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
    ],
  );
}
```

### Example 3: Overlay loading
```dart
void showLoadingOverlay(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BouncingLogo(
                imagePath: 'assets/images/app_logo.png',
                width: 80,
                height: 80,
              ),
              const SizedBox(height: 16),
              Text(
                'Processing...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
```

## Widget Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `imagePath` | `String` | **Required** | Path to the image asset |
| `width` | `double` | `120` | Width of the logo |
| `height` | `double` | `120` | Height of the logo |
| `bounceDuration` | `Duration` | `800ms` | Duration of one bounce cycle |
| `bounceHeight` | `double` | `0.2` | Bounce height as fraction of logo height (0.0 to 1.0) |
| `showShadow` | `bool` | `true` | Whether to show shadow |
| `shadowColor` | `Color` | `Colors.black38` | Color of the shadow |
| `shadowBlurRadius` | `double` | `10.0` | Blur radius of the shadow |

## Integration with State Management

The widget automatically manages its animation lifecycle. It starts animating when built and stops when disposed. You can control visibility using conditional rendering:

```dart
// Show when loading
if (isLoading) {
  return Center(
    child: BouncingLogo(
      imagePath: 'assets/images/app_logo.png',
      width: 100,
      height: 100,
    ),
  );
}
```

## Performance Considerations

- The animation uses Flutter's built-in animation system optimized for performance
- The widget disposes animation controllers properly to prevent memory leaks
- Consider using smaller sizes (e.g., 60x60) for inline loading to reduce visual weight
- For multiple bouncing logos on the same screen, each maintains its own animation controller

## Customization Tips

1. **Faster bounce**: Use `bounceDuration: const Duration(milliseconds: 400)` for quicker feedback
2. **Subtle bounce**: Use `bounceHeight: 0.1` for a more subtle effect
3. **No shadow**: Set `showShadow: false` for a flatter design
4. **Theme integration**: Use `shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3)` to match app theme

## Already Implemented

The bouncing logo is already implemented on the splash screen (`lib/features/auth/presentation/screens/splash_screen.dart`) with the following configuration:
- Width: 120, Height: 120
- Bounce duration: 800ms
- Bounce height: 0.25 (25% of height)
- Shadow color: Primary theme color with 30% opacity
- Shadow blur radius: 20

You can reuse this same widget anywhere in the app by importing it from the shared widgets directory.