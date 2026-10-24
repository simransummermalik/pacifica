# Pacifica (WON 3RD PLACE!!!)

### Starting Life Underwater

Pacifica is a social banking prototype built by an undergraduate hackathon team. We won 3rd place by turning a difficult banking problem into something personal, visual, and shared with friends.

The core idea:

> Money stress is easier to face when it is visible, understandable, and shared with people you trust.

Pacifica turns everyday spending into a living underwater world. Each person in a circle is represented by a fish. Spending moves a fish through the reef, goals create accountability, and small check-ins make the app feel alive instead of judgmental.

## The problem brief

Pacifica was created for the Starting Life Underwater challenge from the Forward Deployed Hackathon.

The fictional client, BankMaxxing Financial, is a regional bank with approximately 2.5 million retail customers. Its younger customers still route paychecks through the bank, but then disappear. They open the app to check a balance, avoid the app when money is tight, and use other apps or AI tools for financial questions.

The brief described a generation that does not start at zero. They start underwater:

- A typical young customer may have student loans, credit-card debt, rent, food costs, and unpredictable expenses.
- Under-30 customers make up roughly one-third of accounts but contribute less than 6% of deposits.
- Banks can spend hundreds of dollars acquiring a young checking customer.
- If that customer leaves quickly, the bank may never recover the acquisition cost.
- Many young customers avoid opening their banking app specifically when they need help most.

The persona in the brief, Jordan, is 22, earns about $2,900 per month, has student loans and credit-card debt, checks their balance before buying things, and stops opening the app during the second half of the month.

The challenge was not just to make another banking dashboard. It was to build something that:

1. Brings younger customers back into the bank.
2. Makes the second visit feel worth it.
3. Helps users become better off after six months.
4. Uses outside, real-world financial context instead of pretending a bank balance tells the whole story.

## Our insight

Most banking apps show a number. Pacifica shows a relationship.

Instead of saying:

> You spent $42.

Pacifica can show:

> You are near the top of the reef this week. Your circle is also spending more on fun. Want to set a tiny goal?

That shift makes money feel less like a private failure and more like a shared, manageable behavior. The app is designed to encourage reflection without turning friends into financial surveillance.

## Inspiration

Pacifica takes inspiration from products and behaviors people already understand:

- BeReal: a low-pressure, time-based check-in that makes participation feel honest and communal.
- Social activity feeds: friends can react, comment, applaud, or downvote a shared purchase.
- Fitness and game leaderboards: spending becomes a visual position in a reef instead of a spreadsheet.
- Group payment apps: friends can request money, send money, split costs, and contribute to a shared pool.
- Modern banking apps: quick balance visibility, clear actions, and helpful spending categories.
- Habit and accountability apps: small goals are easier to keep when your circle can see and encourage progress.

We did not copy these products directly. We combined their strongest interaction patterns around a banking problem: helping young adults stay engaged when their financial life feels difficult.

## What Pacifica does

### 1. A social bank home

The Bank tab is the financial home base:

- Shows the current demo cash balance.
- Lets a user add demo money or withdraw demo money.
- Shows savings progress.
- Displays the user's profile and fish identity.
- Provides access to the Ask Pacifica financial assistant.
- Provides QR-based payment entry points.
- Includes logout and profile controls.

The prototype intentionally uses demo balances. It does not move real money.

### 2. The Activity reef

The Activity tab is the main social experience.

Each circle member is represented by a fish. The fish position is based on category spending for the selected period. A person who has spent less is closer to the top of the reef; a person who has spent more moves deeper into the water.

The reef includes:

- A pinned Activity header.
- A weekly reset message.
- Category filters for All, Food, Fun, Shopping, Transport, and Subscriptions.
- A Find Me action that jumps to the current user.
- A row of circle members and ranking positions.
- Transactions, Goals, and Challenges buttons.
- A selected-fish summary card.
- A progress bar for budget usage.
- Active selfie avatars attached to the matching fish.
- A vertically scrollable reef so the full circle remains usable on a phone.

The category model is deliberately understandable:

| Category | Example merchants |
| --- | --- |
| Food | Starbucks, Dunkin, Chipotle, Trader Joe's |
| Fun | AMC, concerts, games, entertainment |
| Shopping | Target, Goodwill, general retail |
| Transport | MTA, Uber, Lyft, gas, trains |
| Subscriptions | Netflix, Spotify, Hulu, iCloud |

