export type SortField = 'invoice_number' | 'invoice_date' | 'total' | 'status';
export type Invoice = {
  id: string;
  active: boolean;
  invoice_date: string;
  invoice_number: string;
  status: string;
  total: string;
};