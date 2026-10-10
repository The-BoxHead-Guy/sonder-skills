---
name: pest-php-testing-expert
description: >
  Expert in Pest PHP testing (v3/v4) for Laravel and vanilla PHP backends.
  Activates when writing tests, debugging test failures, implementing TDD,
  creating test suites, adding coverage, or when the user mentions Pest,
  PHPUnit, test, spec, assertion, mocking, coverage, TDD, datasets,
  architecture testing, mutation testing, or needs to verify functionality.
  Also activates when working with phpunit.xml, Pest.php, TestCase.php,
  test helpers, factories, or any test infrastructure configuration.
  CRITICAL: NEVER writes fake tests that mock reality — always writes tests
  that genuinely verify functionality and catch real regressions.
---

# Pest PHP Testing Expert

## Core Philosophy

### The Golden Rule of Testing
**Test behavior, not implementation.** A test that breaks when you refactor internals without changing behavior is a liability, not an asset. Every test MUST prove something a user or system would notice if it broke.

### Test What Matters, Not What's Easy
- ✅ Business logic, authorization rules, critical workflows, data integrity
- ❌ What the framework already tests (Eloquent `save()`, validation runner, HTTP kernel)
- ❌ Configuration values, trivial getters/setters, generated code
- ❌ 100% line coverage at the expense of meaningful assertions

### The Honest Test Manifesto
A passing test that doesn't prove anything is worse than no test — it creates false confidence. Every test file must be able to answer: "What production behavior would fail if this test failed?"

---

## Quick Reference

| Concept | Rule |
|---------|------|
| **What to test** | Behavior users would notice, business logic, authorization, error handling |
| **What NOT to test** | Framework internals, Laravel helpers, trivial code, config values |
| **Test type to prefer** | Feature tests (exercise real composition) over unit tests with deep mocks |
| **Mock at** | The system boundary (HTTP client, mailer, filesystem, queue) — NOT inside your domain |
| **Mock with** | Fakes over mocks when interface is small; PHPUnit `createMock` or Mockery |
| **Database** | Real database via `RefreshDatabase` (transaction-rollback), not mocked queries |
| **Test naming** | Behavior specs: `it('rejects checkout when cart is empty')` — not `testCartValidation()` |
| **Edge cases** | Every failure mode you've shipped to production, plus NULLs, empty arrays, boundary values |

---

## Installation & Configuration

### Laravel Project

```bash
composer require pestphp/pest --dev --with-all-dependencies
composer require pestphp/pest-plugin-laravel --dev
```

### Vanilla PHP Project

```bash
composer require pestphp/pest --dev
# No plugin needed — configure manually
```

### `phpunit.xml` Best Practices

```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="vendor/phpunit/phpunit/phpunit.xsd"
         bootstrap="vendor/autoload.php"
         colors="true"
         failOnRisky="true"
         failOnWarning="true"
>
    <testsuites>
        <testsuite name="Unit">
            <directory>tests/Unit</directory>
        </testsuite>
        <testsuite name="Feature">
            <directory>tests/Feature</directory>
        </testsuite>
        <testsuite name="Architecture">
            <directory>tests/Architecture</directory>
        </testsuite>
    </testsuites>

    <source>
        <include>
            <directory>app</directory>
        </include>
    </source>

    <php>
        <!-- Laravel-specific: safe test defaults -->
        <env name="APP_ENV" value="testing"/>
        <env name="DB_CONNECTION" value="sqlite"/>
        <env name="DB_DATABASE" value=":memory:"/>
        <env name="CACHE_STORE" value="array"/>
        <env name="QUEUE_CONNECTION" value="sync"/>
        <env name="SESSION_DRIVER" value="array"/>
        <env name="MAIL_MAILER" value="array"/>
        <env name="BCRYPT_ROUNDS" value="4"/>
        <env name="TELESCOPE_ENABLED" value="false"/>
    </php>
</phpunit>
```

**⚠️ CRITICAL SAFETY GUARD**: Config cache overrides `phpunit.xml` database settings, which means `RefreshDatabase` would run `migrate:fresh` on your **REAL** database. Always add this guard in `tests/Pest.php`:

```php
if (file_exists(__DIR__.'/../bootstrap/cache/config.php')) {
    fwrite(STDERR, "\033[31m[SAFETY] Config cache detected — refusing to run tests!\033[0m\n");
    fwrite(STDERR, "  Run: \033[33mphp artisan config:clear\033[0m\n\n");
    exit(1);
}
```

### `tests/Pest.php` — Test Case Binding

**Laravel:**
```php
pest()->extend(Tests\TestCase::class)
    ->use(Illuminate\Foundation\Testing\RefreshDatabase::class)
    ->in('Feature', 'Unit');
```

**Vanilla PHP:**
```php
// Load your app bootstrap
require_once __DIR__ . '/../app/config/autoloader_configuration.php';

// Set testing environment
putenv('APP_ENV=testing');
if (!defined('APP_ENV')) {
    define('APP_ENV', 'testing');
}
```

### Running Tests

```bash
# All tests
php artisan test

# With parallel (Pest native)
php artisan test --parallel

# Specific file
php artisan test --filter="ReportsTest"

# Specific test
php artisan test --filter="it_rejects_checkout_when_cart_is_empty"

# Unit only
php artisan test --testsuite=Unit

# Profile slow tests
php artisan test --profile

# Coverage (requires Xdebug/PCOV)
php artisan test --coverage --min=80
```

