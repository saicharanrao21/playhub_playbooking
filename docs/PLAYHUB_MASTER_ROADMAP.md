# PlayHub Master Roadmap

## Phase 43: Dynamic Discovery & Media Storage
**Objective**: Replace all remaining dummy discovery data and implement production-ready image handling.
- **Scope**:
  - Backend: `Cities` and `Categories` modules.
  - Database: Add `City` model and seed data.
  - Media: Integration with AWS S3 or compatible object storage for Venue/Facility images.
  - Flutter: Update repositories to fetch real data; update UI to display network images.
- **Priority**: High (Launch Blocker)

## Phase 44: Search & Advanced Filtering
**Objective**: Enable users to find specific venues and facilities based on criteria.
- **Scope**:
  - Backend: Search service with support for city, category, and date filtering.
  - Flutter: Implement the `Search Results` placeholder screen.
- **Priority**: Medium

## Phase 45: Communications & External Drivers
**Objective**: Move beyond in-app notifications to real-world alerts.
- **Scope**:
  - Backend: SMTP driver (Email), Twilio/Msg91 (SMS), Firebase Cloud Messaging (Push).
  - Business Rules: Automated booking reminders and payment confirmations.
- **Priority**: High (Operational Requirement)

## Phase 46: Customer Trust & Feedback
**Objective**: Implement social proof via reviews and ratings.
- **Scope**:
  - Backend: `Reviews` and `Ratings` modules with anti-spam (booking validation).
  - Database: Aggregation logic for venue ratings.
  - Flutter: Review list and submission UI.
- **Priority**: Medium

## Phase 47: Advanced Business Analytics
**Objective**: Provide value to venue owners with data insights.
- **Scope**:
  - Backend: Reporting service for revenue, occupancy, and popular slots.
  - Flutter: Interactive charts on the Business Dashboard.
- **Priority**: Low (Post-Launch)

## Phase 48: Platform Scale & Performance
**Objective**: Prepare for 100k+ concurrent users.
- **Scope**:
  - Backend: Redis caching for availability lookups.
  - Infrastructure: Horizontal scaling configuration.
  - Database: Read replicas and query optimization.
- **Priority**: Scale-Dependent
