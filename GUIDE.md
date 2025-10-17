# Development Guide & Lessons Learned

This document outlines the step-by-step process taken to build the Gemini on Rails application, including the debugging steps and key lessons learned.

## The Goal

To build a simple Ruby on Rails application for a beginner, allowing a user to enter a text prompt and receive a response from the Gemini API, specifically using a Google Cloud Vertex AI project.

---

## Step-by-Step Process

### Phase 1: Setup & Configuration

1.  **Choosing the Gem:**
    *   We initially considered `google-cloud-vertex_ai` but were corrected by the user who pointed out that the third-party `gemini-ai` gem has excellent support for Vertex AI via Application Default Credentials (ADC).
    *   **Lesson:** Always verify a library's capabilities. Third-party libraries can sometimes offer a simpler, more direct API than a full SDK.

2.  **Installing the Gem:**
    *   The chosen gem was added to the `Gemfile`: `gem 'gemini-ai', '~> 4.3.0'`.
    *   We ran `bundle install` from within the `gemini-rails` directory to install it.

3.  **Configuring Credentials:**
    *   We needed to store the Google Cloud Project ID and region securely.
    *   We used `bin/rails credentials:edit` to add the configuration.
    *   **Lesson:** Programmatically editing Rails credentials can be tricky due to its interactive nature. After failed attempts with `sed` and shell redirection, the most reliable method was to use an inline Ruby command as the editor: `EDITOR='ruby -e "File.write(ARGV[0], File.read(...))"' bin/rails credentials:edit`.

### Phase 2: Building the App (MVC)

With the configuration complete, we built the core application following the Model-View-Controller (MVC) pattern.

1.  **Create the Route:**
    *   We edited `config/routes.rb` to define the application's URLs.
    *   We added `root "prompts#index"` to set the home page and `resources :prompts, only: [:index, :create]` to handle showing and submitting the prompt form.

2.  **Create the Controller:**
    *   We generated a `PromptsController` with `bin/rails generate controller Prompts index create`.
    *   We added the logic to the `create` action to:
        1.  Initialize the `Gemini` client.
        2.  Call the `generate_content` method with the user's prompt.
        3.  Store the result in an instance variable (`@response_text`).

3.  **Create the View:**
    *   We edited `app/views/prompts/index.html.erb`.
    *   We used Rails' `form_with` helper to create a form that submits to our `create` action.
    *   We added a section to display the content of `@response_text` if it was present.

### Phase 3: Testing & Debugging

This is where we encountered and solved several issues.

1.  **Problem: 404 API Error (`Faraday::ResourceNotFound`)**
    *   **Symptom:** Submitting the form resulted in a Rails error page.
    *   **Diagnosis:** The error log showed a `404 Not Found` when calling the Vertex AI API. The URL being called was using `/locations/global`.
    *   **Solution:** The `global` region is not valid for this Vertex AI endpoint. We corrected the controller code to use a specific region (`us-central1`) and also took the opportunity to update to the user-specified model name (`gemini-2.5-flash`).
    *   **Lesson:** API endpoints, especially for cloud services, are often region-specific. A `404` error can indicate an incorrect region, not just a wrong path.

2.  **Problem: No Response Displayed (The Blank Page)**
    *   **Symptom:** After fixing the 404, submitting the form resulted in no errors, but the response text did not appear on the page.
    *   **Diagnosis:** The server logs were key. They showed the request was being processed `as TURBO_STREAM`. This meant Rails' default frontend framework, Turbo, was handling the form submission asynchronously and was not automatically updating the page content.
    *   **Solution:** For simplicity, we disabled Turbo for this specific form by changing the `form_with` helper to include `data: { turbo: false }`. This forced a classic, full-page reload, which then correctly displayed the response.
    *   **Lesson:** Modern Rails uses Turbo by default. If a form submission seems to do nothing, check the logs for `as TURBO_STREAM` and decide whether to build a Turbo Stream response or disable Turbo for that element.

### Phase 4: Deployment to Cloud Run

1.  **Containerize the Application:**
    *   We first reviewed the `Dockerfile` and made a small modification to the `CMD` instruction to make it more compatible with the Cloud Run environment.
    *   We then created a repository in Artifact Registry and used `gcloud builds submit` to build the container image and push it to the registry.

2.  **Configure Production Secrets:**
    *   Cloud Run needs the `RAILS_MASTER_KEY` to decrypt production credentials. We created a new secret in Google Secret Manager to hold this key.

3.  **Deploy and Debug:**
    *   We used `gcloud run deploy` to deploy the application. This process also involved several debugging steps.
    *   **Lesson: `gcloud` Beta Features.** The `--iap` flag is not in the general availability `gcloud` component. We had to switch to using `gcloud beta run deploy` to access it.
    *   **Lesson: IAP Security.** The user correctly pointed out that `--allow-unauthenticated` should not be used with `--iap`. We changed this to `--no-allow-unauthenticated` to properly secure the application.
    *   **Lesson: Cloud Run IAM Permissions.** The first deployment failed with a `Permission denied on secret` error. This is because the service account running the Cloud Run instance needs explicit permission to access secrets. We fixed this by granting the `sa-gemini-rails@...` service account the `Secret Manager Secret Accessor` role on the `gemini-rails-master-key` secret.

---

## Conclusion

By following these steps and methodically debugging each issue, we successfully built, tested, and deployed a working Ruby on Rails application that integrates with the Gemini API. The final code and documentation reflect the lessons learned during this process.