---

## Test Organization

### Directory Structure

```
tests/
├── Pest.php                    # Test case binding, expectations, helpers
├── TestCase.php                # Base class with custom assertions
├── Helpers/                    # Optional shared helper functions
├── Datasets/                   # Shared datasets (auto-loaded by Pest)
├── Unit/                       # Pure logic tests (no framework)
│   └── Services/
│       └── DiscountServiceTest.php
├── Feature/                    # Integration-level tests (HTTP, DB, commands)
│   ├── Api/V1/
│   │   ├── ReportsTest.php
│   │   └── Configuration/
│   │       └── ViasTest.php
│   ├── Auth/
│   │   └── RbacTest.php
│   └── Commands/
│       └── CloseReportsTest.php
├── Integration/                # Multi-service integration (vanilla PHP)
│   ├── SsgReportServiceTest.php
│   └── DashboardServiceTest.php
└── Architecture/               # Architectural rules (Pest arch presets)
    └── ArchitectureTest.php
```

### Test Naming Rules

| Rule | Example |
|------|---------|
| Files: `{Name}Test.php` | `ReportsTest.php` |
| Functions: `it('describes behavior')` | `it('rejects checkout when cart is empty')` |
| Functions: `test('describes behavior')` | `test('user cannot delete another user\'s post')` |
| Datasets: named keys | `'missing title' => [['title' => ''], 'title']` |
| Describe: groups related behaviors | `describe('createReport()', function () { ... })` |

**Test names MUST read like behavior documentation.** A new developer should be able to run `php artisan test --list-tests` and understand what the application does.

✅ `it('redirects unauthenticated users to login')`  
✅ `test('admin can soft-delete any report')`  
❌ `testCreateReport` — does not describe behavior  
❌ `test_validation` — too vague, any validation?  

### Test Levels (Which to Pick)

| Level | When to Use | Framework Cost | Speed |
|-------|-------------|----------------|-------|
| **Unit** | Pure logic, isolated computations, value objects, stateless services | Minimal | ⚡ Fast |
| **Feature (HTTP)** | Composed behavior: controller + middleware + request + DB + response | Laravel boot | 🏃 Moderate |
| **Integration** | Service orchestration, API client interactions, multi-component workflows | Partial boot | 🏃 Moderate |
| **Architecture** | Enforce project structure, naming conventions, dependency rules | None | ⚡ Fast |
| **Browser/E2E** | Full user flow across frontend + backend | Full stack | 🐢 Slow |

**Default for Laravel apps**: Feature tests. One feature test (`actingAs()->postJson()...`) exercises routing, middleware, validation, controller, DB, and response — more value per test than multiple isolated unit tests.

---

## Writing Tests (Expectation API)

### Basic Structure

```php
<?php

use App\Models\User;
use App\Services\DiscountService;

// 'it()' adds the word "it" before the description
it('calculates total with percentage discount', function () {
    $service = new DiscountService();
    $total = $service->calculate(100.0, 10); // 10% off

    expect($total)->toBe(90.0);
});

// 'test()' uses the description as-is  
test('empty cart returns zero total', function () {
    $service = new DiscountService();
    $total = $service->calculateForItems([]);

    expect($total)->toBe(0.0);
});
```

### Using `describe()` for Organization

```php
describe('DiscountService', function () {
    describe('calculate()', function () {
        test('applies percentage discount correctly', function () {
            // ...
        });

        test('returns original price when discount is zero', function () {
            // ...
        });
    });

    describe('calculateForItems()', function () {
        test('sums all item prices', function () {
            // ...
        });
    });
});
```

### Essential Expectation API Reference

#### Value Assertions
| Expectation | Checks |
|-------------|--------|
| `->toBe($value)` | `===` strict equality |
| `->toEqual($value)` | `==` loose equality |
| `->toBeNull()` | `null` |
| `->toBeTrue()` | `true` |
| `->toBeFalse()` | `false` |
| `->toBeEmpty()` | `empty()` |
| `->toBeNotEmpty()` | `! empty()` |
| `->toBeGreaterThan($n)` | `> $n` |
| `->toBeGreaterThanOrEqual($n)` | `>= $n` |
| `->toBeLessThan($n)` | `< $n` |
| `->toBeLessThanOrEqual($n)` | `<= $n` |
| `->toBeIn($array)` | `in_array()` |

#### Type Assertions
| Expectation | Checks |
|-------------|--------|
| `->toBeString()` | `is_string()` |
| `->toBeInt()` | `is_int()` |
| `->toBeFloat()` | `is_float()` |
| `->toBeBool()` | `is_bool()` |
| `->toBeArray()` | `is_array()` |
| `->toBeObject()` | `is_object()` |
| `->toBeInstanceOf($class)` | `instanceof` |
| `->toHaveCount($n)` | `count() === $n` |

#### String Assertions
| Expectation | Checks |
|-------------|--------|
| `->toContain($needle)` | `str_contains()` |
| `->toStartWith($prefix)` | `str_starts_with()` |
| `->toEndWith($suffix)` | `str_ends_with()` |
| `->toMatch($regex)` | `preg_match()` |
| `->toBeJson()` | `json_decode() !== null` |

