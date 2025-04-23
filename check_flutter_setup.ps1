Write-Host "?? Checking Flutter installation..."
flutter --version

Write-Host "`n?? Checking Dart installation..."
dart --version

Write-Host "`n?? Checking Flutter doctor..."
flutter doctor

Write-Host "`n?? Validating pubspec.yaml dependencies..."
flutter pub get

Write-Host "`n?? Running basic analyzer checks..."
flutter analyze

Write-Host "`n? All checks done. You are ready to generate APK if no errors were shown above!"