The database stores category values rather than making the app guess every time. A merchant helper function provides a demo classification for common merchants.

### 3. Transactions

Transactions are the bridge between the bank and the social reef.

The Activity screen can open a transaction feed where a user can see shared purchases such as:

- Starbucks coffee.
- Trader Joe's groceries.
- A movie ticket.
- A transit purchase.
- A subscription.
- A debt payment.

Users can choose whether the amount or merchant is visible. A shared purchase creates a social feed post and a structured spending_transactions record. This same purchase can power:

- The transaction list.
- Category totals.
- Reef depth.
- Goal progress.
- Goal-break updates.
- Social reactions and comments.

There are two different transaction concepts in the schema:

1. transactions is for money moving between Pacifica users.
2. spending_transactions is for purchases such as Starbucks, groceries, shopping, or transit.

Keeping those concepts separate prevents a coffee purchase from being confused with a peer-to-peer transfer.

### 4. Goals

Goals are intentionally small and specific. A user can create a goal such as:

- No Starbucks this week.
- Keep food under $60.
- Spend less at restaurants.
- Do not use rideshare this weekend.

Each goal includes a merchant, a weekly limit, and the user's owner ID. Spending records can be compared against that goal.

When a user breaks a goal, Pacifica can create a friendly update in the activity feed, such as:

> Summer went over the Starbucks goal. Send encouragement?

The goal is not meant to shame the user. The point is to create a visible reset moment so the user opens the app and keeps participating.

### 5. Updates, reactions, and comments

The social feed supports:

- Purchase updates.
- Goal-break updates.
- Debt-payment updates.
- Selfie check-ins.
- Applause and upvotes.
- Playful downvotes.
- Comments.

For example:

> Gabe bought coffee again.

A friend can applaud a responsible choice, comment on it, or downvote an expensive impulse purchase. The reaction model is one reaction per user per post, so a user can change their reaction without creating duplicates.

The tone is intentionally playful rather than punitive. A downvote is a circle conversation starter, not a financial penalty.

### 6. Challenges

Challenges turn spending patterns into optional, low-stakes games:

> I bet Gabe spends money at Starbucks this week.

The current prototype models a fixed $2 demo stake. A user can create a challenge, another user can join with a prediction, and the challenge can eventually resolve to a winner.

Important: this is not real-money gambling. The prototype does not charge a card, transfer funds, or create a legal betting product. The stake exists to demonstrate the product interaction and database model.

### 7. Money pools

Money pools support shared plans:

- Chip in for Friday dinner.
- Everyone send $10 for the Airbnb.
- Help pay for the group gift.
- Collect money for the concert.

A pool has a creator, purpose, target amount, status, and member pledges. The schema supports group contributions while the prototype continues to use demo balances.

### 8. Daily selfie check-ins

Pacifica uses a BeReal-inspired check-in loop:

- The user can take a selfie or choose a photo.
- The photo is stored in the private daily-selfies Supabase Storage bucket.
- A relational daily_selfies row stores the owner, storage path, creation time, and expiration time.
- Active selfies appear as circular avatars on the matching fish.
- The check-in expires after the configured cadence.
- The app can prompt a user who does not have an active selfie.

The selfie is not stored directly inside a database image column. The database stores the secure storage path and metadata; Supabase Storage stores the actual image file. This is the safer and more scalable pattern.

### 9. Send money, requests, and QR payments

The Pay experience supports the social money flows a friend group needs:

- Search for a circle member.
- Send demo money.
- Request money.
- Accept or decline a request.
- Use a QR code to open a payment route.
- Attach a note to a payment.
- Protect actions with an idempotency key so a repeated tap does not duplicate a transfer.

### 10. Ask Pacifica

Ask Pacifica is a conversational financial assistant. It can use:

- A local fact sheet about the user's context.
- Current price context from the Bureau of Labor Statistics API.
- A Groq-compatible chat endpoint for the prototype assistant.

The assistant is designed for questions such as:

- Why did groceries feel more expensive this month?
- What category should I try to reduce?
- Can I afford this purchase?
- What should I do about my student debt?

It is a prototype education and reflection tool, not a financial advisor.

### 11. External financial context

The problem brief required at least one public API with real-world context. Pacifica uses the Bureau of Labor Statistics public API to load price-series context for categories such as:

