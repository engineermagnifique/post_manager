#  Posts Manager

A Flutter CRUD application built on top of the [JSONPlaceholder](https://jsonplaceholder.typicode.com) REST API. Features a clean service-layer architecture, typed exception handling, and fully managed async UI states — all without third-party state management libraries.

---

##  Table of Contents

- [Project Info](#project-info)
- [Dependencies](#dependencies)
- [Exception Handling](#exception-handling)
- [Async State & Future Usage](#async-state--future-usage)

---

## Project Info

| Field          | Value                                    |
| -------------- | ---------------------------------------- |
| App Name       | `posts_manager`                          |
| Version        | `1.0.0+1`                                |
| SDK Constraint | Dart `^3.10.8`                           |
| API Endpoint   | `https://jsonplaceholder.typicode.com`   |
| Architecture   | Flutter `StatefulWidget` + Service Layer |

---

## Dependencies

The project keeps its dependency tree intentionally lean — no third-party state management (Provider, Riverpod, BLoC), keeping the learning curve low.

### `flutter` — SDK

> Core framework powering the entire widget tree, Material Design components, animations, and navigation. Every widget in the project (`StatefulWidget`, `AnimationController`, `SliverAppBar`, `ScaffoldMessenger`, etc.) comes from this mandatory dependency.

### `http` `^1.2.2`

> Official Dart HTTP client used in `lib/services/api_service.dart` to communicate with JSONPlaceholder.

Preferred over `dio` because:

- Zero configuration overhead — no interceptor setup or base options class required
- Maintained directly by the Dart team, keeping pace with language updates
- Covers 100% of the app's needs: `GET`, `POST`, `PUT`, `PATCH`, `DELETE`

All HTTP calls are routed through a private `_safeRequest()` helper with a **15-second timeout** applied via Dart's built-in `.timeout()` extension.

### `cupertino_icons` `^1.0.8`

> Standard Flutter starter dependency providing the iOS-style icon set. Kept for cross-platform readiness; the app currently uses `Icons.*` (Material) icons.

### DM Sans _(local asset font)_

> A clean, geometric sans-serif bundled as local TTF assets — **not** fetched via a Google Fonts package.

Five weights are registered:

| Weight        | Usage              |
| ------------- | ------------------ |
| 400 Regular   | Body text, labels  |
| 500 Medium    | Secondary headings |
| 600 SemiBold  | Card titles        |
| 700 Bold      | Section headers    |
| 800 ExtraBold | Hero text          |

Bundling locally guarantees consistent rendering **offline**, with no runtime font-download dependency.

---

## Exception Handling

All HTTP operations flow through a two-layer exception strategy defined in `api_service.dart`.

### Custom Exception Classes

```dart
// Server-side errors (unexpected HTTP status codes)
class ApiException implements Exception {
  final String message;
  final int? statusCode;
}

// Transport/connectivity errors (offline, timeout, DNS failure)
class NetworkException implements Exception {
  final String message;
}
```

### `_safeRequest()` — Network Error Guard

Wraps every HTTP call and maps low-level Dart errors to `NetworkException`:

| Dart Exception     | Mapped Message                                           |
| ------------------ | -------------------------------------------------------- |
| `SocketException`  | "No internet connection"                                 |
| `HttpException`    | "Could not reach the server"                             |
| `TimeoutException` | Caught by generic handler, wrapped as `NetworkException` |
| Any other          | Re-wrapped with original error string                    |

### `_checkStatus()` — HTTP Status Validation

Inspects the HTTP status code after a successful transport and throws `ApiException` for unexpected codes:

| HTTP Code | User-Facing Message                          |
| --------- | -------------------------------------------- |
| `400`     | Bad request — please check your input.       |
| `401`     | Unauthorized — please log in again.          |
| `403`     | Forbidden — you don't have permission.       |
| `404`     | Not found — this post no longer exists.      |
| `422`     | Validation failed — please check your input. |
| `500`     | Server error — please try again later.       |
| Other     | Something went wrong (HTTP `<code>`).        |

### UI-Level Handling

| Screen             | Operation       | On Failure                                                               |
| ------------------ | --------------- | ------------------------------------------------------------------------ |
| `HomeScreen`       | `_loadPosts()`  | Stores message in `_error` state → renders `ErrorView` with Retry button |
| `HomeScreen`       | `_deletePost()` | Shows `AppSnackbar` with `isError: true` (red)                           |
| `CreateEditScreen` | `_save()`       | Shows `AppSnackbar` with the exception message and `isError: true`       |

> **Rule:** The service layer _throws_ typed exceptions. The UI layer _catches_ them, updates state flags, and renders dedicated error widgets or snackbars. Users always see actionable, human-readable messages — never raw stack traces.

---

## Async State & Future Usage

The project does **not** use `FutureBuilder`. Every screen is a `StatefulWidget` that manages async state manually through boolean flags and `setState()`, giving finer simultaneous control over loading, error, and success states.

### Future Methods

| Method          | Screen             | Triggered By                     |
| --------------- | ------------------ | -------------------------------- |
| `_loadPosts()`  | `HomeScreen`       | `initState()` + Refresh button   |
| `_deletePost()` | `HomeScreen`       | Swipe / menu delete action       |
| `_openCreate()` | `HomeScreen`       | FAB "New Post" button            |
| `_openEdit()`   | `HomeScreen`       | Edit action on any card          |
| `_save()`       | `CreateEditScreen` | Publish / Save Changes button    |
| `_onWillPop()`  | `CreateEditScreen` | Back button with unsaved changes |

### State Fields

**`HomeScreen`**

| Field       | Type         | Purpose                                      |
| ----------- | ------------ | -------------------------------------------- |
| `_loading`  | `bool`       | `true` while `_loadPosts()` is in flight     |
| `_deleting` | `bool`       | `true` while `_deletePost()` is in flight    |
| `_error`    | `String?`    | Non-null when `_loadPosts()` fails           |
| `_posts`    | `List<Post>` | Populated on successful fetch                |
| `_filtered` | `List<Post>` | Derived from `_posts` after search filtering |

**`CreateEditScreen`**

| Field         | Type   | Purpose                                   |
| ------------- | ------ | ----------------------------------------- |
| `_saving`     | `bool` | `true` while `_save()` is in flight       |
| `_hasChanges` | `bool` | `true` when the user has edited any field |

### UI States Driven by Futures

| State                | Widget Rendered                                  | Condition                                          |
| -------------------- | ------------------------------------------------ | -------------------------------------------------- |
| **Loading**          | `ShimmerCard` × 6 (animated skeleton)            | `_loading == true`                                 |
| **Error**            | `ErrorView` (icon + message + Retry button)      | `_error != null`                                   |
| **Empty**            | `EmptyView` (contextual message ± Create button) | `_filtered.isEmpty && _error == null`              |
| **Success**          | `SliverList` of `PostCard` widgets               | `_filtered.isNotEmpty`                             |
| **Stats Bar**        | Post count badges                                | `!_loading && _error == null && _posts.isNotEmpty` |
| **Mutation overlay** | `LoadingOverlay` (scrim + spinner + label)       | `_deleting == true` / `_saving == true`            |
| **Disabled submit**  | `ElevatedButton` with `onPressed: null`          | `_saving == true`                                  |
| **Unsaved badge**    | Amber pill in AppBar                             | `_hasChanges == true`                              |

### State Machine — `HomeScreen`

```
Future fires  →  _loading = true   →  ShimmerCards shown
  On success  →  _loading = false, _posts filled  →  PostCard list shown
  On failure  →  _loading = false, _error set     →  ErrorView shown

Delete fires  →  _deleting = true  →  LoadingOverlay shown
  On success  →  post removed from _posts, success snackbar shown
  On failure  →  error snackbar shown
```
