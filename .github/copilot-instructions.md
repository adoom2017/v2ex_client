# V2EX Client - AI Coding Agent Instructions

## Project Overview
Flutter-based V2EX client using Riverpod for state management, V2EX API 2.0 Beta, and Material Design 3.

## Key Architecture Patterns

### State Management with Riverpod
- **Providers**: Located in `lib/src/providers/` - use `FutureProvider.autoDispose.family` for parameterized data loading
- **API Integration**: All providers use `ref.read(apiClientProvider)` to access API client
- **Concurrent Loading**: Use `Future.wait()` for parallel API calls (see `paginatedTopicsProvider`)
- **Immutable Parameters**: Create immutable parameter classes (e.g., `TopicsParam`, `TopicRepliesParam`) for provider families

### API Client Pattern
- **Base URL**: `https://www.v2ex.com/api/v2/` with Bearer token authentication
- **Error Handling**: Specific handling for 401 (token), 404 (not found), with LogService.error()
- **Token Management**: Automatic injection via Dio interceptors, stored in FlutterSecureStorage
- **Pagination**: All list endpoints support `p` parameter for page numbers

### Model Structure
- **JSON Serialization**: Use `@JsonSerializable()` with `build_runner` for code generation
- **Field Mapping**: Map API fields with `@JsonKey(name: 'api_field')` (e.g., `avatar_normal`, `member_id`)
- **Null Safety**: Most fields are nullable to handle partial API responses (notifications vs full profiles)
- **Convenience Methods**: Provide backward-compatible getters (e.g., `avatarNormalUrl`, `avatarLargeUrl`)

### UI Components
- **Screens**: Located in `lib/src/screens/` - use `ConsumerWidget` for Riverpod integration
- **Widgets**: Reusable components in `lib/src/widgets/` (e.g., `TopicListItem`)
- **Error Handling**: Use `AsyncValue.when()` pattern with loading, error, and data states
- **Material Design 3**: Use `Theme.of(context).colorScheme` and `textTheme` for consistent styling

## Critical Developer Workflows

### Code Generation
```bash
dart run build_runner build  # Required after model changes
```

### API Response Handling
- V2EX API returns `{success: true, result: data}` structure
- Always access `response.data['result']` for actual data
- Handle both list and single object responses appropriately

### Avatar Display Pattern
```dart
CircleAvatar(
  backgroundImage: member.avatarNormalUrl.isNotEmpty
      ? NetworkImage(member.avatarNormalUrl)
      : null,
  child: member.avatarNormalUrl.isEmpty
      ? Text(member.username[0].toUpperCase())
      : null,
)
```

### Pagination Implementation
1. Create immutable parameter class with `page` field
2. Use `FutureProvider.autoDispose.family` with parameter
3. Handle page loading in UI with `ListView.builder` and load-more pattern

## V2EX API Specifics
- **Personal Access Token**: Required in Authorization header as `Bearer token`
- **Rate Limit**: 600 requests/hour per IP
- **Key Endpoints**:
  - `notifications` (GET/DELETE)
  - `member` (current user profile)
  - `nodes/:node/topics` (paginated)
  - `topics/:id` (includes full member data)
  - `topics/:id/replies` (paginated)

## Common Debugging
- **Token Issues**: Check Settings screen for PAT configuration
- **Image Loading**: Use fallback patterns for missing/empty avatar URLs
- **Concurrent Loading**: Optimize with `Future.wait()` for better performance
- **Build Errors**: Run `dart run build_runner build` after model changes

## File Structure Conventions
- Models: `lib/src/models/` with `.g.dart` generated files
- Providers: `lib/src/providers/` - one per major data entity
- Services: `lib/src/services/` (ApiClient, TokenService, LogService)
- Screens: `lib/src/screens/` - full-page UI components
- Widgets: `lib/src/widgets/` - reusable UI components