#### Array/Collection Assertions
| Expectation | Checks |
|-------------|--------|
| `->toHaveKey($key)` | `array_key_exists()` |
| `->toHaveKeys($keys)` | All keys exist |
| `->toHaveLength($n)` | `count() === $n` |
| `->each($callback)` | Apply assertion to each element |
| `->sequence($callbacks)` | Assert each element in order |

#### Negation
```php
expect($value)->not->toBeNull();
expect($value)->not->toBeEmpty();
expect($response->json('data'))->not->toHaveKey('password');
```

#### Modifiers
```php
// Chain multiple assertions
expect($user)
    ->name->toBe('John')
    ->email->toBe('john@example.com')
    ->age->toBeGreaterThan(18);

// Assert with condition
expect($value)->when(fn ($v) => $v !== null, fn ($e) => $e->toBeString());

// Match pattern (switch-like)
expect($status)
    ->match(
        'active' => fn ($e) => $e->toBeTrue(),
        'inactive' => fn ($e) => $e->toBeFalse(),
    );
```

### Higher Order Testing

When a test body is only method chains on `$this`, omit the closure:

```php
// Before
it('works', function () {
    $this->get('/')->assertStatus(200);
});

// After (Higher Order)
it('works')
    ->get('/')
    ->assertStatus(200);
```

Combined with expectations (use closures for lazy evaluation):

```php
it('has a name')
    ->expect(fn () => User::create(['name' => 'Nuno'])->name)
    ->toBe('Nuno');
```

### Higher Order Expectations

Chain properties and methods directly on the expectation value:

```php
expect($user)
    ->name->toBe('Nuno')
    ->surname->toBe('Maduro')
    ->email->toBe('enunomaduro@gmail.com')
    ->address()->scoped(fn ($address) => $address
        ->line1->toBe('1 Pest Street')
        ->city->toBe('Lisbon')
        ->country->toBe('Portugal')
    );
```

---

## Datasets (Parameterized Tests)

### Inline Datasets

```php
it('calculates squares correctly', function (int $input, int $expected) {
    expect($input ** 2)->toBe($expected);
})->with([
    [2, 4],
    [3, 9],
    [10, 100],
    [0, 0],
    [-3, 9],
]);
```

### Named Datasets (better failure output)

```php
it('validates email addresses', function (string $email, bool $valid) {
    expect(Validator::isValid($email))->toBe($valid);
})->with([
    'valid email'       => ['user@example.com', true],
    'missing @'         => ['userexample.com', false],
    'empty string'      => ['', false],
    'spaces only'       => ['   ', false],
    'valid plus format' => ['user+tag@example.com', true],
]);
```

### Shared Datasets

Store in `tests/Datasets/` for reuse across files:

```php
// tests/Datasets/ValidationData.php
dataset('invalid_post_payloads', [
    'missing title'  => [['body' => 'Some body'], 'title'],
    'missing body'   => [['title' => 'Some title'], 'body'],
    'empty title'    => [['title' => '', 'body' => 'Body'], 'title'],
    'title too long' => [['title' => str_repeat('a', 256), 'body' => 'Body'], 'title'],
]);

// In any test file:
it('rejects invalid post data', function (array $payload, string $field) {
    $response = $this->postJson('/api/posts', $payload);
    $response->assertUnprocessable();
    $response->assertJsonValidationErrors([$field]);
})->with('invalid_post_payloads');
```

### Bound Datasets (Laravel)

Resolved after `beforeEach()` — useful when database is needed:

```php
dataset('users', [
    [fn () => User::factory()->create(['role' => 'admin']), true],
    [fn () => User::factory()->create(['role' => 'guest']), false],
]);

it('checks admin access', function (User $user, bool $expected) {
    expect($user->can('admin-panel'))->toBe($expected);
})->with('users');
```

### Combining Datasets

Multiple `->with()` calls produce a cartesian product:

```php
it('tests all combinations', function ($role, $permission) {
    // runs 3 × 4 = 12 times
})->with(['admin', 'editor', 'viewer'])
  ->with(['create', 'read', 'update', 'delete']);
```

### Describe Block Datasets

```php
describe('admin operations', function () {
    beforeEach(function () {
        $this->admin = User::factory()->admin()->create();
    });

    it('can delete posts', function () {
        // ...
    });
})->with([['admin'], ['super-admin']]);
```

---

## Laravel-Specific Testing

### HTTP Tests

```php
use Illuminate\Testing\Fluent\AssertableJson;

it('lists all reports', function () {
    $token = config('app.temp_api_token');
    // Or: Sanctum::actingAs(User::factory()->create());

    $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
        ->getJson('/v1/reports');

    $response->assertOk()
        ->assertJsonStructure([
            'data' => [
                'type',
                'id',
                'attributes' => [
                    'title',
                    'status',
                ],
            ],
            'meta' => ['api_version', 'status'],
        ])
        ->assertJson(fn (AssertableJson $json) =>
            $json->where('data.type', 'response')
                 ->where('meta.status', 200)
                 ->etc()
        );
});

it('creates a report with valid data', function () {
    $reportData = [
        'title' => 'Accident on ARC highway',
        'kilometer' => 45,
        'event_type' => 'accident',
    ];

    $response = $this->actingAs(User::factory()->create())
        ->postJson('/v1/reports', $reportData);

    $response->assertCreated()
        ->assertJsonPath('data.attributes.title', 'Accident on ARC highway');

    // CRITICAL: Verify the database was actually written
    $this->assertDatabaseHas('traffic_reports', [
        'title' => 'Accident on ARC highway',
    ]);
});
```

