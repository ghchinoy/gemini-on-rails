# Gemini on Rails

This is a simple Ruby on Rails application to demonstrate how to use the Gemini API with a Google Cloud Vertex AI project.

## Prerequisites

*   Ruby & Bundler
*   A Google Cloud account and project with the Vertex AI API enabled.
*   A Google Cloud service account with the "Vertex AI User" role. You will need the JSON key file for this service account.

## Setup Instructions

1.  **Install Dependencies:**
    Open your terminal, navigate to the `gemini-rails` directory, and run:
    ```bash
    bundle install
    ```

2.  **Configure Credentials:**
    This application uses Rails' encrypted credentials to store your Google Cloud Project ID and region. You also need to point to your service account key.

    a. **Set the Project Details:** Run the following command to edit the credentials.
    ```bash
    EDITOR=nano bin/rails credentials:edit
    ```
    This will open a temporary, decrypted file in the "nano" editor. Add the following configuration, replacing the values with your own:
    ```yaml
    google:
      vertex_ai:
        project_id: your-gcp-project-id
        region: us-central1
    ```
    Save the file and exit the editor (in nano, press `Ctrl+X`, then `Y`, then `Enter`).

    b. **Set Up Application Default Credentials (ADC):**
    The `gemini-ai` gem uses a standard Google Cloud authentication method called ADC. To set it up, point the following environment variable to the path of your service account JSON key file. You can add this line to your shell profile (e.g., `.zshrc`, `.bash_profile`).

    ```bash
    export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/service-account-key.json"
    ```
    *Remember to reload your shell or open a new terminal window after setting this.*

## Running the Application

1.  **Start the Server:**
    ```bash
    bin/rails server
    ```

2.  **Open Your Browser:**
    Navigate to `http://localhost:3000`.

You should see a simple page with a text area. Enter a prompt and see the response from the Gemini API!

## Deployment to Cloud Run

This application is configured for deployment to Google Cloud Run. The following steps were taken to deploy it:

1.  **Create Artifact Registry Repo:**
    ```bash
    gcloud artifacts repositories create gemini-rails-repo --repository-format=docker --location=us-central1
    ```

2.  **Build and Submit Image:**
    ```bash
    gcloud builds submit --region=us-central1 --tag us-central1-docker.pkg.dev/genai-blackbelt-fishfooding/gemini-rails-repo/gemini-rails:latest
    ```

3.  **Create Production Secret:**
    ```bash
    printf "YOUR_RAILS_MASTER_KEY" | gcloud secrets create gemini-rails-master-key --data-file=- --replication-policy=automatic
    ```

4.  **Grant Secret Access to Service Account:**
    ```bash
    gcloud secrets add-iam-policy-binding gemini-rails-master-key --member="serviceAccount:YOUR_SERVICE_ACCOUNT" --role="roles/secretmanager.secretAccessor"
    ```

5.  **Deploy to Cloud Run:**
    ```bash
    gcloud beta run deploy gemini-rails --image=us-central1-docker.pkg.dev/genai-blackbelt-fishfooding/gemini-rails-repo/gemini-rails:latest --service-account=YOUR_SERVICE_ACCOUNT --region=us-central1 --set-secrets=RAILS_MASTER_KEY=gemini-rails-master-key:latest --iap --no-allow-unauthenticated
    ```
