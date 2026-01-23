# sportal_mobile

A Flutter project for the Sportal mobile application.

---

## Deployment Instructions

Follow the steps below to deploy the web version of the Sportal mobile app using `peanut` and GitHub Pages.

### 1. Update versioning

* Update the **version number** in `pubspec.yaml`.
* Update the **version displayed on the splash screen** (if applicable).

### 2. Commit your changes

```bash
git add .
git commit -m "chore: bump version and prepare for deployment"
```

### 3. Push changes to the web app branch

```bash
git push origin web-app
```

### 4. Clean up existing `gh-pages` branch

Delete the local `gh-pages` branch:

```bash
git branch -D gh-pages
```

Delete the remote `gh-pages` branch on GitHub:

```bash
git push origin --delete gh-pages
```

### 5. Build and deploy using Peanut

Run the following command to generate and deploy the web build:

```bash
flutter pub global run peanut
```

### 6. Push the new `gh-pages` branch

```bash
git push origin --set-upstream gh-pages
```

---

### Notes

* Ensure `peanut` is installed globally before running the deploy command.
* Make sure you are on the correct branch before starting the deployment process.
* This process recreates the `gh-pages` branch on every deployment.