### Response Assertions

| Method | Meaning |
|--------|---------|
| `assertOk()` | 200 |
| `assertCreated()` | 201 |
| `assertAccepted()` | 202 |
| `assertNoContent()` | 204 |
| `assertUnauthorized()` | 401 |
| `assertForbidden()` | 403 |
| `assertNotFound()` | 404 |
| `assertUnprocessable()` | 422 |
| `assertSuccessful()` | 200-299 |
| `assertRedirect()` | 302 |

**Always use named assertions over raw status codes.** `assertUnauthorized()` communicates intent; `assertStatus(401)` communicates a number.

### Database Testing

```php
use Illuminate\Foundation\Testing\RefreshDatabase;

// In tests/Pest.php:
pest()->use(RefreshDatabase::class)->in('Feature');

// In test:
it('persists report data to the database', function () {
    $report = Report::factory()->create(['title' => 'Test Report']);

    $this->assertDatabaseHas('traffic_reports', [
        'id' => $report->id,
        'title' => 'Test Report',
    ]);

    $this->assertDatabaseCount('traffic_reports', 1);
    $this->assertModelExists($report);
    $this->assertSoftDeleted($report); // If using SoftDeletes
});
```

### Factories — Custom States

Factories should define meaningful states, not just default data:

```php
// database/factories/TrafficReportFactory.php
class TrafficReportFactory extends Factory
{
    public function definition(): array
    {
        return [
            'title' => fake()->sentence(),
            'is_open' => true,
            'kilometer' => fake()->randomFloat(1, 0, 100),
            // ... defaults
        ];
    }

    public function closed(): static
    {
        return $this->state(fn (array $attrs) => [
            'is_open' => false,
            'closed_at' => now(),
        ]);
    }

    public function withState(string $stateName): static
    {
        $state = State::where('name', $stateName)->first()
            ?? State::factory()->create(['name' => $stateName]);

        return $this->state(fn (array $attrs) => [
            'state_id' => $state->id,
        ]);
    }

    public function highway(string $code): static
    {
        $highway = Highway::where('code', $code)->first()
            ?? Highway::factory()->create(['code' => $code]);

        return $this->state(fn (array $attrs) => [
            'highway_id' => $highway->id,
        ]);
    }
}
```

### Authentication Testing

**Two common patterns in this codebase:**

1. **API Token auth** (config-based):
```php
$token = config('app.temp_api_token');
$response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
    ->getJson('/v1/reports');
```

2. **Sanctum auth** (user-based):
```php
use Laravel\Sanctum\Sanctum;

$user = User::factory()->create();
Sanctum::actingAs($user, ['*'], 'api');

$response = $this->getJson('/v1/reports');
```

### Custom Test Case Assertions (in TestCase.php)

Encapsulate repeated response assertions in the base `TestCase`:

```php
abstract class TestCase extends BaseTestCase
{
    // Success response helpers
    public function assertSuccessResponse(TestResponse $response, array $expectedData = []): void
    {
        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => ['type', 'id', 'attributes'],
                'timestamp',
                'meta' => ['api_version', 'status', 'copyright'],
            ]);

        // Verify timestamp format (ISO 8601 with microseconds)
        expect($response->json('timestamp'))
            ->toMatch('/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z$/');

        if (!empty($expectedData)) {
            $attributes = $response->json('data.attributes');
            foreach ($expectedData as $key => $value) {
                expect($attributes)->toHaveKey($key);
                expect($attributes[$key])->toBe($value);
            }
        }
    }

    // Error response helpers
    public function assertErrorResponse(TestResponse $response, int $statusCode, string $expectedTitle): void
    {
        $response->assertStatus($statusCode)
            ->assertJsonStructure([
                'meta' => ['timestamp', 'api_version', 'status'],
                'errors' => [['status', 'code', 'title', 'detail']],
            ]);
    }

    // Shortcuts
    public function assertUnauthorizedResponse(TestResponse $response): void
    {
        $this->assertErrorResponse($response, 401, 'Unauthorized');
    }

    public function assertForbiddenResponse(TestResponse $response): void
    {
        $this->assertErrorResponse($response, 403, 'Forbidden');
    }
}
```

### Fakes (The Laravel Way)

Use Laravel's built-in fakes — they make assertions without brittle mock expectations:

```php
it('sends welcome email after registration', function () {
    Notification::fake();

    $this->post('/register', [
        'name' => 'John',
        'email' => 'john@example.com',
        'password' => 'password',
    ]);

    $user = User::where('email', 'john@example.com')->first();

    Notification::assertSentTo($user, WelcomeEmail::class);
});

it('queues report generation', function () {
    Queue::fake();

    $this->actingAs($user)->postJson('/v1/reports', $data);

    Queue::assertPushed(GenerateReportJob::class);
});

it('caches km references', function () {
    Cache::spy(); // Use spy to assert cache interactions

    $this->getJson('/v1/km-references');

    Cache::shouldHaveReceived('get')
        ->with('km_references:*')
        ->atLeast()->once();
});
```

### Artisan Command Testing

```php
it('closes expired reports', function () {
    Report::factory()->expired()->create(['is_open' => true]);

    $this->artisan('reports:close', ['ids' => [1], '--type' => 'traffic'])
        ->assertExitCode(0);

    $this->assertDatabaseHas('traffic_reports', [
        'id' => 1,
        'is_open' => false,
    ]);
});
```