- Groceries.
- Rent.
- Eating out.
- Gas.
- Electricity.
- Overall consumer prices.

Responses are cached for 24 hours to reduce network calls and keep the demo resilient. The UI can fall back to a friendly offline message when the API is unavailable.

## Why the reef works

The reef is more than decoration:

| Banking problem | Pacifica response |
| --- | --- |
| Users only check a balance | The reef gives them a reason to return |
| Money stress feels isolating | A trusted circle makes progress social |
| Raw transactions are hard to interpret | Categories and fish position make patterns visual |
| Goals are easy to abandon | Goal-break updates create a reset moment |
| Financial advice feels generic | Ask Pacifica combines user context with external prices |
| Group expenses are awkward | Requests, transfers, QR codes, and pools reduce friction |
| Check-ins are boring | Selfies make the circle feel present and alive |

## Product architecture

~~~text
SwiftUI iOS app
    |
    +-- Bank tab
    |     +-- wallet, savings, profile, assistant, QR entry
    |
    +-- Activity tab
    |     +-- reef ranking
    |     +-- categories
    |     +-- transactions
    |     +-- goals
    |     +-- challenges
    |     +-- comments and reactions
    |     +-- selfie avatars
    |
    +-- Pay tab
          +-- send money
          +-- request money
          +-- QR payment flow

Supabase
    +-- Auth
    +-- Postgres tables and row-level security
    +-- private daily-selfies Storage bucket
    +-- database triggers for profiles, wallets, spending records, and updates

Public context
    +-- Bureau of Labor Statistics API
    +-- cached price context

Assistant
    +-- Groq-compatible chat endpoint
    +-- local facts and price context
~~~

## Repository structure

~~~text
Pacifica/
├── App/
│   └── RootView.swift
├── Core/
│   ├── Services/
│   └── Theme/
├── Features/
│   ├── Activity/
│   ├── Home/
│   └── Pay/
├── Models/
├── Services/
├── HomeView.swift
├── PacificaApp.swift
└── Secrets.swift              # local only; ignored by Git

supabase/
└── migrations/
    ├── 001_pacifica_schema.sql
    ├── 010_activity_comments.sql
    ├── 016_social_money_features.sql
    ├── 018_goal_break_updates.sql
    ├── 020_spending_transactions.sql
    └── 021_selfie_upload_and_circle_reads.sql
~~~

## Database schema

The following Mermaid ER diagram is safe to paste into GitHub, GitLab, Notion, or another Mermaid-compatible Markdown viewer:

