# Upgrade to Java 21 (LTS) — Diary Garden (Android module)

This repository's Android module has been updated to target Java 21 (LTS).

Summary of changes made:
- Updated `android/app/build.gradle.kts`:
  - compileOptions: sourceCompatibility/targetCompatibility -> Java 21
  - kotlinOptions.jvmTarget -> "21"
- Installed JDK 21 on the local environment used for this upgrade (path: `C:\Users\user\.jdk\jdk-21.0.8` in upgrade run)

Notes and next steps for developers & CI:

1. Install JDK 21 locally and set JAVA_HOME

   Windows PowerShell (example):

   ```powershell
   # Set JAVA_HOME for the current session
   $env:JAVA_HOME='C:\Path\to\jdk-21'

   # Run a Gradle build from repo root (android module)
   Push-Location "android"; .\gradlew.bat assembleDebug; Pop-Location
   ```

2. CI / GitHub Actions / Build servers

   - Ensure CI workers are configured to use JDK 21 as `JAVA_HOME` / `java-version` for steps that build the Android module.

3. Android Studio / Local IDE

   - Set the JDK used for Gradle to a JDK 21 installation (via ``Settings → Build, Execution, Deployment → Build Tools → Gradle``).
   - Ensure Kotlin plugin and Android Gradle Plugin versions used are compatible with Java 21. (This repo currently uses AGP 8.9.1 and Kotlin 2.1.0.)

4. Why this change is manual

   - The Java upgrade tooling (generate_upgrade_plan/openrewrite flow) didn't support Android module structure in this workspace, so the upgrade here was performed by
     - updating the Android Gradle Kotlin DSL configuration
     - installing JDK 21 on the upgrade runner
     - validating a full Gradle build with the new JDK

If you want me to attempt a wider automated upgrade flow (generate_upgrade_plan -> openrewrite) for a pure Java / Maven/Gradle project in this repo, I can try — but the Android module requires the manual steps above.