---

## Mocking Strategy

### The Most Important Rule

**Mock at the system boundary, not inside your domain logic.**

✅ Mock: HTTP client, mail transport, filesystem, queue driver, external API  
❌ Mock: Value objects, domain services, your own repositories, Eloquent models  
✅ Use real implementations for everything inside your application boundary  
❌ Never mock what you don't own — mock the interface, not the implementation detail  

### Preference Hierarchy (from most to least preferred)

1. **Real implementation** — fastest to write, most refactor-resistant
2. **Fake** — lightweight in-memory implementation of an interface (e.g., `InMemoryReportRepository implements ReportRepository`)
3. **Test double via `createStub()`/`createMock()`** — PHPUnit's built-in
4. **Mockery** — only when PHPUnit's mock API is insufficient (strict ordering, partial mocking)
5. **Prophecy** — legacy, use only in existing codebases

### Fakes Over Mocks

A fake is a lightweight implementation of an interface that stores state in memory:

```php
// tests/Fakes/InMemoryReportRepository.php
class InMemoryReportRepository implements ReportRepositoryInterface
{
    private array $reports = [];

    public function save(Report $report): void
    {
        $this->reports[$report->id] = $report;
    }

    public function find(int $id): ?Report
    {
        return $this->reports[$id] ?? null;
    }

    public function findAll(): array
    {
        return array_values($this->reports);
    }
}

// In test:
test('creates and retrieves report via repository', function () {
    $repo = new InMemoryReportRepository();
    $service = new ReportService($repo);

    $service->createReport(['title' => 'Test']);
    $result = $service->getReport(1);

    expect($result['title'])->toBe('Test');
});
```

**Why fakes win**: When you refactor the interface, the fake breaks at compile time (implements the interface). Mocks only break at test runtime. Fakes survive refactoring; mocks don't.

### MockApiClient Pattern (Used in scaem.app)

For service classes that depend on an HTTP API client, use a custom mock that extends the real client:

```php
// tests/MockApiClient.php
class MockApiClient extends ApiClient
{
    private array $responses = [];
    private array $callHistory = [];

    public function willReturn(string $method, string $endpoint, mixed $response): self
    {
        $this->responses[$this->key($method, $endpoint)] = $response;
        return $this;
    }

    public function getCallHistory(): array
    {
        return $this->callHistory;
    }

    public function assertCalled(string $method, string $endpoint): bool
    {
        foreach ($this->callHistory as $call) {
            if ($call['method'] === strtoupper($method) && $call['endpoint'] === $endpoint) {
                return true;
            }
        }
        return false;
    }

    // Override parent methods with recorded responses
    public function get(string $endpoint, array $headers = []): ?array
    {
        $this->callHistory[] = ['method' => 'GET', 'endpoint' => $endpoint, 'data' => []];
        return $this->responses[$this->key('GET', $endpoint)] ?? null;
    }

    public function post(string $endpoint, array $data, array $headers = []): ?array
    {
        $this->callHistory[] = ['method' => 'POST', 'endpoint' => $endpoint, 'data' => $data];
        return $this->responses[$this->key('POST', $endpoint)] ?? null;
    }

    private function key(string $method, string $endpoint): string
    {
        return strtoupper($method) . ':' . $endpoint;
    }
}
```

Usage pattern (covers both success and failure paths with real call verification):

```php
test('returns data on success', function () {
    $mockApi = new MockApiClient();
    $mockApi->willReturn('GET', '/v1/reports', [
        'data' => ['attributes' => [['id' => 1, 'title' => 'Test']]],
    ]);
    $service = new ReportService($mockApi);

    $result = $service->getReports();

    expect($result['success'])->toBeTrue();
    expect($mockApi->assertCalled('GET', '/v1/reports'))->toBeTrue();
});

test('returns empty on network failure', function () {
    $mockApi = new MockApiClient();
    $mockApi->willReturn('GET', '/v1/reports', ['_http_code' => 500]);
    $service = new ReportService($mockApi);

    $result = $service->getReports();

    expect($result['success'])->toBeFalse();
    expect($result['network_error'])->toBeTrue();
});
```

### Mockery

When you must use Mockery (e.g., existing patterns in the codebase):

```php
use Mockery\MockInterface;

test('service delegates to repository', function () {
    $repository = Mockery::mock(ReportRepositoryInterface::class);
    $repository->shouldReceive('find')
        ->with(42)
        ->once()
        ->andReturn(new Report(['id' => 42]));

    $service = new ReportService($repository);
    $result = $service->getReport(42);

    expect($result)->not->toBeNull();
    expect($result['id'])->toBe(42);
});
```

---

## Vanilla PHP Testing (Without Laravel)

For non-Laravel PHP projects (like the scaem.app pattern), test setup is minimal:

### `tests/Pest.php` — Vanilla

```php
<?php

require_once __DIR__ . '/../app/config/autoloader_configuration.php';

putenv('APP_ENV=testing');
if (!defined('APP_ENV')) {
    define('APP_ENV', 'testing');
}
```

### Unit Testing Services

Instantiate the service directly with test data — no bootstrapping needed:

```php
test('aggregates stats for empty sessions', function () {
    $service = new ScrapmapReportService();
    $stats = $service->computeStats([]);

    expect($stats['totalSessions'])->toBe(0);
    expect($stats['totalDetections'])->toBe(0);
    expect($stats['uniqueRouteCount'])->toBe(0);
    expect($stats['magnitudCounts']['moderate'])->toBe(0);
    expect($stats['magnitudCounts']['severe'])->toBe(0);
});

test('handles null events_detected using coalesce', function () {
    $service = new ScrapmapReportService();
    $sessions = [
        'readings' => [
            ['events_detected' => null, 'route' => ['name' => 'ARC']],
            ['events_detected' => 3, 'route' => ['name' => 'ARC']],
        ],
    ];

    $stats = $service->computeStats($sessions);

    // The coalesce operator (??) should convert null to 0
    expect($stats['totalDetections'])->toBe(3);
});
```

### Integration Testing with MockApiClient

Same MockApiClient pattern applies to vanilla PHP:

```php
describe('SsgReportService', function () {
    describe('createNexovialReport()', function () {
        test('injects operator_id into payload', function () {
            $mockApi = new MockApiClient();
            $mockApi->willReturn('POST', '/v1/sgi/reports', [
                'data' => ['attributes' => ['report_id' => 123]],
            ]);
            $service = new SsgReportService($mockApi);

            $service->createNexovialReport(['km' => '45'], 42);

            $history = $mockApi->getCallHistory();
            expect($history[0]['data']['operator_id'])->toBe('42');
        });

        test('returns validation errors on 422', function () {
            $mockApi = new MockApiClient();
            $mockApi->willReturn('POST', '/v1/sgi/reports', [
                '_http_code' => 422,
                'errors' => ['kilometer' => ['El campo kilómetro es requerido']],
            ]);
            $service = new SsgReportService($mockApi);

            $result = $service->createNexovialReport([], 1);

            expect($result['success'])->toBeFalse();
            expect($result['errors'])->toHaveKey('kilometer');
        });
    });
});
```

---

## Architecture Testing

Architecture tests enforce structural rules automatically — they're executable design decisions.

### Built-in Presets (Pest 3+)

```php
// tests/Architecture/ArchitectureTest.php

// PHP preset — no die/dump/var_dump in production code
arch()->preset()->php();

// Security preset — no eval, md5, shell_exec, unserialize
arch()->preset()->security();

// Laravel preset — enforce Laravel conventions
arch()->preset()->laravel();

// Strict preset — final classes, strict types, no protected methods
arch()->preset()->strict();

// Relaxed preset — permissive (for legacy codebases)
arch()->preset()->relaxed();
```

### Custom Architecture Rules

```php
arch('controllers have Controller suffix')
    ->expect('App\Http\Controllers')
    ->toHaveSuffix('Controller');

arch('controllers use form requests')
    ->expect('App\Http\Controllers')
    ->toUse('App\Http\Requests');

arch('services are final')
    ->expect('App\Services')
    ->ignoring('App\Services\AbstractService')
    ->toBeFinal();

arch('models extend Eloquent Model')
    ->expect('App\Models')
    ->toExtend('Illuminate\Database\Eloquent\Model');

arch('no dd or dump in production')
    ->expect('App')
    ->not->toUse(['dd', 'dump', 'var_dump', 'print_r', 'ray']);

arch('all files use strict types')
    ->expect('App')
    ->toUseStrictTypes();

arch('repositories only touch models and DB')
    ->expect('App\Repositories')
    ->toOnlyUse([
        'App\Models',
        'Illuminate\Database',
        'Illuminate\Support\Collection',
    ]);

arch('services don\'t depend on HTTP layer')
    ->expect('App\Services')
    ->not->toUse('Illuminate\Http\Request');

arch('controllers don\'t use Eloquent directly')
    ->expect('App\Http\Controllers')
    ->not->toUse('Illuminate\Database\Eloquent\Builder');
```

### Layer Enforcement (for DDD/Clean Architecture)

```php
arch('domain has no framework dependencies')
    ->expect('Domain')
    ->not->toUse(['App\Http', 'Illuminate\Http']);

arch('application uses domain')
    ->expect('App\Application')
    ->toUse('Domain');

arch('infrastructure implements domain contracts')
    ->expect('App\Infrastructure')
    ->toImplement('Domain\Contracts');
```

### Ignoring Exceptions

```php
arch('services are final')
    ->expect('App\Services')
    ->ignoring('App\Services\AbstractService')
    ->toBeFinal();

arch('no dd in production')
    ->expect('App')
    ->not->toUse('dd')
    ->ignoring('App\Debug\DebugService');
```

---

## Advanced Features

### Mutation Testing (Pest 3+)

Mutation testing checks if your tests would catch code changes:

```bash
php artisan test --mutate --filter=DiscountService
php artisan test --mutate --min=80  # Fail if MSI < 80%
```

**Best practices:**
- Start small — one namespace at a time, not the whole app
- Do NOT block CI on mutation score from day one
- Use `covers()` to declare which class a test covers
- Use `mutates()` (Pest 3+) to scope mutation analysis

```php
it('calculates discount correctly')
    ->covers(DiscountService::class, 'calculate')
    ->expect(fn () => (new DiscountService())->calculate(100, 10))
    ->toBe(90.0);
```

### Snapshot Testing

Good for stable outputs (API contracts, generated configs), NOT for dynamic HTML:

```php
it('matches API response snapshot', function () {
    $response = $this->getJson('/v1/reports/1');

    expect($response->json())->toMatchSnapshot();
});
```

