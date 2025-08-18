import { render, screen, fireEvent } from '@testing-library/react'
import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest'
import { Filters } from './index'

// Mock nuqs
const mockSetStartRange = vi.fn()
const mockSetEndRange = vi.fn()

vi.mock('nuqs', () => ({
  useQueryState: vi.fn(),
}))

import { useQueryState } from 'nuqs'
const mockUseQueryState = vi.mocked(useQueryState)

describe('Filters Component', () => {
  beforeEach(() => {
    // Reset mocks before each test
    mockSetStartRange.mockClear()
    mockSetEndRange.mockClear()
    
    // Default mock implementation
    mockUseQueryState
      .mockReturnValueOnce([null, mockSetStartRange]) // startRange
      .mockReturnValueOnce([null, mockSetEndRange])   // endRange
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('renders both date input fields with correct labels', () => {
    render(<Filters />)
    
    expect(screen.getByLabelText('Filtrar desde')).toBeInTheDocument()
    expect(screen.getByLabelText('hasta')).toBeInTheDocument()
  })

  it('renders start date input with correct attributes', () => {
    render(<Filters />)
    
    const startDateInput = screen.getByLabelText('Filtrar desde')
    expect(startDateInput).toHaveAttribute('type', 'date')
    expect(startDateInput).toHaveAttribute('id', 'start-date')
  })

  it('renders end date input with correct attributes', () => {
    render(<Filters />)
    
    const endDateInput = screen.getByLabelText('hasta')
    expect(endDateInput).toHaveAttribute('type', 'date')
    expect(endDateInput).toHaveAttribute('id', 'end-date')
  })

  it('displays empty values when no query state is set', () => {
    render(<Filters />)
    
    const startDateInput = screen.getByLabelText('Filtrar desde') as HTMLInputElement
    const endDateInput = screen.getByLabelText('hasta') as HTMLInputElement
    
    expect(startDateInput.value).toBe('')
    expect(endDateInput.value).toBe('')
  })

  it('displays formatted date values from query state', () => {
    // Mock with date values
    mockUseQueryState
      .mockReturnValueOnce(['2023-12-01T10:30:00Z', mockSetStartRange])
      .mockReturnValueOnce(['2023-12-31T23:59:59Z', mockSetEndRange])

    render(<Filters />)
    
    const startDateInput = screen.getByLabelText('Filtrar desde') as HTMLInputElement
    const endDateInput = screen.getByLabelText('hasta') as HTMLInputElement
    
    expect(startDateInput.value).toBe('2023-12-01')
    expect(endDateInput.value).toBe('2023-12-31')
  })

  it('calls setStartRange when start date changes', () => {
    mockUseQueryState
      .mockReturnValueOnce([null, mockSetStartRange])
      .mockReturnValueOnce([null, mockSetEndRange])

    render(<Filters />)
    
    const startDateInput = screen.getByLabelText('Filtrar desde')
    fireEvent.change(startDateInput, { target: { value: '2023-01-15' } })
    
    expect(mockSetStartRange).toHaveBeenCalledWith('2023-01-15')
  })

  it('calls setEndRange when end date changes', () => {
    mockUseQueryState
      .mockReturnValueOnce([null, mockSetStartRange])
      .mockReturnValueOnce([null, mockSetEndRange])

    render(<Filters />)
    
    const endDateInput = screen.getByLabelText('hasta')
    fireEvent.change(endDateInput, { target: { value: '2023-01-31' } })
    
    expect(mockSetEndRange).toHaveBeenCalledWith('2023-01-31')
  })

  it('preserves existing end date when changing start date', () => {
    mockUseQueryState
      .mockReturnValueOnce([null, mockSetStartRange])
      .mockReturnValueOnce(['2023-01-31', mockSetEndRange])

    render(<Filters />)
    
    const startDateInput = screen.getByLabelText('Filtrar desde')
    fireEvent.change(startDateInput, { target: { value: '2023-01-15' } })
    
    // Should call with new start date and preserve existing end date
    expect(mockSetStartRange).toHaveBeenCalledWith('2023-01-15')
  })

  it('preserves existing start date when changing end date', () => {
    mockUseQueryState
      .mockReturnValueOnce(['2023-01-15', mockSetStartRange])
      .mockReturnValueOnce([null, mockSetEndRange])

    render(<Filters />)
    
    const endDateInput = screen.getByLabelText('hasta')
    fireEvent.change(endDateInput, { target: { value: '2023-01-31' } })
    
    // Should call with new end date and preserve existing start date
    expect(mockSetEndRange).toHaveBeenCalledWith('2023-01-31')
  })

  it('handles empty date input by setting null', () => {
    mockUseQueryState
      .mockReturnValueOnce(['2023-01-15', mockSetStartRange])
      .mockReturnValueOnce(['2023-01-31', mockSetEndRange])

    render(<Filters />)
    
    const startDateInput = screen.getByLabelText('Filtrar desde')
    fireEvent.change(startDateInput, { target: { value: '' } })
    
    expect(mockSetStartRange).toHaveBeenCalledWith(null)
  })

  it('has proper CSS classes for styling', () => {
    render(<Filters />)
    
    const container = screen.getByLabelText('Filtrar desde').closest('.flex.flex-col.sm\\:flex-row.sm\\:items-end.sm\\:justify-between.gap-4')
    expect(container).toBeInTheDocument()
    
    const startDateInput = screen.getByLabelText('Filtrar desde')
    expect(startDateInput).toHaveClass('block', 'w-full', 'rounded-md', 'border-gray-300', 'shadow-sm', 'focus:border-indigo-500', 'focus:ring-indigo-500', 'sm:text-sm')
  })

  describe('formatDateForInput utility function', () => {
    it('handles null input', () => {
      mockUseQueryState
        .mockReturnValueOnce([null, mockSetStartRange])
        .mockReturnValueOnce([null, mockSetEndRange])

      render(<Filters />)
      
      const startDateInput = screen.getByLabelText('Filtrar desde') as HTMLInputElement
      expect(startDateInput.value).toBe('')
    })

    it('formats ISO date string correctly', () => {
      mockUseQueryState
        .mockReturnValueOnce(['2023-12-25T14:30:00.000Z', mockSetStartRange])
        .mockReturnValueOnce([null, mockSetEndRange])

      render(<Filters />)
      
      const startDateInput = screen.getByLabelText('Filtrar desde') as HTMLInputElement
      expect(startDateInput.value).toBe('2023-12-25')
    })

    it('handles date string without time part', () => {
      mockUseQueryState
        .mockReturnValueOnce(['2023-12-25', mockSetStartRange])
        .mockReturnValueOnce([null, mockSetEndRange])

      render(<Filters />)
      
      const startDateInput = screen.getByLabelText('Filtrar desde') as HTMLInputElement
      expect(startDateInput.value).toBe('2023-12-25')
    })
  })
})
