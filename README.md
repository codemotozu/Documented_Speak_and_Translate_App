## Project Structure


```

├── .github/workflows/      # CI/CD configuration for Azure deployment
├── lib/                    # Flutter application source code
│   ├── features/           # Feature modules (translation, voice, etc.)
│   │   └── translation/    # Translation feature
│   │       ├── data/       # Data layer with models and repositories
│   │       ├── domain/     # Domain layer with entities and use cases
│   │       └── presentation/ # UI layer with screens and providers
│   └── main.dart           # Flutter application entry point
└── server/                 # Backend server
  ├── app/                # Server application code
  │   ├── application/    # Application services
  │   ├── domain/         # Domain entities
  │   └── infrastructure/ # API routes and external interfaces
  ├── Dockerfile          # Docker configuration for server
  └── requirements.txt    # Python dependencies
```
