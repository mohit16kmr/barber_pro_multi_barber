# Codespaces Setup - Technical Reference

## Requirements
- GitHub account (free)
- Internet connection
- Browser (Chrome, Firefox, Safari, Edge)

## What Gets Installed Automatically
The `.devcontainer/devcontainer.json` ensures:

1. **Flutter SDK** - Latest version
2. **Dart SDK** - Bundled with Flutter
3. **Android SDK** - For Android development
4. **VS Code Extensions**:
   - Dart Code (official)
   - Flutter (official)
   - Dart Test Tree
   - Code Spell Checker
   - GitHub Copilot

## Environment Variables
Create `.env` file in project root:
```
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-email@firebase.iam.gserviceaccount.com
FIREBASE_DATABASE_URL=your-database-url
```

## Available Commands

### Flutter Commands
```bash
# Check setup
flutter doctor

# Get dependencies
flutter pub get

# Analyze code
flutter analyze

# Run on Chrome (web)
flutter run -d chrome -t lib/main_customer.dart

# Build APK for Android
flutter build apk -t lib/main_customer.dart

# Build iOS
flutter build ios -t lib/main_customer.dart

# Run tests
flutter test

# Clean build
flutter clean
```

### Git Commands
```bash
# Push changes
git push origin main

# Pull changes
git pull origin main

# Create new branch
git checkout -b feature/my-feature

# Commit
git add .
git commit -m "commit message"
```

## Performance Tips
1. Use Chrome for web testing (faster)
2. Close unused files in VS Code
3. Stop Codespace when not using (save credits)
4. Use VS Code built-in terminal

## Forwarded Ports
- **3000** - Backend API (if running)
- **6379** - Redis (if needed)
- **5037** - Android Debug Bridge (ADB)

These ports are automatically forwarded if you run services.

## Troubleshooting

### Slow Performance
- Close unused files/extensions
- Restart Codespace: More actions → Rebuild container

### Gradle Build Fails
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Dart/Flutter Not Found
```bash
# Refresh environment
exit
# Reopen terminal
flutter doctor
```

### Storage Full
```bash
flutter clean
rm -rf build/
git clean -fd
```

## Cost Information (as of 2024)
- **Free tier**: 120 CPU hours/month per user
- **Paid**: $0.18/hour after free quota
- **Storage**: 15GB included, $0.07/GB/day for additional

## Pro Tips
1. Use VS Code keyboard shortcuts for efficiency
2. Enable GitHub Copilot for faster coding
3. Push regularly to avoid data loss
4. Test on Chrome first (faster than physical devices)
5. Use `.gitignore` properly for large files

## Switching to Local Development
When you want to develop locally again:
```bash
# Clone from GitHub
git clone https://github.com/YOUR_USERNAME/newbarberproject.git
cd newbarberproject
flutter pub get
```

Happy coding! 🚀
