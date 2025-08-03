# TypeScript Style Guide

## Runtime

### 🚨 SEMPRE use Bun como primeira opção
- **Bun** é 3x mais rápido que Node.js
- Node.js apenas se Bun incompatível
- Deno como alternativa para edge/serverless

```bash
# Instalar Bun (uma vez)
curl -fsSL https://bun.sh/install | bash

# Criar projeto
bun init

# Instalar dependências
bun install

# Executar
bun run dev
bun run build

# Executar arquivo TypeScript diretamente
bun run index.ts
```

## Package Management

### Ordem de Preferência
1. **bun** (quando usando Bun runtime)
2. **pnpm** (mais eficiente que npm/yarn)
3. **yarn** (se já existente no projeto)
4. **npm** (último recurso)

```bash
# Com Bun
bun add package-name
bun add -d dev-package

# Com pnpm
pnpm add package-name
pnpm add -D dev-package
```

## TypeScript Configuration

### tsconfig.json Moderno
```json
{
  "compilerOptions": {
    // Type Safety - SEMPRE strict
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    
    // Modern Output
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    
    // Interop
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "resolveJsonModule": true,
    
    // DX
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    
    // Paths
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

## Type Safety

### Evite `any` - Use `unknown`
```typescript
// ❌ Ruim
function process(data: any) {
  return data.value; // Sem type safety
}

// ✅ Bom
function process(data: unknown) {
  if (isValidData(data)) {
    return data.value; // Type safe
  }
  throw new Error("Invalid data");
}
```

### Zod para Validação Runtime
```typescript
import { z } from "zod";

// Define schema
const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  age: z.number().min(0).max(120),
});

// Infer type from schema
type User = z.infer<typeof UserSchema>;

// Validate
function validateUser(data: unknown): User {
  return UserSchema.parse(data); // Throws if invalid
}
```

## Modern Patterns

### Prefer Functional over OOP
```typescript
// ❌ Heavy OOP
class UserService {
  private db: Database;
  
  constructor(db: Database) {
    this.db = db;
  }
  
  async getUser(id: string) {
    return this.db.query(id);
  }
}

// ✅ Functional
const createUserService = (db: Database) => ({
  getUser: async (id: string) => db.query(id),
  updateUser: async (id: string, data: Partial<User>) => 
    db.update(id, data),
});
```

### Immutability por Padrão
```typescript
// Use const assertions
const config = {
  api: "https://api.example.com",
  timeout: 5000,
} as const;

// Readonly types
type Config = Readonly<{
  api: string;
  timeout: number;
}>;

// Spread for updates
const newData = { ...oldData, field: newValue };
```

### Composition over Inheritance
```typescript
// ✅ Composition
type Timestamped = {
  createdAt: Date;
  updatedAt: Date;
};

type User = Timestamped & {
  id: string;
  email: string;
};

type Post = Timestamped & {
  id: string;
  title: string;
  authorId: string;
};
```

## Error Handling

### Result Pattern
```typescript
type Result<T, E = Error> = 
  | { ok: true; value: T }
  | { ok: false; error: E };

async function fetchUser(id: string): Promise<Result<User>> {
  try {
    const user = await api.get(`/users/${id}`);
    return { ok: true, value: user };
  } catch (error) {
    return { ok: false, error: error as Error };
  }
}

// Usage
const result = await fetchUser("123");
if (result.ok) {
  console.log(result.value);
} else {
  console.error(result.error);
}
```

## API Design

### tRPC for Type-Safe APIs
```typescript
import { initTRPC } from "@trpc/server";
import { z } from "zod";

const t = initTRPC.create();

export const appRouter = t.router({
  user: t.router({
    get: t.procedure
      .input(z.string().uuid())
      .query(async ({ input }) => {
        return await db.user.findUnique({ where: { id: input } });
      }),
    
    create: t.procedure
      .input(UserSchema)
      .mutation(async ({ input }) => {
        return await db.user.create({ data: input });
      }),
  }),
});

export type AppRouter = typeof appRouter;
```

## Testing

### Vitest (Faster than Jest)
```typescript
import { describe, it, expect } from "vitest";

describe("User Service", () => {
  it("should fetch user by id", async () => {
    const user = await fetchUser("123");
    expect(user).toMatchObject({
      id: "123",
      email: expect.stringContaining("@"),
    });
  });
});
```

## File Organization

```typescript
// Barrel exports in index.ts
export * from "./types";
export * from "./utils";
export { userService } from "./services/user";

// Named exports preferred
export const processData = (data: Data) => {
  // ...
};

// Default exports only for pages/components
export default function HomePage() {
  // ...
}
```

## Performance Tips

### Use Bun's Built-in APIs
```typescript
// File I/O (Bun is faster)
const file = Bun.file("data.json");
const data = await file.json();

// Hashing (Bun native)
const hash = Bun.hash("my-string");

// HTTP Server (Bun native)
Bun.serve({
  port: 3000,
  fetch(req) {
    return new Response("Hello from Bun!");
  },
});
```

### Lazy Loading
```typescript
// Dynamic imports for code splitting
const HeavyComponent = lazy(() => import("./HeavyComponent"));

// Conditional loading
if (needsFeature) {
  const { feature } = await import("./feature");
  feature.init();
}
```

## Common Libraries

### Essential Stack
```typescript
// Runtime & Type Safety
"bun"           // Runtime
"typescript"    // Language
"zod"           // Schema validation
"@types/node"   // Node types (if needed)

// Web Framework (choose one)
"elysia"        // Bun-native, fast
"hono"          // Multi-runtime
"remix"         // Full-stack React

// API
"@trpc/server"  // Type-safe APIs
"drizzle-orm"   // TypeScript ORM

// Testing
"vitest"        // Fast test runner
"@testing-library/react" // React testing
```

## Never Do

- ❌ Use `any` type (use `unknown` or proper types)
- ❌ Ignore TypeScript errors (fix them)
- ❌ Use `require()` (use ES modules)
- ❌ Mutate objects directly (use spread/immutable updates)
- ❌ Use classes for everything (prefer functions)
- ❌ Ship without type checking (`tsc --noEmit`)
- ❌ Use Node.js if Bun works for your use case