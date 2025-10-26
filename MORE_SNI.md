# Additional Service Classes for gem/sni

Based on analysis of `app/mio`, here are the obvious opportunities to add more shared code to `gem/sni`:

## High Priority Candidates

### 1. Pagination System
- **Location**: `app/mio/app/models/concerns/pageable.rb`
- **Value**: Complete pagination framework with `Pager` class
- **Why shared**: Every Rails app needs pagination; currently 200+ lines of duplicated logic

### 2. Query Builder Utilities
- **Location**: `app/mio/app/models/concerns/constrainable.rb` 
- **Value**: Generic SQL constraint builders (`numerical_constraint`, `cross_constraint`)
- **Why shared**: Common pattern for search/filter functionality across apps

### 3. Bootstrap Layout Helpers
- **Location**: `app/mio/app/helpers/application_helper.rb:16-28`
- **Value**: Grid utilities (`center`, `col`, `pagination_links`) that complement existing `Layout` class
- **Why shared**: Completes the Bootstrap toolkit alongside existing `Layout` service

### 4. Session Management Utilities
- **Location**: `app/mio/app/controllers/application_controller.rb:13-35`
- **Value**: Navigation state (`prev_next`, `store_return_page`), search state, authentication helpers
- **Why shared**: Standard patterns every Rails app with authentication needs

### 5. Markdown Processing
- **Location**: `app/mio/app/models/concerns/remarkable.rb`
- **Value**: Markdown rendering with custom image processing
- **Why shared**: Content management is common across apps

## Medium Priority Candidates

### 6. HTTP API Client Framework
- **Location**: `app/mio/lib/tasks/football.rake:7-95`
- **Value**: Abstract `FootballApi` pattern with error handling, response validation
- **Why shared**: Reusable pattern for any external API integration

### 7. Data Validation Patterns
- **Location**: `app/mio/app/presenters/people_checks.rb`
- **Value**: Structured data validation and reporting
- **Why shared**: Common pattern for data integrity across apps

### 8. Error Handling & Flash Utilities
- **Location**: `app/mio/app/helpers/application_helper.rb:8-15`
- **Value**: Flash message styling (`flash_style`), error handling patterns
- **Why shared**: Standard UI patterns across apps

## Immediate Next Steps

The **easiest wins** that complement existing `SysInfo` and `Layout` services:

1. **Add pagination to `gem/sni`** - self-contained and universally needed
2. **Add query builders** - generic and well-abstracted
3. **Extend Bootstrap utilities** - add helper methods that work with `Layout` class

This would create a solid **core utilities gem** covering system info, layouts, pagination, and search - the building blocks most Rails apps share.

## Current gem/sni Structure

```
lib/
├── sni/
│   ├── layout.rb       # Bootstrap grid layout utilities
│   ├── sys_info.rb     # System information service
│   └── version.rb
└── sni.rb
```

## Recommended Expanded Structure

```
lib/
├── sni/
│   ├── layout.rb           # Bootstrap grid layout utilities
│   ├── sys_info.rb         # System information service
│   ├── pageable.rb         # Pagination framework
│   ├── constrainable.rb    # Query builder utilities
│   ├── bootstrap_helpers.rb # Additional Bootstrap helpers
│   ├── session_helpers.rb   # Session management utilities
│   ├── markdown.rb          # Markdown processing
│   └── version.rb
└── sni.rb
```