# GDG Event Badges - Deployment Scaffold

This repository provides a scaffold for deploying a GDG Event Badges system, consisting of a Dart web frontend (GitHub Pages) and a Dart backend (Google Cloud Run). The backend is responsible for generating and deploying attendance certificates to GitHub Pages.

## Project Structure

*   `backend/`: Contains the Dart server application.
*   `frontend/`: Contains the Dart web application.
*   `.github/workflows/`: Contains GitHub Actions workflows for automated deployment.

## Setup Instructions

Follow these steps to set up and deploy your GDG Event Badges system.

### 1. Create a New GitHub Repository

Start by creating a new, empty GitHub repository.

### 2. Copy Project Files

Copy the contents of this scaffold (`backend/`, `frontend/`, `.github/`) into the root of your new GitHub repository.

### 3. GitHub Pages Configuration

Enable GitHub Pages for your repository:
1.  Go to your repository's **Settings** tab.
2.  Navigate to **Pages** in the left sidebar.
3.  Under "Build and deployment", select **Deploy from a branch**.
4.  Choose `gh-pages` as the branch and `/ (root)` as the folder.
5.  Click **Save**.

### 4. Google Cloud Project Setup

You will need a Google Cloud Project with the Cloud Run and Cloud Build APIs enabled.
You also need a Service Account for GitHub Actions to authenticate with Google Cloud. This Service Account needs the following roles:
*   **Cloud Build Editor** (to build the Docker image)
*   **Cloud Run Admin** (to deploy the service)
*   **Storage Object Admin** (to push the Docker image to Container Registry)

To create this service account and download its JSON key:
1.  Go to **IAM & Admin -> Service Accounts** in your Google Cloud Console.
2.  Click "**CREATE SERVICE ACCOUNT**".
3.  Give it a name (e.g., "github-actions-deployer").
4.  Grant the roles "Cloud Build Editor", "Cloud Run Admin", and "Storage Object Admin".
5.  Create a new JSON key and download it. This JSON content will be used for `GCP_CREDENTIALS`.

### 5. GitHub Secrets Configuration

You need to set up the following secrets in your GitHub repository. These secrets are crucial for your GitHub Actions workflows to function correctly.

1.  Go to your repository's **Settings** tab.
2.  Navigate to **Secrets and variables -> Actions** in the left sidebar.
3.  Click **New repository secret**.

#### `GCP_CREDENTIALS`

This secret will securely store the content of your Google Cloud service account key JSON file. GitHub Actions will use this to authenticate with Google Cloud for deployments.

*   **Name:** `GCP_CREDENTIALS`
*   **Value:** Paste the entire JSON content of your downloaded Google Cloud service account key file.

#### `GCP_PROJECT_ID`

This secret stores your Google Cloud Project ID.

*   **Name:** `GCP_PROJECT_ID`
*   **Value:** Enter your Google Cloud Project ID (e.g., `my-gcp-project-12345`).

#### `GH_PAGES_DEPLOY_TOKEN`

This secret stores a GitHub Personal Access Token (PAT) that the backend server will use to commit generated certificate files to the `gh-pages` branch of *this same repository*.

**Security Warning:** This PAT needs `repo` scope, which grants broad access to your repository. Ensure you understand the security implications. For enhanced security, consider using a GitHub App installation token if your use case allows.

To generate a PAT:
1.  Go to your GitHub **Settings -> Developer settings -> Personal access tokens -> Tokens (classic)**.
2.  Click **Generate new token (classic)**.
3.  Give it a descriptive name (e.g., "GDG Event Badges Deploy Token").
4.  Set its expiration.
5.  Under "Select scopes", check the `repo` scope (all sub-options).
6.  Click **Generate token**.
7.  **Copy the token immediately** – you won't be able to see it again.

*   **Name:** `GH_PAGES_DEPLOY_TOKEN`
*   **Value:** Paste the GitHub Personal Access Token you just generated.

### 6. Initial Push and Deployment

Once you have copied all files and configured the GitHub Pages and GitHub Secrets, push your changes to the `main` branch of your new repository.

This push will trigger two GitHub Actions workflows:
*   `frontend-deploy.yml`: Builds and deploys your frontend to GitHub Pages.
*   `backend-deploy.yml`: Builds and deploys your backend to Google Cloud Run.

Monitor the "Actions" tab in your GitHub repository to ensure both deployments succeed.

### 7. Update Frontend with Backend URL

After the backend is deployed to Cloud Run, you will get a service URL. You will need to update your frontend to point to this URL.

1.  Go to the "Actions" tab, find the successful `Deploy Backend to Cloud Run` workflow run, and get the "Service URL" from its logs.
2.  Update the `frontend/lib/main.dart` (or relevant file) in your repository to use this Cloud Run URL for API calls.
3.  Commit and push this change to the `main` branch. This will re-trigger the frontend deployment with the correct backend URL.

### Local Development

#### Prerequisites

*   [Dart SDK](https://dart.dev/get-dart) installed.

#### Backend

1.  Navigate to the `backend/` directory: `cd backend`
2.  Install dependencies: `dart pub get`
3.  Set environment variables (replace with your actual values):
    ```bash
    export GCP_PROJECT_ID="your-gcp-project-id"
    export GITHUB_REPO_OWNER="your-github-username-or-org"
    export GITHUB_REPO_NAME="your-repo-name"
    export GH_PAGES_DEPLOY_TOKEN="your-github-pat"
    export PORT="8080" # Or any desired port
    ```
4.  Run the server: `dart run bin/server.dart`

#### Frontend

1.  Navigate to the `frontend/` directory: `cd frontend`
2.  Install dependencies: `dart pub get`
3.  Run the development server: `dart run build_runner serve`
    *   You might need to update the backend URL in `frontend/lib/main.dart` to `http://localhost:8080` (or your local backend port) for local testing.