```bash
# Update snapshots when contract intentionally changes
php artisan test --update-snapshots
```

### Custom Expectations

Define reusable assertions in `tests/Pest.php`:

```php
expect()->extend('toBeWithinRange', function (int $min, int $max) {
    expect($this->value)->toBeGreaterThanOrEqual($min);
    expect($this->value)->toBeLessThanOrEqual($max);
    return $this;
});

expect()->extend('toHaveValidationError', function (string $field) {
    test()->assertJsonValidationErrors($field);
    return $this;
});

// Usage:
expect($score)->toBeWithinRange(0, 100);
expect($response)->toHaveValidationError('email');
```

### Custom Helpers

Define global helpers in `tests/Helpers.php` or `tests/Pest.php`:

```php
function authenticatedUser(array $attributes = []): User
{
    return User::factory()->create($attributes);
}

function mockExternalApi(array $response): MockApiClient
{
    $mock = new MockApiClient();
    $mock->willReturn('GET', '/external/api', $response);
    return $mock;
}
```

### Flaky Test Handling (Pest 4.7+)

Pest 4.7 supports automatic retries for flaky tests:

```bash
php artisan test --retry=3  # Retry failed tests up to 3 times
```

In `pest.xml`:
```xml
<phpunit>
    <retryCount>3</retryCount>
</phpunit>
```

---

## CI/CD Integration

### Parallel Testing

```bash
# Pest native parallel — no extra package needed
php artisan test --parallel

# With process count
php artisan test --parallel --processes=8
```

**⚠️ Parallel requires per-test database isolation.** Use SQLite `:memory:` (each process gets its own DB) or per-process database names.

### GitHub Actions Workflow

```yaml
name: Tests
on: [push, pull_request]

jobs:
  tests:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        php: [8.2, 8.3, 8.4]
        laravel: [11, 12, 13]

    steps:
      - uses: actions/checkout@v4
      - uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ matrix.php }}
          extensions: pdo_sqlite, mbstring, intl
          coverage: xdebug

      - run: composer install --no-interaction --prefer-dist

      # Safety: ensure no config cache
      - run: php artisan config:clear

      - run: php artisan test --parallel --coverage --min=80
```

### Nx Test Setup (Monorepo)

For projects in an Nx monorepo, define test targets in `project.json`:

```json
{
  "targets": {
    "test": {
      "executor": "nx:run-commands",
      "options": {
        "command": "php artisan test --parallel"
      }
    },
    "ci-test-setup": {
      "commands": [
        "cp .env.example .env",
        "php artisan key:generate",
        "php artisan config:clear"
      ],
      "cache": false
    },
    "ci-test": {
      "executor": "nx:run-commands",
      "options": {
        "command": "php artisan test --parallel"
      },
      "cache": true,
      "dependsOn": ["ci-test-setup"]
    }
  }
}
```

Run from workspace root:
```bash
pnpm nx run <project>:test
pnpm nx run <project>:ci-test  # With setup
```

---

## Things You MUST NEVER Do

### ❌ NEVER Write Tests That Don't Verify Anything
```php
// WRONG — passes without proving anything
it('creates a report', function () {
    $this->postJson('/api/reports', $data)->assertCreated();
    // Where's the database assertion? Did it actually persist?
});

// RIGHT — verifies database was written
it('creates a report', function () {
    $this->postJson('/api/reports', $data)->assertCreated();
    $this->assertDatabaseHas('reports', ['title' => $data['title']]);
});
```

### ❌ NEVER Mock Everything
```php
// WRONG — mocks the entire world, tests nothing real
$repo = $this->createMock(ReportRepository::class);
$mailer = $this->createMock(Mailer::class);
$validator = $this->createMock(Validator::class);
$service = new ReportService($repo, $mailer, $validator);

// RIGHT — mock only the boundary
$httpClient = $this->createMock(HttpClient::class);
$service = new ReportService($httpClient);  // Uses real repositories, real validation
```

### ❌ NEVER Suppress Type Errors in Tests
```php
// WRONG
$result = $service->process($data);
expect($result)->toBe($expected); // If process() throws, test just fails — no type safety

// RIGHT — declare types
test('process returns array', function () {
    /** @var array $result */
    $result = $service->process($data);
    expect($result)->toBeArray();
    expect($result['status'])->toBe('processed');
});
```

### ❌ NEVER Delete Tests Without Understanding Why
Tests document behavior. If a test fails after your change, either:
1. Your change broke something (fix the code, not the test)
2. The behavior intentionally changed (update the test to document the new behavior)
3. The test was genuinely wrong (rare — verify with the team)

### ❌ NEVER Skip Testing Failure Modes
```php
// WRONG — happy path only
test('returns reports', function () {
    // ...
});

// RIGHT — both happy and sad paths
test('returns reports on success', function () { /* ... */ });
test('returns empty array when API fails', function () { /* ... */ });
test('returns error when unauthorized', function () { /* ... */ });
test('handles timeout gracefully', function () { /* ... */ });
```

### ❌ NEVER Use `@group` to Hide Failing Tests
Groups are for organizing, not hiding. A failing test in a group others run in CI means the failure gets ignored until it breaks production.

