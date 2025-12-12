# GitHub Secrets Setup for Android Signed Builds

This guide explains how to set up GitHub repository secrets for the Flutter CI/CD workflow to build signed Android APKs and AABs.

## Generated Keystore & Properties

A sample keystore has been generated locally with:
- **Keystore File**: `android/keystore.jks`
- **Key Alias**: `upload`
- **Store Password**: `change_me_storepass`
- **Key Password**: `change_me_keypass`

> ⚠️ **IMPORTANT**: The generated keystore and `key.properties` are in `.gitignore` and NOT committed to the repo (for security). You must do this setup locally and add secrets to GitHub.

## Step 1: Generate Your Own Keystore (Recommended for Production)

For a production release key, generate a new keystore with strong passwords:

```bash
./scripts/generate_keystore.sh android/release.jks myalias mystore_password mykey_password
```

This will:
1. Create `android/release.jks` (the keystore file)
2. Create/update `android/key.properties` with the configuration
3. Print the base64-encoded keystore

**Keep the output safe!** You'll need it for GitHub Secrets.

## Step 2: Add Repository Secrets on GitHub

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** and add these 4 secrets:

| Secret Name | Value | Example |
|-------------|-------|---------|
| `ANDROID_KEYSTORE` | Base64-encoded keystore (from step 1) | `/u3+7QAAAAIAAAABAAAAxc...` (long string) |
| `KEYSTORE_PASSWORD` | Store password | `change_me_storepass` |
| `KEY_ALIAS` | Key alias | `upload` |
| `KEY_PASSWORD` | Key password | `change_me_keypass` |

### Example: Adding `ANDROID_KEYSTORE` secret

If you ran `./scripts/generate_keystore.sh android/release.jks upload mystore mykey`, the script printed the base64. Copy that entire output and paste it as the `ANDROID_KEYSTORE` secret value.

## Step 3: Commit & Push to Trigger Workflow

After adding secrets to GitHub:

```bash
git add .
git commit -m "Enable Android signing for CI builds"
git push origin fix/flutter-version
```

Or manually trigger the workflow:
- Go to **Actions** → **Build Flutter artifacts (APKs & AABs)** → **Run workflow** → Select branch `fix/flutter-version`

## Step 4: Check Workflow Output

1. Go to **Actions** in your repository
2. Click **Build Flutter artifacts (APKs & AABs)**
3. Watch the latest run — if secrets are configured, you'll see:
   - ✅ Keystore decoded and `key.properties` written
   - ✅ Admin, Barber, and Customer APKs built
   - ✅ AABs (app bundles) built
   - ✅ Artifacts uploaded

## Step 5: Download APKs/AABs

Once the workflow completes successfully:

1. Click the completed workflow run
2. Scroll to **Artifacts** section
3. Download `flutter-apks` and/or `flutter-aabs`

### APK Locations (in workflow)
- `build/app/outputs/flutter-apk/app-{admin,barber,customer}-release.apk`
- Split APKs per ABI (if `--split-per-abi` was used)

### AAB Locations (in workflow)
- `build/app/outputs/bundle/{admin,barber,customer}Release/app-release.aab`

## Troubleshooting

### Secrets not recognized
- Ensure secrets are named exactly: `ANDROID_KEYSTORE`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`
- Wait a few seconds after adding secrets; they may not be immediately available

### Build fails with "keystore password was incorrect"
- Double-check the `KEYSTORE_PASSWORD` value matches the password used when generating the keystore
- Verify `KEY_PASSWORD` and `KEY_ALIAS` match as well

### Keystore base64 format invalid
- Ensure you copied the **entire** base64 string from the script output
- Remove any extra whitespace or line breaks when pasting into GitHub

### Workflow skipped the signing step
- Check if `secrets.ANDROID_KEYSTORE` is empty; the workflow only decodes it if set
- Go to Settings → Secrets and verify all 4 secrets are present

## Local Build (Without CI)

To build locally with the keystore:

```bash
flutter build apk -t lib/main_admin.dart --release
flutter build apk -t lib/main_barber.dart --release
flutter build apk -t lib/main_customer.dart --release

# Or build App Bundles for Play Store
flutter build appbundle -t lib/main_admin.dart --release
flutter build appbundle -t lib/main_barber.dart --release
flutter build appbundle -t lib/main_customer.dart --release
```

The `build.gradle.kts` will automatically use the signing config from `android/key.properties` if it exists.

## Best Practices

1. **Never commit `keystore.jks` or `key.properties` to the repo** — they contain sensitive data.
2. **Use a strong, unique password** for production keystores.
3. **Backup the keystore file** securely (outside the repo).
4. **Rotate keystores periodically** for enhanced security.
5. **Different keystore per environment**: Consider separate keystores for dev, staging, and production.

## References

- [Flutter: Build and release an Android app](https://docs.flutter.dev/deployment/android)
- [Android: Sign your app](https://developer.android.com/studio/publish/app-signing)
- [GitHub Actions: Using secrets](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
