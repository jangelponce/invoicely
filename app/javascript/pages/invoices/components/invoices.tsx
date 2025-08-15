import { useEffect, useState } from "react";
import { useQueryState } from "nuqs";
import { Loading } from "./loading";
import { StatusBadge } from "./status-badge";
import { SortIcon } from "./sort-icon"; 
import { Filters } from "./filters";
import type { SortField, Invoice } from "../types";


const formatDate = (dateString: string) => {
  const dateParts = dateString.split('T')[0].split('-');
  const year = parseInt(dateParts[0]);
  const month = parseInt(dateParts[1]) - 1;
  const day = parseInt(dateParts[2]);
  
  const date = new Date(year, month, day);
  
  return date.toLocaleDateString('es-MX', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
};

const formatCurrency = (amount: string) => {
  return new Intl.NumberFormat('es-MX', {
    style: 'currency',
    currency: 'MXN'
  }).format(parseFloat(amount));
};

export const Invoices = () => {
  const [startRange] = useQueryState("start_range");
  const [endRange] = useQueryState("end_range");
  const [page] = useQueryState("page");
  const [perPage] = useQueryState("per_page");
  const [sort, setSort] = useQueryState("sort");
  const [direction, setDirection] = useQueryState("direction");

  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchInvoices = async () => {
      setLoading(true);
      try {
        const params = new URLSearchParams();
        if (startRange) params.append("start_range", startRange);
        if (endRange) params.append("end_range", endRange);
        if (page) params.append("page", page);
        if (perPage) params.append("per_page", perPage);
        if (sort) params.append("sort", sort);
        if (direction) params.append("direction", direction);
        
        const response = await fetch(`/invoices?${params.toString()}`, {
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/json"
          }
        });

        if (!response.ok) {
          return
        }

        const data = await response.json();
        setInvoices(data.invoices || []);
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

  if (loading) {
    return <Loading />;
  }

  return (
    <div className="space-y-6">
      <div className="bg-white shadow-sm rounded-lg">
        <div className="flex justify-between items-center px-6 py-4 border-b border-gray-200">
          <h1 className="text-2xl font-semibold text-gray-900">Facturas</h1>
          <Filters />
        </div>

        {invoices.length === 0 ? (
          <div className="text-center py-12 h-[calc(100vh-200px)]">
            <div className="flex flex-col items-center justify-center h-full">
              <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              <h3 className="mt-2 text-sm font-medium text-gray-900">No hay facturas</h3>
              <p className="mt-1 text-sm text-gray-500">Intenta ajustar los filtros.</p>
            </div>
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
                        <span>Número de factura</span>
                        <SortIcon field="invoice_number" sort={sort} direction={direction} />
                      </div>
                    </th>
                    <th
                      scope="col"
                      className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                      onClick={() => handleSort('invoice_date')}
                    >
                      <div className="flex items-center space-x-1">
                        <span>Fecha</span>
                        <SortIcon field="invoice_date" sort={sort} direction={direction} />
                      </div>
                    </th>
                    <th
                      scope="col"
                      className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                      onClick={() => handleSort('status')}
                    >
                      <div className="flex items-center space-x-1">
                        <span>Estatus</span>
                        <SortIcon field="status" sort={sort} direction={direction} />
                      </div>
                    </th>
                    <th
                      scope="col"
                      className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                      onClick={() => handleSort('total')}
                    >
                      <div className="flex items-center space-x-1">
                        <span>Total</span>
                        <SortIcon field="total" sort={sort} direction={direction} />
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
                        <StatusBadge status={invoice.status} />
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