### ❌ NEVER Write Circular Assertions
```php
// WRONG — tests nothing at all
it('roundtrip serialization', function () {
    $data = ['name' => 'Test', 'value' => 42];
    $json = json_encode($data);
    $decoded = json_decode($json, true);
    expect($decoded)->toBe($data); // Always passes — same thing encoded and decoded
});
```

---

## Decision Trees

### What Type of Test to Write?

```
What am I testing?
├── Pure computation/side-effect-free logic
│   └── → Unit Test (instantiate, call method, assert result)
├── HTTP endpoint (request → response)
│   ├── Laravel → Feature Test with HTTP helpers
│   └── Vanilla PHP → Integration test with real superglobals
├── Service with external dependencies
│   ├── Dependency is an interface → Fake it  
│   └── Dependency is a concrete class → MockApiClient pattern
├── Artisan command
│   └── → Feature Test with artisan() helper
├── Enforcing project structure
│   └── → Architecture Test (arch()->expect())
├── Third-party API contract
│   └── → Integration test with MockApiClient + snapshot
└── Full user flow
    └── → Browser/E2E test (Dusk or Playwright)
```

### What to Assert?

```
After calling the code under test...
├── Did the response contain the right data? → assertJsonPath, assertSee
├── Did the database change correctly? → assertDatabaseHas, assertDatabaseCount
├── Was the side effect triggered? → Notification::assertSent, Queue::assertPushed
├── Was the external API called correctly? → MockApiClient::getCallHistory
├── Does the error handling work? → assertNotFound, assertUnprocessable
└── Is the structure right? → assertJsonStructure, arch tests
```

---

## Project-Specific Patterns (DataEmergencia Monorepo)

This skill is written for the DataEmergencia monorepo. Here are patterns specific to this codebase:

### Pest Versions by App

| App | Pest Version | Laravel | Type |
|-----|-------------|---------|------|
| `ssg.nexovial.net` | ^4.4 | ^13.0 | API |
| `api.dataemergencia.com` | ^4.1 | ^12.0 | API |
| `carnets.qrnet.app` | ^4.1 | ^12.0 | Inertia |
| `scaem.app` | ^4.7 | None | Vanilla PHP |
| `sar.scaem.app` | ^4.7 | ^13.0 | Inertia |
| `nexovial.net` | ^4.1 | ^12.0 | Inertia |
| `cli` | ^3.8 | Laravel Zero | CLI |
| `bp.scaem.app` | ^3.7 | ^12.0 | Bootstrap |
| `cobranza.dataemergencia.com` | ^4.3 | ^12.0 | API |

### scaem.app (Vanilla PHP) Testing Patterns

- Uses `MockApiClient` (extends real `ApiClient`) for HTTP dependency injection
- No Laravel bootstrapping — pure class instantiation
- Test files organized as `Unit/` and `Integration/` (not `Feature/`)
- Direct `new ClassName()` construction with mock dependencies
- Assert both call history (`assertCalled()`) and call payloads (`getCallHistory()`)

### ssg.nexovial.net (Laravel) Testing Patterns

- `TestCase` with 12 custom assertion helpers (assertSuccessResponse, assertErrorResponse, etc.)
- `RefreshDatabase` on all Feature tests
- Two auth patterns: config-based `api_token` and Sanctum `actingAs()`
- Response format: JSON:API envelope with `data.type`, `data.id`, `data.attributes`, `timestamp`, `meta`
- Config cache safety guard in `tests/Pest.php`
- CI via Nx: `pnpm nx run <project>:ci-test` (includes env setup)
- Shared helpers in `tests/Helpers/Scrapmap.php`
- Mockery used for service layer mocks in Unit tests

### Running Tests in the Monorepo

```bash
# Single project
pnpm nx run ssg.nexovial.net:laravel:test

# With config clear (ALWAYS do this first)
cd apps/ssg.nexovial.net && php artisan config:clear && php artisan test

# All affected by changes
pnpm nx affected -t test

# CI pipeline
pnpm nx affected -t ci-test
```

---

## Key Learnings & Gotchas

### Config Cache Danger
If `bootstrap/cache/config.php` exists, `phpunit.xml` database overrides are IGNORED. `RefreshDatabase` would run `migrate:fresh` on your **real** database. Always run `php artisan config:clear` before tests.

### Parallel Testing Database Isolation
Pest parallel mode runs tests in separate processes. Each process needs its own database. SQLite `:memory:` works automatically (each process gets isolated memory). MySQL/PostgreSQL need per-process database names (`testing_1`, `testing_2`, etc.).

### Pest Runs on PHPUnit
`vendor/bin/pest` runs PHPUnit under the hood. Your `phpunit.xml` is shared between Pest and PHPUnit tests. You can mix Pest and PHPUnit test files in the same suite.

### No `scripts` in per-project `package.json`
In Nx monorepos, do NOT add `scripts` to individual `apps/*/package.json`. All commands are Nx targets defined in `project.json`. Tests run via `pnpm nx run <project>:test`, not `cd apps/project && php artisan test`.

### Dataset Parameter Types Matter
Bound datasets require fully-typed parameters in the test closure:
```php
// ✅ Correct
it('works', function (User $user, string $name) { ... })->with([...]);
// ❌ Wrong — missing type for $user
it('works', function ($user, $name) { ... })->with([...]);
```

### Timestamp Assertions
This codebase uses ISO 8601 timestamps with microsecond precision:
```php
expect($response->json('timestamp'))
    ->toMatch('/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z$/');
```
