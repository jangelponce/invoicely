import { useQueryState } from "nuqs";

const formatDateForInput = (dateString: string | null) => {
  if (!dateString) return '';
  return dateString.split('T')[0];
};

export const Filters = () => {
  const [startRange, setStartRange] = useQueryState("startRange");
  const [endRange, setEndRange] = useQueryState("endRange");

  const handleDateRangeChange = (start: string, end: string) => {
    setStartRange(start || null);
    setEndRange(end || null);
  };

  return (
    <div className="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-4">
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="flex flex-col">
          <label htmlFor="start-date" className="text-sm font-medium text-gray-700 mb-1">
            Filtrar desde
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
            hasta
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
    </div>
  );
};