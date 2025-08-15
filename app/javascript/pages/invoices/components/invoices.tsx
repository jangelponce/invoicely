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

export const Invoices = () => {
  const [startRange] = useQueryState("startRange");
  const [endRange] = useQueryState("endRange");
  const [page] = useQueryState("page");
  const [perPage] = useQueryState("perPage");
  const [sort] = useQueryState("sort");
  const [direction] = useQueryState("direction");

  const [invoices, setInvoices] = useState<Invoice[]>([]);

  useEffect(() => {
    const fetchInvoices = async () => {
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
    };

    fetchInvoices();
  }, [startRange, endRange]);

  return (
    <div>
      <h1>Invoices</h1>
      <ul>
        {invoices.map((invoice) => (
          <li key={invoice.id}>{invoice.invoice_number}</li>
        ))}
      </ul>
    </div>
  );
};
