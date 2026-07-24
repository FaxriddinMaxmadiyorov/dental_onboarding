# Dental Onboarding

A Ruby on Rails application for candidate onboarding in dental recruitment. Candidates upload their CV, the system parses it with AI and prefills their profile, and they review and complete the remaining fields before submitting. Admins review completed profiles through a separate panel.

## Stack

- **Ruby** 3.2.4
- **Rails** 8.1
- **PostgreSQL**
- **Hotwire** (Turbo + Stimulus) for the frontend
- **ActionCable / Turbo Streams** for real-time CV parsing status updates
- **Solid Queue** for background jobs
- **Google Gemini API** for CV parsing
- **Pundit** for authorization
- **Tailwind CSS**
- **RSpec** + **FactoryBot** for testing
- **RuboCop** for linting

## Getting started

```bash
bundle install
rails db:create db:migrate db:seed
bin/dev
```

Visit `http://localhost:3000`.

### Environment variables

```
GEMINI_API_KEY=your_key_here
GEMINI_URL=https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent
CV_MAX_SIZE_MB=25
RECRUITMENT_TEAM_EMAIL=recruitment@example.com
```

### Creating an admin user

```ruby
# rails console
User.create!(email_address: "admin@example.com", password: "changeme123", role: "admin")
```

Candidates do not register; a `CandidateProfile` is created automatically (tied to a `User` account) the first time someone signs in.

## How it works

### 1. Candidate onboarding flow

1. Candidate logs in and lands on **Upload CV** (`/candidate_onboarding/upload`).
2. Uploading a file triggers `ParseCandidateCvJob` in the background.
3. The candidate is redirected to a **status** page that listens over ActionCable (`Turbo::StreamsChannel`) for the parsing result.
4. When parsing finishes, the page redirects automatically to **Edit Profile**, prefilled with whatever the CV parser found.
5. Fields extracted from the CV are marked with an *"Extracted from CV — please check"* label; required fields left empty are marked *"Missing"*.
6. The candidate reviews, corrects, and completes the profile, then submits.
7. On successful submission, `onboarding_completed` is set to `true` and the recruitment team is notified by email.

If parsing fails or the file is unreadable, the candidate can continue manually — no data is invented.

### 2. CV parsing

- `CvTextExtractor` extracts raw text from PDF/DOCX (`.doc` is accepted but not parsed).
- `CvParserService` sends the extracted text to Gemini with a strict prompt: never invent data, leave missing fields blank, support English and Dutch CVs.
- `ProfilePrefillService` maps the parsed JSON onto the candidate's profile, without overwriting fields the candidate already filled in manually. Re-uploading a CV replaces only the data that came from a *previous* CV upload.

### 3. Admin panel

Admins (role: `admin`) can browse completed profiles at `/candidate_profiles`, view details, edit, and delete. Access is enforced through `CandidateProfilePolicy` (Pundit) — candidates cannot reach these pages.

## Running tests

```bash
bundle exec rspec
```

Test coverage includes models, services (CV parsing, profile prefill), request specs for the full onboarding and admin flows, and policy specs for authorization.

## Linting

```bash
bundle exec rubocop
```

Auto-fixable offenses:

```bash
bundle exec rubocop -a
```

## Project structure highlights

```
app/
  controllers/
    candidate_onboardings_controller.rb   # candidate-facing onboarding flow
    candidate_profiles_controller.rb      # admin panel
    sessions_controller.rb                # shared login/logout
  models/
    candidate_profile.rb                  # core profile model, conditional validations
    candidate_document.rb                 # uploaded CV, parsing_status enum
  services/
    cv_text_extractor.rb                  # PDF/DOCX -> raw text
    cv_parser_service.rb                  # raw text -> structured JSON via Gemini
    profile_prefill_service.rb            # structured JSON -> profile fields
  jobs/
    parse_candidate_cv_job.rb             # background job, broadcasts status over ActionCable
  policies/
    candidate_profile_policy.rb           # admin-only access rules
```

## Notes

- CV parsing intentionally never guesses candidate preferences (region, availability, salary, etc.) — the PRD marks these as not extractable from a CV, so they are always filled in manually.
- Skills are matched against the platform's existing skill list where possible; unmatched skills are kept as free-text suggestions for recruiter review, and candidates can remove ones that don't apply.
