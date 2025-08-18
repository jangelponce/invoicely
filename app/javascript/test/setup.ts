import '@testing-library/jest-dom'
import { vi } from 'vitest'

// Mock nuqs module since it's used in the component
vi.mock('nuqs', () => ({
  useQueryState: vi.fn(() => [null, vi.fn()]),
}))
