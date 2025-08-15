import { useEffect, useState } from "react";
import { useQueryState } from "nuqs";

interface Invoice {
  id: string;
  active: boolean;
  invoice_date: string;
  invoice_number: string;
  status: string;
  total: string;
}

type SortField = 'invoice_number' | 'invoice_date' | 'total' | 'status';

export const Invoices = () => {
  const [startRange, setStartRange] = useQueryState("startRange");
  const [endRange, setEndRange] = useQueryState("endRange");
  const [page] = useQueryState("page");
  const [perPage] = useQueryState("perPage");
  const [sort, setSort] = useQueryState("sort");
  const [direction, setDirection] = useQueryState("direction");

  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchInvoices = async () => {
      setLoading(true);
      try {
        const params = new URLSearchParams();
        if (startRange) params.append("startRange", startRange);
        if (endRange) params.append("endRange", endRange);
        if (page) params.append("page", page);
        if (perPage) params.append("perPage", perPage);
        if (sort) params.append("sort", sort);
        if (direction) params.append("direction", direction);
        
        const response = await fetch(`/invoices.json?${params.toString()}`);
        const data = await response.json();
        setInvoices(data.invoices);
      } catch (error) {
        console.error('Failed to fetch invoices:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchInvoices();
  }, [startRange, endRange, page, perPage, sort, direction]);

  const handleSort = (field: SortField) => {
    if (sort === field) {
      setDirection(direction === 'asc' ? 'desc' : 'asc');
    } else {
      setSort(field);
      setDirection('desc');
    }
  };

  const handleDateRangeChange = (start: string, end: string) => {
    setStartRange(start || null);
    setEndRange(end || null);
  };

  const clearFilters = () => {
    setStartRange(null);
    setEndRange(null);
  };

  const formatDateForInput = (dateString: string | null) => {
    if (!dateString) return '';
    return new Date(dateString).toISOString().split('T')[0];
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  const formatCurrency = (amount: string) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(parseFloat(amount));
  };

  const getStatusBadge = (status: string) => {
    const statusClasses = {
      paid: 'bg-green-100 text-green-800',
      pending: 'bg-yellow-100 text-yellow-800',
      overdue: 'bg-red-100 text-red-800',
      draft: 'bg-gray-100 text-gray-800'
    };
    
    const className = statusClasses[status as keyof typeof statusClasses] || statusClasses.draft;
    
    return (
      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${className}`}>
        {status.charAt(0).toUpperCase() + status.slice(1)}
      </span>
    );
  };

  const getSortIcon = (field: SortField) => {
    if (sort !== field) {
      return (
        <svg className="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 9l4-4 4 4m0 6l-4 4-4-4" />
        </svg>
      );
    }
    
    return direction === 'asc' ? (
      <svg className="w-4 h-4 text-gray-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 15l7-7 7 7" />
      </svg>
    ) : (
      <svg className="w-4 h-4 text-gray-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
      </svg>
    );
  };

  if (loading) {
    return (
      <div className="bg-white shadow-sm rounded-lg">
        <div className="px-6 py-4 border-b border-gray-200">
          <h1 className="text-2xl font-semibold text-gray-900">Invoices</h1>
        </div>
        <div className="p-6">
          <div className="animate-pulse">
            <div className="space-y-3">
              {[...Array(5)].map((_, i) => (
                <div key={i} className="grid grid-cols-4 gap-4">
                  <div className="h-4 bg-gray-200 rounded"></div>
                  <div className="h-4 bg-gray-200 rounded"></div>
                  <div className="h-4 bg-gray-200 rounded"></div>
                  <div className="h-4 bg-gray-200 rounded"></div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Date Range Filter */}
      <div className="bg-white shadow-sm rounded-lg">
        <div className="px-6 py-4">
          <div className="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-4">
            <div className="flex flex-col sm:flex-row gap-4">
              <div className="flex flex-col">
                <label htmlFor="start-date" className="text-sm font-medium text-gray-700 mb-1">
                  Start Date
                </label>
                <input
                  type="date"
                  id="start-date"
                  value={formatDateForInput(startRange)}
                  onChange={(e) => handleDateRangeChange(e.target.value, endRange || '')}
                  className="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                />
              </div>
              <div className="flex flex-col">
                <label htmlFor="end-date" className="text-sm font-medium text-gray-700 mb-1">
                  End Date
                </label>
                <input
                  type="date"
                  id="end-date"
                  value={formatDateForInput(endRange)}
                  onChange={(e) => handleDateRangeChange(startRange || '', e.target.value)}
                  className="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                />
              </div>
            </div>
            <div className="flex gap-2">
              {(startRange || endRange) && (
                <button
                  onClick={clearFilters}
                  className="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                  Clear
                </button>
              )}
              <div className="text-sm text-gray-500 flex items-center">
                {startRange && endRange && (
                  <span>
                    {formatDate(startRange)} - {formatDate(endRange)}
                  </span>
                )}
                {startRange && !endRange && (
                  <span>From {formatDate(startRange)}</span>
                )}
                {!startRange && endRange && (
                  <span>Until {formatDate(endRange)}</span>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Invoice Table */}
      <div className="bg-white shadow-sm rounded-lg">
        <div className="px-6 py-4 border-b border-gray-200">
          <h1 className="text-2xl font-semibold text-gray-900">Invoices</h1>
        </div>
      
      {invoices.length === 0 ? (
        <div className="text-center py-12">
          <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
          <h3 className="mt-2 text-sm font-medium text-gray-900">No invoices</h3>
          <p className="mt-1 text-sm text-gray-500">Get started by creating a new invoice.</p>
        </div>
      ) : (
        <div className="overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th
                    scope="col"
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    onClick={() => handleSort('invoice_number')}
                  >
                    <div className="flex items-center space-x-1">
                      <span>Invoice #</span>
                      {getSortIcon('invoice_number')}
                    </div>
                  </th>
                  <th
                    scope="col"
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    onClick={() => handleSort('invoice_date')}
                  >
                    <div className="flex items-center space-x-1">
                      <span>Date</span>
                      {getSortIcon('invoice_date')}
                    </div>
                  </th>
                  <th
                    scope="col"
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    onClick={() => handleSort('status')}
                  >
                    <div className="flex items-center space-x-1">
                      <span>Status</span>
                      {getSortIcon('status')}
                    </div>
                  </th>
                  <th
                    scope="col"
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                    onClick={() => handleSort('total')}
                  >
                    <div className="flex items-center space-x-1">
                      <span>Amount</span>
                      {getSortIcon('total')}
                    </div>
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {invoices.map((invoice) => (
                  <tr key={invoice.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-gray-900">
                        {invoice.invoice_number}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900">
                        {formatDate(invoice.invoice_date)}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {getStatusBadge(invoice.status)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-gray-900">
                        {formatCurrency(invoice.total)}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
      </div>
    </div>
  );
};