~~~mermaid
erDiagram
    AUTH_USERS ||--|| PROFILES : "has"
    PROFILES ||--|| WALLETS : "owns"
    PROFILES ||--o{ FRIENDSHIPS : "requests or receives"
    PROFILES ||--o{ TRANSACTIONS : "sends"
    PROFILES ||--o{ TRANSACTIONS : "receives"
    PROFILES ||--o{ PAYMENT_REQUESTS : "requests"
    PROFILES ||--o{ PAYMENT_REQUESTS : "receives"
    PROFILES ||--o{ SPENDING_TRANSACTIONS : "records"
    PROFILES ||--o{ SPENDING_GOALS : "sets"
    PROFILES ||--o{ FEED_POSTS : "creates"
    PROFILES ||--o{ REACTIONS : "reacts"
    PROFILES ||--o{ ACTIVITY_COMMENTS : "writes"
    PROFILES ||--o{ DAILY_SELFIES : "uploads"
    PROFILES ||--o{ DEBTS : "has"
    PROFILES ||--o{ DEBT_PAYMENTS : "makes"
    PROFILES ||--o{ MONEY_POOLS : "creates"
    PROFILES ||--o{ MONEY_POOL_MEMBERS : "pledges"
    PROFILES ||--o{ SPENDING_CHALLENGES : "creates"
    PROFILES ||--o{ CHALLENGE_ENTRIES : "joins"

    FEED_POSTS ||--o{ REACTIONS : "receives"
    FEED_POSTS ||--o{ ACTIVITY_COMMENTS : "receives"
    FEED_POSTS o|--o| TRANSACTIONS : "may describe"
    FEED_POSTS o|--o| SPENDING_GOALS : "may trigger"
    FEED_POSTS o|--o| SPENDING_TRANSACTIONS : "may originate"

    DEBTS ||--o{ DEBT_PAYMENTS : "has"
    MONEY_POOLS ||--o{ MONEY_POOL_MEMBERS : "contains"
    SPENDING_CHALLENGES ||--o{ CHALLENGE_ENTRIES : "contains"

    AUTH_USERS {
        uuid id PK
        text email
    }

    PROFILES {
        uuid id PK, FK
        text username UK
        text display_name
        text avatar_path
        text fish_color
        text fish_type
        timestamptz created_at
    }

    WALLETS {
        uuid user_id PK, FK
        numeric demo_balance
        timestamptz updated_at
    }

    FRIENDSHIPS {
        uuid id PK
        uuid requester_id FK
        uuid recipient_id FK
        text status
        timestamptz created_at
    }

    TRANSACTIONS {
        uuid id PK
        uuid sender_id FK
        uuid recipient_id FK
        numeric amount
        text note
        text status
        text transaction_type
        uuid idempotency_key UK
        timestamptz created_at
    }

    PAYMENT_REQUESTS {
        uuid id PK
        uuid requester_id FK
        uuid recipient_id FK
        numeric amount
        text note
        text status
        uuid idempotency_key UK
        timestamptz created_at
        timestamptz responded_at
    }

    SPENDING_TRANSACTIONS {
        uuid id PK
        uuid user_id FK
        text merchant
        numeric amount
        text category
        timestamptz spent_at
        text visibility
        uuid source_feed_post_id UK, FK
        text external_id UK
        timestamptz created_at
    }

    SPENDING_GOALS {
        uuid id PK
        uuid user_id FK
        text title
        text merchant
        numeric weekly_limit
        timestamptz created_at
    }

    FEED_POSTS {
        uuid id PK
        uuid user_id FK
        uuid transaction_id FK
        uuid spending_goal_id FK
        uuid goal_id FK
        uuid source_post_id FK
        text post_type
        text caption
        text merchant
        numeric shared_amount
        boolean hide_amount
        boolean hide_merchant
        text visibility
        timestamptz created_at
    }

    REACTIONS {
        uuid id PK
        uuid post_id FK
        uuid user_id FK
        text reaction_type
        timestamptz created_at
    }

    ACTIVITY_COMMENTS {
        uuid id PK
        uuid post_id FK
        uuid user_id FK
        text body
        timestamptz created_at
    }

    DAILY_SELFIES {
        uuid id PK
        uuid user_id FK
        text storage_path
        timestamptz created_at
        timestamptz expires_at
    }

    DEBTS {
        uuid id PK
        uuid user_id FK
        text debt_type
        numeric starting_balance
        numeric remaining_balance
        numeric annual_interest_rate
        timestamptz created_at
    }

    DEBT_PAYMENTS {
        uuid id PK
        uuid debt_id FK
        uuid user_id FK
        numeric amount
        uuid idempotency_key UK
        timestamptz created_at
    }

    MONEY_POOLS {
        uuid id PK
        uuid creator_id FK
        text title
        text purpose
        numeric target_amount
        text status
        timestamptz created_at
    }

    MONEY_POOL_MEMBERS {
        uuid pool_id PK, FK
        uuid user_id PK, FK
        numeric pledged_amount
        timestamptz created_at
    }

    SPENDING_CHALLENGES {
        uuid id PK
        uuid creator_id FK
        text title
        text merchant
        numeric stake_amount
        date week_start
        text status
        uuid winner_id FK
        timestamptz created_at
    }

    CHALLENGE_ENTRIES {
        uuid challenge_id PK, FK
        uuid user_id PK, FK
        text prediction
        numeric stake_amount
        timestamptz created_at
    }
~~~

### Storage relationship

The Mermaid diagram represents relational tables. Selfie images are stored separately:

~~~text
Supabase Storage bucket: daily-selfies (private)
        |
        +-- object name: <user_id>/<unique-file-name>.jpg
        |
        +-- daily_selfies.storage_path points to that object
~~~

The app requests a signed URL for an active selfie and displays it on the matching fish. The image file itself is not placed inside Postgres.

### Database behavior

- An Auth signup triggers handle_new_user(), which creates a profile and an empty wallet.
- A purchase feed post can automatically create a spending_transactions row.
- Merchant names are classified into the five Activity categories.
- Goal-break logic creates a social update when spending passes a goal limit.
- RLS policies protect user-owned wallet, profile, goal, selfie, and payment data.
- Circle-facing records use visibility and active-expiration rules.
- Idempotency keys protect money actions from duplicate submissions.
- Demo seed data makes all five circle members visible during a judging demo.

## Privacy and safety choices

Pacifica is a social money prototype, so privacy is part of the product design:

- Amounts and merchants can be hidden on shared posts.
- Selfies live in a private storage bucket.
- Users can delete their own selfies.
- User-owned rows are protected with Supabase Row Level Security.
- The app uses demo balances rather than real bank account connections.
- Challenges use a demo stake and do not move real money.
- The assistant is framed as educational context, not regulated financial advice.
- Secrets such as the Groq API key are kept in an ignored local file and are not committed.

## What is implemented versus prototype foundation

### Working prototype flows

- Supabase Auth and profile creation.
- Demo wallet balance and wallet transfers.
- Payment requests and QR entry.
- Activity reef with category filters and scroll behavior.
- Structured spending transactions.
- Goals and goal-break updates.
- Reactions and comments.
- Daily selfie upload, expiration, and fish avatar display.
- Ask Pacifica assistant wiring.
- BLS price context with caching.
- Demo circle data for five participants.

### Foundation for the next iteration

- Money pools have a database model and demo seed.
- Challenges have a database model, fixed $2 demo stake, and join flow.
- More advanced circle membership and friend discovery can be tightened beyond the hackathon demo.
- Real bank integrations, account linking, and real-money settlement are intentionally not included.

## Alignment with the challenge

| Challenge requirement | Pacifica implementation |
| --- | --- |
| Re-engage young banking customers | The reef, social feed, selfies, goals, and challenges create reasons to return |
| Make a second visit worth it | Every visit shows new spending context or circle activity |
| Leave the user better off | Goals, category awareness, price context, and accountability encourage small changes |
| Use real-world context | BLS price data informs the ocean conditions and assistant |
| Keep the product approachable | Fish, plain-language cards, and small actions reduce financial intimidation |
| Avoid a separate youth bank | Pacifica is an experience layer on top of banking relationships |
| Avoid new core integrations | The prototype uses Supabase and public APIs rather than a new banking core |

## Out of scope

The original challenge explicitly kept several areas out of scope, and Pacifica follows that boundary:

- Bank account opening or onboarding.
- A separate youth-branded bank.
- Crypto, trading, or investing.
- Buy now, pay later.
- A production core-banking integration.
- Real-money betting or gambling.
- A production financial-advice or credit-underwriting system.

## Running the project

1. Open the Xcode project generated from project.yml.
2. Resolve the Supabase Swift package dependency.
3. Add local development secrets to Pacifica/Secrets.swift; never commit that file.
4. Select an iPhone Simulator.
5. Build and run.
6. Make sure the Supabase migrations have been applied in order.
7. Sign in with one of the seeded demo accounts.

The Xcode project is intentionally not committed because it is generated from the project configuration. Run the project's XcodeGen command when needed.

## Demo story

For a short judging demo:

1. Start on the Bank tab and show the balance, savings, and ocean price context.
2. Open Activity and show the five fish in the circle.
3. Tap Food or Shopping and show how the category changes the reef.
4. Open Transactions and show a merchant purchase.
5. Open Goals and create No Starbucks this week.
6. Show the goal-break update after a matching purchase.
7. Open the selfie check-in, take a photo, and show the selfie avatar on the fish.
8. Open Challenges or a pool to show how a friend group can make spending social.
9. Use Pay to request or send demo money.
10. Ask Pacifica why prices feel different and show the external context response.

## Future direction

The strongest next step is to move from a seeded demo reef to a truly personal one:

- Connect a user-authorized transaction source.
- Let each circle choose what is shared.
- Add richer goal progress and weekly summaries.
- Resolve challenge outcomes automatically.
- Finish the money-pool contribution and settlement flow.
- Add notifications for selfie cadence, goal breaks, requests, and encouragement.
- Improve friend discovery and circle membership policies.
- Measure whether users return, understand their spending, and improve after six months.

## Closing

Pacifica is a small but complete product idea: a bank that acknowledges that young adults are underwater, then gives them a visual world, a trusted circle, and tiny actions to help them move upward.

The reef makes the invisible visible. The social layer makes the difficult less lonely. The financial context makes the app more useful than a balance screen.
