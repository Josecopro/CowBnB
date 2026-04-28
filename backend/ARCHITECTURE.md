# CowBnB Backend Architecture

## Overview

- Modular Node.js backend using Firebase Functions and Firestore.
- Organized by domain (auth, terrenos, etc.) for scalability.
- Shared utilities for validation, logging, error handling, and types.
- Data models and validation rules centralized in `models/`.
- Configurations in `config/`.
- Unit and integration tests in `tests/`.

## Folder Structure

- `config/` - Environment and constants
- `functions/` - Cloud Functions entrypoints (by domain)
- `models/` - Data models, validation, migration
- `shared/` - Utilities, logging, error handling
- `tests/` - Unit and integration tests

## Principles

- Separation of concerns
- Security by default
- Testability
- Clear error and logging conventions
